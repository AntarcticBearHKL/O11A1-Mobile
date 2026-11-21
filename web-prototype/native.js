(() => {
  const bridge = window.O11A1Native;
  if (!bridge || typeof bridge.available !== 'function' || !bridge.available()) return;
  const host = window.O11A1Host;
  if (!host) return;
  const state = host.state;

  document.body.classList.add('native-app');

  const $ = (sel, root = document) => root.querySelector(sel);
  const parse = (raw) => {
    try { return JSON.parse(raw); } catch (_) { return { ok: false, error: 'bad json' }; }
  };
  const esc = (value) => String(value == null ? '' : value)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  const attr = (value) => esc(value).replace(/`/g, '&#96;');
  const log = (message) => { try { bridge.log(String(message)); } catch (_) {} };

  const feeds = {
    home: host.homeFeed,
    search: host.searchResults,
    module: host.moduleFeed,
  };
  const pages = { home: 1, search: 1, module: 1 };
  let searchTimer = null;

  // The delivered design starts with three demo queue rows. In the real app those are cleared.
  if (state.playlist.length && state.playlist.every((item) => !item.bvid)) {
    state.playlist = [];
    state.currentIndex = 0;
    host.updatePlayerLabels();
    host.updatePlaylistCounts();
    host.save();
  }

  function renderRows(feed, items) {
    feed.innerHTML = '';
    feed.__nativeItems = items;
    const fragment = document.createDocumentFragment();
    items.forEach((item, index) => {
      const row = document.createElement('button');
      row.type = 'button';
      row.className = 'video-row real-row';
      row.__nativeItem = item;
      row.dataset.nativeIndex = String(index);
      const pic = item.pic || '';
      row.innerHTML = `
        <span class="row-thumb real">
          ${pic ? `<img src="${attr(pic)}" alt="" loading="lazy" referrerpolicy="no-referrer">` : ''}
          <span class="dur-ph">${esc(item.duration || '00:00')}</span>
        </span>
        <span class="row-copy">
          <span class="real-title">${esc(item.title || '视频')}</span>
          <span class="real-meta">${esc(item.meta || item.owner || '')}</span>
        </span>`;
      const image = $('img', row);
      if (image) image.addEventListener('error', () => image.remove());
      row.addEventListener('click', (event) => {
        if (host.isFeedClickSuppressed && host.isFeedClickSuppressed()) return;
        event.preventDefault();
        event.stopPropagation();
        playItem(item);
      });
      fragment.appendChild(row);
    });
    feed.appendChild(fragment);
  }

  function popularItems(page) {
    const result = parse(bridge.popular(page, 20));
    if (!result.ok) { log('popular error ' + (result.error || '')); return []; }
    return result.items || [];
  }

  function searchItems(query, page) {
    const result = parse(bridge.search(query, page));
    if (!result.ok) { log('search error ' + (result.error || '')); return []; }
    return result.items || [];
  }

  function setNote(text) {
    const note = $('#homeNote');
    if (note) note.textContent = text;
  }

  function loadHome(page) {
    const items = popularItems(page || 1);
    if (!items.length) return false;
    renderRows(feeds.home, items);
    setNote('B 站热门 · 下拉刷新 / 触底刷新');
    return true;
  }

  function loadSearch(query, page) {
    const items = query ? searchItems(query, page || 1) : popularItems(page || 1);
    if (!items.length) {
      feeds.search.innerHTML = '';
      feeds.search.__nativeItems = [];
      host.searchResultsLabel.textContent = query ? `“${query}”的视频` : '热门视频';
      host.searchEmpty.hidden = Boolean(query);
      return false;
    }
    renderRows(feeds.search, items);
    host.searchResultsLabel.textContent = query ? `“${query}”的视频` : '热门视频';
    host.searchEmpty.hidden = true;
    return true;
  }

  function moduleKeyword() {
    const name = state.moduleName || '推荐';
    if (['下载', '会员', '设置'].includes(name)) return 'B站';
    return name;
  }

  function loadModule(page) {
    const keyword = moduleKeyword();
    const items = keyword === '推荐' ? popularItems(page || 1) : searchItems(keyword, page || 1);
    if (!items.length) return false;
    renderRows(feeds.module, items);
    const filter = $('#moduleFilter');
    if (filter) filter.textContent = `${keyword} · 最新`;
    return true;
  }

  function playItem(item) {
    let index = state.playlist.findIndex((entry) => entry.bvid === item.bvid);
    if (index < 0) {
      state.playlist.push(Object.assign({ id: `n${Date.now()}` }, item, {
        key: `bvid:${item.bvid}`,
        title: item.title,
        meta: item.meta || `${item.owner || 'UP'} · ${item.duration || ''}`,
      }));
      index = state.playlist.length - 1;
    } else {
      state.playlist[index] = Object.assign({}, state.playlist[index], item);
    }
    state.currentIndex = index;
    state.duration = 0;
    state.progress = 0;
    state.playing = true;
    host.save();
    host.updatePlayerLabels();
    host.openPlayer({ resume: true });
  }

  /* ---------- media ---------- */
  const video = $('#realVideo');
  const playerVideo = host.playerVideo;
  const status = $('#realVideoStatus');
  const danmakuLayer = document.createElement('div');
  danmakuLayer.className = 'danmaku-layer';
  playerVideo.appendChild(danmakuLayer);
  let danmakuItems = [];
  let danmakuIndex = 0;
  let danmakuLastTime = 0;
  let danmakuLane = 0;
  let mediaItem = null;
  let mediaBackup = '';
  let mediaTriedBackup = false;

  function setStatus(text, mode) {
    if (!status) return;
    status.textContent = text || '';
    playerVideo.classList.toggle('video-loading', mode === 'loading');
    playerVideo.classList.toggle('video-error', mode === 'error');
  }

  function loadDanmaku(cid) {
    danmakuItems = [];
    danmakuIndex = 0;
    danmakuLastTime = 0;
    danmakuLane = 0;
    if (danmakuLayer) danmakuLayer.innerHTML = '';
    if (!cid || typeof bridge.danmaku !== 'function') return;
    const result = parse(bridge.danmaku(cid));
    if (!result.ok || !Array.isArray(result.items)) {
      log('danmaku error ' + (result.error || ''));
      return;
    }
    danmakuItems = result.items
      .filter((row) => row && Number.isFinite(Number(row.t)) && row.text)
      .map((row) => ({ t: Number(row.t), text: String(row.text), color: Number(row.color || 0xffffff), mode: Number(row.mode || 1) }))
      .sort((a, b) => a.t - b.t);
    if (danmakuLayer) danmakuLayer.style.display = state.settings.danmaku ? 'block' : 'none';
  }

  function spawnDanmaku(row) {
    if (!danmakuLayer || !state.settings.danmaku) return;
    const item = document.createElement('span');
    item.className = 'danmaku-item';
    const color = row.color && row.color !== 0xffffff ? '#' + Number(row.color).toString(16).padStart(6, '0') : '#ffffff';
    item.textContent = row.text;
    item.style.color = color;
    item.style.top = `${8 + (danmakuLane % 8) * 9}%`;
    const seconds = Math.max(7, Math.min(14, 8 + String(row.text).length * 0.08));
    item.style.animationDuration = `${seconds}s`;
    danmakuLane += 1;
    item.addEventListener('animationend', () => item.remove());
    danmakuLayer.appendChild(item);
  }

  function tickDanmaku(currentTime) {
    if (!danmakuItems.length || !state.settings.danmaku) return;
    if (currentTime < danmakuLastTime - 1) {
      danmakuIndex = 0;
      if (danmakuLayer) danmakuLayer.innerHTML = '';
    }
    danmakuLastTime = currentTime;
    while (danmakuIndex < danmakuItems.length && danmakuItems[danmakuIndex].t <= currentTime) {
      const row = danmakuItems[danmakuIndex];
      danmakuIndex += 1;
      if (row.t >= currentTime - 0.8) spawnDanmaku(row);
    }
  }

  function sendDanmaku(text) {
    if (!state.settings.danmaku || !text) return;
    spawnDanmaku({ t: video.currentTime || 0, text, color: 0xffffff, mode: 1 });
  }

  function currentItem() {
    return state.playlist[state.currentIndex] || null;
  }

  function clearVideo() {
    mediaItem = null;
    mediaBackup = '';
    mediaTriedBackup = false;
    danmakuItems = [];
    danmakuIndex = 0;
    danmakuLastTime = 0;
    if (danmakuLayer) danmakuLayer.innerHTML = '';
    state.duration = 0;
    try {
      video.pause();
      video.removeAttribute('src');
      video.load();
    } catch (_) {}
    playerVideo.classList.remove('has-video', 'video-loading', 'video-error');
    if (status) status.textContent = '';
  }

  function loadVideo(item, autoplay) {
    if (!item || !item.bvid) {
      clearVideo();
      return;
    }
    if (mediaItem && mediaItem.bvid === item.bvid && video.src) {
      if (autoplay) video.play().catch(() => {});
      return;
    }
    mediaItem = item;
    mediaTriedBackup = false;
    mediaBackup = '';
    state.duration = 0;
    playerVideo.classList.remove('has-video', 'video-error');
    playerVideo.classList.add('video-loading');
    setStatus('加载中…', 'loading');
    const result = parse(bridge.play(item.bvid, item.cid || 0));
    if (!result.ok) {
      setStatus('加载失败 · 点击重试', 'error');
      log('play error ' + (item.bvid || '') + ' ' + (result.error || ''));
      return;
    }
    if (result.cid) {
      item.cid = result.cid;
      const entry = currentItem();
      if (entry) entry.cid = result.cid;
    }
    if (result.qualityLabel) {
      state.settings.quality = result.qualityLabel;
      host.updatePlayerLabels();
    }
    loadDanmaku(result.cid || item.cid);
    mediaBackup = result.backup || '';
    video.src = result.url;
    video.load();
    playerVideo.classList.add('has-video');
    if (autoplay) {
      video.play().then(() => {
        state.playing = true;
        host.pcPlay.textContent = 'Ⅱ';
        host.updatePlaylistDock();
      }).catch(() => {
        state.playing = false;
        host.pcPlay.textContent = '▶';
        setStatus('点击播放', 'error');
      });
    }
  }

  video.addEventListener('loadedmetadata', () => {
    state.duration = Number.isFinite(video.duration) ? video.duration : 0;
    if (state.duration > 0) host.setProgress(video.currentTime / state.duration * 100);
    playerVideo.classList.remove('video-loading');
  });
  video.addEventListener('timeupdate', () => {
    if (!video.duration || !Number.isFinite(video.duration)) return;
    host.setProgress(video.currentTime / video.duration * 100);
    tickDanmaku(video.currentTime);
  });
  video.addEventListener('play', () => {
    state.playing = true;
    host.pcPlay.textContent = 'Ⅱ';
    host.updatePlaylistDock();
    playerVideo.classList.remove('video-loading');
    if (danmakuLayer) danmakuLayer.classList.remove('paused');
    if (status) status.textContent = '';
  });
  video.addEventListener('pause', () => {
    state.playing = false;
    host.pcPlay.textContent = '▶';
    host.updatePlaylistDock();
    if (danmakuLayer) danmakuLayer.classList.add('paused');
  });
  video.addEventListener('waiting', () => {
    playerVideo.classList.add('video-loading');
    if (status) status.textContent = '缓冲中…';
  });
  video.addEventListener('playing', () => {
    playerVideo.classList.remove('video-loading', 'video-error');
    if (status) status.textContent = '';
  });
  video.addEventListener('error', () => {
    if (mediaBackup && !mediaTriedBackup) {
      mediaTriedBackup = true;
      video.src = mediaBackup;
      video.load();
      video.play().catch(() => {});
      return;
    }
    setStatus('播放失败 · 点击重试', 'error');
    log('video element error ' + (mediaItem ? mediaItem.bvid : ''));
  });
  video.addEventListener('ended', () => {
    if (state.settings.loop === '循环') {
      video.currentTime = 0;
      video.play().catch(() => {});
    } else if (state.settings.loop === '下一分P' || state.settings.loop === '继续') {
      host.stepTrack(1);
    } else {
      state.playing = false;
      host.pcPlay.textContent = '▶';
    }
  });
  if (status) status.addEventListener('click', () => {
    if (!playerVideo.classList.contains('video-error') || !mediaItem) return;
    const item = mediaItem;
    clearVideo();
    loadVideo(item, true);
  });

  window.O11A1Media = {
    onOpen() {
      loadVideo(currentItem(), Boolean(state.playing));
    },
    onMinimize() {
      // Same session: audio continues; nothing to do.
    },
    onStop() {
      clearVideo();
    },
    togglePlay() {
      if (!video.src) return false;
      if (video.paused) video.play().catch(() => {});
      else video.pause();
      return true;
    },
    seek(percent) {
      if (!video.duration || !Number.isFinite(video.duration)) return;
      video.currentTime = video.duration * Math.max(0, Math.min(100, percent)) / 100;
    },
    onVolume(value) {
      video.volume = Math.max(0, Math.min(100, value)) / 100;
      video.muted = Number(value) === 0;
    },
    onSettings() {
      if (danmakuLayer) danmakuLayer.style.display = state.settings.danmaku ? 'block' : 'none';
      if (!video.src) return;
      const rate = parseFloat(state.settings.speed || '1');
      video.playbackRate = Number.isFinite(rate) && rate > 0 ? rate : 1;
      video.loop = state.settings.loop === '循环';
    },
    onTrackChange() {
      loadVideo(currentItem(), true);
    },
    onDanmakuSend(text) {
      sendDanmaku(text);
    },
    onRateHold(rate) {
      if (!video.src) return;
      video.playbackRate = rate;
    },
    onRateHoldEnd() {
      if (!video.src) return;
      const rate = parseFloat(state.settings.speed || '1');
      video.playbackRate = Number.isFinite(rate) && rate > 0 ? rate : 1;
    },
    onQualityChange(value) {
      if (!mediaItem || !video.src || typeof bridge.playQuality !== 'function') return;
      const map = { '4K': 120, '1080P60': 116, '1080P': 80, '720P': 64, '480P': 32, '仅音频': 16 };
      const qn = map[value] || 64;
      const keepTime = video.currentTime || 0;
      const wasPlaying = !video.paused;
      const result = parse(bridge.playQuality(mediaItem.bvid, mediaItem.cid || 0, qn));
      if (!result.ok || !result.url) return;
      mediaBackup = result.backup || '';
      mediaTriedBackup = false;
        if (result.qualityLabel) {
        state.settings.quality = result.qualityLabel;
        host.updatePlayerLabels();
      }
      playerVideo.classList.add('video-loading');
      setStatus('切换画质…', 'loading');
      const onMeta = () => {
        video.removeEventListener('loadedmetadata', onMeta);
        if (keepTime > 0 && Number.isFinite(video.duration)) {
          video.currentTime = Math.min(keepTime, Math.max(0, video.duration - 0.5));
        }
        if (wasPlaying) video.play().catch(() => {});
        playerVideo.classList.remove('video-loading');
        setStatus('', '');
      };
      video.addEventListener('loadedmetadata', onMeta);
      video.src = result.url;
      video.load();
    },
  };

  /* ---------- comments ---------- */
  function loadComments() {
    const item = currentItem();
    const aid = item && item.aid ? Number(item.aid) : 0;
    if (!aid) return;
    const result = parse(bridge.comments(aid, 1));
    if (!result.ok || !Array.isArray(result.items)) {
      log('comments error ' + (result.error || ''));
      return;
    }
    host.commentsBody.innerHTML = result.items.map((row) => `
      <div class="comment-row">
        ${row.avatar ? `<img class="comment-avatar" src="${attr(row.avatar)}" alt="" referrerpolicy="no-referrer">` : '<span class="avatar-ph sm"></span>'}
        <div class="comment-text">
          <b>${esc(row.user || '用户')}</b>
          <p>${esc(row.message || '')}</p>
          <small>赞 ${Number(row.like || 0)}</small>
        </div>
      </div>`).join('');
    host.commentsCount.textContent = `${result.count || result.items.length} 条`;
  }

  window.O11A1NativeData = {
    refresh(key) {
      if (key === 'home') {
        pages.home += 1;
        return loadHome(pages.home);
      }
      if (key === 'search') {
        pages.search += 1;
        const query = host.searchInput.value.trim();
        return loadSearch(query, pages.search);
      }
      if (key === 'module') {
        pages.module += 1;
        return loadModule(pages.module);
      }
      return false;
    },
    onComments: loadComments,
  };

  /* ---------- live QR login ---------- */
  const qr = $('#loginQr');
  const qrImage = $('#loginQrImage');
  let qrKey = '';
  let qrTimer = null;
  let qrLoading = false;

  function stopQr() {
    clearInterval(qrTimer);
    qrTimer = null;
    qrKey = '';
  }

  function startQr() {
    if (qrLoading) return;
    qrLoading = true;
    host.loginStatus.textContent = '正在获取二维码…';
    try {
      const result = parse(bridge.qrGenerate());
      if (!result.ok || !result.image) {
        host.loginStatus.textContent = '二维码加载失败 · 可用模拟登录';
        qr.classList.remove('has-real-qr');
        qrLoading = false;
        return;
      }
      qrKey = result.key || '';
      qrImage.src = `data:image/png;base64,${result.image}`;
      qr.classList.add('has-real-qr');
      host.loginStatus.textContent = '打开 B 站 App 扫码登录';
      clearInterval(qrTimer);
      qrTimer = setInterval(pollQr, 2200);
    } catch (error) {
      host.loginStatus.textContent = '二维码加载失败 · 可用模拟登录';
      log('qr generate ' + error);
    }
    qrLoading = false;
  }

  function pollQr() {
    if (!qrKey) return;
    try {
      const result = parse(bridge.qrPoll(qrKey));
      if (!result.ok) return;
      if (Number(result.code) === 0) {
        stopQr();
        state.loggedIn = true;
        host.save();
        host.showPage('home');
        pages.home = 1;
        loadHome(1);
        host.loginStatus.textContent = '已登录';
      } else if (Number(result.code) === 86090) {
        host.loginStatus.textContent = '已扫码 · 请在手机上确认';
      } else if (Number(result.code) === 86101) {
        host.loginStatus.textContent = '等待扫码…';
      } else if (Number(result.code) === 86038) {
        host.loginStatus.textContent = '二维码已过期 · 正在刷新';
        stopQr();
        startQr();
      }
    } catch (error) {
      log('qr poll ' + error);
    }
  }

  function maybeStartQr() {
    if (state.page !== 'login' || qr.classList.contains('has-real-qr') || qrLoading) return;
    startQr();
  }

  qr.addEventListener('click', (event) => {
    if (qr.classList.contains('has-real-qr')) {
      event.preventDefault();
      event.stopImmediatePropagation();
      stopQr();
      startQr();
    }
  }, true);
  const refreshButton = $('#loginRefresh');
  if (refreshButton) refreshButton.addEventListener('click', (event) => {
    event.preventDefault();
    event.stopImmediatePropagation();
    stopQr();
    startQr();
  }, true);

  const loginNote = $('.login-note');
  if (loginNote) loginNote.innerHTML = '登录后同步收藏 / 历史 / 大会员画质<br>扫码登录，或使用「模拟登录」直接进入';

  const pageObserver = new MutationObserver(() => {
    if (state.page === 'login') maybeStartQr();
    if (state.page === 'home' && !feeds.home.querySelector('.real-row') && state.loggedIn) {
      pages.home = 1;
      loadHome(1);
    }
    if (state.page === 'module') {
      pages.module = 1;
      loadModule(1);
    }
  });
  pageObserver.observe(host.app, { attributes: true, attributeFilter: ['data-page'] });

  /* ---------- search ---------- */
  host.searchInput.addEventListener('input', () => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      pages.search = 1;
      const query = host.searchInput.value.trim();
      loadSearch(query, 1);
    }, 320);
  });

  /* ---------- first data load ---------- */
  setTimeout(() => {
    if (state.page === 'login') maybeStartQr();
    if (state.page === 'search') loadSearch(host.searchInput.value.trim(), 1);
    if (state.page === 'module') loadModule(1);
    if (state.loggedIn) loadHome(1);
  }, 120);
})();

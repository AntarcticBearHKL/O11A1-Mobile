(() => {
  const bridge = window.O11A1Native;
  if (!bridge || typeof bridge.available !== 'function' || !bridge.available()) return;
  const host = window.O11A1Host;
  if (!host) return;
  const state = host.state;

  document.body.classList.add('native-app');

  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));
  const parse = (raw) => {
    try { return JSON.parse(raw); } catch (_) { return { ok: false, error: 'bad json' }; }
  };
  const esc = (value) => String(value == null ? '' : value)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  const attr = (value) => esc(value).replace(/`/g, '&#96;');
  const log = (message) => { try { bridge.log(String(message)); } catch (_) {} };
  const call = (name, ...args) => {
    if (typeof bridge[name] !== 'function') return { ok: false, error: `不支持 ${name}` };
    try { return parse(bridge[name](...args)); } catch (error) { return { ok: false, error: String(error) }; }
  };

  const feeds = {
    home: host.homeFeed,
    search: host.searchResults,
    module: host.moduleFeed,
  };
  const pages = { home: 1, search: 1, module: 1, dynamic: 1, messages: 1 };
  const cursors = { home: '', module: '' };
  const more = { home: true, module: true, dynamic: true, messages: true };
  const dynamicFilterNames = ['全部', '视频', '图文'];
  const messageFilterNames = ['回复', '@我', '收到的赞', '私信'];
  const moduleFilterNames = {
    '番剧': ['番剧', '国创', '电影'],
    '影视': ['电影', '纪录片', '电视剧'],
    '分区': ['动画', '音乐', '游戏', '科技'],
  };
  const moduleSeasonTypes = {
    '番剧': [1, 4, 2],
    '影视': [2, 3, 5],
  };
  const moduleZones = [1, 3, 4, 36];
  let searchTimer = null;
  let accountInfo = null;

  // The delivered design starts with three demo queue rows. In the real app those are cleared.
  if (state.playlist.length && state.playlist.every((item) => !item.bvid && !item.epId && !item.roomId)) {
    state.playlist = [];
    state.currentIndex = 0;
    host.updatePlayerLabels();
    host.updatePlaylistCounts();
    host.save();
  }

  function countText(value) {
    const n = Number(value || 0);
    if (n >= 100000000) return `${(n / 100000000).toFixed(1)} 亿`;
    if (n >= 10000) return `${(n / 10000).toFixed(1)} 万`;
    return String(n);
  }

  function timeAgo(value) {
    const raw = Number(value || 0);
    if (!raw) return '';
    const seconds = raw > 100000000000 ? raw / 1000 : raw;
    const delta = Math.max(0, Date.now() / 1000 - seconds);
    if (delta < 60) return '刚刚';
    if (delta < 3600) return `${Math.floor(delta / 60)} 分钟前`;
    if (delta < 86400) return `${Math.floor(delta / 3600)} 小时前`;
    if (delta < 86400 * 30) return `${Math.floor(delta / 86400)} 天前`;
    const date = new Date(seconds * 1000);
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
  }

  function setNote(text) {
    const note = $('#homeNote');
    if (note) note.textContent = text;
  }

  function renderEmpty(feed, title, detail, actionLabel, action) {
    feed.__nativeItems = [];
    feed.innerHTML = `
      <div class="native-empty">
        <b>${esc(title || '暂无内容')}</b>
        ${detail ? `<span>${esc(detail)}</span>` : ''}
        ${actionLabel ? `<button class="pill-btn" type="button">${esc(actionLabel)}</button>` : ''}
      </div>`;
    const button = feed.querySelector('button');
    if (button && action) button.addEventListener('click', action);
  }

  function renderRows(feed, items, label) {
    feed.innerHTML = '';
    feed.__nativeItems = items;
    const fragment = document.createDocumentFragment();
    items.forEach((item, index) => {
      const row = document.createElement('button');
      row.type = 'button';
      row.className = `video-row real-row${item.live ? ' live-row' : ''}${item.seasonId ? ' season-row' : ''}`;
      row.__nativeItem = item;
      row.dataset.nativeIndex = String(index);
      const pic = item.pic || '';
      const progress = item.durationSec > 0 && item.progress > 0
        ? Math.min(100, Math.round(item.progress / item.durationSec * 100))
        : 0;
      row.innerHTML = `
        <span class="row-thumb real">
          ${pic ? `<img src="${attr(pic)}" alt="" loading="lazy" referrerpolicy="no-referrer">` : ''}
          ${item.live ? '<span class="live-badge">LIVE</span>' : ''}
          ${item.live ? '' : `<span class="dur-ph">${esc(item.duration || (item.seasonId ? '番剧' : '00:00'))}</span>`}
          ${progress ? `<span class="row-progress"><span style="width:${progress}%"></span></span>` : ''}
        </span>
        <span class="row-copy">
          <span class="real-title">${esc(item.title || '视频')}</span>
          <span class="real-meta">${esc(item.meta || item.owner || label || '')}</span>
        </span>`;
      const image = $('img', row);
      if (image) image.addEventListener('error', () => image.remove());
      row.addEventListener('click', (event) => {
        if (host.isFeedClickSuppressed && host.isFeedClickSuppressed()) return;
        event.preventDefault();
        event.stopPropagation();
        if (item.live) playLive(item);
        else if (item.seasonId && !item.epId) playSeason(item);
        else playItem(item);
      });
      fragment.appendChild(row);
    });
    feed.appendChild(fragment);
  }

  function feedResult(api, args) {
    return call(api, ...args);
  }

  function moduleKind(name) {
    const moduleName = name || state.moduleName || '推荐';
    const filterIndex = Math.max(0, Number(state.moduleFilterIndex) || 0);
    if (moduleName === '推荐' || moduleName === '热门') return { api: 'popular', args: [], label: 'B 站热门' };
    if (moduleName === '排行') return { api: 'ranking', args: [], label: '全站排行' };
    if (moduleName === '番剧') {
      const types = moduleSeasonTypes['番剧'];
      return { api: 'bangumi', args: [types[filterIndex % types.length]], label: moduleFilterNames['番剧'][filterIndex % 3] };
    }
    if (moduleName === '影视') {
      const types = moduleSeasonTypes['影视'];
      return { api: 'bangumi', args: [types[filterIndex % types.length]], label: moduleFilterNames['影视'][filterIndex % 3] };
    }
    if (moduleName === '直播') return { api: 'live', args: [], label: '直播推荐' };
    if (moduleName === '分区') {
      const rid = moduleZones[filterIndex % moduleZones.length];
      return { api: 'zone', args: [rid], label: moduleFilterNames['分区'][filterIndex % 4] };
    }
    if (moduleName === '关注') return { api: 'following', args: [], label: '关注的 UP' };
    if (moduleName === '收藏') return { api: 'favorites', args: [], label: '收藏夹' };
    if (moduleName === '历史') return { api: 'history', args: [], label: '历史', cursor: true };
    if (moduleName === '动态') return { api: 'following', args: [], label: '关注动态' };
    if (moduleName === '下载') return { api: null, note: '离线下载将在后续版本接入；当前可以边下边播。', label: '离线下载' };
    if (moduleName === '会员') return { api: null, note: '大会员信息以账号中心为准。', label: '大会员' };
    if (moduleName === '养鱼') return { api: null, note: '养鱼入口默认隐藏。', label: '养鱼' };
    return { api: 'search', args: [moduleName], label: moduleName };
  }

  function loadFeed(name, feed, page, cursor) {
    const kind = moduleKind(name);
    if (!kind.api) {
      renderEmpty(feed, kind.label, kind.note);
      return { ok: true, items: [], title: kind.label, needLogin: false };
    }
    if (kind.api === 'favorites' && !state.loggedIn) {
      renderEmpty(feed, '登录后查看收藏', '扫码登录后同步收藏夹。', '去登录', () => host.showPage('login'));
      return { ok: true, items: [], title: kind.label, needLogin: true };
    }
    if ((kind.api === 'history' || kind.api === 'following') && !state.loggedIn) {
      renderEmpty(feed, `登录后查看${kind.label}`, '扫码登录后同步 B 站账号。', '去登录', () => host.showPage('login'));
      return { ok: true, items: [], title: kind.label, needLogin: true };
    }
    const args = kind.api === 'popular' ? [page || 1, 20]
      : kind.api === 'history' ? [page || 1, cursor || '']
        : kind.api === 'favorites' || kind.api === 'ranking' || kind.api === 'live' || kind.api === 'following'
          ? [page || 1]
          : kind.api === 'bangumi' ? [page || 1, kind.args[0]]
            : kind.api === 'zone' ? [kind.args[0], page || 1]
              : kind.api === 'search'
                ? [name, page || 1]
                : [page || 1];
    const result = feedResult(kind.api, args);
    if (!result.ok) {
      if (result.needLogin) {
        renderEmpty(feed, `登录后查看${kind.label}`, '扫码登录后同步 B 站账号。', '去登录', () => host.showPage('login'));
      } else {
        renderEmpty(feed, `${kind.label}加载失败`, result.error || '网络错误', '重试', () => loadFeed(name, feed, 1, ''));
      }
      return { ok: false, items: [], title: kind.label, needLogin: Boolean(result.needLogin) };
    }
    const items = Array.isArray(result.items) ? result.items : [];
    if (items.length === 0) {
      renderEmpty(feed, result.note || `${kind.label}暂无内容`, result.hasMore === false ? '' : '下拉刷新或稍后再试');
    } else {
      renderRows(feed, items, kind.label);
    }
    return {
      ok: true,
      items,
      title: result.title || kind.label,
      next: result.next || '',
      hasMore: result.hasMore !== false,
      needLogin: false,
    };
  }

  function loadHome(page) {
    const module = state.modules.find((mod) => mod.id === state.moduleId && mod.on);
    const name = module ? module.name : '推荐';
    const kind = moduleKind(name);
    const result = loadFeed(name, feeds.home, page || 1, cursors.home);
    if (result.ok) {
      cursors.home = result.next || '';
      setNote(`${result.title || kind.label} · 下拉刷新 / 触底刷新`);
    } else {
      setNote(`${result.title || kind.label} · 加载失败`);
    }
    return true;
  }

  function loadModule(page) {
    const name = state.moduleName || '推荐';
    const kind = moduleKind(name);
    const result = loadFeed(name, feeds.module, page || 1, cursors.module);
    const filter = $('#moduleFilter');
    if (filter) filter.textContent = kind.label || name;
    if (result.ok) cursors.module = result.next || '';
    return true;
  }

  function loadSearch(query, page) {
    const items = query
      ? (feedResult('search', [query, page || 1]).items || [])
      : (feedResult('popular', [page || 1, 20]).items || []);
    if (!items.length) {
      renderEmpty(feeds.search, query ? `“${query}”暂无结果` : '热门视频加载失败', '', query ? '' : '重试', () => loadSearch(query, 1));
      host.searchResultsLabel.textContent = query ? `“${query}”的视频` : '热门视频';
      host.searchEmpty.hidden = true;
      return true;
    }
    renderRows(feeds.search, items, query ? '搜索结果' : '热门');
    host.searchResultsLabel.textContent = query ? `“${query}”的视频` : '热门视频';
    host.searchEmpty.hidden = true;
    return true;
  }

  function playItem(item) {
    if (!item) return;
    if (item.live) { playLive(item); return; }
    if (item.seasonId && !item.epId) { playSeason(item); return; }
    const key = item.epId ? `ep:${item.epId}` : item.roomId ? `live:${item.roomId}` : `bvid:${item.bvid}`;
    let index = state.playlist.findIndex((entry) => entry.key === key);
    if (index < 0) {
      state.playlist.push(Object.assign({ id: `n${Date.now()}` }, item, {
        key,
        title: item.title || '视频',
        meta: item.meta || `${item.owner || 'UP'} · ${item.duration || ''}`,
      }));
      index = state.playlist.length - 1;
    } else {
      state.playlist[index] = Object.assign({}, state.playlist[index], item, { key });
    }
    host.setCurrent(index);
    state.duration = 0;
    state.progress = 0;
    state.playing = true;
    host.save();
    host.updatePlayerLabels();
    host.openPlayer({ resume: true });
  }

  function playSeason(item) {
    const detail = call('season', item.seasonId);
    if (!detail.ok || !Array.isArray(detail.episodes) || !detail.episodes.length) {
      renderEmpty(feeds.module, '番剧加载失败', detail.error || '没有可播放的剧集', '重试', () => loadModule(1));
      return;
    }
    const seasonTitle = detail.title || item.title || '番剧';
    let firstIndex = -1;
    detail.episodes.forEach((episode, index) => {
      const title = `${seasonTitle} · ${episode.title || `第 ${index + 1} 集`}`;
      const key = `ep:${episode.epId}`;
      let queueIndex = state.playlist.findIndex((entry) => entry.key === key);
      const queueItem = Object.assign({}, episode, {
        id: `n${Date.now()}-${index}`,
        key,
        seasonId: item.seasonId,
        seasonTitle,
        title,
        meta: `${seasonTitle} · 第 ${index + 1} 集`,
        pic: episode.pic || detail.cover || item.pic || '',
      });
      if (queueIndex < 0) {
        state.playlist.push(queueItem);
        queueIndex = state.playlist.length - 1;
      } else {
        state.playlist[queueIndex] = Object.assign({}, state.playlist[queueIndex], queueItem);
      }
      if (firstIndex < 0) firstIndex = queueIndex;
    });
    if (firstIndex < 0) return;
    host.setCurrent(firstIndex);
    state.playing = true;
    host.save();
    host.updatePlayerLabels();
    host.openPlayer({ resume: true });
  }

  function playLive(item) {
    const room = call('liveRoom', item.roomId);
    if (!room.ok || !room.url) {
      renderEmpty(feeds.home, '直播加载失败', room.error || '直播间暂不可用', '重试', () => loadHome(1));
      return;
    }
    playItem(Object.assign({}, item, {
      key: `live:${item.roomId}`,
      live: true,
      liveUrl: room.url,
      liveFormat: room.format || 'hls',
      title: item.title || room.title || '直播',
      meta: item.meta || `${item.owner || ''} · LIVE`,
    }));
  }

  /* ---------- media ---------- */
  const video = $('#realVideo');
  const playerVideo = host.playerVideo;
  const player = $('#player');
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
  let mediaLive = false;
  let hls = null;

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
    if (!text) return false;
    const item = currentItem();
    const cid = item && Number(item.cid || 0);
    if (!cid || typeof bridge.sendDanmaku !== 'function') return false;
    const result = call('sendDanmaku', cid, text, Math.round((video.currentTime || 0) * 1000));
    if (!result.ok) {
      log('danmaku send failed ' + (result.error || ''));
      return false;
    }
    if (state.settings.danmaku) spawnDanmaku({ t: video.currentTime || 0, text, color: 0xffffff, mode: 1 });
    return true;
  }

  function currentItem() {
    return state.playlist[state.currentIndex] || null;
  }

  function destroyHls() {
    if (hls) {
      try { hls.destroy(); } catch (_) {}
      hls = null;
    }
  }

  function clearVideo() {
    destroyHls();
    mediaItem = null;
    mediaBackup = '';
    mediaTriedBackup = false;
    mediaLive = false;
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
    if (player) player.classList.remove('live-player');
    if (status) status.textContent = '';
  }

  function qualityQn(value) {
    const map = { '4K': 120, '1080P60': 116, '1080P': 80, '720P': 64, '480P': 32, '仅音频': 16 };
    return map[value] || 64;
  }

  function loadLive(item, autoplay) {
    destroyHls();
    mediaItem = item;
    mediaLive = true;
    mediaBackup = '';
    mediaTriedBackup = false;
    state.duration = 0;
    playerVideo.classList.remove('video-error');
    playerVideo.classList.add('video-loading', 'has-video');
    if (player) player.classList.add('live-player');
    if (host.pcTime) host.pcTime.textContent = 'LIVE';
    setStatus('连接直播…', 'loading');
    const source = item.liveUrl;
    if (!source) {
      setStatus('直播地址不可用', 'error');
      return;
    }
    if (video.canPlayType('application/vnd.apple.mpegurl')) {
      video.src = source;
      video.load();
      if (autoplay) video.play().catch(() => {});
      return;
    }
    if (window.Hls && window.Hls.isSupported()) {
      hls = new window.Hls({ enableWorker: true, lowLatencyMode: false });
      hls.on(window.Hls.Events.MANIFEST_PARSED, () => {
        if (autoplay) video.play().catch(() => {});
      });
      hls.on(window.Hls.Events.ERROR, (_, data) => {
        if (!data || !data.fatal) return;
        setStatus('直播加载失败 · 点击重试', 'error');
      });
      hls.attachMedia(video);
      hls.on(window.Hls.Events.MEDIA_ATTACHED, () => hls.loadSource(source));
      return;
    }
    setStatus('当前 WebView 不支持直播 HLS', 'error');
  }

  function loadVideo(item, autoplay) {
    if (!item) {
      clearVideo();
      return;
    }
    if (item.live) {
      loadLive(item, autoplay);
      return;
    }
    if (!item.bvid && !item.epId) {
      clearVideo();
      return;
    }
    const key = item.epId ? `ep:${item.epId}` : `bvid:${item.bvid}`;
    if (mediaItem && mediaItem.key === key && video.src) {
      if (autoplay) video.play().catch(() => {});
      return;
    }
    destroyHls();
    mediaLive = false;
    if (player) player.classList.remove('live-player');
    mediaItem = item;
    mediaTriedBackup = false;
    mediaBackup = '';
    state.duration = 0;
    playerVideo.classList.remove('has-video', 'video-error');
    playerVideo.classList.add('video-loading');
    setStatus('加载中…', 'loading');
    const result = item.epId
      ? call('playPgc', item.epId, item.bvid || '', item.cid || 0, qualityQn(state.settings.quality))
      : call('playQuality', item.bvid, item.cid || 0, qualityQn(state.settings.quality));
    if (!result.ok) {
      setStatus('加载失败 · 点击重试', 'error');
      log('play error ' + (item.bvid || item.epId || '') + ' ' + (result.error || ''));
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
    if (state.duration > 0 && !mediaLive) host.setProgress(video.currentTime / state.duration * 100);
    if (mediaLive && host.pcTime) host.pcTime.textContent = 'LIVE';
    playerVideo.classList.remove('video-loading');
  });
  video.addEventListener('timeupdate', () => {
    if (mediaLive) {
      if (host.pcTime) host.pcTime.textContent = 'LIVE';
      return;
    }
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
    if (status) status.textContent = mediaLive ? '缓冲中…' : '缓冲中…';
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
    setStatus(mediaLive ? '直播加载失败 · 点击重试' : '播放失败 · 点击重试', 'error');
    log('video element error ' + (mediaItem ? mediaItem.bvid || mediaItem.roomId : ''));
  });
  video.addEventListener('ended', () => {
    if (mediaLive) return;
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
    onMinimize() {},
    onStop() {
      clearVideo();
    },
    togglePlay() {
      if (mediaLive && hls) {
        if (video.paused) video.play().catch(() => {});
        else video.pause();
        return true;
      }
      if (!video.src) return false;
      if (video.paused) video.play().catch(() => {});
      else video.pause();
      return true;
    },
    seek(percent) {
      if (mediaLive || !video.duration || !Number.isFinite(video.duration)) return;
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
      return sendDanmaku(text);
    },
    onRateHold(rate) {
      if (!video.src || mediaLive) return;
      video.playbackRate = rate;
    },
    onRateHoldEnd() {
      if (!video.src || mediaLive) return;
      const rate = parseFloat(state.settings.speed || '1');
      video.playbackRate = Number.isFinite(rate) && rate > 0 ? rate : 1;
    },
    onQualityChange(value) {
      if (!mediaItem || !video.src || mediaItem.live || typeof bridge.playQuality !== 'function') return;
      const qn = qualityQn(value);
      const keepTime = video.currentTime || 0;
      const wasPlaying = !video.paused;
      const result = mediaItem.epId
        ? call('playPgc', mediaItem.epId, mediaItem.bvid || '', mediaItem.cid || 0, qn)
        : call('playQuality', mediaItem.bvid, mediaItem.cid || 0, qn);
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
  let commentSort = 2;
  function commentRow(row) {
    return `
      <div class="comment-row">
        ${row.avatar ? `<img class="comment-avatar" src="${attr(row.avatar)}" alt="" referrerpolicy="no-referrer">` : '<span class="avatar-ph sm"></span>'}
        <div class="comment-text">
          <b>${esc(row.user || '用户')}</b>
          <p>${esc(row.message || '')}</p>
          <small>赞 ${Number(row.like || 0)}</small>
        </div>
      </div>`;
  }

  function loadComments(sort) {
    if (typeof sort === 'number') commentSort = sort;
    const item = currentItem();
    const aid = item && item.aid ? Number(item.aid) : 0;
    if (!aid) {
      host.commentsBody.innerHTML = '<div class="native-empty">当前视频没有评论 ID</div>';
      return;
    }
    const result = typeof bridge.comments === 'function'
      ? call('comments', aid, 1, commentSort)
      : { ok: false, error: '不支持评论' };
    if (!result.ok || !Array.isArray(result.items)) {
      host.commentsBody.innerHTML = `<div class="native-empty">评论加载失败<br>${esc(result.error || '')}</div>`;
      host.commentsCount.textContent = '';
      return;
    }
    if (commentSort === 0 && result.items.length === 0 && !result.count) {
      const fallback = call('comments', aid, 1, 2);
      if (fallback.ok && Array.isArray(fallback.items) && fallback.items.length) {
        host.commentsBody.innerHTML = '<div class="native-empty" style="padding:14px 0">最新评论需要登录后查看，当前显示最热评论</div>'
          + fallback.items.map(commentRow).join('');
        host.commentsCount.textContent = `${fallback.count || fallback.items.length} 条`;
        return;
      }
    }
    host.commentsBody.innerHTML = result.items.map(commentRow).join('');
    host.commentsCount.textContent = `${result.count || result.items.length} 条`;
  }

  function sendComment(text) {
    const item = currentItem();
    const aid = item && item.aid ? Number(item.aid) : 0;
    if (!aid || !text || typeof bridge.sendComment !== 'function') return false;
    const result = call('sendComment', aid, text);
    if (!result.ok) {
      log('comment send failed ' + (result.error || ''));
      return false;
    }
    const row = {
      user: accountInfo && accountInfo.name ? accountInfo.name : '我',
      avatar: accountInfo && accountInfo.face ? accountInfo.face : '',
      message: text,
      like: 0,
    };
    host.commentsBody.insertAdjacentHTML('afterbegin', commentRow(row));
    const current = parseInt(host.commentsCount.textContent, 10) || 0;
    host.commentsCount.textContent = `${current + 1} 条`;
    return true;
  }

  /* ---------- account ---------- */
  function renderAccount() {
    const card = $('#accountCard');
    if (!card) return;
    if (accountInfo && accountInfo.loggedIn) {
      card.innerHTML = `
        ${accountInfo.face ? `<img class="account-avatar" src="${attr(accountInfo.face)}" alt="" referrerpolicy="no-referrer">` : '<span class="avatar-ph lg"></span>'}
        <span class="account-copy">
          <span class="account-name">${esc(accountInfo.name || 'B 站用户')}</span>
          <span class="account-meta">UID ${esc(accountInfo.mid || '')} · Lv${esc(accountInfo.level || 0)}${accountInfo.follower ? ` · ${countText(accountInfo.follower)} 粉丝` : ''}</span>
        </span>
        <span class="account-vip ${accountInfo.vip ? '' : 'off'}">${accountInfo.vip ? (accountInfo.vipLabel || '大会员') : '普通'}</span>`;
    } else {
      card.innerHTML = `
        <span class="avatar-ph lg"></span>
        <span class="account-copy">
          <span class="account-name">未登录</span>
          <span class="account-meta">扫码登录 B 站账号，同步收藏 / 历史 / 动态</span>
        </span>
        <span class="account-vip off">登录</span>`;
    }
    const download = $$('.my-row').find((row) => row.dataset.module === '下载');
    if (download) {
      const meta = $('.my-meta', download);
      if (meta) meta.textContent = '暂未接入';
    }
    const vip = $$('.my-row').find((row) => row.dataset.module === '会员');
    if (vip) {
      const meta = $('.my-meta', vip);
      if (meta) meta.textContent = accountInfo && accountInfo.vip ? (accountInfo.vipLabel || '大会员') : '未开通';
    }
  }

  function loadAccount() {
    if (typeof bridge.account !== 'function') {
      renderAccount();
      return;
    }
    const result = call('account');
    accountInfo = result && result.ok ? result : {
      loggedIn: false,
      name: '',
      face: '',
      mid: 0,
      level: 0,
      vip: false,
    };
    renderAccount();
  }

  function openAccountSheet() {
    const info = accountInfo || {};
    host.openSheet('账户', info.loggedIn ? 'B 站账号 · 实时信息' : '未登录 · 扫码后同步', (body) => {
      const rows = [
        ['昵称', info.name || '未登录'],
        ['UID', info.mid ? String(info.mid) : '—'],
        ['等级', info.level ? `Lv${info.level}` : '—'],
        ['大会员', info.vip ? (info.vipLabel || '大会员') : '未开通'],
        ['粉丝 / 关注', info.loggedIn ? `${countText(info.follower || 0)} / ${countText(info.following || 0)}` : '—'],
        ['硬币', info.loggedIn ? String(info.coins || 0) : '—'],
      ];
      rows.forEach(([label, value]) => {
        const row = document.createElement('div');
        row.className = 'sheet-row';
        row.innerHTML = `<span class="sr-label">${esc(label)}</span><span class="sr-value">${esc(value)}</span>`;
        body.appendChild(row);
      });
      host.actionRow(body, '扫码登录', info.loggedIn ? '已登录' : '去登录', () => {
        host.closeSheet();
        host.showPage('login');
        return '打开登录';
      });
      host.actionRow(body, '退出登录', '', () => {
        if (typeof bridge.logout === 'function') bridge.logout();
        state.loggedIn = false;
        accountInfo = { loggedIn: false, name: '', face: '', mid: 0, level: 0, vip: false };
        renderAccount();
        host.save();
        host.showPage('login');
        return '已退出';
      });
    });
  }

  /* ---------- dynamic / messages ---------- */
  function renderDynamic(items, append) {
    const feed = $('#dynamicFeed');
    if (!feed) return;
    if (!append) feed.innerHTML = '';
    const rows = items.map((item) => {
      const images = Array.isArray(item.images) ? item.images.filter(Boolean) : [];
      const video = item.video;
      return `
        <article class="dynamic-card">
          <div class="dynamic-head">
            ${item.avatar ? `<img class="dynamic-avatar" src="${attr(item.avatar)}" alt="" referrerpolicy="no-referrer">` : '<span class="avatar-ph"></span>'}
            <div>
              <div class="dynamic-author">${esc(item.author || '用户')}</div>
              <div class="dynamic-time">${esc(timeAgo(item.time))}</div>
            </div>
          </div>
          ${item.text ? `<div class="dynamic-text">${esc(item.text)}</div>` : ''}
          ${video ? `
            <button class="dynamic-video" type="button" data-dynamic-video="${attr(video.bvid || '')}">
              ${video.pic ? `<img src="${attr(video.pic)}" alt="" loading="lazy" referrerpolicy="no-referrer">` : ''}
              <span class="dynamic-video-copy">
                <span class="dynamic-video-title">${esc(video.title || '视频')}</span>
                <span class="real-meta">${esc(video.meta || video.owner || '')}</span>
              </span>
            </button>` : ''}
          ${images.length ? `<div class="dynamic-images">${images.map((src) => `<img src="${attr(src)}" alt="" loading="lazy" referrerpolicy="no-referrer" data-view-image="${attr(src)}">`).join('')}</div>` : ''}
          <div class="dynamic-foot"><span>赞 ${esc(item.likes || 0)}</span><span>评论 ${esc(item.comments || 0)}</span></div>
        </article>`;
    });
    feed.insertAdjacentHTML('beforeend', rows.join(''));
    $$('.dynamic-video', feed).forEach((button) => {
      const bvid = button.dataset.dynamicVideo;
      const item = items.find((row) => row.video && row.video.bvid === bvid);
      if (item) button.addEventListener('click', () => playItem(item.video));
    });
    $$('[data-view-image]', feed).forEach((image) => {
      image.addEventListener('click', () => openImageViewer(image.dataset.viewImage));
    });
    const empty = $('#dynamicEmpty');
    if (empty) empty.hidden = true;
  }

  function openImageViewer(src) {
    const viewer = document.createElement('div');
    viewer.className = 'image-viewer';
    viewer.innerHTML = `<img src="${attr(src)}" alt="">`;
    viewer.addEventListener('click', () => viewer.remove());
    document.body.appendChild(viewer);
  }

  function loadDynamic(page, append) {
    if (!state.loggedIn) {
      renderEmpty($('#dynamicFeed'), '登录后查看动态', '扫码登录后同步关注动态。', '去登录', () => host.showPage('login'));
      return true;
    }
    if (typeof bridge.dynamicFeed !== 'function') {
      renderEmpty($('#dynamicFeed'), '当前版本不支持动态', '');
      return true;
    }
    const filter = ['all', 'video', 'image'][Math.max(0, Number(state.dynamicFilterIndex) || 0) % 3];
    const result = call('dynamicFeed', page || 1, filter);
    if (!result.ok) {
      renderEmpty($('#dynamicFeed'), result.needLogin ? '登录后查看动态' : '动态加载失败', result.needLogin ? '扫码登录后同步关注动态。' : (result.error || ''), result.needLogin ? '去登录' : '重试', result.needLogin ? () => host.showPage('login') : () => loadDynamic(1, false));
      return true;
    }
    renderDynamic(result.items || [], Boolean(append));
    more.dynamic = result.hasMore !== false;
    const label = $('#dynamicFilter');
    if (label) label.textContent = `${dynamicFilterNames[Math.max(0, Number(state.dynamicFilterIndex) || 0) % 3]} ⌄`;
    return true;
  }

  function renderMessages(items, append) {
    const feed = $('#messageFeed');
    if (!feed) return;
    if (!append) feed.innerHTML = '';
    feed.insertAdjacentHTML('beforeend', items.map((item) => `
      <div class="message-row">
        ${item.avatar ? `<img class="message-avatar" src="${attr(item.avatar)}" alt="" referrerpolicy="no-referrer">` : '<span class="avatar-ph"></span>'}
        <div class="message-copy">
          <span class="message-user">${esc(item.user || '用户')}</span>
          <span class="message-text">${esc(item.text || '')}</span>
          <span class="message-time">${esc(timeAgo(item.time))}</span>
        </div>
        ${item.unread ? '<span class="message-unread"></span>' : ''}
      </div>`).join(''));
    const empty = $('#messageEmpty');
    if (empty) empty.hidden = true;
  }

  function loadMessages(page, append) {
    if (!state.loggedIn) {
      renderEmpty($('#messageFeed'), '登录后查看消息', '扫码登录后同步回复、@ 和点赞。', '去登录', () => host.showPage('login'));
      return true;
    }
    const index = Math.max(0, Number(state.messageFilterIndex) || 0) % 4;
    if (index === 3) {
      renderEmpty($('#messageFeed'), '私信暂未接入', '回复 / @我 / 收到的赞已经接入真实接口。');
      return true;
    }
    if (typeof bridge.messages !== 'function') {
      renderEmpty($('#messageFeed'), '当前版本不支持消息', '');
      return true;
    }
    const filter = ['reply', 'at', 'like'][index];
    const result = call('messages', page || 1, filter);
    if (!result.ok) {
      renderEmpty($('#messageFeed'), result.needLogin ? '登录后查看消息' : '消息加载失败', result.needLogin ? '扫码登录后同步回复、@ 和点赞。' : (result.error || ''), result.needLogin ? '去登录' : '重试', result.needLogin ? () => host.showPage('login') : () => loadMessages(1, false));
      return true;
    }
    renderMessages(result.items || [], Boolean(append));
    more.messages = result.hasMore !== false;
    const label = $('#messageFilter');
    if (label) label.textContent = `${messageFilterNames[index]} ⌄`;
    return true;
  }

  /* ---------- player info / actions ---------- */
  function playerInfo() {
    const item = currentItem();
    if (!item) {
      host.openSheet('信息', '当前没有播放项', (body) => {
        host.actionRow(body, '返回', '', () => host.closeSheet());
      });
      return;
    }
    const detail = item.bvid ? call('videoInfo', item.bvid) : { ok: false };
    const stat = detail.stat || {};
    const owner = detail.owner || item.owner || 'UP 主';
    const title = detail.title || item.title || '视频';
    const bvid = detail.bvid || item.bvid || '';
    const aid = detail.aid || item.aid || 0;
    const desc = detail.desc || item.desc || '暂无简介';
    if (detail.ok) {
      if (typeof detail.faved === 'boolean') state.fav = detail.faved;
      if (typeof detail.coined !== 'undefined') state.coin = Number(detail.coined) > 0;
      if (typeof detail.followed === 'boolean') state.followed = detail.followed;
      host.save();
    }
    host.openSheet('信息', detail.ok ? '真实视频信息 · B 站接口' : '视频信息加载失败', (body) => {
      const rows = [
        ['标题', title],
        ['UP 主', owner],
        ['BV / av', `${bvid || '—'} / av${aid || '—'}`],
        ['播放 / 弹幕', `${countText(stat.view || item.play || 0)} / ${countText(stat.danmaku || 0)}`],
        ['点赞 / 投币 / 收藏', `${countText(stat.like || 0)} / ${countText(stat.coin || 0)} / ${countText(stat.favorite || 0)}`],
        ['评论 / 分享', `${countText(stat.reply || 0)} / ${countText(stat.share || 0)}`],
        ['简介', desc],
      ];
      rows.forEach(([label, value]) => {
        const row = document.createElement('div');
        row.className = 'sheet-row';
        row.innerHTML = `<span class="sr-label">${esc(label)}</span><span class="sr-value">${esc(value)}</span>`;
        body.appendChild(row);
      });
      if (Array.isArray(detail.pages) && detail.pages.length > 1) {
        host.actionRow(body, '分 P', `${detail.pages.length} 个`, () => {
          host.closeSheet();
          host.showPage('playlist', 'home');
          return '打开播放列表';
        });
      }
    });
  }

  function playerPerf() {
    const quality = video.getVideoPlaybackQuality ? video.getVideoPlaybackQuality() : null;
    let buffered = 0;
    try {
      if (video.buffered && video.buffered.length) {
        buffered = Math.max(0, video.buffered.end(video.buffered.length - 1) - video.currentTime);
      }
    } catch (_) {}
    const rows = [
      ['媒体', mediaLive ? '直播 HLS' : (video.videoWidth ? `${video.videoWidth} × ${video.videoHeight}` : '—')],
      ['解码', 'WebView 媒体层'],
      ['当前 / 总时长', mediaLive ? 'LIVE' : `${video.currentTime.toFixed(1)} / ${Number.isFinite(video.duration) ? video.duration.toFixed(1) : '—'} s`],
      ['缓冲', `${buffered.toFixed(1)} s`],
      ['丢帧', quality ? String(quality.droppedVideoFrames || 0) : '—'],
      ['倍速', `${video.playbackRate || 1}×`],
      ['硬解', '由系统 WebView 决定'],
    ];
    host.openSheet('性能', '当前 WebView 媒体指标', (body) => {
      rows.forEach(([label, value]) => {
        const row = document.createElement('div');
        row.className = 'sheet-row';
        row.innerHTML = `<span class="sr-label">${esc(label)}</span><span class="sr-value">${esc(value)}</span>`;
        body.appendChild(row);
      });
    });
  }

  function favoriteCurrent() {
    const item = currentItem();
    if (!item || !item.aid || typeof bridge.favorite !== 'function') return '无视频';
    const next = !state.fav;
    const result = call('favorite', item.aid, next);
    if (!result.ok) return result.needLogin ? '请先登录' : (result.error || '操作失败');
    state.fav = next;
    host.save();
    return next ? '已收藏' : '已取消';
  }

  function coinCurrent() {
    const item = currentItem();
    if (!item || !item.aid || typeof bridge.coin !== 'function') return '无视频';
    if (state.coin) return '已投币';
    const result = call('coin', item.aid, 2, false);
    if (!result.ok) return result.needLogin ? '请先登录' : (result.error || '投币失败');
    state.coin = true;
    host.save();
    return '已投币';
  }

  function followCurrent() {
    const item = currentItem();
    if (!item || !item.mid || typeof bridge.follow !== 'function') {
      const detail = item && item.bvid ? call('videoInfo', item.bvid) : null;
      if (detail && detail.ok && detail.mid) item.mid = detail.mid;
    }
    if (!item || !item.mid) return '没有 UP 信息';
    const next = !state.followed;
    const result = call('follow', item.mid, next);
    if (!result.ok) return result.needLogin ? '请先登录' : (result.error || '关注失败');
    state.followed = next;
    host.save();
    return next ? '已关注' : '已取消';
  }

  function copyCurrentLink() {
    const item = currentItem();
    if (!item || !item.bvid || typeof bridge.copy !== 'function') return '无链接';
    const url = `https://www.bilibili.com/video/${item.bvid}`;
    const result = call('copy', url);
    return result.ok ? '已复制' : '复制失败';
  }

  function screenshotCurrent() {
    if (typeof bridge.screenshot !== 'function') return '不支持截图';
    const result = call('screenshot');
    if (!result.ok) {
      log('screenshot failed ' + (result.error || ''));
      return '保存失败';
    }
    return '已保存';
  }

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
        loadAccount();
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

  const accountCard = $('#accountCard');
  if (accountCard) accountCard.addEventListener('click', (event) => {
    if (!state.loggedIn) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    openAccountSheet();
  }, true);

  const dynamicFilter = $('#dynamicFilter');
  if (dynamicFilter) dynamicFilter.addEventListener('click', () => {
    setTimeout(() => {
      pages.dynamic = 1;
      loadDynamic(1, false);
    }, 0);
  });
  const messageFilter = $('#messageFilter');
  if (messageFilter) messageFilter.addEventListener('click', () => {
    setTimeout(() => {
      pages.messages = 1;
      loadMessages(1, false);
    }, 0);
  });
  const moduleFilter = $('#moduleFilter');
  if (moduleFilter) moduleFilter.addEventListener('click', () => {
    setTimeout(() => {
      pages.module = 1;
      cursors.module = '';
      loadModule(1);
    }, 0);
  });

  const appScroll = $('#appScroll');
  if (appScroll) appScroll.addEventListener('scroll', () => {
    if (appScroll.scrollTop + appScroll.clientHeight < appScroll.scrollHeight - 220) return;
    if (state.page === 'dynamic' && more.dynamic) {
      more.dynamic = false;
      pages.dynamic += 1;
      if (loadDynamic(pages.dynamic, true) && $('#dynamicFeed').querySelector('.native-empty')) more.dynamic = false;
    }
    if (state.page === 'messages' && more.messages) {
      more.messages = false;
      pages.messages += 1;
      if (loadMessages(pages.messages, true) && $('#messageFeed').querySelector('.native-empty')) more.messages = false;
    }
  });

  const pageObserver = new MutationObserver(() => {
    if (state.page === 'login') maybeStartQr();
    if (state.page === 'home') {
      if (!feeds.home.querySelector('.real-row')) {
        pages.home = 1;
        cursors.home = '';
        loadHome(1);
      }
    }
    if (state.page === 'module') {
      pages.module = 1;
      cursors.module = '';
      loadModule(1);
    }
    if (state.page === 'dynamic') {
      pages.dynamic = 1;
      loadDynamic(1, false);
    }
    if (state.page === 'messages') {
      pages.messages = 1;
      loadMessages(1, false);
    }
    if (state.page === 'my') loadAccount();
  });
  pageObserver.observe(host.app, { attributes: true, attributeFilter: ['data-page'] });

  const moduleLabel = $('#myModuleName');
  if (moduleLabel) {
    new MutationObserver(() => {
      if (state.page === 'home') {
        pages.home = 1;
        cursors.home = '';
        loadHome(1);
      }
    }).observe(moduleLabel, { childList: true, characterData: true, subtree: true });
  }

  window.O11A1NativeData = {
    refresh(key) {
      if (key === 'home') {
        pages.home += 1;
        return loadHome(pages.home);
      }
      if (key === 'search') {
        pages.search += 1;
        return loadSearch(host.searchInput.value.trim(), pages.search);
      }
      if (key === 'module') {
        pages.module += 1;
        return loadModule(pages.module);
      }
      return false;
    },
    onComments: (sort) => loadComments(sort),
    sendComment,
    favorite: favoriteCurrent,
    coin: coinCurrent,
    follow: followCurrent,
    copyLink: copyCurrentLink,
    screenshot: screenshotCurrent,
    playerInfo,
    playerPerf,
    openAccount: openAccountSheet,
    get accountInfo() { return accountInfo; },
  };

  /* ---------- search ---------- */
  host.searchInput.addEventListener('input', () => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      pages.search = 1;
      loadSearch(host.searchInput.value.trim(), 1);
    }, 320);
  });

  /* ---------- first data load ---------- */
  setTimeout(() => {
    loadAccount();
    if (state.page === 'login') maybeStartQr();
    if (state.page === 'search') loadSearch(host.searchInput.value.trim(), 1);
    if (state.page === 'module') loadModule(1);
    if (state.page === 'dynamic') loadDynamic(1, false);
    if (state.page === 'messages') loadMessages(1, false);
    if (state.page === 'my') loadAccount();
    if (state.loggedIn) loadHome(1);
  }, 120);
})();

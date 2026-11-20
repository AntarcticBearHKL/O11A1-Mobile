(() => {
  const $ = (selector, root = document) => root.querySelector(selector);
  const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));

  const app = $('#app');
  const appScroll = $('#appScroll');
  const player = $('#player');
  const playerStage = $('#playerStage');
  const playerControls = $('#playerControls');
  const playerTitle = $('#playerTitle');
  const playerSub = $('#playerSub');
  const pcPlay = $('#pcPlay');
  const pcTime = $('#pcTime');
  const pcQuality = $('#pcQuality');
  const pcSpeed = $('#pcSpeed');
  const pcInterp = $('#pcInterp');
  const pcEnhance = $('#pcEnhance');
  const pcDanmaku = $('#pcDanmaku');
  const pcFullscreen = $('#pcFullscreen');
  const progressBar = $('.progress-ph', playerControls);
  const progressPlayed = $('.progress-played', playerControls);
  const progressThumb = $('.progress-thumb', playerControls);
  const seekRipple = $('#seekRipple');
  const lockBadge = $('#lockBadge');
  const psheet = $('#psheet');
  const psheetBackdrop = $('#psheetBackdrop');
  const psheetTitle = $('#psheetTitle');
  const psheetSub = $('#psheetSub');
  const psheetBody = $('#psheetBody');
  const psheetClose = $('#psheetClose');
  const moduleBtn = $('#moduleBtn');
  const moduleTitle = $('#moduleTitle');
  const moduleMenu = $('#moduleMenu');
  const homeNote = $('#homeNote');
  const playlistList = $('#playlistList');
  const playlistCount = $('#playlistCount');
  const myPlaylistCount = $('#myPlaylistCount');
  const tabPlaylistCount = $('#tabPlaylistCount');
  const moduleSettings = $('#moduleSettings');
  const moduleCount = $('#moduleCount');
  const searchInput = $('#searchInput');
  const searchResultsLabel = $('#searchResultsLabel');
  const searchResults = $('#searchResults');
  const commandList = $('#commandList');
  const commandLabel = $('#commandLabel');
  const modulePageTitle = $('#modulePageTitle');
  const moduleNote = $('#moduleNote');
  const moduleFilter = $('#moduleFilter');
  const dynamicFilter = $('#dynamicFilter');
  const messageFilter = $('#messageFilter');
  const followBtn = $('#followBtn');
  const loginStatus = $('#loginStatus');
  const protoDrawer = $('#protoDrawer');
  const protoBackdrop = $('#protoBackdrop');
  const protoFab = $('#protoFab');

  const STORAGE_KEY = 'o11a1.v2.prototype';
  const TOTAL_SECONDS = 24 * 60;

  const DEFAULT_MODULES = [
    { id: 'recommend', name: '推荐', desc: '首页推荐流与关注动态混排', group: '首页', on: true },
    { id: 'hot', name: '热门', desc: '全站热门视频', group: '首页', on: false },
    { id: 'rank', name: '排行', desc: '排行榜与分区榜', group: '首页', on: false },
    { id: 'bangumi', name: '番剧', desc: '每日放送 / 番剧索引 / 排行榜', group: '内容', on: true },
    { id: 'movie', name: '影视', desc: '电影 / 电视剧 / 纪录片 / 综艺', group: '内容', on: false },
    { id: 'live', name: '直播', desc: '直播推荐 / 分区 / 房间', group: '内容', on: true },
    { id: 'zone', name: '分区', desc: '20 个一级分区与最新投稿', group: '内容', on: false },
    { id: 'follow', name: '关注', desc: '关注的 UP 主投稿与动态', group: '内容', on: false },
    { id: 'favorite', name: '收藏', desc: '收藏夹推荐 / 全部收藏夹', group: '内容', on: true },
    { id: 'history', name: '历史', desc: '观看历史与续播进度', group: '内容', on: true },
    { id: 'dynamic', name: '动态', desc: '全部 / 视频 / 图文', group: '社区', on: false },
    { id: 'fish', name: '养鱼', desc: 'AI 看片 / 试验台 / 设置', group: '社区', on: false },
  ];

  const DEFAULT_PLAYLIST = [
    { id: 'q1', title: '队列视频占位 01', meta: 'UP 占位 01 · 00:00' },
    { id: 'q2', title: '队列视频占位 02', meta: 'UP 占位 02 · 00:00' },
    { id: 'q3', title: '队列视频占位 03', meta: 'UP 占位 03 · 00:00' },
  ];

  const DEFAULT_SETTINGS = {
    defaultQuality: '最高',
    quality: '1080P60',
    speed: '1.0×',
    interp: '120',
    enhance: 'CAS',
    native4k: false,
    audioOnly: false,
    loop: '循环',
    aspect: '适应',

    danmaku: true,
    danmakuOpacity: 85,
    danmakuSize: 100,
    danmakuSpeed: 100,
    danmakuArea: '全屏',
    danmakuDensity: true,

    theme: '跟随系统',
    bgTransparency: 70,
    glassBlur: 60,
    bgBlur: 40,

    doubleSeek: true,
    longPress2x: true,
    swipeBrightness: true,
    doubleFullscreen: true,

    hideLive: false,
    hideBangumi: false,
    hideFish: false,
    hideHotSearch: false,

    wifiPreload: true,
    cloudBlock: true,
    cloudLevel: 5,
    preloadNext: true,
    warmPages: true,

    autostart: false,
    closeToTray: true,
    autoUpdate: true,
  };

  const loaded = (() => {
    try {
      if (new URLSearchParams(window.location.search).has('reset')) {
        localStorage.removeItem(STORAGE_KEY);
      }
    } catch (_) {}
    return loadPersisted();
  })();

  const state = {
    page: 'home',
    platform: loaded?.platform === 'android' ? 'android' : 'ios',
    moduleId: loaded?.moduleId || 'recommend',
    modules: DEFAULT_MODULES.map((mod) => ({
      ...mod,
      on: loaded?.modules && typeof loaded.modules[mod.id] === 'boolean' ? loaded.modules[mod.id] : mod.on,
    })),
    playlist: loaded && Array.isArray(loaded.playlist)
      ? loaded.playlist.map((item) => ({ ...item }))
      : DEFAULT_PLAYLIST.map((item) => ({ ...item })),
    currentIndex: Number.isInteger(loaded?.currentIndex) ? loaded.currentIndex : 0,
    settings: { ...DEFAULT_SETTINGS, ...(loaded?.settings || {}) },
    playerOpen: false,
    playing: false,
    locked: false,
    progress: 0,
    detailAdded: false,
    fav: false,
    coin: false,
    cached: false,
    shot: false,
    copied: false,
    moduleReturn: 'home',
    moduleName: '收藏',
    moduleFilterIndex: 0,
    dynamicFilterIndex: 0,
    messageFilterIndex: 0,
  };

  if (!state.modules.some((mod) => mod.id === state.moduleId && mod.on)) {
    state.moduleId = state.modules.find((mod) => mod.on)?.id || null;
  }
  if (state.currentIndex >= state.playlist.length) {
    state.currentIndex = Math.max(0, state.playlist.length - 1);
  }

  let hideTimer = null;
  let clickTimer = null;
  let clearArmed = false;
  let clearTimer = null;

  const MODULE_NOTES = {
    收藏: '收藏夹推荐 · 全部收藏夹 · 占位',
    历史: '继续观看 · 分页 / 每页条数 · 占位',
    关注: '关注的 UP 主投稿 · 占位',
    养鱼: '看片 / 试验台 / 设置 · 占位',
    下载: '离线任务 · 下载进度 · 占位',
    会员: '大会员权益 / 任务 / 特权目录 · 占位',
    番剧: '每日放送 / 番剧索引 / 排行榜 · 占位',
    影视: '电影 / 电视剧 / 纪录片 / 综艺 · 占位',
    直播: '直播推荐 / 分区 / 房间 · 占位',
    分区: '20 个一级分区 · 占位',
  };

  const DYNAMIC_FILTERS = ['全部', '视频', '图文'];
  const MESSAGE_FILTERS = ['回复', '@', '赞', '私信'];
  const MODULE_FILTERS = ['全部', '最新', '热门'];

  const sheetData = {
    quality: {
      title: '画质',
      sub: 'DASH · AVC / HEVC / AV1 · 4K 与 1080P+ 需要大会员',
      options: [
        { label: '4K 超清', value: '4K', meta: '大会员' },
        { label: '1080P60', value: '1080P60', meta: '高帧率' },
        { label: '1080P 高清', value: '1080P' },
        { label: '720P', value: '720P' },
        { label: '480P', value: '480P' },
        { label: '仅音频', value: '仅音频' },
      ],
      selected: () => state.settings.quality,
      apply: (value) => {
        state.settings.quality = value;
        updatePlayerLabels();
        save();
      },
    },
    speed: {
      title: '倍速',
      sub: '0.1×–10×；音频使用多级 atempo',
      options: [
        { label: '0.5×', value: '0.5×' },
        { label: '0.75×', value: '0.75×' },
        { label: '1.0×', value: '1.0×', meta: '标准' },
        { label: '1.25×', value: '1.25×' },
        { label: '1.5×', value: '1.5×' },
        { label: '2.0×', value: '2.0×' },
        { label: '3.0×', value: '3.0×' },
      ],
      selected: () => state.settings.speed || '1.0×',
      apply: (value) => {
        state.settings.speed = value;
        updatePlayerLabels();
        save();
      },
    },
    interp: {
      title: '插帧',
      sub: '自动 = 跟随屏幕刷新率；不会因掉帧自动关闭',
      options: [
        { label: '关闭', value: '关' },
        { label: '自动', value: '自动', meta: '跟随屏幕' },
        { label: '60', value: '60' },
        { label: '90', value: '90' },
        { label: '120', value: '120', meta: 'ProMotion' },
      ],
      selected: () => state.settings.interp,
      apply: (value) => {
        state.settings.interp = value;
        updatePlayerLabels();
        save();
      },
    },
    enhance: {
      title: '画质增强',
      sub: 'GPU 直接采样；直播强制关闭增强与插帧',
      options: [
        { label: '关闭', value: '关' },
        { label: 'CAS', value: 'CAS', meta: '低负载' },
        { label: 'Anime4K', value: 'Anime4K', meta: '高负载' },
      ],
      selected: () => state.settings.enhance,
      apply: (value) => {
        state.settings.enhance = value;
        updatePlayerLabels();
        save();
      },
    },
  };

  /* ---------- persistence ---------- */
  function loadPersisted() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return null;
      return JSON.parse(raw);
    } catch (_) {
      return null;
    }
  }

  function save() {
    try {
      const modules = {};
      state.modules.forEach((mod) => { modules[mod.id] = mod.on; });
      localStorage.setItem(STORAGE_KEY, JSON.stringify({
        platform: state.platform,
        moduleId: state.moduleId,
        modules,
        playlist: state.playlist,
        currentIndex: state.currentIndex,
        settings: state.settings,
      }));
    } catch (_) {}
  }

  function escapeHTML(value) {
    return String(value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function formatTime(seconds) {
    const s = Math.max(0, Math.round(seconds));
    const m = Math.floor(s / 60);
    const r = s % 60;
    return `${String(m).padStart(2, '0')}:${String(r).padStart(2, '0')}`;
  }

  /* ---------- navigation ---------- */
  const TAB_INDEX = { home: 0, dynamic: 1, playlist: 2, messages: 3, my: 4 };

  function showPage(page) {
    state.page = page;
    $$('.page').forEach((section) => {
      section.classList.toggle('active', section.dataset.page === page);
    });
    app.dataset.page = page;
    if (TAB_INDEX[page] !== undefined) {
      app.style.setProperty('--tab', String(TAB_INDEX[page]));
    }
    $$('.tab').forEach((tab) => {
      tab.classList.toggle('on', tab.dataset.page === page);
    });
    appScroll.scrollTop = 0;
    closeModuleMenu();
    if (page === 'search') {
      setTimeout(() => searchInput.focus(), 120);
    }
  }

  function openModulePage(name) {
    state.moduleReturn = TAB_INDEX[state.page] !== undefined ? state.page : 'home';
    state.moduleName = name;
    state.moduleFilterIndex = 0;
    modulePageTitle.textContent = name;
    moduleFilter.textContent = MODULE_FILTERS[0];
    moduleNote.textContent = MODULE_NOTES[name] || '模块占位 · 内容由真实接口接入';
    showPage('module');
  }

  /* ---------- home modules ---------- */
  function currentModule() {
    return state.modules.find((mod) => mod.id === state.moduleId && mod.on) || null;
  }

  function refreshHomeHeader() {
    const mod = currentModule();
    moduleTitle.textContent = mod ? mod.name : '无模块';
    if (!mod) {
      homeNote.textContent = '所有主页模块已关闭 · 在「主页模块」中启用';
      return;
    }
    homeNote.textContent = `${mod.name}模块占位 · 单列 · 下拉刷新 / 触底加载`;
  }

  function renderModuleMenu() {
    moduleMenu.innerHTML = '';
    const enabled = state.modules.filter((mod) => mod.on);
    if (!enabled.length) {
      const empty = document.createElement('div');
      empty.className = 'mm-empty';
      empty.textContent = '没有启用的主页模块。到「我的 → 主页模块」里选择。';
      moduleMenu.appendChild(empty);
      return;
    }
    enabled.forEach((mod) => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = mod.id === state.moduleId ? 'on' : '';
      button.innerHTML = `<span>${escapeHTML(mod.name)}</span><span class="mm-check">✓</span>`;
      button.addEventListener('click', () => {
        state.moduleId = mod.id;
        refreshHomeHeader();
        renderModuleMenu();
        closeModuleMenu();
        appScroll.scrollTo({ top: 0, behavior: 'smooth' });
        save();
      });
      moduleMenu.appendChild(button);
    });
  }

  function openModuleMenu() {
    renderModuleMenu();
    moduleMenu.hidden = false;
    moduleBtn.classList.add('open');
  }

  function closeModuleMenu() {
    moduleMenu.hidden = true;
    moduleBtn.classList.remove('open');
  }

  function toggleModuleMenu() {
    if (moduleMenu.hidden) openModuleMenu();
    else closeModuleMenu();
  }

  function renderModuleSettings() {
    moduleSettings.innerHTML = '';
    const groups = ['首页', '内容', '社区'];
    groups.forEach((group) => {
      const wrap = document.createElement('div');
      wrap.className = 'module-group';
      const label = document.createElement('div');
      label.className = 'module-group-label';
      label.textContent = group;
      wrap.appendChild(label);

      state.modules.filter((mod) => mod.group === group).forEach((mod) => {
        const row = document.createElement('button');
        row.type = 'button';
        row.className = `module-toggle${mod.on ? ' on' : ''}`;
        row.innerHTML = `
          <span class="mt-copy">
            <span class="mt-name">${escapeHTML(mod.name)}</span>
            <span class="mt-desc">${escapeHTML(mod.desc)}</span>
          </span>
          <span class="switch"></span>`;
        row.addEventListener('click', () => {
          mod.on = !mod.on;
          if (!mod.on && state.moduleId === mod.id) {
            state.moduleId = state.modules.find((item) => item.on)?.id || null;
          }
          if (!state.moduleId) {
            state.moduleId = state.modules.find((item) => item.on)?.id || null;
          }
          renderModuleSettings();
          renderModuleMenu();
          refreshHomeHeader();
          save();
        });
        wrap.appendChild(row);
      });
      moduleSettings.appendChild(wrap);
    });

    const enabledCount = state.modules.filter((mod) => mod.on).length;
    moduleCount.textContent = `已启用 ${enabledCount} / ${state.modules.length} 个模块 · 首页标题下拉即可切换`;
  }

  /* ---------- playlist ---------- */
  function playlistItemMarkup(item, index, current, removable) {
    return `
      <span class="pl-index">${String(index + 1).padStart(2, '0')}</span>
      <span class="pl-thumb"><span class="ph-label">封面</span></span>
      <span class="pl-copy">
        <span class="pl-title">${escapeHTML(item.title)}${current ? '<span class="pl-badge">播放中</span>' : ''}</span>
        <span class="pl-meta">${escapeHTML(item.meta)}</span>
      </span>
      ${removable ? '<button class="pl-remove" type="button" title="移出播放列表">×</button>' : ''}`;
  }

  function updatePlaylistCounts() {
    const count = state.playlist.length;
    playlistCount.textContent = `${count} 项`;
    myPlaylistCount.textContent = `${count} 项`;
    tabPlaylistCount.textContent = String(count);
    tabPlaylistCount.hidden = count === 0;

    const clearButton = $('#clearPlaylist');
    clearButton.hidden = count === 0;
    if (count === 0) {
      clearArmed = false;
      clearTimeout(clearTimer);
      clearButton.textContent = '清空';
      clearButton.classList.remove('danger');
    }
  }

  function renderPlaylist() {
    playlistList.innerHTML = '';
    if (!state.playlist.length) {
      const empty = document.createElement('div');
      empty.className = 'empty-state';
      empty.innerHTML = `
        <span class="empty-ico">☰</span>
        <b>播放列表是空的</b>
        <p>在视频详情或播放器里加入队列，随时接着看。</p>
        <button class="pill-btn" type="button" data-goto="home">去首页看看</button>`;
      playlistList.appendChild(empty);
      updatePlaylistCounts();
      return;
    }

    state.playlist.forEach((item, index) => {
      const row = document.createElement('div');
      row.className = `playlist-item${index === state.currentIndex ? ' current' : ''}`;
      row.setAttribute('role', 'button');
      row.tabIndex = 0;
      row.innerHTML = playlistItemMarkup(item, index, index === state.currentIndex, true);

      row.addEventListener('click', (event) => {
        if (event.target.closest('.pl-remove')) return;
        setCurrent(index, false);
      });
      row.addEventListener('keydown', (event) => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          setCurrent(index, false);
        }
      });

      const remove = $('.pl-remove', row);
      remove.addEventListener('click', (event) => {
        event.stopPropagation();
        removeFromPlaylist(index);
      });

      playlistList.appendChild(row);
    });

    updatePlaylistCounts();
  }

  function setCurrent(index, closeSheetAfter) {
    if (index < 0 || index >= state.playlist.length) return;
    state.currentIndex = index;
    renderPlaylist();
    updatePlayerLabels();
    save();
    if (closeSheetAfter) closeSheet();
  }

  function removeFromPlaylist(index) {
    state.playlist.splice(index, 1);
    if (!state.playlist.length) state.currentIndex = 0;
    else if (state.currentIndex > index) state.currentIndex -= 1;
    else if (state.currentIndex >= state.playlist.length) state.currentIndex = state.playlist.length - 1;
    renderPlaylist();
    updatePlayerLabels();
    save();
  }

  function addToPlaylist(title) {
    const index = state.playlist.length + 1;
    state.playlist.push({
      id: `q${Date.now()}`,
      title: title || `视频占位 ${String(index).padStart(2, '0')}`,
      meta: `UP 占位 ${String(index).padStart(2, '0')} · 00:00`,
    });
    renderPlaylist();
    updatePlayerLabels();
    save();
  }

  function clearPlaylist() {
    state.playlist = [];
    state.currentIndex = 0;
    renderPlaylist();
    updatePlayerLabels();
    save();
  }

  /* ---------- player ---------- */
  function updatePlayerLabels() {
    const item = state.playlist[state.currentIndex];
    playerTitle.textContent = item ? item.title : '暂无播放项';
    playerSub.textContent = `${item ? item.meta : '占位'} · ${state.settings.quality} · 占位`;
    pcQuality.textContent = state.settings.quality;
    pcSpeed.textContent = state.settings.speed || '1.0×';
    pcInterp.textContent = `插帧 ${state.settings.interp}`;
    pcEnhance.textContent = state.settings.enhance;
    pcDanmaku.classList.toggle('on', state.settings.danmaku);
    setProgress(state.progress);
  }

  function setProgress(percent) {
    state.progress = Math.min(100, Math.max(0, percent));
    progressPlayed.style.width = `${state.progress}%`;
    progressThumb.style.left = `${state.progress}%`;
    const current = TOTAL_SECONDS * state.progress / 100;
    pcTime.textContent = `${formatTime(current)} / ${formatTime(TOTAL_SECONDS)}`;
  }

  function showControls() {
    clearTimeout(hideTimer);
    if (!state.playerOpen || state.locked) return;
    player.classList.remove('ui-hidden');
    playerControls.classList.remove('hidden');
    scheduleHide();
  }

  function scheduleHide() {
    clearTimeout(hideTimer);
    if (!state.playerOpen || state.locked) return;
    hideTimer = setTimeout(() => {
      if (!state.playerOpen || state.locked) return;
      playerControls.classList.add('hidden');
      player.classList.add('ui-hidden');
    }, 3000);
  }

  function openPlayer() {
    if (!state.playlist.length) addToPlaylist();
    state.playerOpen = true;
    state.playing = false;
    state.locked = false;
    state.progress = 0;
    pcPlay.textContent = '▶';
    updatePlayerLabels();
    player.classList.add('open');
    player.setAttribute('aria-hidden', 'false');
    player.inert = false;
    player.classList.remove('ui-hidden');
    lockBadge.classList.remove('show');
    closeSheet();
    showControls();
    if (screen.orientation && screen.orientation.lock) {
      screen.orientation.lock('landscape').catch(() => {});
    }
  }

  function closePlayer() {
    state.playerOpen = false;
    state.locked = false;
    clearTimeout(hideTimer);
    clearTimeout(clickTimer);
    clickTimer = null;
    if (player.contains(document.activeElement)) document.activeElement.blur();
    player.classList.remove('open', 'ui-hidden');
    player.setAttribute('aria-hidden', 'true');
    player.inert = true;
    lockBadge.classList.remove('show');
    playerControls.classList.remove('hidden');
    closeSheet();
    if (document.fullscreenElement && document.exitFullscreen) {
      document.exitFullscreen().catch(() => {});
    }
    if (screen.orientation && screen.orientation.unlock) {
      try { screen.orientation.unlock(); } catch (_) {}
    }
    pcFullscreen.textContent = '全屏';
  }

  function lockPlayer() {
    state.locked = true;
    clearTimeout(hideTimer);
    player.classList.add('ui-hidden');
    playerControls.classList.add('hidden');
    lockBadge.classList.add('show');
    closeSheet();
  }

  function unlockPlayer() {
    state.locked = false;
    lockBadge.classList.remove('show');
    showControls();
  }

  function togglePlay() {
    state.playing = !state.playing;
    pcPlay.textContent = state.playing ? 'Ⅱ' : '▶';
    showControls();
  }

  function showRipple(text, leftPercent) {
    seekRipple.textContent = text;
    seekRipple.style.left = `${leftPercent}%`;
    seekRipple.classList.remove('go');
    void seekRipple.offsetWidth;
    seekRipple.classList.add('go');
  }

  function seekBy(seconds) {
    const delta = seconds / TOTAL_SECONDS * 100;
    setProgress(state.progress + delta);
    showRipple(seconds > 0 ? `+${seconds}s` : `${seconds}s`, seconds > 0 ? 72 : 28);
    showControls();
  }

  function toggleFullscreen() {
    if (document.fullscreenElement) {
      document.exitFullscreen().catch(() => {});
      pcFullscreen.textContent = '全屏';
      return;
    }
    if (document.documentElement.requestFullscreen) {
      document.documentElement.requestFullscreen().then(() => {
        pcFullscreen.textContent = '退出全屏';
      }).catch(() => {});
    }
  }

  /* ---------- sheets ---------- */
  function openSheet(title, sub, build) {
    psheetTitle.textContent = title;
    psheetSub.textContent = sub || '';
    psheetBody.innerHTML = '';
    if (build) build(psheetBody);
    psheet.inert = false;
    psheet.classList.add('open');
    psheetBackdrop.classList.add('show');
    psheetBody.scrollTop = 0;
  }

  function closeSheet() {
    if (psheet.contains(document.activeElement)) document.activeElement.blur();
    psheet.classList.remove('open');
    psheetBackdrop.classList.remove('show');
    psheet.inert = true;
  }

  function openOptionsSheet(kind) {
    const data = sheetData[kind];
    if (!data) return;
    openSheet(data.title, data.sub, (body) => {
      data.options.forEach((option) => {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = `opt${data.selected() === option.value ? ' on' : ''}`;
        button.innerHTML = `
          <span class="opt-copy">
            <span>${escapeHTML(option.label)}</span>
            ${option.meta ? `<small>${escapeHTML(option.meta)}</small>` : ''}
          </span>
          <span class="opt-dot"></span>`;
        button.addEventListener('click', () => {
          data.apply(option.value);
          closeSheet();
        });
        body.appendChild(button);
      });
    });
  }

  function openQueueSheet() {
    const count = state.playlist.length;
    openSheet('播放列表', `${count} 项 · 点击切换当前播放`, (body) => {
      if (!count) {
        const empty = document.createElement('div');
        empty.className = 'empty-state';
        empty.style.padding = '28px 12px';
        empty.innerHTML = '<span class="empty-ico">☰</span><b>队列是空的</b><p>从视频详情加入后，这里就是播放队列。</p>';
        body.appendChild(empty);
        return;
      }
      state.playlist.forEach((item, index) => {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = `queue-item${index === state.currentIndex ? ' on' : ''}`;
        button.innerHTML = playlistItemMarkup(item, index, index === state.currentIndex, false);
        button.addEventListener('click', () => {
          setCurrent(index, true);
        });
        body.appendChild(button);
      });
      const openPage = document.createElement('button');
      openPage.type = 'button';
      openPage.className = 'opt';
      openPage.innerHTML = '<span>打开播放列表页</span><span class="meta">管理队列 ›</span>';
      openPage.addEventListener('click', () => {
        closeSheet();
        showPage('playlist');
      });
      body.appendChild(openPage);
    });
  }

  function actionRow(body, label, value, run) {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'opt';
    button.innerHTML = `<span>${escapeHTML(label)}</span><span class="meta">${escapeHTML(value || '')}</span>`;
    button.addEventListener('click', () => {
      const result = run();
      if (result) {
        const meta = $('.meta', button);
        if (meta) meta.textContent = result;
      }
    });
    body.appendChild(button);
  }

  function openDetailSheet() {
    openSheet('视频操作', '占位内容 · 不请求真实接口', (body) => {
      actionRow(body, state.fav ? '已收藏' : '收藏', state.fav ? '已加入' : '', () => {
        state.fav = !state.fav;
        return state.fav ? '已加入' : '已取消';
      });
      actionRow(body, state.coin ? '已投币' : '投币', state.coin ? '2 币' : '', () => {
        state.coin = true;
        return '已投币';
      });
      actionRow(body, '分享', state.copied ? '已复制' : '复制链接', () => {
        state.copied = true;
        return '已复制';
      });
      actionRow(body, '缓存', state.cached ? '已加入下载' : '离线下载', () => {
        state.cached = true;
        return '已加入下载';
      });
      actionRow(body, state.detailAdded ? '已在播放列表' : '加入播放列表', state.detailAdded ? '队列 +1' : '', () => {
        if (!state.detailAdded) {
          addToPlaylist();
          state.detailAdded = true;
        }
        return '已加入';
      });
    });
  }

  function openPlayerMoreSheet() {
    openSheet('播放器', '所有改动即时生效 · 无弹窗提示', (body) => {
      actionRow(body, '播放设置', '画质 / 插帧 / 增强', () => {
        openSettingsSheet('settings-playback');
      });
      actionRow(body, '弹幕设置', state.settings.danmaku ? '开' : '关', () => {
        openSettingsSheet('settings-danmaku');
      });
      actionRow(body, '循环模式', state.settings.loop, () => {
        const list = ['循环', '继续', '下一分P', '暂停'];
        state.settings.loop = list[(list.indexOf(state.settings.loop) + 1) % list.length];
        save();
        return state.settings.loop;
      });
      actionRow(body, '播放器比例', state.settings.aspect, () => {
        const list = ['适应', '拉伸', '裁切'];
        state.settings.aspect = list[(list.indexOf(state.settings.aspect) + 1) % list.length];
        save();
        return state.settings.aspect;
      });
      actionRow(body, '锁定屏幕', '隐藏控件', () => {
        lockPlayer();
      });
      actionRow(body, '截图', state.shot ? '已保存' : '保存画面', () => {
        state.shot = true;
        return '已保存';
      });
      actionRow(body, state.fav ? '已收藏' : '收藏', state.fav ? '已加入' : '', () => {
        state.fav = !state.fav;
        return state.fav ? '已加入' : '已取消';
      });
      actionRow(body, '复制链接', state.copied ? '已复制' : 'BV 占位', () => {
        state.copied = true;
        return '已复制';
      });
      actionRow(body, '举报', '', () => '已提交（占位）');
    });
  }

  function openSettingsSheet(id) {
    const def = settingsDefinition(id);
    if (!def) return;
    openSheet(def.title, def.sub, (body) => {
      def.rows.forEach((row) => body.appendChild(buildSettingRow(row)));
    });
  }

  function buildSettingRow(row) {
    if (row.type === 'switch') {
      const wrap = document.createElement('div');
      wrap.className = 'sheet-row';
      wrap.innerHTML = `<span class="sr-label">${escapeHTML(row.label)}</span>`;
      const toggle = document.createElement('button');
      toggle.type = 'button';
      toggle.className = `sheet-switch${state.settings[row.key] ? ' on' : ''}`;
      toggle.addEventListener('click', () => {
        state.settings[row.key] = !state.settings[row.key];
        toggle.classList.toggle('on', state.settings[row.key]);
        save();
        if (row.onChange) row.onChange();
      });
      wrap.appendChild(toggle);
      return wrap;
    }

    if (row.type === 'choice') {
      const wrap = document.createElement('div');
      wrap.className = 'sheet-row choice-row';
      wrap.innerHTML = `<span class="sr-label">${escapeHTML(row.label)}</span>`;
      const line = document.createElement('div');
      line.className = 'choice-line';
      row.options.forEach((option) => {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = `choice-btn${state.settings[row.key] === option ? ' on' : ''}`;
        button.textContent = option;
        button.addEventListener('click', () => {
          state.settings[row.key] = option;
          $$('.choice-btn', line).forEach((item) => item.classList.toggle('on', item === button));
          save();
          if (row.onChange) row.onChange();
        });
        line.appendChild(button);
      });
      wrap.appendChild(line);
      return wrap;
    }

    if (row.type === 'slider') {
      const wrap = document.createElement('div');
      wrap.className = 'sheet-slider';
      const label = document.createElement('label');
      label.textContent = row.label;
      const input = document.createElement('input');
      input.type = 'range';
      input.min = String(row.min);
      input.max = String(row.max);
      input.step = String(row.step || 1);
      input.value = String(state.settings[row.key]);
      const output = document.createElement('output');
      const format = row.format || ((value) => `${value}${row.unit || ''}`);
      output.textContent = format(state.settings[row.key]);
      input.addEventListener('input', () => {
        state.settings[row.key] = Number(input.value);
        output.textContent = format(input.value);
        save();
        if (row.onChange) row.onChange();
      });
      wrap.append(label, input, output);
      return wrap;
    }

    if (row.type === 'action') {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'sheet-row tapable';
      button.innerHTML = `<span class="sr-label">${escapeHTML(row.label)}</span><span class="sr-value">${escapeHTML(row.value || '')}</span>`;
      button.addEventListener('click', () => {
        const result = row.run ? row.run() : '占位';
        if (result) {
          const value = $('.sr-value', button);
          if (value) value.textContent = result;
        }
      });
      return button;
    }

    const wrap = document.createElement('div');
    wrap.className = 'sheet-row';
    wrap.innerHTML = `<span class="sr-label">${escapeHTML(row.label)}</span><span class="sr-value">${escapeHTML(row.value || '')}</span>`;
    return wrap;
  }

  function settingsDefinition(id) {
    const definitions = {
      'settings-playback': {
        title: '播放',
        sub: '画质、插帧、增强修改后写回全局设置，换视频沿用',
        rows: [
          { type: 'choice', label: '默认画质', key: 'defaultQuality', options: ['最高', '2160P', '1440P', '1080P', '720P', '480P', '360P'] },
          { type: 'choice', label: '当前画质', key: 'quality', options: ['4K', '1080P60', '1080P', '720P', '480P', '仅音频'], onChange: updatePlayerLabels },
          { type: 'choice', label: '插帧', key: 'interp', options: ['关', '自动', '60', '90', '120'], onChange: updatePlayerLabels },
          { type: 'choice', label: '画质增强', key: 'enhance', options: ['关', 'CAS', 'Anime4K'], onChange: updatePlayerLabels },
          { type: 'switch', label: '原始分辨率解码（4K）', key: 'native4k' },
          { type: 'switch', label: '仅音频', key: 'audioOnly' },
          { type: 'static', label: '解码策略', value: '硬件优先 · 占位' },
        ],
      },
      'settings-danmaku': {
        title: '弹幕',
        sub: '实时生效，现有弹幕不清空；屏蔽规则在「设置 → 屏蔽」',
        rows: [
          { type: 'switch', label: '弹幕显示', key: 'danmaku', onChange: updatePlayerLabels },
          { type: 'slider', label: '不透明度', key: 'danmakuOpacity', min: 0, max: 100, unit: '%' },
          { type: 'slider', label: '字号', key: 'danmakuSize', min: 50, max: 150, unit: '%' },
          { type: 'slider', label: '速度', key: 'danmakuSpeed', min: 50, max: 200, step: 10, format: (v) => `${(v / 100).toFixed(1)}×` },
          { type: 'choice', label: '显示区域', key: 'danmakuArea', options: ['全屏', '1/2 屏', '1/3 屏'] },
          { type: 'switch', label: '分布密度', key: 'danmakuDensity' },
          { type: 'static', label: '弹幕节拍', value: '跟随屏幕刷新率 · 占位' },
        ],
      },
      'settings-download': {
        title: '离线下载',
        sub: 'DASH 视频 + 音频 → FFmpeg 合流 MP4；同时最多 2 个任务',
        rows: [
          { type: 'static', label: '同时任务', value: '2 个' },
          { type: 'switch', label: '仅 Wi-Fi 预加载', key: 'wifiPreload' },
          { type: 'static', label: '队列', value: '0 个任务' },
          { type: 'action', label: '打开下载目录', value: '占位', run: () => '已打开（占位）' },
          { type: 'action', label: '清理已完成', value: '0 个', run: () => '已清理 0 个' },
        ],
      },
      'settings-appearance': {
        title: '外观',
        sub: '浅色 / 深色 / 跟随系统；背景透明度与模糊分别控制',
        rows: [
          { type: 'choice', label: '主题', key: 'theme', options: ['跟随系统', '浅色', '深色'] },
          { type: 'slider', label: '背景透明度', key: 'bgTransparency', min: 0, max: 100, unit: '%' },
          { type: 'slider', label: '玻璃模糊', key: 'glassBlur', min: 0, max: 100, unit: '%' },
          { type: 'slider', label: '背景模糊', key: 'bgBlur', min: 0, max: 100, unit: '%' },
          { type: 'static', label: '圆角', value: '18 / 24 / 27' },
        ],
      },
      'settings-gesture': {
        title: '手势',
        sub: '移动端把桌面快捷键转成手势；外接键盘仍可用',
        rows: [
          { type: 'switch', label: '双击左 / 右 ±10s', key: 'doubleSeek' },
          { type: 'switch', label: '长按 2× 快放', key: 'longPress2x' },
          { type: 'switch', label: '上下滑 音量 / 亮度', key: 'swipeBrightness' },
          { type: 'switch', label: '双击画面 全屏 / 还原', key: 'doubleFullscreen' },
          { type: 'static', label: '进度条', value: '拖动精确 seek · 占位' },
        ],
      },
      'settings-distraction': {
        title: '防干扰',
        sub: '只保留自己需要的入口，首页会更干净',
        rows: [
          { type: 'switch', label: '隐藏直播入口', key: 'hideLive' },
          { type: 'switch', label: '隐藏番剧入口', key: 'hideBangumi' },
          { type: 'switch', label: '隐藏养鱼入口', key: 'hideFish' },
          { type: 'switch', label: '隐藏热搜', key: 'hideHotSearch' },
          { type: 'static', label: '应用范围', value: '首页 / 底栏 / 搜索' },
        ],
      },
      'settings-account': {
        title: '账户',
        sub: '二维码登录 · 头像 / 昵称 / UID / 等级',
        rows: [
          { type: 'static', label: '昵称', value: '占位账号' },
          { type: 'static', label: 'UID', value: '100000000' },
          { type: 'static', label: '等级', value: 'Lv6 · 占位' },
          { type: 'static', label: '大会员', value: '未开通' },
          { type: 'action', label: '扫码登录', value: '未登录 / 占位', run: () => { closeSheet(); showPage('login'); return '打开登录'; } },
          { type: 'action', label: '打开账户页', value: '账户 / 经验 / 权益', run: () => '账户页（占位）' },
          { type: 'action', label: '退出登录', value: '', run: () => '已退出（占位）' },
        ],
      },
      'settings-shortcuts': {
        title: '快捷键',
        sub: '桌面端 11 项播放器快捷键；移动端映射为手势，外接键盘保留',
        rows: [
          { type: 'static', label: '播放 / 暂停', value: '空格' },
          { type: 'static', label: '全屏 / 还原', value: '双击画面' },
          { type: 'static', label: '快退 / 快进', value: '← / →' },
          { type: 'static', label: '音量', value: '↑ / ↓' },
          { type: 'static', label: '静音', value: 'M' },
          { type: 'action', label: '全部 11 项映射', value: '打开', run: () => '快捷键面板（占位）' },
          { type: 'action', label: '恢复默认', value: '', run: () => '已恢复默认' },
        ],
      },
      'settings-system': {
        title: '系统',
        sub: '移动端只保留适用的项；开机自启 / 托盘仅桌面',
        rows: [
          { type: 'switch', label: '开机自启', key: 'autostart' },
          { type: 'switch', label: '关闭到托盘', key: 'closeToTray' },
          { type: 'switch', label: '自动检查更新', key: 'autoUpdate' },
          { type: 'action', label: '检查更新', value: 'v2.0.0-prototype', run: () => '已是最新（占位）' },
        ],
      },
      'settings-block': {
        title: '屏蔽',
        sub: '关键词 / 正则 / 用户；弹幕与评论共用规则',
        rows: [
          { type: 'static', label: '关键词', value: '占位词 01、02' },
          { type: 'static', label: '正则', value: '无' },
          { type: 'static', label: '用户', value: 'UP 占位 01' },
          { type: 'action', label: '添加规则', value: '', run: () => '已添加（占位）' },
          { type: 'action', label: '清空规则', value: '', run: () => '已清空' },
        ],
      },
      'settings-cloud': {
        title: '智能云屏蔽',
        sub: '服务端同步的 AI 屏蔽等级',
        rows: [
          { type: 'switch', label: '智能云屏蔽', key: 'cloudBlock' },
          { type: 'slider', label: 'AI 等级', key: 'cloudLevel', min: 0, max: 10 },
          { type: 'action', label: '立即同步', value: '', run: () => '已同步（占位）' },
        ],
      },
      'settings-storage': {
        title: '存储',
        sub: '缓存、离线任务与本地文件',
        rows: [
          { type: 'static', label: '页面缓存', value: '0 MB' },
          { type: 'static', label: '离线任务', value: '0 个' },
          { type: 'action', label: '清理缓存', value: '', run: () => '已清理 0 MB' },
          { type: 'action', label: '打开下载目录', value: '', run: () => '已打开（占位）' },
        ],
      },
      'settings-optimize': {
        title: '优化',
        sub: '预加载与页面预热；硬件解码在移动端强制开启',
        rows: [
          { type: 'switch', label: '后台预加载', key: 'preloadNext' },
          { type: 'switch', label: '缓存下一批推荐', key: 'warmPages' },
          { type: 'static', label: '硬件解码', value: '强制开启' },
          { type: 'static', label: '插帧管线', value: 'GPU · 占位' },
        ],
      },
      'settings-about': {
        title: '关于 O11A1',
        sub: '移动端 V2 布局原型',
        rows: [
          { type: 'static', label: '版本', value: '2.0.0 · Web 原型' },
          { type: 'static', label: '构建', value: '2026-11-21' },
          { type: 'static', label: '核心', value: 'o11a1-core · UniFFI' },
          { type: 'static', label: '播放器', value: 'Media3 / AVFoundation' },
          { type: 'action', label: '开源许可', value: '查看', run: () => '许可页（占位）' },
        ],
      },
    };
    return definitions[id] || null;
  }

  /* ---------- search / commands ---------- */
  const COMMANDS = [
    { icon: '☰', label: '播放列表', meta: '队列', run: () => showPage('playlist') },
    { icon: '◫', label: '主页模块', meta: '自定义', run: () => showPage('modules') },
    { icon: '⚙', label: '设置', meta: '全部', run: () => showPage('settings') },
    { icon: '◉', label: '登录 / 账户', meta: '扫码', run: () => showPage('login') },
    { icon: '⌄', label: '切换首页模块', meta: '快速切换', run: () => { showPage('home'); openModuleMenu(); } },
    { icon: '◉', label: '打开播放器', meta: '横屏', run: openPlayer },
    { icon: '⌕', label: '搜索占位', meta: '输入', run: () => searchInput.focus() },
    { icon: '◈', label: '收藏', meta: '收藏夹', run: () => openModulePage('收藏') },
    { icon: '↺', label: '历史', meta: '继续观看', run: () => openModulePage('历史') },
    { icon: '▤', label: '番剧', meta: '每日放送', run: () => openModulePage('番剧') },
    { icon: '▶', label: '直播', meta: '推荐 / 分区', run: () => openModulePage('直播') },
    { icon: '▦', label: '分区', meta: '20 个一级分区', run: () => openModulePage('分区') },
    { icon: '◌', label: '养鱼 · AI 看片', meta: '实验', run: () => openModulePage('养鱼') },
    { icon: '◍', label: '动态', meta: '关注', run: () => showPage('dynamic') },
    { icon: '✉', label: '消息', meta: '回复 / @ / 赞', run: () => showPage('messages') },
  ];

  function renderCommands(query) {
    const keyword = query.trim().toLowerCase();
    const matches = keyword
      ? COMMANDS.filter((command) => `${command.label} ${command.meta}`.toLowerCase().includes(keyword))
      : COMMANDS;
    commandLabel.textContent = keyword ? `命令 · ${matches.length} 项` : '快速命令';
    commandList.innerHTML = '';
    if (!matches.length) {
      const empty = document.createElement('div');
      empty.className = 'command-empty';
      empty.textContent = '没有匹配的命令 · 直接输入会得到占位搜索结果';
      commandList.appendChild(empty);
      return;
    }
    matches.forEach((command) => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'command-row';
      button.innerHTML = `<span class="cmd-ico">${command.icon}</span><span>${escapeHTML(command.label)}</span><span class="cmd-meta">${escapeHTML(command.meta)}</span>`;
      button.addEventListener('click', () => {
        closeModuleMenu();
        command.run();
      });
      commandList.appendChild(button);
    });
  }

  function updateSearch() {
    const query = searchInput.value.trim();
    renderCommands(query);
    const hasQuery = query.length > 0;
    searchResultsLabel.hidden = !hasQuery;
    searchResults.hidden = !hasQuery;
    if (hasQuery) {
      searchResultsLabel.textContent = `“${query}” 的结果（占位）`;
    }
  }

  /* ---------- prototype drawer ---------- */
  function openDrawer() {
    protoDrawer.inert = false;
    protoDrawer.classList.add('open');
    protoDrawer.setAttribute('aria-hidden', 'false');
    protoBackdrop.classList.add('show');
    protoFab.classList.add('hide');
  }

  function closeDrawer() {
    if (protoDrawer.contains(document.activeElement)) document.activeElement.blur();
    protoDrawer.classList.remove('open');
    protoDrawer.setAttribute('aria-hidden', 'true');
    protoDrawer.inert = true;
    protoBackdrop.classList.remove('show');
    protoFab.classList.remove('hide');
  }

  function setPlatform(platform) {
    state.platform = platform;
    document.body.dataset.platform = platform;
    $$('#platformSwitch button').forEach((button) => {
      button.classList.toggle('on', button.dataset.platform === platform);
    });
    save();
  }

  function resetPrototype() {
    try { localStorage.removeItem(STORAGE_KEY); } catch (_) {}
    const url = new URL(window.location.href);
    url.searchParams.set('reset', '1');
    window.location.href = url.toString();
  }

  /* ---------- event wiring ---------- */
  document.addEventListener('click', (event) => {
    const goto = event.target.closest('[data-goto]');
    if (goto) {
      showPage(goto.dataset.goto);
      closeDrawer();
      return;
    }

    const moduleTarget = event.target.closest('[data-module]');
    if (moduleTarget) {
      openModulePage(moduleTarget.dataset.module);
      return;
    }

    const detail = event.target.closest('[data-open-detail]');
    if (detail) {
      state.detailAdded = false;
      showPage('detail');
      return;
    }

    const play = event.target.closest('[data-open-player]');
    if (play) {
      openPlayer();
      return;
    }

    const backHome = event.target.closest('[data-back-home]');
    if (backHome) {
      showPage('home');
      return;
    }

    const sheet = event.target.closest('[data-sheet]');
    if (sheet) {
      const kind = sheet.dataset.sheet;
      if (sheetData[kind]) openOptionsSheet(kind);
      else if (kind.startsWith('settings-')) openSettingsSheet(kind);
      return;
    }

    if (!event.target.closest('#moduleBtn') && !event.target.closest('#moduleMenu')) {
      closeModuleMenu();
    }
  });

  $$('.tab').forEach((tab) => {
    tab.addEventListener('click', () => showPage(tab.dataset.page));
  });

  moduleBtn.addEventListener('click', (event) => {
    event.stopPropagation();
    toggleModuleMenu();
  });

  moduleMenu.addEventListener('click', (event) => event.stopPropagation());

  $('#searchBtn').addEventListener('click', () => showPage('search'));
  $('#searchCancel').addEventListener('click', () => showPage('home'));
  searchInput.addEventListener('input', updateSearch);
  searchInput.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
      event.preventDefault();
      searchInput.blur();
    }
  });

  $('#detailMore').addEventListener('click', openDetailSheet);

  $('#accountCard').addEventListener('click', () => showPage('login'));
  $('#loginRefresh').addEventListener('click', () => {
    loginStatus.textContent = '二维码已刷新 · 占位';
  });
  $('#loginQr').addEventListener('click', () => {
    loginStatus.textContent = '登录成功 · 正在进入首页…';
    setTimeout(() => showPage('home'), 700);
  });

  followBtn.addEventListener('click', () => {
    const on = followBtn.classList.toggle('on');
    followBtn.textContent = on ? '已关注' : '关注';
  });

  $$('.detail-tabs').forEach((group) => {
    $$('button', group).forEach((button) => {
      button.addEventListener('click', () => {
        $$('button', group).forEach((item) => item.classList.remove('on'));
        button.classList.add('on');
      });
    });
  });

  const clearPlaylistBtn = $('#clearPlaylist');
  clearPlaylistBtn.addEventListener('click', () => {
    if (!state.playlist.length) return;
    if (!clearArmed) {
      clearArmed = true;
      clearPlaylistBtn.textContent = '确认清空';
      clearPlaylistBtn.classList.add('danger');
      clearTimeout(clearTimer);
      clearTimer = setTimeout(() => {
        clearArmed = false;
        clearPlaylistBtn.textContent = '清空';
        clearPlaylistBtn.classList.remove('danger');
      }, 5000);
      return;
    }
    clearArmed = false;
    clearTimeout(clearTimer);
    clearPlaylistBtn.textContent = '清空';
    clearPlaylistBtn.classList.remove('danger');
    clearPlaylist();
  });

  dynamicFilter.addEventListener('click', () => {
    state.dynamicFilterIndex = (state.dynamicFilterIndex + 1) % DYNAMIC_FILTERS.length;
    dynamicFilter.textContent = `${DYNAMIC_FILTERS[state.dynamicFilterIndex]} ⌄`;
  });

  messageFilter.addEventListener('click', () => {
    state.messageFilterIndex = (state.messageFilterIndex + 1) % MESSAGE_FILTERS.length;
    messageFilter.textContent = `${MESSAGE_FILTERS[state.messageFilterIndex]} ⌄`;
  });

  moduleFilter.addEventListener('click', () => {
    state.moduleFilterIndex = (state.moduleFilterIndex + 1) % MODULE_FILTERS.length;
    moduleFilter.textContent = MODULE_FILTERS[state.moduleFilterIndex];
    moduleNote.textContent = `${state.moduleName} · ${MODULE_FILTERS[state.moduleFilterIndex]} · 占位`;
  });

  $('#moduleBack').addEventListener('click', () => showPage(state.moduleReturn || 'home'));

  /* player */
  $('#playerBack').addEventListener('click', closePlayer);
  $('#playerQueue').addEventListener('click', openQueueSheet);
  $('#playerMore').addEventListener('click', openPlayerMoreSheet);
  pcPlay.addEventListener('click', togglePlay);
  pcDanmaku.addEventListener('click', () => {
    state.settings.danmaku = !state.settings.danmaku;
    updatePlayerLabels();
    save();
  });
  pcFullscreen.addEventListener('click', toggleFullscreen);
  lockBadge.addEventListener('click', unlockPlayer);

  playerStage.addEventListener('pointermove', () => {
    if (state.playerOpen && !state.locked) showControls();
  });

  playerStage.addEventListener('click', (event) => {
    if (event.target.closest('.player-controls')) return;
    if (state.locked) return;
    if (clickTimer) return;
    clickTimer = setTimeout(() => {
      clickTimer = null;
      if (playerControls.classList.contains('hidden')) showControls();
      else {
        playerControls.classList.add('hidden');
        player.classList.add('ui-hidden');
        clearTimeout(hideTimer);
      }
    }, 220);
  });

  playerStage.addEventListener('dblclick', (event) => {
    if (event.target.closest('.player-controls')) return;
    if (state.locked) return;
    clearTimeout(clickTimer);
    clickTimer = null;
    const rect = playerStage.getBoundingClientRect();
    const right = event.clientX > rect.left + rect.width / 2;
    seekBy(right ? 10 : -10);
  });

  progressBar.addEventListener('click', (event) => {
    const rect = progressBar.getBoundingClientRect();
    const percent = (event.clientX - rect.left) / rect.width * 100;
    setProgress(percent);
    showControls();
  });

  psheetBackdrop.addEventListener('click', closeSheet);
  psheetClose.addEventListener('click', closeSheet);

  document.addEventListener('fullscreenchange', () => {
    pcFullscreen.textContent = document.fullscreenElement ? '退出全屏' : '全屏';
  });

  /* keyboard */
  document.addEventListener('keydown', (event) => {
    if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') {
      event.preventDefault();
      showPage('search');
      return;
    }
    if (event.key === 'Escape') {
      if (psheet.classList.contains('open')) { closeSheet(); return; }
      if (protoDrawer.classList.contains('open')) { closeDrawer(); return; }
      if (state.playerOpen) { closePlayer(); return; }
      if (state.page === 'search' || state.page === 'detail') { showPage('home'); return; }
      if (!moduleMenu.hidden) { closeModuleMenu(); return; }
    }
    if (!state.playerOpen || state.locked) return;
    if (event.code === 'Space') {
      event.preventDefault();
      togglePlay();
    } else if (event.key === 'ArrowLeft') {
      event.preventDefault();
      seekBy(-5);
    } else if (event.key === 'ArrowRight') {
      event.preventDefault();
      seekBy(5);
    } else if (event.key.toLowerCase() === 'f') {
      toggleFullscreen();
    }
  });

  /* prototype drawer */
  protoFab.addEventListener('click', openDrawer);
  $('#protoClose').addEventListener('click', closeDrawer);
  protoBackdrop.addEventListener('click', closeDrawer);
  $('#landscapeBtn').addEventListener('click', () => { closeDrawer(); openPlayer(); });
  $('#resetBtn').addEventListener('click', resetPrototype);
  $$('#platformSwitch button').forEach((button) => {
    button.addEventListener('click', () => setPlatform(button.dataset.platform));
  });
  $('#labelsBtn').addEventListener('click', () => {
    document.body.classList.toggle('no-labels');
    $('#labelsBtn').classList.toggle('on');
  });
  $('#gridBtn').addEventListener('click', () => {
    document.body.classList.toggle('grid');
    $('#gridBtn').classList.toggle('on');
  });
  $('#motionBtn').addEventListener('click', () => {
    document.body.classList.toggle('reduce-motion');
    $('#motionBtn').classList.toggle('on');
  });

  if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    document.body.classList.add('reduce-motion');
    $('#motionBtn').classList.add('on');
  }

  /* init */
  document.body.dataset.platform = state.platform;
  $$('#platformSwitch button').forEach((button) => {
    button.classList.toggle('on', button.dataset.platform === state.platform);
  });
  refreshHomeHeader();
  renderModuleMenu();
  renderModuleSettings();
  renderPlaylist();
  renderCommands('');
  updatePlayerLabels();
  updateSearch();
  showPage('home');
})();

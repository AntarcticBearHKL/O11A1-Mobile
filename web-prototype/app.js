(() => {
  const $ = (selector, root = document) => root.querySelector(selector);
  const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));

  const app = $('#app');
  const appScroll = $('#appScroll');
  const pullRefresh = $('#pullRefresh');
  const pullRefreshLabel = $('#pullRefreshLabel');
  const homeFeed = $('#homeFeed');
  const moduleFeed = $('#moduleFeed');
  const player = $('#player');
  const playerStage = $('#playerStage');
  const playerControls = $('#playerControls');
  const playerTitle = $('#playerTitle');
  const playerSub = $('#playerSub');
  const pcPlay = $('#pcPlay');
  const pcPrev = $('#pcPrev');
  const pcNext = $('#pcNext');
  const pcTime = $('#pcTime');
  const pcMute = $('#pcMute');
  const pcVolume = $('#pcVolume');
  const pcQuality = $('#pcQuality');
  const pcSpeed = $('#pcSpeed');
  const pcInterp = $('#pcInterp');
  const pcEnhance = $('#pcEnhance');
  const pcDanmaku = $('#pcDanmaku');
  const pcDanmakuInput = $('#pcDanmakuInput');
  const pcDanmakuSend = $('#pcDanmakuSend');
  const pcLoop = $('#pcLoop');
  const pcQueue = $('#pcQueue');
  const pcSide = $('#pcSide');
  const pcSettings = $('#pcSettings');
  const pcShot = $('#pcShot');
  const pcFullscreen = $('#pcFullscreen');
  const pcGrab = $('#pcGrab');
  const progressBar = $('.progress-ph', playerControls);
  const progressPlayed = $('.progress-played', playerControls);
  const progressThumb = $('.progress-thumb', playerControls);
  const seekRipple = $('#seekRipple');
  const lockBadge = $('#lockBadge');
  const brightnessHud = $('#brightnessHud');
  const brightnessFill = $('#brightnessFill');
  const brightnessValue = $('#brightnessValue');
  const volumeHud = $('#volumeHud');
  const volumeFill = $('#volumeFill');
  const volumeValue = $('#volumeValue');
  const rateHud = $('#rateHud');
  const rateValue = $('#rateValue');
  const rateLabel = $('#rateLabel');
  const rotateHud = $('#rotateHud');
  const rotateArrow = $('#rotateArrow');
  const rotateLabel = $('#rotateLabel');
  const swipeHint = $('#swipeHint');
  const commentsPanel = $('#commentsPanel');
  const commentsBack = $('#commentsBack');
  const commentsTabs = $('#commentsTabs');
  const commentsBody = $('#commentsBody');
  const commentsCount = $('#commentsCount');
  const commentInput = $('#commentInput');
  const commentSend = $('#commentSend');
  const playerVideo = $('#playerVideo');
  const psheet = $('#psheet');
  const psheetBackdrop = $('#psheetBackdrop');
  const psheetTitle = $('#psheetTitle');
  const psheetSub = $('#psheetSub');
  const psheetBody = $('#psheetBody');
  const psheetClose = $('#psheetClose');
  const homeNote = $('#homeNote');
  const myModuleName = $('#myModuleName');
  const myModuleRow = $('#myModuleRow');
  const myFishRow = $('#myFishRow');
  const sidebar = $('#sidebar');
  const sidebarBackdrop = $('#sidebarBackdrop');
  const sidebarNav = $('#sidebarNav');
  const sidebarSearch = $('#sidebarSearch');
  const playlistDock = $('#playlistDock');
  const pdThumb = $('#pdThumb');
  const pdTitle = $('#pdTitle');
  const pdMeta = $('#pdMeta');
  const pdProgress = $('#pdProgress');
  const playlistPageList = $('#playlistPageList');
  const playlistPageCount = $('#playlistPageCount');
  const playlistBack = $('#playlistBack');
  const moduleSettings = $('#moduleSettings');
  const moduleCount = $('#moduleCount');
  const navSettings = $('#navSettings');
  const navCount = $('#navCount');
  const navSelectedPreview = $('#navSelectedPreview');
  const navModeNote = $('#navModeNote');
  const navNote = $('#navNote');
  const navAllToggle = $('#navAllToggle');
  const searchInput = $('#searchInput');
  const searchResultsLabel = $('#searchResultsLabel');
  const searchResults = $('#searchResults');
  const searchEmpty = $('#searchEmpty');
  const moduleFilter = $('#moduleFilter');
  const dynamicFilter = $('#dynamicFilter');
  const messageFilter = $('#messageFilter');
  const loginStatus = $('#loginStatus');
  const searchClear = $('#searchClear');
  const protoDrawer = $('#protoDrawer');
  const protoBackdrop = $('#protoBackdrop');
  const protoFab = $('#protoFab');
  const homeLandscapeBtn = $('#homeLandscapeBtn');

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

  const NAV_ITEMS = [
    { id: 'home', label: '首页', icon: '⌂', type: 'page', target: 'home', group: '桌面端' },
    { id: 'favorite', label: '收藏', icon: '◈', type: 'module', target: '收藏', group: '桌面端' },
    { id: 'search', label: '搜索', icon: '⌕', type: 'search', group: '桌面端' },
    { id: 'fish', label: '养鱼', icon: '◌', type: 'module', target: '养鱼', group: '桌面端' },
    { id: 'live', label: '直播', icon: '▶', type: 'module', target: '直播', group: '桌面端' },
    { id: 'follow', label: '关注', icon: '◍', type: 'module', target: '关注', group: '桌面端' },
    { id: 'dynamic', label: '动态', icon: '◉', type: 'page', target: 'dynamic', group: '桌面端' },
    { id: 'messages', label: '消息', icon: '✉', type: 'page', target: 'messages', group: '桌面端' },
    { id: 'history', label: '历史', icon: '↺', type: 'module', target: '历史', group: '桌面端' },
    { id: 'my', label: '我的', icon: '◌', type: 'page', target: 'my', group: '移动端' },
  ];

  const DEFAULT_NAV_SELECTED = ['home', 'favorite', 'dynamic', 'messages', 'my'];
  const PAGE_NAV = { home: 'home', search: 'search', dynamic: 'dynamic', messages: 'messages', my: 'my' };

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
    doubleRotate: true,
    longPressRate: true,
    swipeLevel: true,
    middleCollapse: true,
    swipeComments: true,

    hideLive: false,
    hideBangumi: false,
    hideFish: true,
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
    loggedIn: loaded?.loggedIn === true,
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
    miniVisible: false,
    playing: false,
    locked: false,
    progress: 0,
    brightness: Number.isFinite(loaded?.brightness) ? Math.max(0, Math.min(100, loaded.brightness)) : 100,
    volume: Number.isFinite(loaded?.volume) ? Math.max(0, Math.min(100, loaded.volume)) : 80,
    rotation: 'right',
    landscapeHome: loaded?.landscapeHome === true,
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
    navAllVisible: loaded && typeof loaded.navAllVisible === 'boolean' ? loaded.navAllVisible : true,
    navSelected: normalizeNavSelected(loaded?.navSelected),
    navActive: 'home',
    searchReturn: 'home',
    searchReturnNav: null,
    playlistReturn: 'home',
    playlistReturnNav: null,
  };

  if (!state.modules.some((mod) => mod.id === state.moduleId && mod.on)) {
    state.moduleId = state.modules.find((mod) => mod.on)?.id || null;
  }
  if (state.currentIndex >= state.playlist.length) {
    state.currentIndex = Math.max(0, state.playlist.length - 1);
  }

  function normalizeNavSelected(value) {
    const valid = Array.isArray(value)
      ? value.filter((id) => NAV_ITEMS.some((item) => item.id === id))
      : [];
    const unique = [...new Set(valid)].slice(0, 5);
    DEFAULT_NAV_SELECTED.forEach((id) => {
      if (unique.length < 5 && !unique.includes(id)) unique.push(id);
    });
    return unique.length ? unique : DEFAULT_NAV_SELECTED.slice();
  }

  let hideTimer = null;
  let clearArmed = false;
  let clearTimer = null;
  let stageGesture = null;
  let stageTapTimer = null;
  let lastStageTap = { time: 0, zone: '' };
  let levelHudTimer = null;
  let rateHudTimer = null;
  let rotateHudTimer = null;
  let commentsGesture = null;
  let commentsCloseTimer = null;
  let commentTotal = 128;
  let feedSwipeStart = null;
  let sidebarSwipeStart = null;
  let suppressFeedClickUntil = 0;
  let suppressSidebarClickUntil = 0;
  let suppressDockClickUntil = 0;
  let dockDrag = null;
  let dockAbsorbTimer = null;
  let lastVolume = state.volume || 80;
  let toolbarDrag = null;
  let touchPull = null;
  let pullDistance = 0;
  let pullBusy = false;
  let pullSettleTimer = null;
  let bottomRefreshTimer = null;
  let bottomRefreshArmed = true;
  const feedRefreshCounts = { home: 0, search: 0, module: 0 };
  const PULL_THRESHOLD = 64;
  const PULL_MAX = 112;

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
        loggedIn: state.loggedIn,
        platform: state.platform,
        moduleId: state.moduleId,
        modules,
        playlist: state.playlist,
        currentIndex: state.currentIndex,
        settings: state.settings,
        navAllVisible: state.navAllVisible,
        navSelected: state.navSelected,
        brightness: state.brightness,
        volume: state.volume,
        landscapeHome: state.landscapeHome,
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
  function navItemsVisible() {
    return NAV_ITEMS.filter((item) => !(state.settings.hideFish && item.id === 'fish'));
  }

  function visibleNavItems() {
    return navItemsVisible();
  }

  function findNavItemByModule(name) {
    return NAV_ITEMS.find((item) => item.type === 'module' && item.target === name) || null;
  }

  function renderSidebar() {
    const items = visibleNavItems().filter((item) => item.type !== 'search');
    sidebarNav.innerHTML = '';
    items.forEach((item) => {
      const row = document.createElement('button');
      row.type = 'button';
      row.className = 'sidebar-item';
      row.dataset.nav = item.id;
      row.innerHTML = `
        <span class="sidebar-ico">${item.icon}</span>
        <span class="sidebar-label">${escapeHTML(item.label)}</span>`;
      row.addEventListener('click', () => {
        closeSidebar();
        handleNav(item, row);
      });
      sidebarNav.appendChild(row);
    });

    updateNavActive();
    updatePlaylistCounts();
  }

  function updateNavActive() {
    $$('.sidebar-item', sidebarNav).forEach((row) => {
      row.classList.toggle('on', row.dataset.nav === state.navActive);
    });
    sidebarSearch.classList.toggle('on', state.navActive === 'search');
  }

  function openSidebar() {
    if (!state.loggedIn) {
      showPage('login');
      return;
    }
    renderSidebar();
    updateMiniPlayer();
    sidebar.inert = false;
    sidebar.classList.add('open');
    sidebarBackdrop.classList.add('show');
    sidebar.setAttribute('aria-hidden', 'false');
    app.classList.add('sidebar-open');
    updatePlaylistDock();
  }

  function closeSidebar() {
    if (!sidebar.classList.contains('open')) return;
    sidebar.classList.remove('open');
    sidebarBackdrop.classList.remove('show');
    sidebar.setAttribute('aria-hidden', 'true');
    sidebar.inert = true;
    app.classList.remove('sidebar-open');
    updatePlaylistDock();
    if (sidebar.contains(document.activeElement)) document.activeElement.blur();
  }

  function handleNav(item, button) {
    if (item.type === 'search') {
      openSearch();
      return;
    }
    if (item.type === 'module') {
      openModulePage(item.target, item.id);
      return;
    }
    showPage(item.target, item.id);
  }

  function openSearch() {
    if (!state.loggedIn) {
      showPage('login');
      return;
    }
    if (state.page !== 'search') {
      state.searchReturn = state.page;
      state.searchReturnNav = state.navActive;
    }
    showPage('search');
  }

  function closeSearch() {
    const target = state.searchReturn && state.searchReturn !== 'search' ? state.searchReturn : 'home';
    showPage(target, state.searchReturnNav || undefined);
  }

  function loginSucceeded() {
    if (!state.loggedIn) {
      state.loggedIn = true;
      app.classList.remove('auth-gate');
      save();
    }
    loginStatus.textContent = '登录成功 · 正在进入首页…';
    setTimeout(() => {
      if (state.loggedIn) showPage('home');
    }, 600);
  }

  function logout() {
    state.loggedIn = false;
    if (state.playerOpen) stopPlayback();
    closeSheet();
    closeSidebar();
    app.classList.add('auth-gate');
    state.navActive = '';
    save();
    updateNavActive();
    showPage('login');
    loginStatus.textContent = '已退出登录 · 扫码登录';
  }

  function showPage(page, navId) {
    if (!state.loggedIn && page !== 'login') {
      page = 'login';
      navId = null;
    }
    state.page = page;
    app.classList.toggle('auth-gate', !state.loggedIn);
    $$('.page').forEach((section) => {
      section.classList.toggle('active', section.dataset.page === page);
    });
    app.dataset.page = page;
    document.body.classList.toggle('search-mode', page === 'search');
    if (page !== 'search' && document.activeElement === searchInput) {
      searchInput.blur();
    }
    if (page === 'login') {
      state.navActive = '';
      loginStatus.textContent = state.loggedIn ? '已登录 · 可重新扫码（占位）' : '扫码登录 · 占位';
    } else if (navId !== undefined && navId !== null) {
      state.navActive = navId;
    } else if (PAGE_NAV[page]) {
      state.navActive = PAGE_NAV[page];
    }
    updateNavActive();
    updatePlaylistDock();
    bottomRefreshArmed = true;
    clearTimeout(bottomRefreshTimer);
    if (pullDistance > 0) resetPullVisual();
    appScroll.scrollTop = 0;
    if (page === 'search') {
      setTimeout(() => searchInput.focus(), 120);
    }
  }

  function openModulePage(name, navId) {
    if (!state.loggedIn) {
      showPage('login');
      return;
    }
    if (PAGE_NAV[state.page]) {
      state.moduleReturn = state.page;
    } else if (['settings', 'modules', 'nav'].includes(state.page)) {
      state.moduleReturn = 'my';
    } else if (state.page !== 'module') {
      state.moduleReturn = 'home';
    }
    state.moduleName = name;
    state.moduleFilterIndex = 0;
    moduleFilter.textContent = MODULE_FILTERS[0];
    const navItem = findNavItemByModule(name);
    showPage('module', navId || navItem?.id || state.navActive);
  }

  /* ---------- feed refresh ---------- */
  function activeFeed() {
    if (state.page === 'home') return homeFeed;
    if (state.page === 'search') return searchResults;
    if (state.page === 'module') return moduleFeed;
    return null;
  }

  const FEED_ROW_VARIANTS = [
    { thumb: '', w1: 'w90', w2: 'w60', m1: 'w30', m2: 'w18' },
    { thumb: 'alt', w1: 'w80', w2: 'w50', m1: 'w35', m2: 'w18' },
    { thumb: 'alt2', w1: 'w85', w2: 'w55', m1: 'w25', m2: 'w20' },
    { thumb: 'alt3', w1: 'w75', w2: 'w65', m1: 'w30', m2: 'w18' },
    { thumb: '', w1: 'w90', w2: 'w55', m1: 'w30', m2: 'w22' },
    { thumb: 'alt', w1: 'w75', w2: 'w45', m1: 'w25', m2: 'w20' },
  ];

  function feedRowMarkup(variant) {
    const v = FEED_ROW_VARIANTS[variant % FEED_ROW_VARIANTS.length];
    return `
      <button class="video-row" type="button" data-open-player>
        <span class="row-thumb ${v.thumb}"><span class="ph-label">封面</span><span class="dur-ph">00:00</span></span>
        <span class="row-copy"><span class="ph-title"><i class="ph-line ${v.w1}"></i><i class="ph-line ${v.w2}"></i></span><span class="row-meta"><i class="ph-line ${v.m1}"></i><i class="ph-line ${v.m2}"></i></span></span>
      </button>`;
  }

  function renderFeedRows(feed, count, offset) {
    const rows = [];
    for (let i = 0; i < count; i += 1) rows.push(feedRowMarkup(i + offset));
    feed.innerHTML = rows.join('');
  }

  function resetPullVisual() {
    pullDistance = 0;
    app.classList.remove('pulling');
    pullRefresh.classList.remove('show', 'ready');
  }

  function settlePullVisual() {
    app.classList.remove('pulling');
    app.classList.add('pull-settle');
    app.style.setProperty('--pull', '0px');
    clearTimeout(pullSettleTimer);
    pullSettleTimer = setTimeout(() => {
      app.classList.remove('pull-settle');
      app.style.removeProperty('--pull');
    }, 260);
  }

  function updatePull(dy) {
    if (pullBusy) return;
    pullDistance = Math.min(PULL_MAX, Math.max(0, dy * 0.5));
    if (pullDistance < 2) {
      resetPullVisual();
      return;
    }
    app.classList.add('pulling');
    app.classList.remove('pull-settle');
    app.style.setProperty('--pull', `${pullDistance}px`);
    pullRefresh.classList.add('show');
    const ready = pullDistance >= PULL_THRESHOLD;
    pullRefresh.classList.toggle('ready', ready);
    if (!pullRefresh.classList.contains('refreshing')) {
      pullRefreshLabel.textContent = ready ? '松开刷新' : '下拉刷新';
    }
  }

  function finishPull() {
    if (pullDistance <= 0) return;
    const shouldRefresh = pullDistance >= PULL_THRESHOLD;
    settlePullVisual();
    if (!shouldRefresh) {
      pullDistance = 0;
      pullRefresh.classList.remove('show', 'ready');
      return;
    }
    pullDistance = 0;
    refreshActiveFeed();
  }

  function refreshActiveFeed() {
    const feed = activeFeed();
    if (!feed || pullBusy) return;
    const key = state.page;
    const count = feed.children.length || (key === 'home' ? 9 : key === 'search' ? 5 : 4);
    feedRefreshCounts[key] = (feedRefreshCounts[key] || 0) + 1;
    pullBusy = true;
    pullRefresh.classList.add('show', 'refreshing');
    pullRefresh.classList.remove('ready', 'done');
    pullRefreshLabel.textContent = '刷新中';
    renderFeedRows(feed, count, feedRefreshCounts[key]);
    feed.classList.remove('is-refreshing');
    void feed.offsetWidth;
    feed.classList.add('is-refreshing');
    appScroll.scrollTo({ top: 0, behavior: 'smooth' });
    setTimeout(() => {
      feed.classList.remove('is-refreshing');
      pullRefresh.classList.remove('refreshing');
      pullRefresh.classList.add('done');
      pullRefreshLabel.textContent = '已刷新';
      setTimeout(() => {
        pullRefresh.classList.remove('show', 'done');
        pullBusy = false;
      }, 420);
    }, 360);
  }

  /* ---------- home modules ---------- */
  function currentModule() {
    return state.modules.find((mod) => mod.id === state.moduleId && mod.on) || null;
  }

  function refreshHomeHeader() {
    const mod = currentModule();
    if (myModuleName) myModuleName.textContent = mod ? mod.name : '无模块';
    if (!mod) {
      homeNote.textContent = '所有主页模块已关闭 · 在「主页模块」中启用';
      return;
    }
    homeNote.textContent = `${mod.name}模块占位 · 单列 · 下拉刷新 / 触底刷新`;
  }

  function selectModule(moduleId) {
    state.moduleId = moduleId;
    refreshHomeHeader();
    save();
    closeSheet();
    showPage('home');
    appScroll.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function openModuleSheet() {
    const enabled = state.modules.filter((mod) => mod.on && !(state.settings.hideFish && mod.id === 'fish'));
    openSheet('首页模块', '选择首页当前模块', (body) => {
      if (!enabled.length) {
        const empty = document.createElement('div');
        empty.className = 'empty-state';
        empty.style.padding = '28px 12px';
        empty.innerHTML = '<span class="empty-ico">◫</span><b>没有启用的主页模块</b><p>到「主页模块」里打开至少一个。</p>';
        body.appendChild(empty);
        const go = document.createElement('button');
        go.type = 'button';
        go.className = 'pill-btn';
        go.textContent = '去主页模块设置';
        go.addEventListener('click', () => {
          closeSheet();
          showPage('modules', 'my');
        });
        body.appendChild(go);
        return;
      }
      enabled.forEach((mod) => {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = `opt${mod.id === state.moduleId ? ' on' : ''}`;
        button.innerHTML = `
          <span class="opt-copy">
            <span>${escapeHTML(mod.name)}</span>
            <small>${escapeHTML(mod.desc)}</small>
          </span>
          <span class="opt-dot"></span>`;
        button.addEventListener('click', () => selectModule(mod.id));
        body.appendChild(button);
      });
    });
    psheet.dataset.kind = 'module';
  }

  function renderModuleSettings() {
    moduleSettings.innerHTML = '';
    const visibleModules = state.modules.filter((mod) => !(state.settings.hideFish && mod.id === 'fish'));
    const groups = ['首页', '内容', '社区'];
    groups.forEach((group) => {
      const wrap = document.createElement('div');
      wrap.className = 'module-group';
      const label = document.createElement('div');
      label.className = 'module-group-label';
      label.textContent = group;
      wrap.appendChild(label);

      visibleModules.filter((mod) => mod.group === group).forEach((mod) => {
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
          refreshHomeHeader();
          save();
        });
        wrap.appendChild(row);
      });
      moduleSettings.appendChild(wrap);
    });

    const enabledCount = visibleModules.filter((mod) => mod.on).length;
    moduleCount.textContent = `已启用 ${enabledCount} / ${visibleModules.length} 个模块 · 首页模块 sheet 即可切换`;
  }

  /* ---------- hidden entries (fish off for now) ---------- */
  function applyHiddenEntries() {
    const hideFish = state.settings.hideFish;
    if (hideFish) {
      state.navSelected = normalizeNavSelected(state.navSelected.filter((id) => id !== 'fish'));
      const fish = state.modules.find((mod) => mod.id === 'fish');
      if (fish) fish.on = false;
      if (state.moduleId === 'fish') {
        state.moduleId = state.modules.find((mod) => mod.on && mod.id !== 'fish')?.id || null;
      }
    }
    if (myFishRow) myFishRow.hidden = hideFish;
    renderSidebar();
    renderNavSettings();
    renderModuleSettings();
    refreshHomeHeader();
    save();
  }

  /* ---------- bottom navigation editor ---------- */
  function renderNavSettings() {
    const visibleItems = navItemsVisible();
    const selectedIds = state.navSelected.filter((id) => visibleItems.some((item) => item.id === id));
    const selectedCount = selectedIds.length;
    navCount.textContent = `${selectedCount} / 5`;
    navAllToggle.classList.toggle('on', state.navAllVisible);
    navModeNote.textContent = state.navAllVisible
      ? `全量预览中：底部显示全部 ${visibleItems.length} 个按钮；关掉后只显示下面勾选的 ${selectedCount} 个。`
      : `自定义：底部只显示你勾选的 ${selectedCount} 个按钮。`;

    navSelectedPreview.innerHTML = '';
    selectedIds.forEach((id) => {
      const item = visibleItems.find((entry) => entry.id === id);
      if (!item) return;
      const chip = document.createElement('span');
      chip.className = 'nav-chip on';
      chip.innerHTML = `<span>${item.icon}</span><span>${escapeHTML(item.label)}</span>`;
      navSelectedPreview.appendChild(chip);
    });

    navSettings.innerHTML = '';
    ['桌面端', '移动端'].forEach((group) => {
      const label = document.createElement('div');
      label.className = 'module-group-label';
      label.textContent = group === '桌面端' ? '桌面端底部按钮' : '移动端新增';
      navSettings.appendChild(label);

      visibleItems.filter((item) => item.group === group).forEach((item) => {
        const on = state.navSelected.includes(item.id);
        const row = document.createElement('button');
        row.type = 'button';
        row.className = `nav-setting${on ? ' on' : ''}`;
        row.innerHTML = `
          <span class="nav-setting-ico">${item.icon}</span>
          <span class="mt-copy">
            <span class="mt-name">${escapeHTML(item.label)}</span>
            <span class="mt-desc">${item.type === 'search' ? '动作 · 打开视频搜索' : item.type === 'queue' ? '动作 · 打开播放列表' : item.type === 'module' ? `页面 · ${escapeHTML(item.target)}` : '页面'}</span>
          </span>
          <span class="switch"></span>`;
        row.addEventListener('click', () => toggleNavItem(item.id));
        navSettings.appendChild(row);
      });
    });
  }

  function toggleNavItem(id) {
    const selected = state.navSelected.includes(id);
    if (selected) {
      if (state.navSelected.length <= 1) {
        navNote.textContent = '至少保留一个底部按钮。';
        return;
      }
      state.navSelected = state.navSelected.filter((item) => item !== id);
    } else {
      if (state.navSelected.length >= 5) {
        navNote.textContent = '最多保留 5 个，先关掉一个再选。';
        return;
      }
      state.navSelected.push(id);
    }
    navNote.textContent = '';
    save();
    renderNavSettings();
    if (!state.navAllVisible) renderSidebar();
  }

  /* ---------- playlist (floating dock + page) ---------- */
  function playlistItemMarkup(item, index, current, removable) {
    return `
      <span class="pl-index">${String(index + 1).padStart(2, '0')}</span>
      <span class="pl-thumb"><span class="ph-label">封面</span></span>
      <span class="pl-copy">
        <span class="pl-title">${escapeHTML(item.title)}${current ? '<span class="pl-badge">当前</span>' : ''}</span>
        <span class="pl-meta">${escapeHTML(item.meta)}</span>
      </span>
      ${removable ? '<button class="pl-remove" type="button" title="移出播放列表">×</button>' : ''}`;
  }

  function updatePlaylistCounts() {
    updatePlaylistDock();
  }

  function updatePlaylistDock() {
    const count = state.playlist.length;
    const item = state.playlist[state.currentIndex];
    const feedPage = ['home', 'search', 'module', 'dynamic'].includes(state.page);
    const feedVisible = state.loggedIn && count > 0 && feedPage && !state.playerOpen;
    const show = feedVisible && !app.classList.contains('sidebar-open');
    playlistDock.classList.toggle('show', show);
    playlistDock.setAttribute('aria-hidden', show ? 'false' : 'true');
    playlistDock.setAttribute('aria-label', `播放列表，${count} 项`);
    playlistDock.inert = !show;
    app.classList.toggle('has-playlist', feedVisible);
    if (!item) {
      pdTitle.textContent = '播放列表';
      pdMeta.textContent = `${count} 项`;
      pdProgress.style.width = '0%';
      return;
    }
    pdTitle.textContent = item.title;
    pdMeta.textContent = `播放列表 · ${count} 项 · ${state.playing ? '正在播放' : state.progress > 0 ? '已暂停' : '待播放'}`;
    pdProgress.style.width = `${state.progress}%`;
  }

  function pulsePlaylistDock() {
    updatePlaylistDock();
    if (!playlistDock.classList.contains('show')) return;
    playlistDock.classList.remove('receiving');
    void playlistDock.offsetWidth;
    playlistDock.classList.add('receiving');
    setTimeout(() => playlistDock.classList.remove('receiving'), 500);
  }

  function absorbPlaylistDock() {
    if (!playlistDock.classList.contains('show')) return;
    playlistDock.classList.remove('absorbing');
    void playlistDock.offsetWidth;
    playlistDock.classList.add('absorbing');
    clearTimeout(dockAbsorbTimer);
    dockAbsorbTimer = setTimeout(() => playlistDock.classList.remove('absorbing'), 560);
  }

  function flyRowToPlaylist(row) {
    const thumb = row ? row.querySelector('.row-thumb') : null;
    const dockVisible = playlistDock.classList.contains('show');
    if (!thumb || !dockVisible || document.body.classList.contains('reduce-motion')
      || typeof thumb.animate !== 'function') {
      absorbPlaylistDock();
      return;
    }
    const start = thumb.getBoundingClientRect();
    const end = pdThumb.getBoundingClientRect();
    if (!start.width || !end.width) {
      absorbPlaylistDock();
      return;
    }
    const flyer = thumb.cloneNode(true);
    flyer.querySelectorAll('.ph-label, .dur-ph').forEach((node) => node.remove());
    flyer.classList.add('playlist-fly');
    row.classList.add('row-flying');
    setTimeout(() => row.classList.remove('row-flying'), 620);
    flyer.style.left = `${start.left}px`;
    flyer.style.top = `${start.top}px`;
    flyer.style.width = `${start.width}px`;
    flyer.style.height = `${start.height}px`;
    document.body.appendChild(flyer);

    const dx = end.left + end.width / 2 - (start.left + start.width / 2);
    const dy = end.top + end.height / 2 - (start.top + start.height / 2);
    const scale = Math.max(0.18, end.width / start.width);
    const flight = flyer.animate([
      {
        transform: 'translate3d(0,0,0) scale(1)',
        opacity: 1,
        borderRadius: '14px',
        boxShadow: '0 14px 34px rgba(20,20,30,.22)',
      },
      {
        transform: `translate3d(${dx * 0.52}px, ${dy * 0.52 - 46}px,0) scale(${scale + 0.3})`,
        opacity: 0.94,
        offset: 0.55,
        borderRadius: '13px',
        boxShadow: '0 22px 48px rgba(47,124,246,.34)',
      },
      {
        transform: `translate3d(${dx}px, ${dy}px,0) scale(${scale})`,
        opacity: 0,
        borderRadius: '11px',
        boxShadow: '0 8px 20px rgba(47,124,246,.24)',
      },
    ], {
      duration: 560,
      easing: 'cubic-bezier(.22,1,.36,1)',
    });
    flight.finished.then(() => flyer.remove()).catch(() => flyer.remove());
    setTimeout(absorbPlaylistDock, 430);
  }

  function setCurrent(index) {
    if (index < 0 || index >= state.playlist.length) return;
    state.currentIndex = index;
    updatePlayerLabels();
    updatePlaylistCounts();
    save();
  }

  function removeFromPlaylist(index) {
    state.playlist.splice(index, 1);
    if (!state.playlist.length) state.currentIndex = 0;
    else if (state.currentIndex > index) state.currentIndex -= 1;
    else if (state.currentIndex >= state.playlist.length) state.currentIndex = state.playlist.length - 1;
    if (!state.playlist.length && (state.playerOpen || state.miniVisible)) stopPlayback();
    updatePlayerLabels();
    updatePlaylistCounts();
    save();
    refreshPlaylistPage();
  }

  function addToPlaylist(title, meta, key) {
    const existing = key ? state.playlist.findIndex((item) => item.key === key) : -1;
    if (existing >= 0) {
      setCurrent(existing);
      return { added: false, count: state.playlist.length };
    }
    const index = state.playlist.length + 1;
    state.playlist.push({
      id: `q${Date.now()}`,
      key: key || '',
      title: title || `视频占位 ${String(index).padStart(2, '0')}`,
      meta: meta || `UP 占位 ${String(index).padStart(2, '0')} · 00:00`,
    });
    if (state.playlist.length === 1) state.currentIndex = 0;
    updatePlayerLabels();
    updatePlaylistCounts();
    save();
    refreshPlaylistPage();
    return { added: true, count: state.playlist.length };
  }

  function clearPlaylist() {
    state.playlist = [];
    state.currentIndex = 0;
    clearArmed = false;
    clearTimeout(clearTimer);
    if (state.playerOpen || state.miniVisible) stopPlayback();
    updatePlayerLabels();
    updatePlaylistCounts();
    save();
    refreshPlaylistPage();
  }

  function refreshPlaylistPage() {
    if (state.page === 'playlist') renderPlaylistPage();
    updatePlaylistDock();
  }

  function renderPlaylistPage() {
    const count = state.playlist.length;
    clearArmed = false;
    clearTimeout(clearTimer);
    playlistPageCount.textContent = `${count} 项`;
    playlistPageList.innerHTML = '';
    if (!count) {
      const empty = document.createElement('div');
      empty.className = 'empty-state';
      empty.innerHTML = `
        <span class="empty-ico">☰</span>
        <b>播放列表是空的</b>
        <p>在任意视频行上向左滑，视频会进入播放列表。</p>
        <button class="pill-btn" type="button" id="playlistEmptyHome">去首页看看</button>`;
      playlistPageList.appendChild(empty);
      const goHome = $('#playlistEmptyHome', empty);
      goHome.addEventListener('click', () => showPage('home'));
      return;
    }

    state.playlist.forEach((item, index) => {
      const row = document.createElement('div');
      row.className = `playlist-page-item${index === state.currentIndex ? ' on' : ''}`;
      row.setAttribute('role', 'button');
      row.tabIndex = 0;
      row.innerHTML = playlistItemMarkup(item, index, index === state.currentIndex, true);
      const openItem = () => {
        if (index !== state.currentIndex) state.progress = 0;
        state.currentIndex = index;
        state.playing = true;
        save();
        openPlayer({ resume: true });
      };
      row.addEventListener('click', (event) => {
        if (event.target.closest('.pl-remove')) return;
        openItem();
      });
      row.addEventListener('keydown', (event) => {
        if (event.key !== 'Enter' && event.key !== ' ') return;
        event.preventDefault();
        openItem();
      });
      const remove = $('.pl-remove', row);
      remove.addEventListener('click', (event) => {
        event.stopPropagation();
        removeFromPlaylist(index);
      });
      playlistPageList.appendChild(row);
    });

    const clear = document.createElement('button');
    clear.type = 'button';
    clear.className = 'opt playlist-clear';
    clear.innerHTML = '<span>清空播放列表</span><span class="meta">停止播放</span>';
    clear.addEventListener('click', () => {
      if (!clearArmed) {
        clearArmed = true;
        clear.textContent = '确认清空';
        clear.classList.add('on');
        clearTimeout(clearTimer);
        clearTimer = setTimeout(() => {
          clearArmed = false;
          clear.textContent = '清空播放列表';
          clear.classList.remove('on');
        }, 5000);
        return;
      }
      clearPlaylist();
    });
    playlistPageList.appendChild(clear);
  }

  function openPlaylistPage() {
    if (!state.loggedIn) {
      showPage('login');
      return;
    }
    if (state.page !== 'playlist') {
      state.playlistReturn = state.page;
      state.playlistReturnNav = state.navActive;
    }
    if (state.playerOpen) minimizePlayer();
    renderPlaylistPage();
    showPage('playlist');
  }

  function closePlaylistPage() {
    const target = state.playlistReturn && state.playlistReturn !== 'playlist' ? state.playlistReturn : 'home';
    showPage(target, state.playlistReturnNav || undefined);
  }

  function feedRowKey(row) {
    const feed = row.closest('.feed');
    const rows = feed ? $$('.video-row', feed) : [row];
    const index = Math.max(0, rows.indexOf(row)) + 1;
    const scope = state.page === 'module' ? `module:${state.moduleName}` : state.page;
    return `row:${scope}:${index}`;
  }

  function feedRowTitle(row) {
    const feed = row.closest('.feed');
    const rows = feed ? $$('.video-row', feed) : [row];
    const index = Math.max(0, rows.indexOf(row)) + 1;
    const label = state.page === 'search'
      ? (searchResultsLabel.textContent || '搜索')
      : state.page === 'module'
        ? state.moduleName
        : '推荐';
    return `${label}视频占位 ${String(index).padStart(2, '0')}`;
  }

  function addFeedRowToPlaylist(row) {
    if (!row || !state.loggedIn) return;
    addToPlaylist(feedRowTitle(row), 'UP 占位 · 左滑加入', feedRowKey(row));
    row.classList.remove('row-queued');
    void row.offsetWidth;
    row.classList.add('row-queued');
    setTimeout(() => row.classList.remove('row-queued'), 520);
    flyRowToPlaylist(row);
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
    pcLoop.textContent = state.settings.loop;
    pcVolume.value = String(state.volume);
    pcMute.textContent = state.volume === 0 ? '静' : '音';
    pcMute.classList.toggle('on', state.volume === 0);
    setProgress(state.progress);
    updatePlaylistDock();
  }

  function updateMiniPlayer() {
    // Playback continues without a persistent mini card; the playlist dock and page own playback state.
  }

  function showMiniPlayer() {
    if (!state.playlist.length) return;
    state.miniVisible = true;
    updateMiniPlayer();
  }

  function hideMiniPlayer() {
    state.miniVisible = false;
    updateMiniPlayer();
  }

  function setProgress(percent) {
    state.progress = Math.min(100, Math.max(0, percent));
    progressPlayed.style.width = `${state.progress}%`;
    progressThumb.style.left = `${state.progress}%`;
    pdProgress.style.width = `${state.progress}%`;
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

  function openPlayer(options = {}) {
    if (!state.loggedIn) {
      showPage('login');
      return;
    }
    const resume = options.resume === true;
    const autoplay = options.autoplay === true;
    if (!state.playlist.length) addToPlaylist();
    if (!resume) {
      state.playing = autoplay;
      state.progress = 0;
    }
    state.playerOpen = true;
    state.locked = false;
    hideMiniPlayer();
    clearTimeout(hideTimer);
    pcPlay.textContent = state.playing ? 'Ⅱ' : '▶';
    updatePlayerLabels();
    player.style.animation = '';
    player.style.transition = '';
    player.style.transform = '';
    player.style.opacity = '';
    player.style.pointerEvents = '';
    player.classList.remove('dragging', 'collapsing');
    player.classList.add('open');
    player.setAttribute('aria-hidden', 'false');
    player.inert = false;
    player.classList.remove('ui-hidden');
    lockBadge.classList.remove('show');
    updatePlaylistDock();
    closeSheet();
    resetComments();
    applyBrightness(state.brightness);
    applyVolume(state.volume);
    hideLevelHuds(0);
    hideRateHud(0);
    rotateHud.classList.remove('show');
    showControls();
    lockPlayerOrientation();
  }

  function minimizePlayer() {
    if (!state.playerOpen) return;
    state.playerOpen = false;
    state.locked = false;
    clearTimeout(hideTimer);
    player.classList.remove('dragging');
    player.style.animation = 'none';
    player.style.transition = 'transform .3s cubic-bezier(.4,0,.2,1), opacity .28s ease';
    player.style.transform = 'translateY(105%) scale(.96)';
    player.style.opacity = '0';
    player.style.pointerEvents = 'none';
    playerControls.classList.remove('hidden');
    lockBadge.classList.remove('show');
    resetComments();
    hideLevelHuds(0);
    hideRateHud(0);
    rotateHud.classList.remove('show');
    closeSheet();
    if (player.contains(document.activeElement)) document.activeElement.blur();
    showMiniPlayer();
    updatePlaylistDock();
    setTimeout(() => {
      if (!state.playerOpen) pulsePlaylistDock();
    }, 140);
    if (document.fullscreenElement && document.exitFullscreen) {
      document.exitFullscreen().catch(() => {});
    }
    releasePlayerOrientation();
    pcFullscreen.classList.remove('on');
    pcFullscreen.title = '全屏';
    setTimeout(() => {
      if (state.playerOpen) return;
      player.classList.remove('open', 'ui-hidden', 'collapsing');
      player.setAttribute('aria-hidden', 'true');
      player.inert = true;
      player.style.animation = '';
      player.style.transition = '';
      player.style.transform = '';
      player.style.opacity = '';
      player.style.pointerEvents = '';
    }, 300);
  }

  function stopPlayback() {
    state.playerOpen = false;
    state.miniVisible = false;
    state.playing = false;
    state.progress = 0;
    state.locked = false;
    clearTimeout(hideTimer);
    hideMiniPlayer();
    if (player.contains(document.activeElement)) document.activeElement.blur();
    player.classList.remove('open', 'dragging', 'collapsing', 'ui-hidden');
    player.setAttribute('aria-hidden', 'true');
    player.inert = true;
    player.style.animation = '';
    player.style.transition = '';
    player.style.transform = '';
    player.style.opacity = '';
    player.style.pointerEvents = '';
    playerControls.classList.remove('hidden');
    lockBadge.classList.remove('show');
    updatePlaylistDock();
    resetComments();
    hideLevelHuds(0);
    hideRateHud(0);
    rotateHud.classList.remove('show');
    pcPlay.textContent = '▶';
    closeSheet();
    if (document.fullscreenElement && document.exitFullscreen) {
      document.exitFullscreen().catch(() => {});
    }
    releasePlayerOrientation();
    pcFullscreen.classList.remove('on');
    pcFullscreen.title = '全屏';
    updatePlayerLabels();
  }

  function lockPlayer() {
    state.locked = true;
    clearTimeout(hideTimer);
    player.classList.add('ui-hidden');
    playerControls.classList.add('hidden');
    lockBadge.classList.add('show');
    resetComments();
    hideLevelHuds(0);
    hideRateHud(0);
    rotateHud.classList.remove('show');
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
    updateMiniPlayer();
    if (state.playerOpen) showControls();
  }

  function stepTrack(delta) {
    if (!state.playlist.length) return;
    state.currentIndex = (state.currentIndex + delta + state.playlist.length) % state.playlist.length;
    state.progress = 0;
    state.playing = true;
    updatePlayerLabels();
    save();
    showControls();
  }

  function cycleLoop() {
    const list = ['循环', '继续', '下一分P', '暂停'];
    state.settings.loop = list[(list.indexOf(state.settings.loop) + 1) % list.length];
    updatePlayerLabels();
    save();
    showControls();
  }

  function sendDanmaku() {
    const text = pcDanmakuInput.value.trim();
    if (!text) return;
    pcDanmakuInput.value = '';
    pcDanmakuSend.textContent = '已发送';
    pcDanmakuSend.classList.add('done');
    setTimeout(() => {
      pcDanmakuSend.textContent = '发送';
      pcDanmakuSend.classList.remove('done');
    }, 1000);
  }

  function openPlayerInfoSheet() {
    openSheet('信息', '占位内容 · 不请求真实接口', (body) => {
      [['标题', '当前播放占位'], ['UP 主', 'UP 占位'], ['播放 / 弹幕', '0 / 0'], ['BV / av', 'BV 占位'], ['简介', '简介占位']].forEach(([label, value]) => {
        const row = document.createElement('div');
        row.className = 'sheet-row';
        row.innerHTML = `<span class="sr-label">${label}</span><span class="sr-value">${value}</span>`;
        body.appendChild(row);
      });
    });
  }

  function openPlayerPerfSheet() {
    openSheet('性能', '占位指标 · 不请求真实接口', (body) => {
      [['解码', '硬解占位'], ['渲染', '120 Hz 占位'], ['缓存', '0.0 s'], ['总码率', '0 kbps'], ['AV gap', '0 ms'], ['丢帧', '0']].forEach(([label, value]) => {
        const row = document.createElement('div');
        row.className = 'sheet-row';
        row.innerHTML = `<span class="sr-label">${label}</span><span class="sr-value">${value}</span>`;
        body.appendChild(row);
      });
    });
  }

  function openPlayerSideSheet() {
    openSheet('播放器面板', '信息 / 选集 / 评论 / 性能 / 设置', (body) => {
      actionRow(body, '信息', '标题 / UP / 数据', () => {
        closeSheet();
        openPlayerInfoSheet();
      });
      actionRow(body, '选集', '播放列表 / 分P', () => {
        closeSheet();
        openPlaylistPage();
      });
      actionRow(body, '评论', '全屏评论', () => {
        closeSheet();
        openComments();
      });
      actionRow(body, '性能', 'fps / 码率 / 缓存', () => {
        closeSheet();
        openPlayerPerfSheet();
      });
      actionRow(body, '设置', '播放 / 弹幕 / 截图', () => {
        closeSheet();
        openPlayerMoreSheet();
      });
    });
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
      pcFullscreen.classList.remove('on');
      pcFullscreen.title = '全屏';
      return;
    }
    if (document.documentElement.requestFullscreen) {
      document.documentElement.requestFullscreen().then(() => {
        pcFullscreen.classList.add('on');
        pcFullscreen.title = '退出全屏';
      }).catch(() => {});
    }
  }

  /* ---------- brightness / volume ---------- */
  function clampPercent(value) {
    return Math.max(0, Math.min(100, Math.round(value)));
  }

  function applyBrightness(value, persist) {
    state.brightness = clampPercent(value);
    brightnessValue.textContent = `${state.brightness}%`;
    brightnessFill.style.height = `${state.brightness}%`;
    playerVideo.style.setProperty('--dim', String((100 - state.brightness) / 100 * 0.82));
    if (persist) save();
  }

  function applyVolume(value, persist) {
    state.volume = clampPercent(value);
    if (state.volume > 0) lastVolume = state.volume;
    volumeValue.textContent = `${state.volume}%`;
    volumeFill.style.height = `${state.volume}%`;
    pcVolume.value = String(state.volume);
    pcMute.textContent = state.volume === 0 ? '静' : '音';
    pcMute.classList.toggle('on', state.volume === 0);
    if (persist) save();
  }

  function showLevelHud(hud) {
    clearTimeout(levelHudTimer);
    levelHudTimer = null;
    brightnessHud.classList.toggle('show', hud === brightnessHud);
    volumeHud.classList.toggle('show', hud === volumeHud);
    brightnessHud.setAttribute('aria-hidden', hud === brightnessHud ? 'false' : 'true');
    volumeHud.setAttribute('aria-hidden', hud === volumeHud ? 'false' : 'true');
  }

  function hideLevelHuds(delay = 0) {
    clearTimeout(levelHudTimer);
    levelHudTimer = setTimeout(() => {
      levelHudTimer = null;
      brightnessHud.classList.remove('show');
      volumeHud.classList.remove('show');
      brightnessHud.setAttribute('aria-hidden', 'true');
      volumeHud.setAttribute('aria-hidden', 'true');
    }, delay);
  }

  function showRateHud(direction) {
    const restore = state.settings.speed || '1.0×';
    clearTimeout(rateHudTimer);
    rateHudTimer = null;
    rateValue.textContent = direction === 'left' ? '0.5×' : '2.0×';
    rateLabel.textContent = `${direction === 'left' ? '慢放' : '快放'}中 · 松开恢复 ${restore}`;
    rateHud.classList.add('show');
  }

  function hideRateHud(delay = 0) {
    clearTimeout(rateHudTimer);
    rateHudTimer = setTimeout(() => {
      rateHudTimer = null;
      rateHud.classList.remove('show');
    }, delay);
  }

  function rotatePlayer(direction) {
    if (!state.playerOpen || state.locked) return;
    state.rotation = direction;
    rotateArrow.textContent = direction === 'right' ? '↻' : '↺';
    rotateLabel.textContent = direction === 'right' ? '横屏 · 右' : '横屏 · 左';
    rotateHud.classList.remove('turn-left', 'turn-right', 'show');
    void rotateHud.offsetWidth;
    rotateHud.classList.add(direction === 'right' ? 'turn-right' : 'turn-left', 'show');
    clearTimeout(rotateHudTimer);
    rotateHudTimer = setTimeout(() => rotateHud.classList.remove('show'), 1200);
    lockPlayerOrientation();
  }

  function lockPlayerOrientation() {
    if (!screen.orientation || !screen.orientation.lock) return;
    const target = state.rotation === 'left' ? 'landscape-primary' : 'landscape-secondary';
    screen.orientation.lock(target).catch(() => {
      screen.orientation.lock('landscape').catch(() => {});
    });
  }

  function releasePlayerOrientation() {
    if (screen.orientation && screen.orientation.unlock) {
      try { screen.orientation.unlock(); } catch (_) {}
    }
  }

  /* ---------- main page landscape ---------- */
  function syncLandscape() {
    const auto = window.innerWidth > window.innerHeight && window.innerWidth <= 960;
    const landscape = state.landscapeHome || auto;
    app.classList.toggle('landscape', landscape);
    document.body.classList.toggle('landscape', landscape);
    if (homeLandscapeBtn) {
      homeLandscapeBtn.classList.toggle('on', state.landscapeHome);
      homeLandscapeBtn.setAttribute('aria-pressed', state.landscapeHome ? 'true' : 'false');
      homeLandscapeBtn.textContent = state.landscapeHome ? '横屏主页 · 开' : '横屏主页';
    }
  }

  /* ---------- full-screen comments ---------- */
  function openComments(fromPeek) {
    if (!state.playerOpen) return;
    clearTimeout(commentsCloseTimer);
    commentsCloseTimer = null;
    commentsPanel.inert = false;
    commentsPanel.classList.remove('closing', 'peeking', 'dragging');
    commentsPanel.setAttribute('aria-hidden', 'false');
    if (fromPeek) {
      void commentsPanel.offsetWidth;
      commentsPanel.classList.add('open');
      requestAnimationFrame(() => { commentsPanel.style.transform = ''; });
    } else {
      commentsPanel.style.transform = '';
      commentsPanel.classList.add('open');
    }
    player.classList.add('comments-open');
    swipeHint.classList.remove('show');
    commentsBody.scrollTop = 0;
    clearTimeout(hideTimer);
    playerControls.classList.add('hidden');
    player.classList.add('ui-hidden');
  }

  function resetComments() {
    clearTimeout(commentsCloseTimer);
    commentsCloseTimer = null;
    commentsPanel.classList.remove('open', 'peeking', 'closing', 'dragging');
    commentsPanel.style.transform = '';
    commentsPanel.setAttribute('aria-hidden', 'true');
    commentsPanel.inert = true;
    player.classList.remove('comments-open');
    swipeHint.classList.remove('show');
  }

  function closeComments(options = {}) {
    const wasOpen = commentsPanel.classList.contains('open') || commentsPanel.classList.contains('peeking');
    if (!wasOpen) return;
    commentsPanel.inert = true;
    commentsPanel.classList.remove('peeking', 'dragging');
    commentsPanel.classList.add('closing');
    commentsPanel.classList.remove('open');
    commentsPanel.style.transform = 'translateX(102%)';
    commentsPanel.setAttribute('aria-hidden', 'true');
    player.classList.remove('comments-open');
    if (commentsPanel.contains(document.activeElement)) document.activeElement.blur();
    clearTimeout(commentsCloseTimer);
    commentsCloseTimer = setTimeout(() => {
      commentsCloseTimer = null;
      commentsPanel.classList.remove('closing');
      commentsPanel.style.transform = '';
    }, 340);
    if (!options.silent && state.playerOpen) {
      setTimeout(() => {
        if (state.playerOpen && !commentsPanel.classList.contains('open')) showControls();
      }, 40);
    }
  }

  function cancelCommentsPeek() {
    if (!commentsPanel.classList.contains('peeking')) return;
    commentsPanel.classList.remove('peeking', 'dragging');
    commentsPanel.classList.add('closing');
    commentsPanel.style.transform = '';
    commentsPanel.setAttribute('aria-hidden', 'true');
    commentsPanel.inert = true;
    player.classList.remove('comments-open');
    clearTimeout(commentsCloseTimer);
    commentsCloseTimer = setTimeout(() => {
      commentsCloseTimer = null;
      commentsPanel.classList.remove('closing');
    }, 340);
  }

  /* ---------- player gesture state machine ---------- */
  function stageZone(clientX) {
    const rect = playerStage.getBoundingClientRect();
    const ratio = (clientX - rect.left) / Math.max(1, rect.width);
    if (ratio < 1 / 3) return 'left';
    if (ratio > 2 / 3) return 'right';
    return 'middle';
  }

  function startStageGesture(event) {
    if (!state.playerOpen || state.locked) return;
    if (event.button !== undefined && event.button !== 0) return;
    if (event.target.closest('.player-controls, .player-top, .lock-badge, button, input, textarea')) return;
    if (commentsPanel.classList.contains('open')) return;
    clearTimeout(hideTimer);
    clearTimeout(stageTapTimer);
    stageTapTimer = null;
    const zone = stageZone(event.clientX);
    stageGesture = {
      pointerId: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      zone,
      mode: null,
      moved: false,
      longPressFired: false,
      longPressTimer: null,
      collapseY: 0,
      horizontal: 0,
    };
    if (zone !== 'middle' && state.settings.longPressRate) {
      stageGesture.longPressTimer = setTimeout(() => {
        const gesture = stageGesture;
        if (!gesture || gesture.moved || gesture.mode) return;
        gesture.longPressFired = true;
        gesture.mode = 'rate';
        clearTimeout(hideTimer);
        showRateHud(gesture.zone);
        if (navigator.vibrate) navigator.vibrate(8);
      }, 360);
    }
    event.preventDefault();
  }

  function moveStageGesture(event) {
    const gesture = stageGesture;
    if (!gesture || event.pointerId !== gesture.pointerId) return;
    const dx = event.clientX - gesture.startX;
    const dy = event.clientY - gesture.startY;
    if (gesture.mode === 'rate' || gesture.longPressFired) return;

    if (!gesture.moved) {
      if (Math.hypot(dx, dy) < 8) return;
      gesture.moved = true;
      clearTimeout(gesture.longPressTimer);
      gesture.longPressTimer = null;
      player.classList.add('gesture-active');
      if (state.settings.swipeComments && Math.abs(dx) > Math.abs(dy) * 1.15) {
        gesture.mode = 'horizontal';
      } else if (gesture.zone === 'middle') {
        gesture.mode = dy > 0 ? 'collapse' : 'toolbar';
        if (dy > 0 && !state.settings.middleCollapse) return;
      } else if (state.settings.swipeLevel) {
        gesture.mode = 'level';
        gesture.startBrightness = state.brightness;
        gesture.startVolume = state.volume;
        showLevelHud(gesture.zone === 'left' ? brightnessHud : volumeHud);
      } else {
        return;
      }
    }

    if (gesture.mode === 'collapse') {
      const dragY = Math.max(0, dy);
      gesture.collapseY = dragY;
      const scale = 1 - Math.min(0.05, dragY / 3000);
      player.style.transform = `translateY(${dragY}px) scale(${scale})`;
      player.style.opacity = String(1 - Math.min(0.35, dragY / 800));
    } else if (gesture.mode === 'toolbar') {
      showControls();
      clearTimeout(hideTimer);
    } else if (gesture.mode === 'level') {
      const rect = playerStage.getBoundingClientRect();
      const delta = (-dy / Math.max(1, rect.height)) * 140;
      if (gesture.zone === 'left') applyBrightness(gesture.startBrightness + delta);
      else applyVolume(gesture.startVolume + delta);
    } else if (gesture.mode === 'horizontal') {
      gesture.horizontal = dx;
      if (dx < 0 && state.settings.swipeComments) {
        const rect = playerStage.getBoundingClientRect();
        const progress = Math.min(1, -dx / Math.max(1, rect.width * 0.62));
        commentsPanel.classList.add('peeking');
        commentsPanel.setAttribute('aria-hidden', 'false');
        commentsPanel.inert = true;
        commentsPanel.style.transform = `translateX(${(1 - progress) * 100}%)`;
        player.classList.add('comments-open');
        swipeHint.classList.toggle('show', -dx > 46);
      } else {
        swipeHint.classList.remove('show');
      }
    }
  }

  function handleStageTap(zone) {
    const now = Date.now();
    if (lastStageTap.zone === zone && now - lastStageTap.time < 300) {
      lastStageTap = { time: 0, zone: '' };
      clearTimeout(stageTapTimer);
      stageTapTimer = null;
      if (zone === 'middle') {
        togglePlay();
      } else if (state.settings.doubleRotate) {
        rotatePlayer(zone);
      } else {
        toggleStageControls();
      }
      return;
    }
    lastStageTap = { time: now, zone };
    clearTimeout(stageTapTimer);
    stageTapTimer = setTimeout(() => {
      stageTapTimer = null;
      lastStageTap = { time: 0, zone: '' };
      toggleStageControls();
    }, 260);
  }

  function toggleStageControls() {
    if (!state.playerOpen || state.locked) return;
    if (playerControls.classList.contains('hidden') || player.classList.contains('ui-hidden')) {
      showControls();
    } else {
      playerControls.classList.add('hidden');
      player.classList.add('ui-hidden');
      clearTimeout(hideTimer);
    }
  }

  function endStageGesture(event) {
    const gesture = stageGesture;
    if (!gesture) return;
    if (event && event.pointerId !== undefined && event.pointerId !== gesture.pointerId) return;
    stageGesture = null;
    clearTimeout(gesture.longPressTimer);
    gesture.longPressTimer = null;
    player.classList.remove('gesture-active');
    swipeHint.classList.remove('show');
    const cancelled = event && event.type === 'pointercancel';

    if (gesture.longPressFired) {
      hideRateHud(220);
      showControls();
      return;
    }

    if (!gesture.moved) {
      if (!cancelled) handleStageTap(gesture.zone);
      return;
    }

    if (gesture.mode === 'collapse') {
      if (gesture.collapseY > 110) {
        minimizePlayer();
        return;
      }
      player.style.transition = 'transform .24s cubic-bezier(.16,1,.3,1), opacity .2s ease';
      player.style.transform = 'none';
      player.style.opacity = '1';
      setTimeout(() => {
        if (state.playerOpen) {
          player.style.transition = '';
          player.style.transform = '';
          player.style.opacity = '';
        }
      }, 260);
    } else if (gesture.mode === 'toolbar') {
      showControls();
    } else if (gesture.mode === 'level') {
      hideLevelHuds(700);
      showControls();
      save();
    } else if (gesture.mode === 'horizontal') {
      if (gesture.horizontal < -70) openComments(true);
      else cancelCommentsPeek();
    }
  }

  /* ---------- comments panel swipe ---------- */
  function startCommentsGesture(event) {
    if (!commentsPanel.classList.contains('open')) return;
    if (event.button !== undefined && event.button !== 0) return;
    if (event.target.closest('input, button, .comments-input')) return;
    commentsGesture = {
      pointerId: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      moved: false,
      dragging: false,
      dx: 0,
    };
  }

  function moveCommentsGesture(event) {
    const gesture = commentsGesture;
    if (!gesture || event.pointerId !== gesture.pointerId) return;
    const dx = event.clientX - gesture.startX;
    const dy = event.clientY - gesture.startY;
    gesture.dx = dx;
    if (!gesture.moved) {
      if (Math.hypot(dx, dy) < 10) return;
      gesture.moved = true;
      if (dx > 0 && Math.abs(dx) > Math.abs(dy) * 1.25) {
        gesture.dragging = true;
        commentsPanel.classList.add('dragging');
      }
    }
    if (!gesture.dragging) return;
    const width = commentsPanel.getBoundingClientRect().width || 1;
    const progress = Math.min(1, Math.max(0, dx / (width * 0.75)));
    commentsPanel.style.transform = `translateX(${progress * 100}%)`;
  }

  function endCommentsGesture() {
    const gesture = commentsGesture;
    if (!gesture) return;
    commentsGesture = null;
    if (!gesture.dragging) return;
    commentsPanel.classList.remove('dragging');
    if (gesture.dx > 90) closeComments();
    else commentsPanel.style.transform = '';
  }

  /* ---------- sheets ---------- */
  function openSheet(title, sub, build) {
    psheet.dataset.kind = '';
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
      actionRow(body, '加入播放列表', '当前队列 +1', () => {
        addToPlaylist();
        return '已加入';
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
      actionRow(body, '投币', state.coin ? '已投币' : '2 币', () => {
        state.coin = true;
        return '已投币';
      });
      actionRow(body, '复制链接', state.copied ? '已复制' : 'BV 占位', () => {
        state.copied = true;
        return '已复制';
      });
      actionRow(body, '缓存', state.cached ? '已加入下载' : '离线下载', () => {
        state.cached = true;
        return '已加入下载';
      });
      actionRow(body, '举报', '', () => '已提交（占位）');
      actionRow(body, '关闭播放', '停止并清空进度', () => {
        stopPlayback();
      });
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
        sub: '三区分工：中间收起/工具栏，左右亮度/音量，双击左右旋转，长按左右减速/加速',
        rows: [
          { type: 'switch', label: '中间上滑 工具栏 / 下滑 收起', key: 'middleCollapse' },
          { type: 'switch', label: '左右上下滑 亮度 / 音量', key: 'swipeLevel' },
          { type: 'switch', label: '左滑 全屏评论', key: 'swipeComments' },
          { type: 'switch', label: '双击左 / 右 旋转屏幕', key: 'doubleRotate' },
          { type: 'switch', label: '长按左 / 右 减速 / 加速', key: 'longPressRate' },
          { type: 'static', label: '进度条', value: '横向拖动 seek · 占位' },
        ],
      },
      'settings-distraction': {
        title: '防干扰',
        sub: '只保留自己需要的入口，首页会更干净',
        rows: [
          { type: 'switch', label: '隐藏直播入口', key: 'hideLive' },
          { type: 'switch', label: '隐藏番剧入口', key: 'hideBangumi' },
          { type: 'switch', label: '隐藏养鱼入口', key: 'hideFish', onChange: applyHiddenEntries },
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
          { type: 'action', label: '扫码登录', value: state.loggedIn ? '已登录' : '未登录 / 占位', run: () => { closeSheet(); showPage('login'); return '打开登录'; } },
          { type: 'action', label: '打开账户页', value: '账户 / 经验 / 权益', run: () => '账户页（占位）' },
          { type: 'action', label: '退出登录', value: '', run: () => { logout(); return '已退出'; } },
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

  /* ---------- search ---------- */
  function updateSearch() {
    const query = searchInput.value.trim();
    const hasQuery = query.length > 0;
    searchClear.hidden = !hasQuery;
    searchResultsLabel.textContent = hasQuery ? `“${query}”的视频（占位）` : '热门视频';
    searchResults.hidden = false;
    searchEmpty.hidden = true;
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

  function syncKeyboardOffset() {
    const vv = window.visualViewport;
    const focused = document.activeElement === searchInput;
    const offset = focused && vv
      ? Math.max(0, window.innerHeight - vv.height - vv.offsetTop)
      : 0;
    document.documentElement.style.setProperty('--kb', `${offset}px`);
  }

  if (window.visualViewport) {
    window.visualViewport.addEventListener('resize', syncKeyboardOffset);
    window.visualViewport.addEventListener('scroll', syncKeyboardOffset);
  }
  window.addEventListener('resize', syncKeyboardOffset);
  syncKeyboardOffset();

  /* ---------- event wiring ---------- */
  document.addEventListener('click', (event) => {
    if (Date.now() < suppressFeedClickUntil) return;
    const playlistTarget = event.target.closest('[data-queue]');
    if (playlistTarget) {
      openPlaylistPage();
      closeDrawer();
      return;
    }

    const goto = event.target.closest('[data-goto]');
    if (goto) {
      const target = goto.dataset.goto;
      const navAlias = { settings: 'my', modules: 'my', nav: 'my' }[target];
      showPage(target, navAlias);
      closeDrawer();
      return;
    }

    const moduleTarget = event.target.closest('[data-module]');
    if (moduleTarget) {
      openModulePage(moduleTarget.dataset.module);
      return;
    }

    const play = event.target.closest('[data-open-player]');
    if (play) {
      openPlayer({ autoplay: true });
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
  });

  $('#searchCancel').addEventListener('click', closeSearch);
  searchClear.addEventListener('click', () => {
    searchInput.value = '';
    updateSearch();
    searchInput.focus();
  });
  searchInput.addEventListener('input', updateSearch);
  searchInput.addEventListener('focus', syncKeyboardOffset);
  searchInput.addEventListener('blur', syncKeyboardOffset);
  searchInput.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
      event.preventDefault();
      searchInput.blur();
    }
  });

  navAllToggle.addEventListener('click', () => {
    state.navAllVisible = !state.navAllVisible;
    navNote.textContent = '';
    save();
    renderSidebar();
    renderNavSettings();
  });

  $('#accountCard').addEventListener('click', () => showPage('login'));
  myModuleRow.addEventListener('click', openModuleSheet);
  $('#loginRefresh').addEventListener('click', () => {
    loginStatus.textContent = '二维码已刷新 · 占位';
  });
  $('#loginQr').addEventListener('click', loginSucceeded);
  $('#loginQr').addEventListener('keydown', (event) => {
    if (event.key !== 'Enter' && event.key !== ' ') return;
    event.preventDefault();
    loginSucceeded();
  });
  $('#loginCta').addEventListener('click', loginSucceeded);

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
  });

  /* player */
  $('#playerBack').addEventListener('click', minimizePlayer);
  $('#playerQueue').addEventListener('click', openPlaylistPage);
  $('#playerMore').addEventListener('click', openPlayerMoreSheet);
  pcPlay.addEventListener('click', togglePlay);
  pcPrev.addEventListener('click', () => stepTrack(-1));
  pcNext.addEventListener('click', () => stepTrack(1));
  pcMute.addEventListener('click', () => {
    if (state.volume > 0) applyVolume(0, true);
    else applyVolume(lastVolume || 80, true);
  });
  pcVolume.addEventListener('input', () => applyVolume(Number(pcVolume.value), false));
  pcVolume.addEventListener('change', () => applyVolume(Number(pcVolume.value), true));
  pcDanmaku.addEventListener('click', () => {
    state.settings.danmaku = !state.settings.danmaku;
    updatePlayerLabels();
    save();
  });
  pcDanmakuSend.addEventListener('click', sendDanmaku);
  pcDanmakuInput.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
      event.preventDefault();
      sendDanmaku();
    }
  });
  pcLoop.addEventListener('click', cycleLoop);
  pcQueue.addEventListener('click', openPlaylistPage);
  pcSide.addEventListener('click', openPlayerSideSheet);
  pcSettings.addEventListener('click', openPlayerMoreSheet);
  pcShot.addEventListener('click', () => {
    state.shot = true;
    pcShot.textContent = '✓';
    pcShot.classList.add('done');
    setTimeout(() => {
      pcShot.textContent = '⤓';
      pcShot.classList.remove('done');
    }, 900);
  });
  pcFullscreen.addEventListener('click', toggleFullscreen);
  lockBadge.addEventListener('click', unlockPlayer);

  playerControls.addEventListener('pointerdown', (event) => {
    if (event.target.closest('button, input, .progress-ph')) return;
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    toolbarDrag = { id: event.pointerId, x: event.clientX, y: event.clientY };
  });
  window.addEventListener('pointerup', (event) => {
    if (!toolbarDrag || event.pointerId !== toolbarDrag.id) return;
    const dx = event.clientX - toolbarDrag.x;
    const dy = event.clientY - toolbarDrag.y;
    toolbarDrag = null;
    if (dy > 24 && Math.abs(dy) > Math.abs(dx)) {
      playerControls.classList.add('hidden');
      player.classList.add('ui-hidden');
      clearTimeout(hideTimer);
    }
  });
  window.addEventListener('pointercancel', () => { toolbarDrag = null; });

  sidebarSearch.addEventListener('click', () => {
    closeSidebar();
    openSearch();
  });
  sidebarBackdrop.addEventListener('click', closeSidebar);
  playlistBack.addEventListener('click', closePlaylistPage);

  playlistDock.addEventListener('pointerdown', (event) => {
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    dockDrag = { id: event.pointerId, x: event.clientX, y: event.clientY, dy: 0, moved: false };
    playlistDock.classList.add('dragging');
  });
  window.addEventListener('pointermove', (event) => {
    if (!dockDrag || event.pointerId !== dockDrag.id) return;
    const dy = event.clientY - dockDrag.y;
    dockDrag.dy = dy;
    if (Math.abs(dy) > 6) dockDrag.moved = true;
    const up = Math.min(0, dy);
    if (up < 0) {
      const progress = Math.min(1, -up / 96);
      playlistDock.style.transform = `translate(-50%, ${up}px) scale(${1 - progress * 0.05})`;
      playlistDock.style.opacity = String(1 - progress * 0.3);
    }
  });
  window.addEventListener('pointerup', (event) => {
    if (!dockDrag || event.pointerId !== dockDrag.id) return;
    const gesture = dockDrag;
    dockDrag = null;
    playlistDock.classList.remove('dragging');
    if (gesture.moved && gesture.dy < -40) {
      suppressDockClickUntil = Date.now() + 500;
      playlistDock.classList.add('launching');
      playlistDock.style.transform = '';
      playlistDock.style.opacity = '';
      setTimeout(() => {
        playlistDock.classList.remove('launching');
        if (state.playlist.length) openPlayer({ resume: true });
      }, 160);
      return;
    }
    playlistDock.style.transform = '';
    playlistDock.style.opacity = '';
  });
  window.addEventListener('pointercancel', () => {
    if (!dockDrag) return;
    dockDrag = null;
    playlistDock.classList.remove('dragging');
    playlistDock.style.transform = '';
    playlistDock.style.opacity = '';
  });
  playlistDock.addEventListener('click', () => {
    if (Date.now() < suppressDockClickUntil) return;
    openPlaylistPage();
  });

  appScroll.addEventListener('pointerdown', (event) => {
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    if (event.target.closest('input, textarea')) return;
    feedSwipeStart = {
      id: event.pointerId,
      x: event.clientX,
      y: event.clientY,
      row: event.target.closest('.video-row'),
      pull: appScroll.scrollTop <= 0 && Boolean(activeFeed()) && !pullBusy,
      pulling: false,
    };
  });
  window.addEventListener('pointermove', (event) => {
    if (!feedSwipeStart || event.pointerId !== feedSwipeStart.id) return;
    if (!feedSwipeStart.pull || pullBusy) return;
    const dx = event.clientX - feedSwipeStart.x;
    const dy = event.clientY - feedSwipeStart.y;
    if (Math.abs(dx) > Math.abs(dy) * 1.15 && Math.abs(dx) > 8) {
      feedSwipeStart.pull = false;
      if (feedSwipeStart.pulling) {
        feedSwipeStart.pulling = false;
        settlePullVisual();
        pullRefresh.classList.remove('show', 'ready');
      }
      return;
    }
    if (dy > 8) {
      feedSwipeStart.pulling = true;
      if (event.cancelable) event.preventDefault();
      updatePull(dy);
    }
  });
  window.addEventListener('pointerup', (event) => {
    if (!feedSwipeStart || event.pointerId !== feedSwipeStart.id) return;
    const dx = event.clientX - feedSwipeStart.x;
    const dy = event.clientY - feedSwipeStart.y;
    const start = feedSwipeStart;
    feedSwipeStart = null;
    if (start.pulling) {
      suppressFeedClickUntil = Date.now() + 360;
      finishPull();
      return;
    }
    if (dx < -64 && Math.abs(dx) > Math.abs(dy) * 1.4 && start.row) {
      suppressFeedClickUntil = Date.now() + 360;
      addFeedRowToPlaylist(start.row);
      return;
    }
    if (dx > 64 && Math.abs(dx) > Math.abs(dy) * 1.4) {
      suppressFeedClickUntil = Date.now() + 360;
      openSidebar();
    }
  });
  window.addEventListener('pointercancel', () => {
    if (feedSwipeStart?.pulling) {
      settlePullVisual();
      pullRefresh.classList.remove('show', 'ready');
    }
    feedSwipeStart = null;
  });

  appScroll.addEventListener('touchstart', (event) => {
    if (event.touches.length !== 1 || pullBusy) return;
    const touch = event.touches[0];
    touchPull = {
      x: touch.clientX,
      y: touch.clientY,
      active: appScroll.scrollTop <= 0 && Boolean(activeFeed()),
      pulling: false,
    };
  }, { passive: true });
  appScroll.addEventListener('touchmove', (event) => {
    if (!touchPull || event.touches.length !== 1) return;
    const touch = event.touches[0];
    const dx = touch.clientX - touchPull.x;
    const dy = touch.clientY - touchPull.y;
    if (!touchPull.active || dy <= 0) return;
    if (Math.abs(dx) > Math.abs(dy) * 1.15) return;
    if (dy > 8) {
      if (event.cancelable) event.preventDefault();
      touchPull.pulling = true;
      updatePull(dy);
    }
  }, { passive: false });
  const endTouchPull = () => {
    if (!touchPull) return;
    const wasPulling = touchPull.pulling;
    touchPull = null;
    if (wasPulling) {
      suppressFeedClickUntil = Date.now() + 360;
      finishPull();
    }
  };
  appScroll.addEventListener('touchend', endTouchPull);
  appScroll.addEventListener('touchcancel', () => {
    if (touchPull?.pulling) {
      settlePullVisual();
      pullRefresh.classList.remove('show', 'ready');
    }
    touchPull = null;
  });

  appScroll.addEventListener('scroll', () => {
    if (!activeFeed() || pullBusy) return;
    const max = appScroll.scrollHeight - appScroll.clientHeight;
    if (max <= 0) return;
    const atBottom = appScroll.scrollTop >= max - 12;
    if (!atBottom) {
      bottomRefreshArmed = true;
      clearTimeout(bottomRefreshTimer);
      return;
    }
    if (!bottomRefreshArmed) return;
    bottomRefreshArmed = false;
    clearTimeout(bottomRefreshTimer);
    bottomRefreshTimer = setTimeout(() => {
      if (pullBusy || !activeFeed()) return;
      const maxNow = appScroll.scrollHeight - appScroll.clientHeight;
      if (appScroll.scrollTop < maxNow - 14) return;
      refreshActiveFeed();
    }, 160);
  });

  sidebar.addEventListener('pointerdown', (event) => {
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    sidebarSwipeStart = { id: event.pointerId, x: event.clientX, y: event.clientY };
  });
  window.addEventListener('pointerup', (event) => {
    if (!sidebarSwipeStart || event.pointerId !== sidebarSwipeStart.id) return;
    const dx = event.clientX - sidebarSwipeStart.x;
    const dy = event.clientY - sidebarSwipeStart.y;
    sidebarSwipeStart = null;
    if (dx < -56 && Math.abs(dx) > Math.abs(dy) * 1.4) {
      suppressSidebarClickUntil = Date.now() + 360;
      closeSidebar();
    }
  });
  sidebar.addEventListener('click', (event) => {
    if (Date.now() < suppressSidebarClickUntil) {
      event.preventDefault();
      event.stopPropagation();
    }
  }, true);

  playerStage.addEventListener('pointerdown', startStageGesture);
  window.addEventListener('pointermove', moveStageGesture);
  window.addEventListener('pointerup', endStageGesture);
  window.addEventListener('pointercancel', endStageGesture);

  commentsBack.addEventListener('click', () => closeComments());
  commentsTabs.addEventListener('click', (event) => {
    const button = event.target.closest('[data-comment-tab]');
    if (!button) return;
    $$('[data-comment-tab]', commentsTabs).forEach((item) => item.classList.toggle('on', item === button));
    commentsBody.style.opacity = '0.3';
    setTimeout(() => { commentsBody.style.opacity = ''; }, 160);
  });

  commentInput.addEventListener('input', () => {
    commentSend.disabled = !commentInput.value.trim();
  });
  commentInput.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
      event.preventDefault();
      commentSend.click();
    }
  });
  commentSend.addEventListener('click', () => {
    const text = commentInput.value.trim();
    if (!text) return;
    const row = document.createElement('div');
    row.className = 'comment-row';
    row.innerHTML = `
      <span class="avatar-ph sm"></span>
      <div class="comment-text">
        <b>我</b>
        <p>${escapeHTML(text)}</p>
        <small>刚刚 · 占位</small>
      </div>`;
    commentsBody.prepend(row);
    commentInput.value = '';
    commentSend.disabled = true;
    commentTotal += 1;
    commentsCount.textContent = `${commentTotal} 条`;
    commentSend.classList.add('done');
    commentSend.textContent = '已发送';
    setTimeout(() => {
      commentSend.classList.remove('done');
      commentSend.textContent = '发送';
    }, 1200);
    commentsBody.scrollTop = 0;
  });

  commentsPanel.addEventListener('pointerdown', startCommentsGesture);
  window.addEventListener('pointermove', moveCommentsGesture);
  window.addEventListener('pointerup', endCommentsGesture);
  window.addEventListener('pointercancel', endCommentsGesture);

  progressBar.addEventListener('click', (event) => {
    const rect = progressBar.getBoundingClientRect();
    const percent = (event.clientX - rect.left) / rect.width * 100;
    setProgress(percent);
    showControls();
  });

  psheetBackdrop.addEventListener('click', closeSheet);
  psheetClose.addEventListener('click', closeSheet);

  document.addEventListener('fullscreenchange', () => {
    const on = Boolean(document.fullscreenElement);
    pcFullscreen.classList.toggle('on', on);
    pcFullscreen.title = on ? '退出全屏' : '全屏';
  });

  /* keyboard */
  document.addEventListener('keydown', (event) => {
    if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k') {
      event.preventDefault();
      openSearch();
      return;
    }
    if (event.key === 'Escape') {
      if (sidebar.classList.contains('open')) { closeSidebar(); return; }
      if (commentsPanel.classList.contains('open')) { closeComments(); return; }
      if (psheet.classList.contains('open')) { closeSheet(); return; }
      if (protoDrawer.classList.contains('open')) { closeDrawer(); return; }
      if (state.playerOpen) { minimizePlayer(); return; }
      if (state.page === 'search') { closeSearch(); return; }
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
  homeLandscapeBtn.addEventListener('click', () => {
    state.landscapeHome = !state.landscapeHome;
    syncLandscape();
    save();
    closeDrawer();
  });
  window.addEventListener('resize', syncLandscape);
  window.addEventListener('orientationchange', syncLandscape);
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
  $('#bgBtn').addEventListener('click', () => {
    document.body.classList.toggle('flat-bg');
    $('#bgBtn').classList.toggle('on');
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
  app.classList.toggle('auth-gate', !state.loggedIn);
  $$('#platformSwitch button').forEach((button) => {
    button.classList.toggle('on', button.dataset.platform === state.platform);
  });
  applyHiddenEntries();
  updatePlayerLabels();
  updateSearch();
  syncLandscape();
  applyBrightness(state.brightness);
  applyVolume(state.volume);
  hideLevelHuds(0);
  showPage(state.loggedIn ? 'home' : 'login');

  /* ---------- prototype review modes (?demo= / ?selftest=1) ---------- */
  function stagePoint(zone) {
    const rect = playerStage.getBoundingClientRect();
    const ratio = zone === 'left' ? 0.16 : zone === 'right' ? 0.84 : 0.5;
    return {
      x: rect.left + rect.width * ratio,
      y: rect.top + rect.height * 0.5,
    };
  }

  function pointerEvent(type, x, y, buttons) {
    return new PointerEvent(type, {
      bubbles: true,
      cancelable: true,
      pointerId: 11,
      pointerType: 'touch',
      isPrimary: true,
      button: 0,
      buttons,
      clientX: x,
      clientY: y,
    });
  }

  function dispatchSwipe(zone, dx, dy) {
    const start = stagePoint(zone);
    playerStage.dispatchEvent(pointerEvent('pointerdown', start.x, start.y, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent(
        'pointermove',
        start.x + (dx * step) / 6,
        start.y + (dy * step) / 6,
        1,
      ));
    }
    window.dispatchEvent(pointerEvent('pointerup', start.x + dx, start.y + dy, 0));
  }

  function dispatchTap(zone) {
    const point = stagePoint(zone);
    playerStage.dispatchEvent(pointerEvent('pointerdown', point.x, point.y, 1));
    window.dispatchEvent(pointerEvent('pointerup', point.x, point.y, 0));
  }

  function pressStage(zone) {
    const point = stagePoint(zone);
    playerStage.dispatchEvent(pointerEvent('pointerdown', point.x, point.y, 1));
    return {
      release() {
        window.dispatchEvent(pointerEvent('pointerup', point.x, point.y, 0));
      },
    };
  }

  async function runGestureSelfTest() {
    const results = [];
    const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

    const gate = app.dataset.page === 'login';
    if (!state.loggedIn) {
      state.loggedIn = true;
      app.classList.remove('auth-gate');
      save();
      showPage('home');
    }
    results.push(`gate=${gate}`);

    openPlayer();
    applyBrightness(50);
    applyVolume(40);
    await sleep(120);
    dispatchSwipe('left', 0, -140);
    results.push(`brightness=${state.brightness}`);

    await sleep(120);
    dispatchSwipe('right', 0, 140);
    results.push(`volume=${state.volume}`);

    await sleep(180);
    dispatchSwipe('middle', 0, 190);
    results.push(`collapsed=${!state.playerOpen && state.miniVisible}`);

    await sleep(420);
    openPlayer({ resume: true });
    await sleep(360);
    dispatchSwipe('middle', -240, 0);
    results.push(`comments=${commentsPanel.classList.contains('open')}`);

    commentInput.value = '测试评论';
    commentInput.dispatchEvent(new Event('input', { bubbles: true }));
    const sendEnabled = !commentSend.disabled;
    commentSend.click();
    results.push(`send=${sendEnabled && commentTotal === 129 && commentsBody.firstElementChild.textContent.includes('测试评论')}`);

    closeComments();
    await sleep(380);
    dispatchTap('left');
    await sleep(80);
    dispatchTap('left');
    await sleep(80);
    results.push(`rotate=${rotateHud.classList.contains('show') && state.rotation === 'left'}`);

    const hold = pressStage('right');
    await sleep(430);
    results.push(`rate=${rateHud.classList.contains('show') && rateValue.textContent === '2.0×'}`);
    hold.release();
    await sleep(320);
    results.push(`rateEnd=${!rateHud.classList.contains('show')}`);

    const grab = pcGrab.getBoundingClientRect();
    const grabX = grab.left + grab.width / 2;
    const grabY = grab.top + grab.height / 2;
    pcGrab.dispatchEvent(pointerEvent('pointerdown', grabX, grabY, 1));
    window.dispatchEvent(pointerEvent('pointermove', grabX, grabY + 40, 1));
    window.dispatchEvent(pointerEvent('pointerup', grabX, grabY + 40, 0));
    await sleep(80);
    results.push(`toolbarHide=${playerControls.classList.contains('hidden')}`);
    showControls();

    minimizePlayer();
    await sleep(420);
    results.push(`dock=${playlistDock.classList.contains('show')}`);
    const rect = appScroll.getBoundingClientRect();
    const startX = rect.left + rect.width * 0.5;
    const startY = rect.top + rect.height * 0.5;
    appScroll.dispatchEvent(pointerEvent('pointerdown', startX, startY, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', startX + (120 * step) / 6, startY, 1));
    }
    window.dispatchEvent(pointerEvent('pointerup', startX + 120, startY, 0));
    await sleep(80);
    results.push(`sidebar=${sidebar.classList.contains('open')}`);
    closeSidebar();

    const row = $('#homeFeed .video-row');
    const countBefore = state.playlist.length;
    const rowRect = row.getBoundingClientRect();
    const rowY = rowRect.top + rowRect.height / 2;
    const rowX = rowRect.left + rowRect.width / 2;
    row.dispatchEvent(pointerEvent('pointerdown', rowX, rowY, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', rowX - (120 * step) / 6, rowY, 1));
    }
    window.dispatchEvent(pointerEvent('pointerup', rowX - 120, rowY, 0));
    await sleep(120);
    results.push(`rowQueue=${state.playlist.some((item) => item.key === feedRowKey(row))}`);
    if (state.playlist.length > countBefore) {
      state.playlist.pop();
      state.currentIndex = Math.min(state.currentIndex, Math.max(0, state.playlist.length - 1));
      updatePlayerLabels();
      updatePlaylistCounts();
      save();
    }

    const bottomBefore = feedRefreshCounts.home;
    appScroll.scrollTop = appScroll.scrollHeight;
    appScroll.dispatchEvent(new Event('scroll'));
    await sleep(700);
    results.push(`bottomRefresh=${feedRefreshCounts.home > bottomBefore}`);
    await sleep(900);

    appScroll.scrollTop = 0;
    const pullBefore = feedRefreshCounts.home;
    const feedRect = homeFeed.getBoundingClientRect();
    const pullX = feedRect.left + feedRect.width / 2;
    const pullY = Math.max(feedRect.top + 40, 80);
    homeFeed.dispatchEvent(pointerEvent('pointerdown', pullX, pullY, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', pullX, pullY + step * 24, 1));
    }
    window.dispatchEvent(pointerEvent('pointerup', pullX, pullY + 144, 0));
    await sleep(200);
    results.push(`pullRefresh=${feedRefreshCounts.home > pullBefore}`);

    document.title = `SELFTEST ${results.join(' ')}`;
  }

  const reviewParams = new URLSearchParams(window.location.search);
  const demo = reviewParams.get('demo');
  if (reviewParams.has('nomotion')) document.body.classList.add('reduce-motion');
  if (demo === 'login') {
    state.loggedIn = false;
    app.classList.add('auth-gate');
    save();
    showPage('login');
  } else if (demo && !state.loggedIn) {
    state.loggedIn = true;
    app.classList.remove('auth-gate');
    save();
    showPage('home');
  }
  if (demo === 'landscape') {
    state.landscapeHome = true;
    syncLandscape();
  } else if (demo === 'comments') {
    openPlayer();
    setTimeout(() => openComments(), 220);
  } else if (demo === 'sidebar') {
    setTimeout(openSidebar, 300);
  } else if (demo === 'refresh') {
    setTimeout(() => updatePull(150), 400);
  } else if (demo === 'queue') {
    setTimeout(() => {
      const row = $('#homeFeed .video-row');
      if (row) addFeedRowToPlaylist(row);
    }, 700);
  } else if (demo === 'brightness' || demo === 'volume' || demo === 'rate' || demo === 'rotate') {
    openPlayer();
    setTimeout(() => {
      if (demo === 'brightness') {
        applyBrightness(42);
        showLevelHud(brightnessHud);
        hideLevelHuds(9000);
      } else if (demo === 'volume') {
        applyVolume(64);
        showLevelHud(volumeHud);
        hideLevelHuds(9000);
      } else if (demo === 'rate') {
        applyBrightness(74);
        showRateHud('right');
        hideRateHud(9000);
      } else {
        rotatePlayer('left');
        clearTimeout(rotateHudTimer);
        rotateHudTimer = setTimeout(() => rotateHud.classList.remove('show'), 9000);
      }
    }, 220);
  }
  if (reviewParams.has('selftest')) setTimeout(runGestureSelfTest, 400);
})();

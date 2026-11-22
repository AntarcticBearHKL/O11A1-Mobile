(() => {
  const $ = (selector, root = document) => root.querySelector(selector);
  const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));

  const app = $('#app');
  const appMain = $('.app-main');
  const appScroll = $('#appScroll');
  const homeFeed = $('#homeFeed');
  const moduleFeed = $('#moduleFeed');
  const player = $('#player');
  const playerPauseRing = $('#playerPauseRing');
  const playerTop = $('.player-top');
  const playerStage = $('#playerStage');
  const playerControls = $('#playerControls');
  const playerTitle = $('#playerTitle');
  const playerSub = $('#playerSub');
  const pcPlay = $('#pcPlay');
  const pcTime = $('#pcTime');
  const pcQuality = $('#pcQuality');
  const pcQualityValue = $('#pcQualityValue');
  const pcSpeed = $('#pcSpeed');
  const pcSpeedValue = $('#pcSpeedValue');
  const pcInterp = $('#pcInterp');
  const pcInterpValue = $('#pcInterpValue');
  const pcEnhance = $('#pcEnhance');
  const pcEnhanceValue = $('#pcEnhanceValue');
  const pcDanmaku = $('#pcDanmaku');
  const pcLoop = $('#pcLoop');
  const pcLoopValue = $('#pcLoopValue');
  const pcSide = $('#pcSide');
  const pcSettings = $('#pcSettings');
  const pcShot = $('#pcShot');
  const pcShotValue = $('#pcShotValue');
  const pcFullscreen = $('#pcFullscreen');
  const progressBar = $('.progress-ph', playerControls);
  const progressPlayed = $('.progress-played', playerControls);
  const progressThumb = $('.progress-thumb', playerControls);
  const seekRipple = $('#seekRipple');
  const lockBadge = $('#lockBadge');
  const rateHud = $('#rateHud');
  const rateValue = $('#rateValue');
  const rateLabel = $('#rateLabel');
  const rotateHud = $('#rotateHud');
  const rotateArrow = $('#rotateArrow');
  const rotateLabel = $('#rotateLabel');
  const playerOrientationBadge = $('#playerOrientationBadge');
  const swipeHint = $('#swipeHint');
  const commentsPanel = $('#commentsPanel');
  const commentsBody = $('#commentsBody');
  const videoDetailPanel = $('#videoDetailPanel');
  const videoDetailScroll = $('#videoDetailScroll');
  const videoDetailBody = $('#videoDetailBody');
  const playerVideo = $('#playerVideo');
  const realVideo = $('#realVideo');
  const feedDebug = $('#feedDebug');
  const feedDebugHz = $('#feedDebugHz');
  const feedDebugFps = $('#feedDebugFps');
  const videoDebug = $('#videoDebug');
  const postCanvas = $('#postCanvas');
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
  const sidebarFoot = $('#sidebarFoot');
  const searchClose = $('#searchClose');
  const searchBack = $('#searchBack');
  const searchHotSection = $('#searchHotSection');
  const searchSuggestSection = $('#searchSuggestSection');
  const hotSearchList = $('#hotSearchList');
  const searchSuggestList = $('#searchSuggestList');
  const searchHomePage = $('.page[data-page="search-home"]');
  const playlistDock = $('#playlistDock');
  const playlistPage = $('.page[data-page="playlist"]');
  const upPage = $('.page[data-page="up"]');
  const pdThumb = $('#pdThumb');
  const pdTitle = $('#pdTitle');
  const pdMeta = $('#pdMeta');
  const pdProgress = $('#pdProgress');
  const pdSearch = $('#pdSearch');
  const pdSearchInput = $('#pdSearchInput');
  const pdSearchBack = $('#pdSearchBack');
  const dockSearchHot = $('#dockSearchHot');
  const dockSearchSuggest = $('#dockSearchSuggest');
  const dockHotSearchList = $('#dockHotSearchList');
  const dockSearchSuggestList = $('#dockSearchSuggestList');
  const searchResultsPage = $('.page[data-page="search"]');
  const dockPlaylistBody = $('#dockPlaylistBody');
  const dockPlaylistList = $('#dockPlaylistList');
  const dockPlaylistCount = $('#dockPlaylistCount');
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
    { id: 'home', label: '首页', icon: 'home', type: 'page', target: 'home', group: '桌面端' },
    { id: 'favorite', label: '收藏', icon: 'favorite', type: 'module', target: '收藏', group: '桌面端' },
    { id: 'fish', label: '养鱼', icon: 'fish', type: 'module', target: '养鱼', group: '桌面端' },
    { id: 'live', label: '直播', icon: 'live', type: 'module', target: '直播', group: '桌面端' },
    { id: 'follow', label: '关注', icon: 'follow', type: 'module', target: '关注', group: '桌面端' },
    { id: 'dynamic', label: '动态', icon: 'dynamic', type: 'page', target: 'dynamic', group: '桌面端' },
    { id: 'messages', label: '消息', icon: 'messages', type: 'page', target: 'messages', group: '桌面端' },
    { id: 'history', label: '历史', icon: 'history', type: 'module', target: '历史', group: '桌面端' },
    { id: 'my', label: '我的', icon: 'my', type: 'page', target: 'my', group: '移动端' },
  ];

  const NAV_ICONS = {
    home: '<path d="M3.5 10.7 12 3.5l8.5 7.2V20a1 1 0 0 1-1 1h-5v-6h-5v6h-5a1 1 0 0 1-1-1z"/>',
    favorite: '<path d="M6.5 3.5h11a1 1 0 0 1 1 1v16l-6.5-4-6.5 4v-16a1 1 0 0 1 1-1z"/>',
    fish: '<path d="M3.5 12c2.4-3.1 5.5-4.6 9.1-4.6 3.1 0 5.7 1.5 7.9 4.6-2.2 3.1-4.8 4.6-7.9 4.6-3.6 0-6.7-1.5-9.1-4.6z"/><path d="M3.5 12 1.5 8.7v6.6L3.5 12z"/><circle cx="15.8" cy="10.5" r="0.8" fill="currentColor" stroke="none"/>',
    live: '<rect x="3" y="4.5" width="18" height="12.5" rx="2"/><path d="m10 8 5 2.75L10 13.5z"/><path d="M8.5 21h7M12 17v4"/>',
    follow: '<circle cx="9" cy="8" r="3.8"/><path d="M2.5 21v-1.4A5.6 5.6 0 0 1 8.1 14h1.8a5.6 5.6 0 0 1 5.6 5.6V21"/><path d="M19 8.5v5M16.5 11h5"/>',
    dynamic: '<path d="M3 12h3.4l2.4-5.8 4.4 11.6 2.4-5.8H21"/>',
    messages: '<path d="M4 4.5h16a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H9l-5 4v-4a1 1 0 0 1-1-1v-10a1 1 0 0 1 1-1z"/><path d="M8 9h8M8 12.5h5"/>',
    history: '<path d="M3.2 12a8.8 8.8 0 1 0 2.7-6.3"/><path d="M3 4.2v4.4h4.4"/><path d="M12 7.4V12l3.1 1.9"/>',
    my: '<circle cx="12" cy="8" r="3.8"/><path d="M4.5 21v-1.5A5.5 5.5 0 0 1 10 14h4a5.5 5.5 0 0 1 5.5 5.5V21"/>',
  };

  function navIcon(name) {
    const body = NAV_ICONS[name];
    if (!body) return '';
    return `<svg class="nav-svg" viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${body}</svg>`;
  }

  const DEFAULT_NAV_SELECTED = ['home', 'favorite', 'dynamic', 'messages', 'my'];
  const PAGE_NAV = { home: 'home', search: 'search', dynamic: 'dynamic', messages: 'messages', my: 'my' };

  const DEFAULT_SETTINGS = {
    defaultQuality: '最高',
    quality: '1080P60',
    speed: '1.0×',
    interp: '关',
    enhance: '关',
    native4k: false,
    audioOnly: false,
    loop: '循环',
    aspect: '适应',
    debugHud: true,
    feedDebug: true,
    autoLandscape: true,

    danmaku: true,
    danmakuOpacity: 85,
    danmakuSize: 100,
    danmakuSpeed: 100,
    danmakuArea: '全屏',
    danmakuDensity: true,

    theme: '跟随系统',
    bgTransparency: 0,
    glassBlur: 60,
    bgBlur: 100,

    doubleSeek: true,
    longPress2x: true,
    doubleFullscreen: true,
    longPressRate: true,
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
    playerLandscape: false,
    playerLandscapeDir: 0,
    progress: 0,
    duration: 0,
    streamInfo: { videoBitrate: 0, audioBitrate: 0, sourceWidth: 0, sourceHeight: 0, netBps: 0, netAt: 0, direct: false },
    landscapeHome: loaded?.landscapeHome === true,
    fav: false,
    coin: false,
    followed: false,
    liked: false,
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

  if (loaded?.bgStyleVersion !== 2) {
    state.settings.bgTransparency = 0;
    state.settings.bgBlur = 100;
  }
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
  let rateHudTimer = null;
  let rotateHudTimer = null;
  let gyroBound = false;
  let gyroPermission = 'ask';
  let gyroPermissionPending = false;
  let gyroCandidateDir = null;
  let gyroCandidateTimer = null;

  let commentsGesture = null;
  let commentsCloseTimer = null;
  let videoDetailOpen = false;
  let videoDetailSwipe = null;
  let videoDetailCloseTimer = null;
  let videoDetailRenderTimer = null;
  let pendingPlayerOrigin = null;
  let playerOpenWindowAnim = null;
  let playerOpenWindowTimer = null;
  let playerCollapseAnim = null;
  let playerCollapseRadiusAnim = null;
  let playerPauseRingAnim = null;
  let playerCollapseTimer = null;
  let playerCollapseToken = 0;
  let playerDockForced = false;
  let rowSwipe = null;
  let sidebarPicked = null;
  let menuSwipeStart = null;
  let searchDrag = null;
  let sidebarSwipeStart = null;
  let suppressFeedClickUntil = 0;
  let suppressSidebarClickUntil = 0;
  let suppressPlaylistClickUntil = 0;
  let suppressDockClickUntil = 0;
  let dockLaunching = false;
  let dockLaunchTimer = null;
  let dockDrag = null;
  let dockAbsorbTimer = null;
  let playlistDrag = null;
  let toolbarDrag = null;
  let mockFeedLoading = false;
  let mockFeedLoadedAt = 0;

  const FEED_PREFETCH = 900;
  const ROW_ACTION_ARM = 24;
  const ROW_ACTION_UP = 160;
  const ROW_ACTION_MAX = 230;

  const MODULE_NOTES = {
    收藏: '真实收藏夹 · 第一页 20 条',
    历史: '真实观看历史 · 触底翻页',
    关注: '关注的 UP 主动态',
    养鱼: '入口默认隐藏',
    下载: '离线下载暂未接入',
    会员: '账号大会员状态',
    番剧: '番剧 / 国创 / 电影',
    影视: '电影 / 纪录片 / 电视剧',
    直播: '直播推荐 · HLS',
    分区: '分区最新投稿',
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
        if (window.O11A1Media && typeof window.O11A1Media.onQualityChange === 'function') {
          window.O11A1Media.onQualityChange(value);
        }
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
        landscapeHome: state.landscapeHome,
        bgStyleVersion: 2,
      }));
    } catch (_) {}
  }

  /* ---------- appearance / theme ---------- */
  function resolvedTheme() {
    if (state.settings.theme === '深色') return 'dark';
    if (state.settings.theme === '浅色') return 'light';
    try {
      return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    } catch (_) {
      return 'light';
    }
  }

  function applyAppearance() {
    const dark = resolvedTheme() === 'dark';
    const theme = dark ? 'dark' : 'light';
    const bg = Math.max(0, Math.min(100, Number(state.settings.bgTransparency) || 0));
    const glass = Math.max(0, Math.min(100, Number(state.settings.glassBlur) || 0));
    const bgBlur = Math.max(0, Math.min(100, Number(state.settings.bgBlur) || 0));
    const ios = state.platform === 'ios';
    const style = document.body.style;
    document.body.dataset.theme = theme;
    document.documentElement.style.colorScheme = theme;
    style.setProperty('--wallpaper-opacity', (0.22 + (100 - bg) / 100 * 0.78).toFixed(3));
    style.setProperty('--wallpaper-blur', `${(bgBlur / 100 * 60).toFixed(1)}px`);
    style.setProperty('--glass-blur', `blur(${(glass / 100 * 30).toFixed(1)}px) saturate(${dark ? 1.25 : 1.6})`);
    style.setProperty('--topbar-blur', `blur(${(glass / 100 * 26).toFixed(1)}px) saturate(1.5)`);
    const glassAlpha = 0.5 + (100 - glass) / 100 * 0.38;
    const sheetAlpha = 0.62 + (100 - glass) / 100 * 0.3;
    if (dark) {
      style.setProperty('--glass-bg', ios
        ? `linear-gradient(135deg,rgba(28,34,46,${(glassAlpha + 0.02).toFixed(2)}),rgba(16,20,28,${(glassAlpha - 0.14).toFixed(2)}))`
        : `rgba(18,22,30,${glassAlpha.toFixed(2)})`);
      style.setProperty('--glass-border', 'rgba(120,140,170,.22)');
      style.setProperty('--sheet-bg', `rgba(20,24,32,${sheetAlpha.toFixed(2)})`);
      style.setProperty('--sheet-border', 'rgba(120,140,170,.22)');
      style.setProperty('--topbar-bg', `linear-gradient(180deg,rgba(11,13,18,${(sheetAlpha + 0.04).toFixed(2)}),rgba(11,13,18,${(sheetAlpha - 0.28).toFixed(2)}))`);
      style.setProperty('--topbar-border', 'rgba(120,140,170,.16)');
    } else {
      style.setProperty('--glass-bg', ios
        ? `linear-gradient(135deg,rgba(255,255,255,${(glassAlpha + 0.16).toFixed(2)}),rgba(255,255,255,${(glassAlpha - 0.12).toFixed(2)}))`
        : `rgba(250,250,252,${glassAlpha.toFixed(2)})`);
      style.setProperty('--glass-border', 'rgba(0,0,0,.08)');
      style.setProperty('--sheet-bg', `rgba(255,255,255,${sheetAlpha.toFixed(2)})`);
      style.setProperty('--sheet-border', 'rgba(0,0,0,.08)');
      style.setProperty('--topbar-bg', `linear-gradient(180deg,rgba(250,250,252,${(sheetAlpha + 0.04).toFixed(2)}),rgba(250,250,252,${(sheetAlpha - 0.3).toFixed(2)}))`);
      style.setProperty('--topbar-border', 'rgba(0,0,0,.06)');
    }
    const meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute('content', dark ? '#0B0D12' : '#FAFAFC');
  }

  if (window.matchMedia) {
    try {
      const query = window.matchMedia('(prefers-color-scheme: dark)');
      if (query.addEventListener) query.addEventListener('change', applyAppearance);
      else if (query.addListener) query.addListener(applyAppearance);
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
    sidebarFoot.innerHTML = '';

    const createRow = (item) => {
      const row = document.createElement('button');
      row.type = 'button';
      row.className = 'sidebar-item';
      row.dataset.nav = item.id;
      row.innerHTML = `
        <span class="sidebar-ico">${navIcon(item.icon)}</span>
        <span class="sidebar-label">${escapeHTML(item.label)}</span>`;
      row.addEventListener('click', () => {
        closeSidebar();
        handleNav(item, row);
      });
      return row;
    };

    items.filter((item) => item.id !== 'my').forEach((item) => {
      sidebarNav.appendChild(createRow(item));
    });
    items.filter((item) => item.id === 'my').forEach((item) => {
      sidebarFoot.appendChild(createRow(item));
    });

    updateNavActive();
    updatePlaylistCounts();
  }

  function updateNavActive() {
    $$('.sidebar-item', sidebar).forEach((row) => {
      row.classList.toggle('on', row.dataset.nav === state.navActive);
    });
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
    playlistDock.classList.remove('receiving', 'absorbing');
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
    if (state.page !== 'search-home' && state.page !== 'search') {
      state.searchReturn = state.page;
      state.searchReturnNav = state.navActive;
    }
    searchInput.value = '';
    updateSearch();
    resetSearchDrag();
    showPage('search-home');
    setTimeout(() => searchInput.focus(), 160);
  }

  function closeSearch() {
    const target = state.searchReturn && state.searchReturn !== 'search' && state.searchReturn !== 'search-home'
      ? state.searchReturn
      : 'home';
    resetSearchDrag();
    showPage(target, state.searchReturnNav || undefined);
  }

  function resetSearchResultsDrag() {
    if (!searchResultsPage) return;
    searchResultsPage.classList.remove('dragging');
    searchResultsPage.classList.add('settling');
    searchResultsPage.style.transition = 'transform .32s cubic-bezier(.16,1,.3,1)';
    searchResultsPage.style.transform = '';
    searchResultsPage.style.boxShadow = '';
    setTimeout(() => {
      if (!searchResultsPage.classList.contains('dragging')) {
        searchResultsPage.style.transition = '';
        searchResultsPage.classList.remove('settling');
      }
    }, 340);
  }

  function closeSearchFromSwipe() {
    if (!searchResultsPage) {
      closeSearch();
      return;
    }
    searchResultsPage.classList.remove('dragging');
    searchResultsPage.classList.add('settling');
    searchResultsPage.style.transition = 'transform .32s cubic-bezier(.22,1,.36,1)';
    searchResultsPage.style.transform = 'translate3d(105%,0,0)';
    searchResultsPage.style.boxShadow = '-18px 0 46px rgba(10,12,20,.18)';
    setTimeout(() => {
      closeSearch();
      searchResultsPage.classList.remove('settling');
      searchResultsPage.style.transition = '';
      searchResultsPage.style.transform = '';
      searchResultsPage.style.boxShadow = '';
    }, 320);
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

  let smsPollTimer = null;
  function openSmsLogin() {
    if (!window.O11A1Native || typeof window.O11A1Native.openWebLogin !== 'function') {
      loginStatus.textContent = '当前版本不支持短信登录';
      return;
    }
    let result;
    try { result = JSON.parse(window.O11A1Native.openWebLogin()); } catch (_) { result = { ok: false }; }
    if (!result || !result.ok) {
      loginStatus.textContent = result && result.error ? result.error : '打开短信登录失败';
      return;
    }
    loginStatus.textContent = '已打开 B 站短信登录页…';
    clearInterval(smsPollTimer);
    let attempts = 0;
    smsPollTimer = setInterval(() => {
      attempts += 1;
      if (state.loggedIn) {
        clearInterval(smsPollTimer);
        smsPollTimer = null;
        return;
      }
      let account = null;
      try { account = JSON.parse(window.O11A1Native.account()); } catch (_) {}
      if (account && account.ok && account.loggedIn) {
        clearInterval(smsPollTimer);
        smsPollTimer = null;
        loginSucceeded();
        return;
      }
      if (attempts > 120) {
        clearInterval(smsPollTimer);
        smsPollTimer = null;
        loginStatus.textContent = '还没有检测到登录 · 可以重新打开短信登录';
      }
    }, 1500);
  }

  function logout() {
    state.loggedIn = false;
    if (window.O11A1Native && typeof window.O11A1Native.logout === 'function') {
      try { window.O11A1Native.logout(); } catch (_) {}
    }
    if (state.playerOpen) stopPlayback();
    closeSheet();
    closeSidebar();
    app.classList.add('auth-gate');
    state.navActive = '';
    save();
    updateNavActive();
    showPage('login');
    loginStatus.textContent = '已退出登录 · 短信验证码登录';
  }

  function showPage(page, navId) {
    const previousPage = state.page;
    if (!state.loggedIn && page !== 'login') {
      page = 'login';
      navId = null;
    }
    if (page === 'up' && upPage) {
      const base = state.upReturn && state.upReturn !== 'up'
        ? state.upReturn
        : (previousPage !== 'up' ? previousPage : 'home');
      state.page = 'up';
      app.classList.toggle('auth-gate', !state.loggedIn);
      $$('.page').forEach((section) => {
        if (section === upPage) return;
        if (section === searchResultsPage) return;
        section.classList.toggle('active', section.dataset.page === base);
      });
      app.dataset.page = 'up';
      document.body.classList.toggle('search-mode', false);
      if (typeof updateDebugHud === 'function') updateDebugHud();
      if (searchResultsPage && base !== 'search') {
        searchResultsPage.classList.remove('active', 'dragging', 'settling', 'entering');
        searchResultsPage.style.transition = '';
        searchResultsPage.style.transform = '';
        searchResultsPage.style.opacity = '';
        searchResultsPage.style.boxShadow = '';
      }
      upPage.classList.remove('up-dragging', 'up-settling', 'entering');
      upPage.style.transition = '';
      upPage.style.transform = '';
      upPage.style.opacity = '';
      upPage.style.boxShadow = '';
      upPage.classList.add('active');
      void upPage.offsetWidth;
      upPage.classList.add('entering');
      setTimeout(() => upPage.classList.remove('entering'), 430);
      upPage.scrollTop = 0;
      updatePlaylistDock();
      return;
    }
    if (page === 'search' && searchResultsPage) {
      const base = state.searchReturn && state.searchReturn !== 'search'
        ? state.searchReturn
        : (previousPage !== 'search' ? previousPage : 'home');
      state.page = 'search';
      app.classList.toggle('auth-gate', !state.loggedIn);
      $$('.page').forEach((section) => {
        if (section === searchResultsPage) return;
        section.classList.toggle('active', section.dataset.page === base);
      });
      app.dataset.page = 'search';
      document.body.classList.toggle('search-mode', false);
      if (typeof updateDebugHud === 'function') updateDebugHud();
      searchResultsPage.style.zIndex = '48';
      searchResultsPage.classList.remove('dragging', 'settling', 'entering');
      searchResultsPage.style.transition = '';
      searchResultsPage.style.transform = '';
      searchResultsPage.style.opacity = '';
      searchResultsPage.style.boxShadow = '';
      searchResultsPage.classList.add('active');
      void searchResultsPage.offsetWidth;
      searchResultsPage.classList.add('entering');
      setTimeout(() => searchResultsPage.classList.remove('entering'), 380);
      searchResultsPage.scrollTop = 0;
      updatePlaylistDock();
      return;
    }
    const returningToBase = previousPage === 'up'
      && page === (state.upReturn || 'home');
    const returningFromSearch = previousPage === 'search'
      && page === (state.searchReturn || 'home');
    if (previousPage === 'up' && upPage) {
      upPage.classList.remove('active', 'up-dragging', 'up-settling', 'entering');
      upPage.style.transition = '';
      upPage.style.transform = '';
      upPage.style.opacity = '';
      upPage.style.boxShadow = '';
    }
    if (previousPage === 'search' && searchResultsPage) {
      searchResultsPage.classList.remove('active', 'dragging', 'settling', 'entering');
      searchResultsPage.style.transition = '';
      searchResultsPage.style.transform = '';
      searchResultsPage.style.opacity = '';
      searchResultsPage.style.boxShadow = '';
    }
    state.page = page;
    app.classList.toggle('auth-gate', !state.loggedIn);
    $$('.page').forEach((section) => {
      section.classList.toggle('active', section.dataset.page === page);
    });
    app.dataset.page = page;
    document.body.classList.toggle('search-mode', page === 'search' || page === 'search-home');
    if (typeof updateDebugHud === 'function') updateDebugHud();
    if (page !== 'search-home' && document.activeElement === searchInput) {
      searchInput.blur();
    }
    if (page === 'login') {
      state.navActive = '';
      loginStatus.textContent = state.loggedIn ? '已登录 · 可重新登录' : '短信验证码登录';
    } else if (navId !== undefined && navId !== null) {
      state.navActive = navId;
    } else if (PAGE_NAV[page]) {
      state.navActive = PAGE_NAV[page];
    }
    updateNavActive();
    updatePlaylistDock();
    if (!returningToBase && !returningFromSearch) appScroll.scrollTop = 0;
    if (page === 'search-home') {
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

  /* ---------- feed window ---------- */
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

  function markMockChunk(feed, chunk) {
    $$('.video-row', feed).forEach((row) => {
      if (row.closest('.feed-skeleton')) return;
      row.dataset.chunk = String(chunk);
    });
  }

  function clearMockFeedSkeleton(feed) {
    if (!feed) return;
    $$('.feed-skeleton', feed).forEach((node) => node.remove());
  }

  function showMockFeedSkeleton(feed, page, count) {
    if (!feed) return;
    clearMockFeedSkeleton(feed);
    const total = Math.max(1, Number(count) || 9);
    const fragment = document.createDocumentFragment();
    for (let i = 0; i < total; i += 1) {
      const row = document.createElement('div');
      row.className = 'feed-item feed-skeleton';
      row.dataset.skeletonPage = String(page);
      row.setAttribute('aria-hidden', 'true');
      row.innerHTML = `
        <span class="video-row skel-row">
          <span class="row-thumb skel-thumb"></span>
          <span class="row-copy">
            <span class="ph-line w80"></span>
            <span class="ph-line w55"></span>
            <span class="ph-line w30"></span>
          </span>
        </span>`;
      fragment.appendChild(row);
    }
    feed.appendChild(fragment);
  }

  function appendMockFeedChunk(feed, page) {
    if (!feed || document.body.classList.contains('native-app')) return;
    if (!Array.isArray(feed.__chunkPages) || !feed.__chunkPages.length) {
      feed.__chunkPages = [1];
      markMockChunk(feed, 1);
    }
    const next = page || (Math.max(...feed.__chunkPages) + 1);
    if (feed.__chunkPages.includes(next)) return;
    const oldest = Math.min(...feed.__chunkPages);
    if (oldest && next < oldest) return;
    const skeletons = $$('.feed-skeleton', feed);
    const realRows = [];
    for (let i = 0; i < 9; i += 1) {
      const holder = document.createElement('div');
      holder.innerHTML = feedRowMarkup(i + next * 3);
      const row = holder.firstElementChild;
      if (!row) continue;
      row.dataset.chunk = String(next);
      realRows.push(row);
    }
    if (skeletons.length) {
      realRows.forEach((row, index) => {
        const skeleton = skeletons[index];
        if (skeleton && skeleton.isConnected) skeleton.replaceWith(row);
        else feed.appendChild(row);
      });
      skeletons.slice(realRows.length).forEach((skeleton) => skeleton.remove());
    } else {
      realRows.forEach((row) => feed.appendChild(row));
    }
    feed.__chunkPages.push(next);
    while (feed.__chunkPages.length > 2) {
      const oldPage = feed.__chunkPages.shift();
      const oldRows = $$(`[data-chunk="${oldPage}"]`, feed);
      const firstOld = oldRows[0];
      const lastOld = oldRows[oldRows.length - 1];
      const oldHeight = firstOld && lastOld
        ? lastOld.getBoundingClientRect().bottom - firstOld.getBoundingClientRect().top
        : 0;
      const beforeScroll = oldHeight > 0 ? appScroll.scrollTop : 0;
      oldRows.forEach((row) => row.remove());
      if (oldHeight > 0) {
        window.__o11a1ScrollAdjust = Date.now();
        appScroll.scrollTop = Math.max(0, beforeScroll - oldHeight);
      }
    }
  }

  function maybeAppendMockFeed() {
    const now = Date.now();
    if (now - (window.__o11a1ScrollAdjust || 0) < 160) return;
    if (document.body.classList.contains('native-app') || mockFeedLoading) return;
    if (now - mockFeedLoadedAt < 600) return;
    const feed = activeFeed();
    if (!feed) return;
    const max = appScroll.scrollHeight - appScroll.clientHeight;
    if (max <= 0 || appScroll.scrollTop < max - FEED_PREFETCH) return;
    const current = Array.isArray(feed.__chunkPages) && feed.__chunkPages.length
      ? Math.max(...feed.__chunkPages)
      : 1;
    const next = current + 1;
    mockFeedLoading = true;
    const key = state.page;
    showMockFeedSkeleton(feed, next, 9);
    setTimeout(() => {
      mockFeedLoading = false;
      if (state.page !== key) {
        clearMockFeedSkeleton(feed);
        return;
      }
      const pages = Array.isArray(feed.__chunkPages) ? feed.__chunkPages : [];
      const oldest = pages.length ? Math.min(...pages) : 0;
      if ((pages.includes(next)) || (oldest && next < oldest)) {
        clearMockFeedSkeleton(feed);
        return;
      }
      appendMockFeedChunk(feed, next);
      mockFeedLoadedAt = Date.now();
    }, 160);
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
    homeNote.textContent = `${mod.name} · 触底加载 · 保留最近两段`;
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
      chip.innerHTML = `<span class="nav-chip-ico">${navIcon(item.icon)}</span><span>${escapeHTML(item.label)}</span>`;
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
          <span class="nav-setting-ico">${navIcon(item.icon)}</span>
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
      <span class="pl-thumb">${item.pic ? `<img src="${escapeHTML(item.pic)}" alt="">` : '<span class="ph-label">封面</span>'}</span>
      <span class="pl-copy">
        <span class="pl-title">${escapeHTML(item.title)}${current ? '<span class="pl-badge">当前</span>' : ''}</span>
        <span class="pl-meta">${escapeHTML(item.meta)}</span>
      </span>
      ${removable ? '<button class="pl-remove" type="button" title="移出播放列表">×</button>' : ''}`;
  }

  function setDockExpanded(expanded) {
    const next = Boolean(expanded);
    playlistDock.classList.remove('dragging');
    playlistDock.classList.toggle('expanded', next);
    void playlistDock.offsetWidth;
    playlistDock.style.height = '';
    playlistDock.style.borderTopLeftRadius = '';
    playlistDock.style.borderTopRightRadius = '';
    playlistDock.style.boxShadow = '';
    if (next) renderDockPlaylist();
  }

  function openPlaylistItem(index, sourceRow) {
    if (!Number.isInteger(index) || index < 0 || index >= state.playlist.length) return;
    if (index !== state.currentIndex) state.progress = 0;
    state.currentIndex = index;
    state.playing = true;
    save();
    if (sourceRow) {
      const thumb = sourceRow.querySelector('.pl-thumb');
      if (thumb) {
        const rect = thumb.getBoundingClientRect();
        if (rect.width && rect.height) {
          pendingPlayerOrigin = {
            thumb,
            rect,
            radius: getComputedStyle(thumb).borderRadius || '0px',
            time: Date.now(),
          };
        }
      }
    }
    setDockExpanded(false);
    openPlayer({ resume: true });
  }

  function renderDockPlaylist() {
    if (!dockPlaylistList) return;
    const count = state.playlist.length;
    if (dockPlaylistCount) dockPlaylistCount.textContent = `${count} 项`;
    dockPlaylistList.innerHTML = '';
    if (!count) {
      dockPlaylistList.innerHTML = '<div class="pd-empty"><b>播放列表是空的</b><span>在视频行上向左滑加入播放列表</span></div>';
      return;
    }
    state.playlist.forEach((item, index) => {
      const row = document.createElement('div');
      row.className = `playlist-page-item${index === state.currentIndex ? ' on' : ''}`;
      row.setAttribute('role', 'button');
      row.tabIndex = 0;
      row.innerHTML = playlistItemMarkup(item, index, index === state.currentIndex, true);
      const open = () => openPlaylistItem(index, row);
      row.addEventListener('click', (event) => {
        if (event.target.closest('.pl-remove')) return;
        open();
      });
      row.addEventListener('keydown', (event) => {
        if (event.key !== 'Enter' && event.key !== ' ') return;
        event.preventDefault();
        open();
      });
      const remove = $('.pl-remove', row);
      if (remove) {
        remove.addEventListener('click', (event) => {
          event.stopPropagation();
          removeFromPlaylist(index);
        });
      }
      dockPlaylistList.appendChild(row);
    });
  }

  function updatePlaylistCounts() {
    updatePlaylistDock();
  }

  function updatePlaylistDock() {
    const count = state.playlist.length;
    const item = state.playlist[state.currentIndex];
    renderDockPlaylist();
    const dockVisible = state.loggedIn && (!state.playerOpen || dockLaunching);
    const show = dockVisible;
    playlistDock.classList.toggle('show', show);
    playlistDock.setAttribute('aria-hidden', show ? 'false' : 'true');
    playlistDock.setAttribute('aria-label', `播放列表，${count} 项`);
    playlistDock.inert = !show;
    app.classList.toggle('has-playlist', dockVisible);
    playlistDock.style.opacity = '';
    playlistDock.style.transform = '';
    if (!item) {
      pdThumb.innerHTML = '<span class="ph-label">封面</span>';
      pdTitle.textContent = '播放列表';
      pdMeta.textContent = `${count} 项`;
      pdProgress.style.width = '0%';
      return;
    }
    pdThumb.innerHTML = item.pic
      ? `<img src="${escapeHTML(item.pic)}" alt="">`
      : '<span class="ph-label">封面</span>';
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
    const detailOpen = videoDetailOpen;
    const useDock = dockVisible && !detailOpen;
    if (!thumb || (!useDock && !detailOpen) || document.body.classList.contains('reduce-motion')
      || typeof thumb.animate !== 'function') {
      if (useDock) absorbPlaylistDock();
      return;
    }
    const start = thumb.getBoundingClientRect();
    const end = useDock
      ? pdThumb.getBoundingClientRect()
      : {
        left: window.innerWidth / 2 - 30,
        top: window.innerHeight - 54,
        width: 60,
        height: 60,
      };
    if (!start.width || !end.width) {
      if (useDock) absorbPlaylistDock();
      return;
    }
    const sourceRadius = getComputedStyle(thumb).borderRadius || '0px';
    const flyer = thumb.cloneNode(true);
    flyer.querySelectorAll('.ph-label, .dur-ph').forEach((node) => node.remove());
    flyer.classList.add('playlist-fly');
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
        borderRadius: sourceRadius,
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
        borderRadius: '12px',
        boxShadow: '0 8px 20px rgba(47,124,246,.24)',
      },
    ], {
      duration: 560,
      easing: 'cubic-bezier(.22,1,.36,1)',
    });
    flight.finished.then(() => flyer.remove()).catch(() => flyer.remove());
    setTimeout(() => {
      if (useDock) absorbPlaylistDock();
    }, 430);
  }

  function setCurrent(index) {
    if (index < 0 || index >= state.playlist.length) return;
    state.currentIndex = index;
    resetInteractionState();
    updatePlayerLabels();
    updatePlaylistCounts();
    save();
  }

  function resetInteractionState() {
    state.fav = false;
    state.coin = false;
    state.followed = false;
    state.liked = false;
    state.cached = false;
    state.shot = false;
    state.copied = false;
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

  function addToPlaylist(title, meta, key, extra) {
    const existing = key ? state.playlist.findIndex((item) => item.key === key) : -1;
    if (existing >= 0) {
      setCurrent(existing);
      return { added: false, count: state.playlist.length };
    }
    const index = state.playlist.length + 1;
    const item = Object.assign({
      id: `q${Date.now()}`,
      key: key || '',
      title: title || `视频占位 ${String(index).padStart(2, '0')}`,
      meta: meta || `UP 占位 ${String(index).padStart(2, '0')} · 00:00`,
    }, extra || {});
    state.playlist.push(item);
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
      goHome.addEventListener('click', () => withPlaylistTransition(() => showPage('home')));
      return;
    }

    state.playlist.forEach((item, index) => {
      const row = document.createElement('div');
      row.className = `playlist-page-item${index === state.currentIndex ? ' on' : ''}`;
      row.setAttribute('role', 'button');
      row.tabIndex = 0;
      row.innerHTML = playlistItemMarkup(item, index, index === state.currentIndex, true);
      const openItem = () => openPlaylistItem(index, row);
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

  function resetPlaylistPageDrag() {
    if (!playlistPage) return;
    playlistPage.classList.remove('dragging');
    playlistPage.style.transition = '';
    playlistPage.style.transform = '';
    playlistPage.style.opacity = '';
  }

  function withPlaylistTransition(run) {
    if (!document.startViewTransition || document.body.classList.contains('reduce-motion')) {
      run();
      return;
    }
    const root = document.documentElement;
    let ran = false;
    const execute = () => {
      ran = true;
      run();
    };
    const clear = () => root.classList.remove('playlist-vt');
    root.classList.add('playlist-vt');
    let transition;
    try {
      transition = document.startViewTransition(execute);
    } catch (_) {
      clear();
      if (!ran) run();
      return;
    }
    const timer = setTimeout(clear, 700);
    if (transition && transition.finished && typeof transition.finished.finally === 'function') {
      transition.finished.finally(() => {
        clearTimeout(timer);
        clear();
      });
    }
    if (transition && transition.ready && typeof transition.ready.catch === 'function') {
      transition.ready.catch(clear);
    }
  }

  function openPlaylistPage() {
    if (!state.loggedIn) {
      showPage('login');
      return;
    }
    setDockExpanded(false);
    if (state.page === 'playlist') return;
    state.playlistReturn = state.page;
    state.playlistReturnNav = state.navActive;
    if (state.playerOpen) minimizePlayer();
    withPlaylistTransition(() => {
      resetPlaylistPageDrag();
      renderPlaylistPage();
      showPage('playlist');
    });
  }

  function closePlaylistPage(useTransition) {
    const target = state.playlistReturn && state.playlistReturn !== 'playlist' ? state.playlistReturn : 'home';
    const run = () => showPage(target, state.playlistReturnNav || undefined);
    if (useTransition) withPlaylistTransition(run);
    else run();
  }

  function closePlaylistWithDrag() {
    if (!playlistPage) {
      closePlaylistPage();
      return;
    }
    playlistPage.style.transition = 'transform .36s cubic-bezier(.16,1,.3,1),opacity .28s ease';
    playlistPage.style.transform = 'translateY(105%) scale(.98)';
    playlistPage.style.opacity = '0';
    setTimeout(() => {
      closePlaylistPage();
      resetPlaylistPageDrag();
    }, 380);
  }

  function applyPlaylistDrag(dy) {
    if (!playlistPage) return;
    const drag = Math.min(360, Math.max(0, dy));
    const progress = Math.min(1, drag / 280);
    playlistPage.style.transform = `translateY(${drag}px) scale(${1 - progress * 0.025})`;
    playlistPage.style.opacity = String(1 - progress * 0.35);
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
    const item = row.__nativeItem;
    if (item) {
      addToPlaylist(item.title, item.meta, `bvid:${item.bvid}`, item);
    } else {
      addToPlaylist(feedRowTitle(row), 'UP 占位 · 左滑加入', feedRowKey(row));
    }
    flyRowToPlaylist(row);
  }

  function rowActionForOffset(offset) {
    if (offset >= ROW_ACTION_UP) return 'up';
    if (offset >= ROW_ACTION_ARM) return 'queue';
    return '';
  }

  function ensureRowMask(row) {
    let mask = row.querySelector('.row-swipe-mask');
    if (mask) return mask;
    mask = document.createElement('span');
    mask.className = 'row-swipe-mask';
    mask.dataset.action = 'queue';
    mask.setAttribute('aria-hidden', 'true');
    mask.innerHTML = '<b class="rsm-label">加入播放列表</b><small class="rsm-hint">左滑加入</small>';
    row.appendChild(mask);
    return mask;
  }

  function setRowSwipe(wrapper, offset) {
    if (!wrapper) return;
    const row = wrapper.querySelector('.video-row');
    if (!row) return;
    const mask = ensureRowMask(row);
    const armedQueue = offset >= ROW_ACTION_ARM;
    const armedUp = offset >= ROW_ACTION_UP;
    const action = armedUp ? 'up' : 'queue';
    const armed = armedUp ? 'up' : armedQueue ? 'queue' : '';
    const opacity = Math.min(1, Math.max(0, offset / 24));
    mask.dataset.action = action;
    mask.style.opacity = String(opacity);
    const label = mask.querySelector('.rsm-label');
    const hint = mask.querySelector('.rsm-hint');
    if (label) label.textContent = armedUp ? '查看 UP 主' : '加入播放列表';
    if (hint) hint.textContent = armedUp
      ? '松开查看 UP 主'
      : armedQueue ? '松开加入 · 继续左滑看 UP 主' : '左滑加入';
    mask.classList.toggle('armed', Boolean(armed));
    mask.classList.toggle('armed-up', armedUp);
    if (armed && armed !== wrapper.__rowArmed && navigator.vibrate) navigator.vibrate(6);
    wrapper.__rowArmed = armed;
    wrapper.__rowAction = armed ? action : '';
  }

  function resetRowSwipe(wrapper) {
    if (!wrapper) return;
    const row = wrapper.querySelector('.video-row');
    wrapper.classList.remove('swiping');
    wrapper.__rowAction = '';
    wrapper.__rowArmed = '';
    if (row) {
      const mask = row.querySelector('.row-swipe-mask');
      if (mask) {
        mask.style.opacity = '';
        mask.dataset.action = 'queue';
        mask.classList.remove('armed', 'armed-up', 'fired');
        const label = mask.querySelector('.rsm-label');
        const hint = mask.querySelector('.rsm-hint');
        if (label) label.textContent = '加入播放列表';
        if (hint) hint.textContent = '左滑加入';
      }
    }
  }

  function openUpPageForRow(row) {
    const item = row && row.__nativeItem;
    if (!item) return;
    if (videoDetailOpen) {
      openUpFromDetail(item);
      return;
    }
    if (window.O11A1NativeData && typeof window.O11A1NativeData.openUpPage === 'function') {
      window.O11A1NativeData.openUpPage(item);
      return;
    }
    openSheet('UP 主', item.owner || 'UP 主', (body) => {
      body.innerHTML = `<div class="native-empty"><b>${escapeHTML(item.owner || 'UP 主')}</b><span>当前版本没有 UP 主主页接口。</span></div>`;
    });
  }

  function resetUpPageDrag() {
    if (!upPage) return;
    upPage.classList.remove('up-dragging');
    upPage.classList.add('up-settling');
    upPage.style.transition = 'transform .3s cubic-bezier(.16,1,.3,1)';
    upPage.style.transform = '';
    upPage.style.boxShadow = '';
    setTimeout(() => {
      if (!upPage.classList.contains('up-dragging')) {
        upPage.style.transition = '';
        upPage.classList.remove('up-settling');
      }
    }, 320);
  }

  function closeUpPageFromSwipe() {
    if (!upPage) {
      showPage(state.upReturn || 'home');
      return;
    }
    upPage.classList.remove('up-dragging', 'entering');
    upPage.classList.add('up-settling');
    upPage.style.transition = 'transform .32s cubic-bezier(.22,1,.36,1)';
    upPage.style.transform = 'translate3d(105%,0,0)';
    upPage.style.boxShadow = '-18px 0 46px rgba(10,12,20,.18)';
    setTimeout(() => {
      showPage(state.upReturn || 'home', state.upReturnNav || undefined);
      upPage.classList.remove('up-settling');
      upPage.style.transition = '';
      upPage.style.transform = '';
      upPage.style.boxShadow = '';
    }, 320);
  }

  function triggerRowAction(wrapper, action) {
    if (!wrapper || !action) return;
    const row = wrapper.querySelector('.video-row');
    if (!row) return;
    suppressFeedClickUntil = Date.now() + 420;
    const mask = row.querySelector('.row-swipe-mask');
    if (mask) {
      mask.classList.add('armed', 'fired');
      mask.classList.toggle('armed-up', action === 'up');
      wrapper.classList.remove('swiping');
      mask.style.opacity = '0';
    }
    if (action === 'queue') addFeedRowToPlaylist(row);
    else if (action === 'up') openUpPageForRow(row);
    setTimeout(() => resetRowSwipe(wrapper), 220);
  }

  /* ---------- live sidebar drag ---------- */
  function clearSidebarPicked() {
    sidebarPicked = null;
    $$('.sidebar-item.picked', sidebar).forEach((row) => row.classList.remove('picked'));
  }

  function setSidebarPicked(row) {
    if (!row || row === sidebarPicked) return;
    sidebarPicked = row;
    $$('.sidebar-item.picked', sidebar).forEach((item) => item.classList.remove('picked'));
    row.classList.add('picked');
    if (navigator.vibrate) navigator.vibrate(6);
  }

  function sidebarSelectRows() {
    return $$('.sidebar-nav .sidebar-item', sidebar);
  }

  function sidebarSelectStep(count) {
    const travel = Math.min(320, Math.max(180, window.innerHeight * 0.28));
    return travel / Math.max(1, count - 1);
  }

  function beginSidebarSelect(gesture) {
    const rows = sidebarSelectRows();
    if (!rows.length) return;
    const active = rows.find((row) => row.dataset.nav === state.navActive)
      || (state.navActive === 'my' ? rows[rows.length - 1] : rows[0]);
    gesture.sidebarRows = rows;
    gesture.sidebarIndex = Math.max(0, rows.indexOf(active));
    gesture.sidebarAnchorY = gesture.sidebarLastY;
    gesture.sidebarStep = sidebarSelectStep(rows.length);
    gesture.sidebarSteps = 0;
    setSidebarPicked(active);
  }

  function moveSidebarSelect(gesture, clientY) {
    const rows = gesture.sidebarRows;
    if (!rows || !rows.length || !gesture.sidebarStep) return;
    const steps = Math.trunc((clientY - gesture.sidebarAnchorY) / gesture.sidebarStep);
    if (steps === gesture.sidebarSteps) return;
    const delta = steps - gesture.sidebarSteps;
    gesture.sidebarSteps = steps;
    const count = rows.length;
    gesture.sidebarIndex = ((gesture.sidebarIndex + delta) % count + count) % count;
    setSidebarPicked(rows[gesture.sidebarIndex]);
  }

  function beginSidebarDrag() {
    if (!state.loggedIn) return false;
    renderSidebar();
    updateMiniPlayer();
    clearSidebarPicked();
    sidebar.classList.remove('selecting');
    sidebar.inert = false;
    sidebar.setAttribute('aria-hidden', 'false');
    app.classList.add('sidebar-open', 'sidebar-dragging');
    sidebar.classList.add('open');
    sidebarBackdrop.classList.add('show');
    playlistDock.classList.remove('receiving', 'absorbing');
    updatePlaylistDock();
    return true;
  }

  function applySidebarDrag(progress) {
    const p = Math.max(0, Math.min(1, progress));
    appMain.style.transform = `translate3d(${(p * 10).toFixed(2)}%,0,0) scale(${(1 - p * 0.1).toFixed(4)}) rotateY(${(p * 5).toFixed(2)}deg)`;
    appMain.style.borderRadius = `${(p * 24).toFixed(1)}px`;
    sidebar.style.transform = `translate3d(${((p - 1) * 100).toFixed(2)}%,0,0)`;
    sidebarBackdrop.style.opacity = String(p);
  }

  function finishSidebarDrag() {
    app.classList.remove('sidebar-dragging');
    sidebar.classList.remove('selecting');
    clearSidebarPicked();
    appMain.style.transform = '';
    appMain.style.borderRadius = '';
    sidebar.style.transform = '';
    sidebarBackdrop.style.opacity = '';
  }

  function closeSidebarFromDrag() {
    app.classList.remove('sidebar-dragging');
    sidebar.classList.remove('selecting');
    clearSidebarPicked();
    closeSidebar();
    appMain.style.transform = '';
    appMain.style.borderRadius = '';
    sidebar.style.transform = '';
    sidebarBackdrop.style.opacity = '';
  }

  function endSidebarDrag(start, event) {
    if (!start) return;
    clearTimeout(start.sidebarHoldTimer);
    start.sidebarHoldTimer = null;
    const progress = start.sidebarProgress || 0;
    const selecting = start.sidebarSelecting === true;
    const picked = sidebarPicked;
    const cancelled = event && event.type === 'pointercancel';
    suppressFeedClickUntil = Date.now() + 420;
    suppressSidebarClickUntil = Date.now() + 420;
    if (selecting && picked && !cancelled) {
      if (progress < 0.12) {
        closeSidebarFromDrag();
        return;
      }
      const item = NAV_ITEMS.find((entry) => entry.id === picked.dataset.nav);
      closeSidebarFromDrag();
      if (item) handleNav(item, picked);
      return;
    }
    if (!cancelled && progress >= 0.22) {
      finishSidebarDrag();
      updatePlaylistDock();
      return;
    }
    closeSidebarFromDrag();
  }

  /* ---------- player ---------- */
  /* ---------- debug HUD ---------- */
  const debugState = {
    displayHz: 0,
    nativeHz: 0,
    compositorHz: 0,
    feedFps: 0,
    videoFps: 0,
    videoPresentFps: 0,
    decodeFps: 0,
    dropped: 0,
    avGap: null,
    bitrate: 0,
    bitrateAt: 0,
    videoStartAt: 0,
    lastMediaTime: null,
    lastFrameAt: 0,
  };
  const debugFrame = { start: 0, count: 0, videoStart: 0, videoCount: 0, decodeTotal: null, decodeAt: 0, decodeFps: 0, rvfcCount: 0 };
  let debugNetBytes = null;
  let debugNetAt = 0;
  let debugTimer = null;

  function commonHz(value) {
    if (!Number.isFinite(value) || value <= 0) return 0;
    const rates = [24, 30, 48, 50, 60, 90, 120, 144, 165, 240];
    let best = rates[0];
    let distance = Infinity;
    rates.forEach((rate) => {
      const d = Math.abs(rate - value);
      if (d < distance) { distance = d; best = rate; }
    });
    return Math.abs(best - value) <= 6 ? best : Math.round(value);
  }

  function sampleVideoQuality() {
    let total = null;
    let dropped = 0;
    if (typeof realVideo.webkitDecodedFrameCount === 'number') {
      total = Number(realVideo.webkitDecodedFrameCount || 0);
      dropped = Number(realVideo.webkitDroppedFrameCount || 0);
      if (total <= 0) total = null;
    }
    try {
      if (total === null && typeof realVideo.getVideoPlaybackQuality === 'function') {
        const quality = realVideo.getVideoPlaybackQuality();
        total = Number(quality.totalVideoFrames || 0);
        dropped = Number(quality.droppedVideoFrames || 0);
      }
    } catch (_) {}
    const now = performance.now();
    if (total !== null) {
      if (debugFrame.decodeTotal !== null && now - debugFrame.decodeAt >= 400) {
        const delta = Math.max(0, total - debugFrame.decodeTotal);
        const seconds = Math.max(0.2, (now - debugFrame.decodeAt) / 1000);
        debugFrame.decodeFps = delta / seconds;
      }
      debugFrame.decodeTotal = total;
      debugFrame.decodeAt = now;
    }
    debugState.dropped = dropped;
    if (window.O11A1Native && typeof window.O11A1Native.mediaStats === 'function') {
      try {
        const stats = JSON.parse(window.O11A1Native.mediaStats());
        if (stats && stats.ok) {
          const bytes = Number(stats.bytes || 0);
          if (debugNetBytes !== null && now > debugNetAt) {
            const delta = Math.max(0, bytes - debugNetBytes);
            const instant = Math.round(delta * 8 / ((now - debugNetAt) / 1000) / 1000);
            if (instant > 0) {
              debugState.bitrate = instant;
              debugState.bitrateAt = now;
            } else if (now - (debugState.bitrateAt || 0) > 6000) {
              const average = Math.round(bytes * 8 / Math.max(1, (now - (debugState.videoStartAt || now)) / 1000) / 1000);
              debugState.bitrate = average;
            }
          }
          debugNetBytes = bytes;
          debugNetAt = now;
        }
      } catch (_) {}
    } else if (typeof realVideo.webkitVideoDecodedByteCount === 'number') {
      const bytes = Number(realVideo.webkitVideoDecodedByteCount);
      if (debugNetBytes !== null && now > debugNetAt) {
        const delta = Math.max(0, bytes - debugNetBytes);
        debugState.bitrate = Math.round(delta * 8 / ((now - debugNetAt) / 1000) / 1000);
      }
      debugNetBytes = bytes;
      debugNetAt = now;
    }
  }

  function formatDebugBitrate(bps) {
    const value = Math.max(0, Number(bps) || 0);
    if (value === 0) return '—';
    if (value >= 1000000) return `${(value / 1000000).toFixed(2)} Mbps`;
    if (value >= 1000) return `${Math.round(value / 1000)} kbps`;
    return `${Math.round(value)} bps`;
  }

  function debugDurationText(seconds) {
    if (!Number.isFinite(seconds)) return '—';
    if (seconds < 60) return `${Math.max(0, seconds).toFixed(1)} s`;
    const total = Math.round(seconds);
    const hours = Math.floor(total / 3600);
    const minutes = Math.floor((total % 3600) / 60);
    const rest = total % 60;
    if (hours > 0) {
      return `${hours}:${String(minutes).padStart(2, '0')}:${String(rest).padStart(2, '0')}`;
    }
    return `${String(minutes).padStart(2, '0')}:${String(rest).padStart(2, '0')}`;
  }

  function debugBufferedAhead() {
    if (!realVideo || realVideo.readyState === 0) return null;
    try {
      const ranges = realVideo.buffered;
      if (!ranges || !ranges.length) return 0;
      const current = realVideo.currentTime;
      let best = 0;
      for (let index = 0; index < ranges.length; index += 1) {
        const start = ranges.start(index);
        const end = ranges.end(index);
        if (end < current) continue;
        if (start > current + 1) break;
        best = Math.max(best, end - current);
      }
      return best;
    } catch (_) {
      return null;
    }
  }

  function updateDebugHud() {
    const feedVisible = state.settings.feedDebug !== false
      && ['home', 'search', 'module'].includes(state.page);
    feedDebug.classList.toggle('show', feedVisible);
    document.body.classList.toggle('feed-debug-on', feedVisible);
    const playerVisible = state.settings.debugHud !== false && state.playerOpen;
    videoDebug.hidden = !playerVisible;
    if (!feedVisible && !playerVisible) return;
    const hz = debugState.nativeHz || debugState.displayHz;
    feedDebugHz.textContent = `${hz ? hz.toFixed(1) : '—'} Hz`;
    feedDebugFps.textContent = `${(debugState.compositorHz || debugState.feedFps).toFixed(1)} fps`;
    if (!playerVisible) return;

    const fps = debugState.videoPresentFps || 0;
    const frameMs = fps > 0.5 ? 1000 / fps : 0;
    const danmakuOn = state.settings.danmaku !== false;
    const danmakuActive = danmakuOn && !realVideo.paused && !realVideo.ended
      && Boolean(playerVideo.querySelector('.danmaku-item'));
    const danmakuFps = danmakuActive ? (debugState.feedFps || debugState.compositorHz || 0) : 0;
    const uiFps = debugState.feedFps || debugState.compositorHz || 0;

    const info = state.streamInfo || {};
    const videoW = Number(realVideo.videoWidth) || 0;
    const videoH = Number(realVideo.videoHeight) || 0;
    const sourceW = Number(info.sourceWidth) || videoW;
    const sourceH = Number(info.sourceHeight) || videoH;
    const screenW = Math.round((window.screen && window.screen.width ? window.screen.width : window.innerWidth)
      * (window.devicePixelRatio || 1));
    const screenH = Math.round((window.screen && window.screen.height ? window.screen.height : window.innerHeight)
      * (window.devicePixelRatio || 1));
    const dimensions = (width, height) => (width > 0 && height > 0 ? `${width}×${height}` : '—×—');
    const resolution = `源${dimensions(sourceW, sourceH)}/解${dimensions(videoW, videoH)}/屏${screenW}×${screenH}`;

    const directNet = Number(info.netBps) || 0;
    const directFresh = directNet > 0 && performance.now() - (Number(info.netAt) || 0) < 2500;
    const netBps = info.direct
      ? (directFresh ? directNet : 0)
      : Math.max(0, Number(debugState.bitrate) || 0) * 1000;
    const videoBps = Number(info.videoBitrate) || 0;
    const audioBps = Number(info.audioBitrate) || 0;
    const totalBps = videoBps + audioBps;
    let network = '— / —';
    if (netBps > 0) {
      network = totalBps > 0
        ? `${formatDebugBitrate(netBps)} / ${formatDebugBitrate(videoBps)} (${(netBps / totalBps).toFixed(1)}×)`
        : `${formatDebugBitrate(netBps)} / —`;
    } else if (totalBps > 0) {
      network = `— / ${formatDebugBitrate(videoBps)}`;
    }

    const buffered = debugBufferedAhead();
    const bufferText = buffered === null ? '—' : debugDurationText(buffered);

    videoDebug.textContent = [
      `画面帧率  ${fps.toFixed(1)} · ${frameMs.toFixed(1)} ms`,
      `弹幕帧率  ${danmakuFps.toFixed(1)}`,
      `界面帧率  ${uiFps.toFixed(1)}`,
      `分辨率    ${resolution}`,
      `网络      ${network}`,
      `缓冲长度  ${bufferText}`,
      `下集预载  —`,
    ].join('\n');
  }

  function initDebugHud() {
    const readNativeRates = () => {
      try {
        if (window.O11A1Native && typeof window.O11A1Native.displayHz === 'function') {
          const hz = Number(window.O11A1Native.displayHz());
          if (Number.isFinite(hz) && hz > 0) debugState.nativeHz = hz;
        }
        if (window.O11A1Native && typeof window.O11A1Native.compositorFps === 'function') {
          const fps = Number(window.O11A1Native.compositorFps());
          if (Number.isFinite(fps) && fps > 0) debugState.compositorHz = fps;
        }
      } catch (_) {}
    };
    readNativeRates();
    setInterval(readNativeRates, 1200);
    let last = performance.now();
    const samples = [];
    function frame(now) {
      const delta = now - last;
      last = now;
      if (delta > 2 && delta < 200) samples.push(delta);
      if (samples.length > 180) samples.splice(0, samples.length - 180);
      debugFrame.count += 1;
      if (realVideo && !realVideo.paused && !realVideo.ended) debugFrame.videoCount += 1;
      if (!debugFrame.start) {
        debugFrame.start = now;
        debugFrame.videoStart = now;
      }
      const span = now - debugFrame.start;
      if (span >= 1000) {
        debugState.feedFps = debugFrame.count * 1000 / span;
        debugState.videoFps = debugFrame.videoCount * 1000 / Math.max(1, now - debugFrame.videoStart);
        if (samples.length) {
          const sorted = samples.slice().sort((a, b) => a - b);
          const median = sorted[Math.floor(sorted.length * 0.5)];
          const measured = 1000 / Math.max(1, median);
          const rounded = commonHz(measured);
          if (rounded >= 24) {
            debugState.displayHz = Math.max(rounded, (debugState.displayHz || 0) * 0.995);
          }
        }
        debugFrame.start = now;
        debugFrame.count = 0;
        debugFrame.videoStart = now;
        debugFrame.videoCount = 0;
        debugFrame.decodeFps = 0;
        sampleVideoQuality();
        if (debugFrame.rvfcCount > 0
          && (!debugFrame.decodeFps || debugFrame.decodeFps < debugState.videoFps * 0.35)) {
          debugFrame.decodeFps = debugFrame.rvfcCount;
        }
        debugState.videoPresentFps = debugFrame.rvfcCount > 0
          ? debugFrame.rvfcCount
          : (realVideo.paused || realVideo.ended ? 0 : debugState.videoFps);
        debugFrame.rvfcCount = 0;
        updateDebugHud();
      }
      requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);

    const onFrame = (now, metadata) => {
      debugState.lastMediaTime = Number(metadata && metadata.mediaTime);
      debugState.lastFrameAt = now;
      debugFrame.rvfcCount += 1;
      if (metadata && Number.isFinite(debugState.lastMediaTime)) {
        debugState.avGap = Math.max(0, (realVideo.currentTime - debugState.lastMediaTime) * 1000);
      }
      if (typeof realVideo.requestVideoFrameCallback === 'function') {
        realVideo.requestVideoFrameCallback(onFrame);
      }
    };
    if (realVideo && typeof realVideo.requestVideoFrameCallback === 'function') {
      realVideo.requestVideoFrameCallback(onFrame);
    } else if (realVideo) {
      realVideo.addEventListener('timeupdate', () => {
        if (!Number.isFinite(debugState.lastMediaTime)) debugState.avGap = null;
      });
    }
    if (realVideo) {
      realVideo.addEventListener('loadedmetadata', () => {
        debugState.videoStartAt = performance.now();
        debugState.bitrateAt = 0;
        debugNetBytes = null;
        debugNetAt = 0;
      });
    }
    setInterval(sampleVideoQuality, 1000);
    updateDebugHud();
  }

  function setPlayIcon(playing) {
    player.classList.toggle('paused', playing !== true);
    if (!pcPlay) return;
    pcPlay.classList.toggle('playing', playing === true);
    pcPlay.setAttribute('aria-label', playing ? '暂停' : '播放');
  }

  function updatePlayerLabels() {
    const item = state.playlist[state.currentIndex];
    playerTitle.textContent = item ? item.title : '暂无播放项';
    const nativeSuffix = window.O11A1Native ? '' : ' · 占位';
    const qualitySuffix = item && item.offlineUrl ? '' : ` · ${state.settings.quality}`;
    playerSub.textContent = `${item ? item.meta : '占位'}${qualitySuffix}${nativeSuffix}`;
    pcQualityValue.textContent = state.settings.quality;
    pcSpeedValue.textContent = state.settings.speed || '1.0×';
    pcInterpValue.textContent = state.settings.interp;
    pcEnhanceValue.textContent = state.settings.enhance;
    pcDanmaku.classList.toggle('on', state.settings.danmaku);
    pcLoopValue.textContent = state.settings.loop;
    setProgress(state.progress);
    updatePlaylistDock();
    if (window.O11A1Media && typeof window.O11A1Media.onSettings === 'function') {
      window.O11A1Media.onSettings();
    }
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

  function setProgress(percent, seek) {
    state.progress = Math.min(100, Math.max(0, percent));
    progressPlayed.style.width = `${state.progress}%`;
    progressThumb.style.left = `${state.progress}%`;
    pdProgress.style.width = `${state.progress}%`;
    const total = state.duration > 0 ? state.duration : TOTAL_SECONDS;
    const current = total * state.progress / 100;
    pcTime.textContent = `${formatTime(current)} / ${formatTime(total)}`;
    if (seek && window.O11A1Media && typeof window.O11A1Media.seek === 'function') {
      window.O11A1Media.seek(state.progress);
    }
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
    }, 2000);
  }

  /* ---------- player orientation ---------- */
  function playerLandscapeDirection(mode) {
    if (mode === true || mode === 'left' || mode === -1) return -1;
    if (mode === 'right' || mode === 1) return 1;
    return 0;
  }

  function setPlayerOrientation(mode, options = {}) {
    const dir = playerLandscapeDirection(mode);
    const changed = state.playerLandscape !== (dir !== 0) || state.playerLandscapeDir !== dir;
    state.playerLandscape = dir !== 0;
    state.playerLandscapeDir = dir;
    player.classList.toggle('landscape', dir !== 0);
    player.classList.toggle('landscape-left', dir === -1);
    player.classList.toggle('landscape-right', dir === 1);
    if (playerOrientationBadge) playerOrientationBadge.hidden = dir === 0;
    if (!changed || options.silent) return;
    rotateArrow.textContent = dir ? '↔' : '↕';
    rotateLabel.textContent = dir ? '横屏' : '竖屏';
    const hint = rotateHud.querySelector('small');
    if (hint) hint.textContent = dir ? '陀螺仪 · 转动手机恢复竖屏' : '陀螺仪 · 已恢复竖屏';
    rotateHud.classList.remove('show');
    void rotateHud.offsetWidth;
    rotateHud.classList.add('show');
    clearTimeout(rotateHudTimer);
    rotateHudTimer = setTimeout(() => {
      rotateHudTimer = null;
      rotateHud.classList.remove('show');
    }, 1200);
  }

  function queueGyroOrientation(dir) {
    if (dir === state.playerLandscapeDir) {
      clearTimeout(gyroCandidateTimer);
      gyroCandidateTimer = null;
      gyroCandidateDir = null;
      return;
    }
    if (gyroCandidateDir === dir) return;
    gyroCandidateDir = dir;
    clearTimeout(gyroCandidateTimer);
    gyroCandidateTimer = setTimeout(() => {
      gyroCandidateTimer = null;
      const target = gyroCandidateDir;
      gyroCandidateDir = null;
      if (target === null || !state.playerOpen || target === state.playerLandscapeDir) return;
      if (stageGesture || player.classList.contains('to-playlist') || player.classList.contains('dragging')) return;
      setPlayerOrientation(target, { silent: false });
      if (navigator.vibrate) navigator.vibrate(6);
    }, 360);
  }

  function onDeviceOrientation(event) {
    if (!state.playerOpen || state.locked || state.settings.autoLandscape === false) return;
    if (psheet && psheet.classList.contains('open')) return;
    if (window.innerWidth > window.innerHeight) return;
    const gamma = Number(event.gamma);
    if (!Number.isFinite(gamma)) return;
    const magnitude = Math.abs(gamma);
    let next = null;
    if (magnitude >= 55) next = gamma > 0 ? -1 : 1;
    else if (magnitude <= 28) next = 0;
    if (next === null) return;
    queueGyroOrientation(next);
  }

  function attachGyro() {
    if (gyroBound) return;
    gyroBound = true;
    window.addEventListener('deviceorientation', onDeviceOrientation, true);
  }

  function startGyro() {
    if (state.settings.autoLandscape === false) return;
    if (!window.DeviceOrientationEvent) return;
    const ctor = window.DeviceOrientationEvent;
    attachGyro();
    if (typeof ctor.requestPermission === 'function' && gyroPermission === 'ask' && !gyroPermissionPending) {
      gyroPermissionPending = true;
      Promise.resolve(ctor.requestPermission())
        .then((result) => {
          gyroPermission = result === 'granted' ? 'granted' : 'denied';
        })
        .catch(() => {
          gyroPermission = 'ask';
        })
        .finally(() => {
          gyroPermissionPending = false;
        });
    }
  }

  function stopGyro() {
    if (gyroBound) {
      window.removeEventListener('deviceorientation', onDeviceOrientation, true);
      gyroBound = false;
    }
    clearTimeout(gyroCandidateTimer);
    gyroCandidateTimer = null;
    gyroCandidateDir = null;
  }

  function cancelPlayerOpenExpansion() {
    clearTimeout(playerOpenWindowTimer);
    playerOpenWindowTimer = null;
    if (playerOpenWindowAnim) {
      try { playerOpenWindowAnim.cancel(); } catch (_) {}
      playerOpenWindowAnim = null;
    }
    player.classList.remove('window-opening');
    player.style.pointerEvents = '';
    player.style.transform = '';
    player.style.borderRadius = '';
  }

  function expandPlayerWindowFromOrigin(origin) {
    const source = origin && origin.rect;
    const finish = () => {
      clearTimeout(playerOpenWindowTimer);
      playerOpenWindowTimer = null;
      player.classList.remove('window-opening');
      player.style.pointerEvents = '';
      player.style.transform = '';
      player.style.borderRadius = '';
      if (playerOpenWindowAnim) {
        try { playerOpenWindowAnim.cancel(); } catch (_) {}
        playerOpenWindowAnim = null;
      }
    };
    if (!source || !source.width || !source.height
      || typeof player.animate !== 'function'
      || document.body.classList.contains('reduce-motion')) {
      finish();
      return;
    }
    const base = player.getBoundingClientRect();
    if (!base.width || !base.height) {
      finish();
      return;
    }
    const scaleX = source.width / base.width;
    const scaleY = source.height / base.height;
    const dx = source.left + source.width / 2 - (base.left + base.width / 2);
    const dy = source.top + source.height / 2 - (base.top + base.height / 2);
    let completed = false;
    const complete = () => {
      if (completed) return;
      completed = true;
      finish();
    };
    playerOpenWindowAnim = player.animate([
      {
        transform: `translate(${dx}px, ${dy}px) scale(${scaleX}, ${scaleY})`,
        borderRadius: origin.radius || '0px',
      },
      {
        transform: 'translate(0, 0) scale(1, 1)',
        borderRadius: '0px',
      },
    ], { duration: 400, easing: 'cubic-bezier(.22,.61,.36,1)', fill: 'forwards' });
    if (playerOpenWindowAnim.finished && playerOpenWindowAnim.finished.then) {
      playerOpenWindowAnim.finished.then(complete).catch(() => {});
    }
    playerOpenWindowTimer = setTimeout(complete, 520);
  }

  function openPlayer(options = {}) {
    if (!state.loggedIn) {
      showPage('login');
      return;
    }
    const origin = pendingPlayerOrigin;
    pendingPlayerOrigin = null;
    const wasOpen = state.playerOpen;
    cancelPlayerOpenExpansion();
    cancelPlayerCollapse();
    if (videoDetailOpen) closeVideoDetail({ silent: true });
    if (!wasOpen && (state.page === 'up' || upPage.classList.contains('active'))) {
      closeUpPageFromSwipe();
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
    if (!wasOpen) setPlayerOrientation(false, { silent: true });
    hideMiniPlayer();
    clearTimeout(hideTimer);
    setPlayIcon(state.playing);
    updatePlayerLabels();
    player.style.animation = '';
    player.style.transition = '';
    player.style.transform = '';
    player.style.opacity = '';
    player.style.pointerEvents = '';
    player.classList.remove('dragging', 'collapsing', 'window-opening');
    const expandFromRow = Boolean(!wasOpen && origin && origin.rect
      && !document.body.classList.contains('reduce-motion'));
    if (expandFromRow) {
      player.classList.add('window-opening');
      player.style.animation = 'none';
      player.style.pointerEvents = 'none';
    }
    player.classList.add('open');
    player.setAttribute('aria-hidden', 'false');
    player.inert = false;
    player.classList.remove('ui-hidden');
    lockBadge.classList.remove('show');
    updatePlaylistDock();
    closeSheet();
    resetComments();
    hideRateHud(0);
    rotateHud.classList.remove('show');
    showControls();
    startGyro();
    if (expandFromRow) expandPlayerWindowFromOrigin(origin);
    if (window.O11A1Media && typeof window.O11A1Media.onOpen === 'function') {
      window.O11A1Media.onOpen();
    }
  }

  function cancelPlayerCollapse() {
    playerCollapseToken += 1;
    clearTimeout(playerCollapseTimer);
    playerCollapseTimer = null;
    if (playerCollapseAnim) {
      try { playerCollapseAnim.cancel(); } catch (_) {}
      playerCollapseAnim = null;
    }
    if (playerCollapseRadiusAnim) {
      try { playerCollapseRadiusAnim.cancel(); } catch (_) {}
      playerCollapseRadiusAnim = null;
    }
    if (playerPauseRingAnim) {
      try { playerPauseRingAnim.cancel(); } catch (_) {}
      playerPauseRingAnim = null;
    }
    if (playerPauseRing) {
      playerPauseRing.style.borderWidth = '';
      playerPauseRing.style.transition = '';
    }
    player.style.borderRadius = '';
    if (playerDockForced) {
      playlistDock.style.transition = '';
      playlistDock.style.transform = '';
      playlistDock.style.opacity = '';
      playerDockForced = false;
    }
    player.classList.remove('to-playlist');
  }

  function minimizePlayer(fromY = 0, fromScale = 1) {
    if (!state.playerOpen) return;
    const dragRadius = Math.min(28, Math.max(0, parseFloat(player.style.borderRadius) || 0));
    cancelPlayerOpenExpansion();
    cancelPlayerCollapse();
    resetVideoDetail();
    state.playerOpen = false;
    state.locked = false;
    stopGyro();
    clearTimeout(hideTimer);
    const dragY = Number.isFinite(fromY) ? Math.max(0, fromY) : 0;
    const dragScale = Number.isFinite(fromScale) ? Math.min(1, Math.max(0.8, fromScale)) : 1;
    player.classList.remove('dragging');
    player.style.animation = 'none';
    player.style.transition = 'none';
    player.style.transform = 'none';
    player.style.opacity = '1';
    player.style.pointerEvents = 'none';
    player.classList.add('to-playlist');
    player.inert = true;
    lockBadge.classList.remove('show');
    resetComments();
    hideRateHud(0);
    rotateHud.classList.remove('show');
    closeSheet();
    if (player.contains(document.activeElement)) document.activeElement.blur();
    showMiniPlayer();
    updatePlaylistDock();
    let target = null;
    if (playlistDock.classList.contains('show')) {
      playlistDock.classList.remove('receiving', 'absorbing', 'dragging');
      playlistDock.style.transition = 'none';
      playlistDock.style.transform = 'translate(-50%, 0)';
      playlistDock.style.opacity = '1';
      playerDockForced = true;
      target = pdThumb.getBoundingClientRect();
    }
    const base = player.getBoundingClientRect();
    const targetScale = target && base.width
      ? Math.max(0.06, Math.min(1, target.width / base.width))
      : 0.08;
    const endX = target && base.width
      ? target.left + target.width / 2 - (base.left + base.width / 2)
      : 0;
    const endY = target && base.height
      ? target.top + target.height / 2 - (base.top + base.height / 2)
      : base.height * 0.55;
    const token = ++playerCollapseToken;
    let finished = false;
    const complete = () => {
      if (finished || token !== playerCollapseToken) return;
      finished = true;
      clearTimeout(playerCollapseTimer);
      playerCollapseTimer = null;
      if (playerCollapseAnim) {
        try { playerCollapseAnim.cancel(); } catch (_) {}
        playerCollapseAnim = null;
      }
      if (playerCollapseRadiusAnim) {
        try { playerCollapseRadiusAnim.cancel(); } catch (_) {}
        playerCollapseRadiusAnim = null;
      }
      if (playerPauseRingAnim) {
        try { playerPauseRingAnim.cancel(); } catch (_) {}
        playerPauseRingAnim = null;
      }
      if (playerPauseRing) {
        playerPauseRing.style.borderWidth = '';
        playerPauseRing.style.transition = '';
      }
      player.classList.remove('open', 'ui-hidden', 'collapsing', 'to-playlist', 'dragging');
      player.setAttribute('aria-hidden', 'true');
      player.inert = true;
      player.style.animation = '';
      player.style.transition = '';
      player.style.transform = '';
      player.style.opacity = '';
      player.style.borderRadius = '';
      player.style.pointerEvents = '';
      setPlayerOrientation(false, { silent: true });
      if (playerDockForced) {
        playlistDock.style.transition = '';
        playlistDock.style.transform = '';
        playlistDock.style.opacity = '';
        playerDockForced = false;
      }
      absorbPlaylistDock();
    };
    if (typeof player.animate === 'function' && target && target.width > 0) {
      const midScale = dragScale + (targetScale - dragScale) * 0.9;
      if (playerPauseRing && player.classList.contains('paused')) {
        playerPauseRingAnim = playerPauseRing.animate([
          { borderWidth: `${2 / Math.max(0.2, dragScale)}px` },
          { borderWidth: `${2 / Math.max(0.06, targetScale)}px` },
        ], { duration: 540, easing: 'linear', fill: 'forwards' });
      }
      playerCollapseRadiusAnim = player.animate([
        { borderRadius: `${dragRadius}px` },
        { borderRadius: '140px' },
      ], { duration: 540, easing: 'linear', fill: 'forwards' });
      playerCollapseAnim = player.animate([
        {
          transform: `translate(0px, ${dragY}px) scale(${dragScale})`,
          opacity: 1,
        },
        {
          transform: `translate(${endX * 0.9}px, ${endY * 0.9}px) scale(${midScale})`,
          opacity: 1,
          offset: 0.9,
        },
        {
          transform: `translate(${endX}px, ${endY}px) scale(${targetScale})`,
          opacity: 0,
        },
      ], {
        duration: 540,
        easing: 'cubic-bezier(.22,1,.36,1)',
        fill: 'forwards',
      });
      if (playerCollapseAnim.finished && playerCollapseAnim.finished.then) {
        playerCollapseAnim.finished.then(complete).catch(() => {});
      }
      playerCollapseTimer = setTimeout(complete, 650);
    } else {
      player.style.transition = 'none';
      player.style.transform = `translate(0px, ${dragY}px) scale(${dragScale})`;
      player.style.borderRadius = `${dragRadius}px`;
      void player.offsetWidth;
      player.style.transition = 'transform .5s cubic-bezier(.22,1,.36,1),opacity .24s ease .22s,border-radius .54s linear';
      player.style.transform = target
        ? `translate(${endX}px, ${endY}px) scale(${targetScale})`
        : 'translateY(105%) scale(.94)';
      player.style.opacity = '0';
      player.style.borderRadius = '140px';
      if (playerPauseRing && player.classList.contains('paused')) {
        playerPauseRing.style.transition = 'border-width .54s linear';
        playerPauseRing.style.borderWidth = `${2 / Math.max(0.06, targetScale)}px`;
      }
      playerCollapseTimer = setTimeout(complete, 650);
    }
    if (document.fullscreenElement && document.exitFullscreen) {
      document.exitFullscreen().catch(() => {});
    }
    pcFullscreen.classList.remove('on');
    pcFullscreen.title = '全屏';
    if (window.O11A1Media && typeof window.O11A1Media.onMinimize === 'function') {
      window.O11A1Media.onMinimize();
    }
  }

  function stopPlayback() {
    cancelPlayerOpenExpansion();
    cancelPlayerCollapse();
    resetVideoDetail();
    state.playerOpen = false;
    state.miniVisible = false;
    state.playing = false;
    state.progress = 0;
    state.locked = false;
    stopGyro();
    setPlayerOrientation(false, { silent: true });
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
    hideRateHud(0);
    rotateHud.classList.remove('show');
    setPlayIcon(false);
    closeSheet();
    if (document.fullscreenElement && document.exitFullscreen) {
      document.exitFullscreen().catch(() => {});
    }
    pcFullscreen.classList.remove('on');
    pcFullscreen.title = '全屏';
    if (window.O11A1Media && typeof window.O11A1Media.onStop === 'function') {
      window.O11A1Media.onStop();
    }
    updatePlayerLabels();
  }

  function lockPlayer() {
    state.locked = true;
    clearTimeout(hideTimer);
    player.classList.add('ui-hidden');
    playerControls.classList.add('hidden');
    lockBadge.classList.add('show');
    resetComments();
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
    if (window.O11A1Media && typeof window.O11A1Media.togglePlay === 'function'
      && window.O11A1Media.togglePlay()) {
      if (state.playerOpen) showControls();
      return;
    }
    state.playing = !state.playing;
    setPlayIcon(state.playing);
    updateMiniPlayer();
    if (state.playerOpen) showControls();
  }

  function stepTrack(delta) {
    if (!state.playlist.length) return;
    state.currentIndex = (state.currentIndex + delta + state.playlist.length) % state.playlist.length;
    state.progress = 0;
    state.playing = true;
    resetInteractionState();
    updatePlayerLabels();
    save();
    showControls();
    if (window.O11A1Media && typeof window.O11A1Media.onTrackChange === 'function') {
      window.O11A1Media.onTrackChange();
    }
  }

  function cycleLoop() {
    const list = ['循环', '继续', '下一分P', '暂停'];
    state.settings.loop = list[(list.indexOf(state.settings.loop) + 1) % list.length];
    updatePlayerLabels();
    save();
    showControls();
  }

  function openPlayerInfoSheet() {
    if (window.O11A1NativeData && typeof window.O11A1NativeData.playerInfo === 'function') {
      window.O11A1NativeData.playerInfo();
      return;
    }
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
    if (window.O11A1NativeData && typeof window.O11A1NativeData.playerPerf === 'function') {
      window.O11A1NativeData.playerPerf();
      return;
    }
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
    const total = state.duration > 0 ? state.duration : TOTAL_SECONDS;
    const delta = seconds / total * 100;
    setProgress(state.progress + delta, true);
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

  function showRateHud(direction) {
    const restore = state.settings.speed || '1.0×';
    clearTimeout(rateHudTimer);
    rateHudTimer = null;
    rateValue.textContent = direction === 'left' ? '0.5×' : '2.0×';
    rateLabel.textContent = `${direction === 'left' ? '慢放' : '快放'}中 · 松开恢复 ${restore}`;
    rateHud.classList.add('show');
    if (window.O11A1Media && typeof window.O11A1Media.onRateHold === 'function') {
      window.O11A1Media.onRateHold(direction === 'left' ? 0.5 : 2.0);
    }
  }

  function hideRateHud(delay = 0) {
    clearTimeout(rateHudTimer);
    rateHudTimer = setTimeout(() => {
      rateHudTimer = null;
      rateHud.classList.remove('show');
    }, delay);
  }

  /* ---------- main page landscape ---------- */
  function syncLandscape() {
    const landscape = state.landscapeHome;
    app.classList.toggle('landscape', landscape);
    document.body.classList.toggle('landscape', landscape);
    if (homeLandscapeBtn) {
      homeLandscapeBtn.classList.toggle('on', state.landscapeHome);
      homeLandscapeBtn.setAttribute('aria-pressed', state.landscapeHome ? 'true' : 'false');
      homeLandscapeBtn.textContent = state.landscapeHome ? '横屏主页 · 开' : '横屏主页';
    }
  }

  /* ---------- video detail overlay ---------- */
  const detailSkeletonMarkup = videoDetailBody ? videoDetailBody.innerHTML : '';

  function openVideoDetail(fromPeek) {
    if (!videoDetailPanel || !state.playerOpen || videoDetailOpen) return;
    clearTimeout(videoDetailCloseTimer);
    clearTimeout(videoDetailRenderTimer);
    videoDetailOpen = true;
    videoDetailPanel.inert = false;
    videoDetailPanel.classList.remove('closing', 'peeking', 'dragging');
    videoDetailPanel.style.transition = '';
    videoDetailPanel.setAttribute('aria-hidden', 'false');
    if (fromPeek) {
      videoDetailPanel.classList.add('open');
      requestAnimationFrame(() => { videoDetailPanel.style.transform = ''; });
    } else {
      videoDetailPanel.style.transform = '';
      videoDetailPanel.classList.add('open');
    }
    if (videoDetailBody) videoDetailBody.innerHTML = detailSkeletonMarkup;
    videoDetailScroll.scrollTop = 0;
    swipeHint.classList.remove('show', 'left');
    clearTimeout(hideTimer);
    playerControls.classList.add('hidden');
    player.classList.add('ui-hidden');
    videoDetailRenderTimer = setTimeout(() => {
      videoDetailRenderTimer = null;
      if (!videoDetailOpen) return;
      if (window.O11A1NativeData && typeof window.O11A1NativeData.renderVideoDetail === 'function') {
        window.O11A1NativeData.renderVideoDetail();
      }
    }, 320);
  }

  function cancelVideoDetailPeek() {
    if (!videoDetailPanel || videoDetailOpen
      || !videoDetailPanel.classList.contains('peeking')) return;
    videoDetailPanel.classList.remove('peeking');
    videoDetailPanel.classList.add('closing');
    videoDetailPanel.setAttribute('aria-hidden', 'true');
    videoDetailPanel.inert = true;
    videoDetailPanel.style.transform = '';
    clearTimeout(videoDetailCloseTimer);
    videoDetailCloseTimer = setTimeout(() => {
      videoDetailCloseTimer = null;
      videoDetailPanel.classList.remove('closing');
      videoDetailPanel.style.transform = '';
    }, 420);
  }

  function closeVideoDetail(options = {}) {
    if (!videoDetailPanel || !videoDetailOpen) return;
    videoDetailOpen = false;
    videoDetailSwipe = null;
    clearTimeout(videoDetailRenderTimer);
    videoDetailRenderTimer = null;
    videoDetailPanel.inert = true;
    videoDetailPanel.classList.remove('open', 'peeking', 'dragging');
    videoDetailPanel.classList.add('closing');
    videoDetailPanel.setAttribute('aria-hidden', 'true');
    videoDetailPanel.style.transform = 'translateX(calc(-100% - 18px))';
    clearTimeout(videoDetailCloseTimer);
    videoDetailCloseTimer = setTimeout(() => {
      videoDetailCloseTimer = null;
      videoDetailPanel.classList.remove('closing');
      videoDetailPanel.style.transition = '';
      videoDetailPanel.style.transform = '';
    }, 420);
    if (!options.silent) {
      setTimeout(() => {
        if (state.playerOpen && !commentsPanel.classList.contains('open')) showControls();
      }, 160);
    }
  }

  function openUpFromDetail(item) {
    if (!item) return;
    if (videoDetailOpen) closeVideoDetail({ silent: true });
    if (window.O11A1NativeData && typeof window.O11A1NativeData.openUpPage === 'function') {
      window.O11A1NativeData.openUpPage(item);
    }
  }

  function startVideoDetailSwipe(event) {
    if (!videoDetailOpen || !videoDetailPanel) return;
    if (event.button !== undefined && event.button !== 0) return;
    if (event.target.closest('.video-row, button, input, textarea, a')) return;
    videoDetailSwipe = {
      pointerId: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      dx: 0,
      dragging: false,
    };
  }

  function moveVideoDetailSwipe(event) {
    const gesture = videoDetailSwipe;
    if (!gesture || event.pointerId !== gesture.pointerId) return;
    const dx = event.clientX - gesture.startX;
    const dy = event.clientY - gesture.startY;
    if (!gesture.dragging) {
      if (Math.hypot(dx, dy) < 10) return;
      if (dx < 0 && Math.abs(dx) > Math.abs(dy) * 1.2) {
        gesture.dragging = true;
        videoDetailPanel.classList.add('dragging');
      } else {
        return;
      }
    }
    if (event.cancelable) event.preventDefault();
    gesture.dx = Math.min(0, dx);
    videoDetailPanel.style.transform = `translate3d(${gesture.dx}px,0,0)`;
  }

  function endVideoDetailSwipe() {
    const gesture = videoDetailSwipe;
    videoDetailSwipe = null;
    if (!gesture || !gesture.dragging) return;
    videoDetailPanel.classList.remove('dragging');
    if (gesture.dx < -90) {
      closeVideoDetail();
      return;
    }
    videoDetailPanel.style.transition = 'transform .3s cubic-bezier(.16,1,.3,1)';
    videoDetailPanel.style.transform = '';
    setTimeout(() => {
      if (videoDetailOpen) {
        videoDetailPanel.style.transition = '';
        videoDetailPanel.style.transform = '';
      }
    }, 320);
  }

  function resetVideoDetail() {
    videoDetailOpen = false;
    videoDetailSwipe = null;
    clearTimeout(videoDetailCloseTimer);
    clearTimeout(videoDetailRenderTimer);
    videoDetailCloseTimer = null;
    videoDetailRenderTimer = null;
    if (!videoDetailPanel) return;
    videoDetailPanel.classList.remove('open', 'peeking', 'closing', 'dragging');
    videoDetailPanel.style.transition = '';
    videoDetailPanel.style.transform = '';
    videoDetailPanel.setAttribute('aria-hidden', 'true');
    videoDetailPanel.inert = true;
  }

  /* ---------- full-screen comments ---------- */
  function openComments(fromPeek) {
    if (!state.playerOpen) return;
    if (videoDetailOpen) resetVideoDetail();
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
    if (window.O11A1NativeData && typeof window.O11A1NativeData.onComments === 'function') {
      window.O11A1NativeData.onComments(undefined, { opening: true });
    }
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
  function stageZone(event) {
    const rect = playerStage.getBoundingClientRect();
    let ratio;
    if (state.playerLandscape) {
      const centerY = rect.top + rect.height / 2;
      const localX = state.playerLandscapeDir === -1
        ? -(event.clientY - centerY)
        : (event.clientY - centerY);
      ratio = 0.5 + localX / Math.max(1, rect.height);
    } else {
      ratio = (event.clientX - rect.left) / Math.max(1, rect.width);
    }
    if (ratio < 1 / 3) return 'left';
    if (ratio > 2 / 3) return 'right';
    return 'middle';
  }

  function startStageGesture(event) {
    if (!state.playerOpen || state.locked) return;
    if (event.button !== undefined && event.button !== 0) return;
    if (event.target.closest('.player-controls, .player-top, .lock-badge, button, input, textarea')) return;
    if (commentsPanel.classList.contains('open') || videoDetailOpen) return;
    clearTimeout(hideTimer);
    clearTimeout(stageTapTimer);
    stageTapTimer = null;
    const zone = stageZone(event);
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
      lastDy: 0,
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
    const dir = state.playerLandscapeDir;
    const localX = state.playerLandscape ? dy * dir : dx;
    const localY = state.playerLandscape ? -dx * dir : dy;
    gesture.localX = localX;
    gesture.localY = localY;
    gesture.lastDy = localY;
    if (gesture.mode === 'rate' || gesture.longPressFired) return;

    if (!gesture.moved) {
      if (Math.hypot(dx, dy) < 8) return;
      gesture.moved = true;
      clearTimeout(gesture.longPressTimer);
      gesture.longPressTimer = null;
      player.classList.add('gesture-active');
      if (state.settings.swipeComments && Math.abs(localX) > Math.abs(localY) * 1.15) {
        gesture.mode = 'horizontal';
      } else if (gesture.zone === 'middle') {
        if (localY > 0 && state.settings.middleCollapse) gesture.mode = 'collapse';
        else {
          gesture.mode = 'none';
          return;
        }
      } else {
        return;
      }
    }

    if (gesture.mode === 'collapse') {
      const dragY = Math.max(0, localY);
      gesture.collapseY = dragY;
      const scale = 1 - Math.min(0.05, dragY / 3000);
      if (state.playerLandscape) {
        player.style.transform = `scale(${scale})`;
      } else {
        player.style.transform = `translateY(${dragY}px) scale(${scale})`;
      }
      player.style.opacity = '1';
      player.style.borderRadius = `${Math.min(28, dragY * 0.16)}px`;
    } else if (gesture.mode === 'horizontal') {
      gesture.horizontal = localX;
      const rect = playerStage.getBoundingClientRect();
      const localWidth = state.playerLandscape ? rect.height : rect.width;
      if (localX < 0 && state.settings.swipeComments) {
        const progress = Math.min(1, -localX / Math.max(1, localWidth * 0.62));
        commentsPanel.classList.add('peeking');
        commentsPanel.setAttribute('aria-hidden', 'false');
        commentsPanel.inert = true;
        commentsPanel.style.transform = `translateX(${(1 - progress) * 100}%)`;
        player.classList.add('comments-open');
        swipeHint.textContent = '‹ 松开查看评论';
        swipeHint.classList.remove('left');
        swipeHint.classList.toggle('show', -localX > 46);
      } else if (localX > 0 && videoDetailPanel) {
        const progress = Math.min(1, localX / Math.max(1, localWidth * 0.62));
        videoDetailPanel.classList.add('peeking');
        videoDetailPanel.setAttribute('aria-hidden', 'false');
        videoDetailPanel.inert = true;
        videoDetailPanel.style.transform = `translateX(${-(1 - progress) * 100}%)`;
        swipeHint.textContent = '‹ 松开查看详情';
        swipeHint.classList.add('left');
        swipeHint.classList.toggle('show', localX > 46);
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
      if (zone === 'middle') togglePlay();
      else toggleStageControls();
      return;
    }
    lastStageTap = { time: now, zone };
    clearTimeout(stageTapTimer);
    stageTapTimer = setTimeout(() => {
      stageTapTimer = null;
      lastStageTap = { time: 0, zone: '' };
      scheduleHide();
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
      if (window.O11A1Media && typeof window.O11A1Media.onRateHoldEnd === 'function') {
        window.O11A1Media.onRateHoldEnd();
      }
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
        const fromY = state.playerLandscape ? 0 : gesture.collapseY;
        minimizePlayer(fromY, 1 - Math.min(0.05, gesture.collapseY / 3000));
        return;
      }
      player.style.transition = 'transform .24s cubic-bezier(.16,1,.3,1), opacity .2s ease, border-radius .2s ease';
      player.style.transform = 'none';
      player.style.opacity = '1';
      player.style.borderRadius = '0px';
      setTimeout(() => {
        if (state.playerOpen) {
          player.style.transition = '';
          player.style.transform = '';
          player.style.opacity = '';
          player.style.borderRadius = '';
        }
      }, 260);
    } else if (gesture.mode === 'horizontal') {
      if (gesture.horizontal > 70) {
        cancelCommentsPeek();
        openVideoDetail(true);
      } else if (gesture.horizontal < -70) {
        cancelVideoDetailPeek();
        openComments(true);
      } else {
        cancelCommentsPeek();
        cancelVideoDetailPeek();
      }
    }
  }

  /* ---------- comments panel swipe ---------- */
  function startCommentsGesture(event) {
    if (!commentsPanel.classList.contains('open')) return;
    if (event.button !== undefined && event.button !== 0) return;
    if (event.target.closest('button')) return;
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

  /* ---------- external keyboard ---------- */
  const KEYBOARD_MAP = [
    ['空格 / K', '播放 / 暂停'],
    ['← / →', '快退 / 快进 5 秒'],
    ['F', '全屏 / 还原'],
    ['C', '打开 / 关闭评论'],
    ['D', '弹幕开关'],
    ['L', '锁定 / 解锁'],
    ['[ / ]', '减速 / 加速'],
    ['1–6', '画质 4K → 480P'],
    ['P', '截图'],
    ['N / B', '下一个 / 上一个'],
    ['Esc', '关闭面板 / 解锁 / 收起'],
  ];

  function openKeyboardSheet() {
    openSheet('外接键盘', '播放器打开时生效 · 输入框内不拦截', (body) => {
      KEYBOARD_MAP.forEach(([key, action]) => {
        const row = document.createElement('div');
        row.className = 'sheet-row';
        row.innerHTML = `<span class="sr-label">${escapeHTML(action)}</span><span class="sr-value kbd-value">${escapeHTML(key)}</span>`;
        body.appendChild(row);
      });
    });
  }

  function seekRelative(seconds) {
    if (state.locked) return;
    if (!realVideo || !Number.isFinite(realVideo.duration) || realVideo.duration <= 0) return;
    const next = Math.max(0, Math.min(realVideo.duration - 0.15, realVideo.currentTime + seconds));
    realVideo.currentTime = next;
    showControls();
    seekRipple.textContent = `${seconds > 0 ? '+' : ''}${seconds}s`;
    seekRipple.classList.remove('show');
    void seekRipple.offsetWidth;
    seekRipple.classList.add('show');
    clearTimeout(seekRipple._timer);
    seekRipple._timer = setTimeout(() => seekRipple.classList.remove('show'), 520);
  }

  function changeSpeed(delta) {
    const rates = [0.5, 0.75, 1, 1.25, 1.5, 2, 3];
    const current = parseFloat(state.settings.speed || '1') || 1;
    let index = 0;
    let distance = Infinity;
    rates.forEach((rate, i) => {
      const d = Math.abs(rate - current);
      if (d < distance) { distance = d; index = i; }
    });
    const next = rates[Math.max(0, Math.min(rates.length - 1, index + delta))];
    state.settings.speed = `${next.toFixed(2).replace(/0$/, '')}×`;
    save();
    updatePlayerLabels();
    if (realVideo) realVideo.playbackRate = next;
    showControls();
  }

  function handlePlayerKey(event) {
    const target = event.target;
    const typing = target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable);
    if (event.key === 'Escape') {
      if (psheet.classList.contains('open')) { closeSheet(); event.preventDefault(); return; }
      if (commentsPanel.classList.contains('open')) { closeComments(); event.preventDefault(); return; }
      if (state.locked) { unlockPlayer(); event.preventDefault(); return; }
      if (state.playerOpen) { minimizePlayer(); event.preventDefault(); return; }
      return;
    }
    if (typing || !state.playerOpen) return;
    const key = event.key;
    const lower = key.toLowerCase();
    if (key === ' ' || lower === 'k') {
      event.preventDefault(); togglePlay(); showControls(); return;
    }
    if (key === 'ArrowLeft') { event.preventDefault(); seekRelative(-5); return; }
    if (key === 'ArrowRight') { event.preventDefault(); seekRelative(5); return; }
    if (lower === 'f') { event.preventDefault(); toggleFullscreen(); return; }
    if (lower === 'c') { event.preventDefault(); commentsPanel.classList.contains('open') ? closeComments() : openComments(); return; }
    if (lower === 'd') { event.preventDefault(); pcDanmaku.click(); return; }
    if (lower === 'l') { event.preventDefault(); state.locked ? unlockPlayer() : lockPlayer(); return; }
    if (key === '[') { event.preventDefault(); changeSpeed(-1); return; }
    if (key === ']') { event.preventDefault(); changeSpeed(1); return; }
    if (lower === 'p') { event.preventDefault(); pcShot.click(); return; }
    if (lower === 'n') { event.preventDefault(); stepTrack(1); return; }
    if (lower === 'b') { event.preventDefault(); stepTrack(-1); return; }
    if (/^[1-6]$/.test(key)) {
      event.preventDefault();
      const quality = ['4K', '1080P60', '1080P', '720P', '480P', '仅音频'][Number(key) - 1];
      state.settings.quality = quality;
      save();
      updatePlayerLabels();
      if (window.O11A1Media && window.O11A1Media.onQualityChange) window.O11A1Media.onQualityChange(quality);
      showControls();
    }
  }
  window.addEventListener('keydown', handlePlayerKey);

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
        if (window.O11A1NativeData && typeof window.O11A1NativeData.screenshot === 'function') {
          const result = window.O11A1NativeData.screenshot();
          state.shot = result === '已保存';
          return result;
        }
        state.shot = true;
        return '已保存';
      });
      actionRow(body, '点赞', state.liked ? '已点赞' : '', () => {
        if (window.O11A1NativeData && typeof window.O11A1NativeData.like === 'function') {
          return window.O11A1NativeData.like();
        }
        state.liked = !state.liked;
        return state.liked ? '已点赞' : '已取消';
      });
      actionRow(body, state.fav ? '已收藏' : '收藏', state.fav ? '已加入' : '', () => {
        if (window.O11A1NativeData && typeof window.O11A1NativeData.favorite === 'function') {
          return window.O11A1NativeData.favorite();
        }
        state.fav = !state.fav;
        return state.fav ? '已加入' : '已取消';
      });
      actionRow(body, '投币', state.coin ? '已投币' : '2 币', () => {
        if (window.O11A1NativeData && typeof window.O11A1NativeData.coin === 'function') {
          return window.O11A1NativeData.coin();
        }
        state.coin = true;
        return '已投币';
      });
      actionRow(body, '关注 UP', state.followed ? '已关注' : '', () => {
        if (window.O11A1NativeData && typeof window.O11A1NativeData.follow === 'function') {
          return window.O11A1NativeData.follow();
        }
        state.followed = !state.followed;
        return state.followed ? '已关注' : '已取消';
      });
      actionRow(body, '复制链接', state.copied ? '已复制' : 'BV 链接', () => {
        if (window.O11A1NativeData && typeof window.O11A1NativeData.copyLink === 'function') {
          const result = window.O11A1NativeData.copyLink();
          state.copied = result === '已复制';
          return result;
        }
        state.copied = true;
        return '已复制';
      });
      actionRow(body, '缓存', '当前版本暂未接入', () => '暂未接入');
      actionRow(body, '举报', '', () => '暂未接入');
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
    const nativeAccount = (window.O11A1NativeData && window.O11A1NativeData.accountInfo) || {};
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
          { type: 'switch', label: '陀螺仪自动横屏', key: 'autoLandscape', onChange: () => { if (state.settings.autoLandscape) { if (state.playerOpen) startGyro(); } else { stopGyro(); setPlayerOrientation(false); } } },
          { type: 'switch', label: '视频调试 HUD', key: 'debugHud', onChange: updateDebugHud },
          { type: 'switch', label: '视频流刷新率', key: 'feedDebug', onChange: updateDebugHud },
          { type: 'static', label: '解码策略', value: 'WebView 媒体层 · 系统决定' },
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
          { type: 'static', label: '弹幕节拍', value: 'CSS 动画 · 跟随显示刷新' },
        ],
      },
      'settings-download': {
        title: '离线下载',
        sub: '当前版本支持边下边播；离线任务与合流暂未接入',
        rows: [
          { type: 'static', label: '同时任务', value: '2 个' },
          { type: 'switch', label: '仅 Wi-Fi 预加载', key: 'wifiPreload' },
          { type: 'static', label: '离线任务', value: '暂未接入' },
          { type: 'action', label: '打开下载目录', value: '暂未接入', run: () => '暂未接入' },
          { type: 'action', label: '清理已完成', value: '0 个', run: () => '没有已完成任务' },
        ],
      },
      'settings-appearance': {
        title: '外观',
        sub: '浅色 / 深色 / 跟随系统；背景透明度与模糊分别控制',
        rows: [
          { type: 'choice', label: '主题', key: 'theme', options: ['跟随系统', '浅色', '深色'], onChange: applyAppearance },
          { type: 'slider', label: '背景透明度', key: 'bgTransparency', min: 0, max: 100, unit: '%', onChange: applyAppearance },
          { type: 'slider', label: '玻璃模糊', key: 'glassBlur', min: 0, max: 100, unit: '%', onChange: applyAppearance },
          { type: 'slider', label: '背景模糊', key: 'bgBlur', min: 0, max: 100, unit: '%', onChange: applyAppearance },
          { type: 'static', label: '圆角', value: '18 / 24 / 27' },
        ],
      },
      'settings-gesture': {
        title: '手势',
        sub: '中间下滑收起、双击播放/暂停，左右长按减速/加速；陀螺仪自动横屏，亮度与音量交给系统控制',
        rows: [
          { type: 'switch', label: '中间下滑 收起播放器', key: 'middleCollapse' },
          { type: 'static', label: '陀螺仪', value: '自动横屏 / 竖屏' },
          { type: 'static', label: '单击画面', value: '显示工具栏 · 1 秒后自动隐藏' },
          { type: 'switch', label: '左滑 全屏评论', key: 'swipeComments' },
          { type: 'switch', label: '长按左 / 右 减速 / 加速', key: 'longPressRate' },
          { type: 'static', label: '进度条', value: '横向拖动 seek' },
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
          { type: 'static', label: '昵称', value: nativeAccount.name || '未登录' },
          { type: 'static', label: 'UID', value: nativeAccount.mid ? String(nativeAccount.mid) : '—' },
          { type: 'static', label: '等级', value: nativeAccount.loggedIn ? `Lv${nativeAccount.level || 0}` : '—' },
          { type: 'static', label: '大会员', value: nativeAccount.vip ? (nativeAccount.vipLabel || '大会员') : '未开通' },
          { type: 'action', label: '短信登录', value: state.loggedIn ? '已登录' : '未登录', run: () => { closeSheet(); showPage('login'); return '打开登录'; } },
          { type: 'action', label: '打开账户页', value: '账户 / 经验 / 权益', run: () => {
            if (window.O11A1NativeData && typeof window.O11A1NativeData.openAccount === 'function') {
              closeSheet();
              window.O11A1NativeData.openAccount();
              return '已打开';
            }
            return '账户页';
          } },
          { type: 'action', label: '退出登录', value: '', run: () => { logout(); return '已退出'; } },
        ],
      },
      'settings-shortcuts': {
        title: '快捷键',
        sub: '桌面端播放器快捷键；外接键盘可用',
        rows: [
          { type: 'static', label: '播放 / 暂停', value: '空格 / K' },
          { type: 'static', label: '全屏 / 还原', value: 'F / 双击画面' },
          { type: 'static', label: '快退 / 快进', value: '← / →' },
          { type: 'static', label: '弹幕 / 评论 / 锁定', value: 'D / C / L' },
          { type: 'static', label: '画质 / 倍速', value: '1–6 / [ ]' },
          { type: 'action', label: '全部快捷键映射', value: '打开', run: () => { openKeyboardSheet(); return '已打开'; } },
          { type: 'action', label: '恢复默认', value: '', run: () => '键盘映射固定为默认' },
        ],
      },
      'settings-system': {
        title: '系统',
        sub: '移动端只保留适用的项；开机自启 / 托盘仅桌面',
        rows: [
          { type: 'switch', label: '开机自启', key: 'autostart' },
          { type: 'switch', label: '关闭到托盘', key: 'closeToTray' },
          { type: 'switch', label: '自动检查更新', key: 'autoUpdate' },
          { type: 'action', label: '版本', value: '0.2.0 · native', run: () => '当前为测试版' },
        ],
      },
      'settings-block': {
        title: '屏蔽',
        sub: '关键词 / 正则 / 用户；弹幕与评论共用规则',
        rows: [
          { type: 'static', label: '关键词', value: '未设置' },
          { type: 'static', label: '正则', value: '无' },
          { type: 'static', label: '用户', value: '未设置' },
          { type: 'action', label: '添加规则', value: '', run: () => '当前版本暂未接入' },
          { type: 'action', label: '清空规则', value: '', run: () => '已清空' },
        ],
      },
      'settings-cloud': {
        title: '智能云屏蔽',
        sub: '服务端同步的 AI 屏蔽等级',
        rows: [
          { type: 'switch', label: '智能云屏蔽', key: 'cloudBlock' },
          { type: 'slider', label: 'AI 等级', key: 'cloudLevel', min: 0, max: 10 },
          { type: 'action', label: '立即同步', value: '', run: () => '已保存本地设置' },
        ],
      },
      'settings-storage': {
        title: '存储',
        sub: '缓存、离线任务与本地文件',
        rows: [
          { type: 'static', label: '页面缓存', value: '由系统 WebView 管理' },
          { type: 'static', label: '离线任务', value: '暂未接入' },
          { type: 'action', label: '清理缓存', value: '', run: () => '暂未接入' },
          { type: 'action', label: '打开下载目录', value: '', run: () => '暂未接入' },
        ],
      },
      'settings-optimize': {
        title: '优化',
        sub: '预加载与页面预热；硬件解码在移动端强制开启',
        rows: [
          { type: 'switch', label: '后台预加载', key: 'preloadNext' },
          { type: 'switch', label: '缓存下一批推荐', key: 'warmPages' },
          { type: 'static', label: '硬件解码', value: '强制开启' },
          { type: 'static', label: '插帧管线', value: 'WebView 媒体层' },
        ],
      },
      'settings-about': {
        title: '关于 O11A1',
        sub: '移动端 V2 原生桥接版',
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
  const HOT_SEARCHES = ['原神', '崩坏：星穹铁道', '明日方舟', 'B站跨年晚会', 'AI 编程', 'iPhone 17', '黑神话：悟空', '美食探店'];

  function renderHotSearches() {
    if (!hotSearchList) return;
    hotSearchList.innerHTML = HOT_SEARCHES.map((term, index) => `
      <button class="search-chip" type="button" data-search-term="${escapeHTML(term)}">
        <i>${index + 1}</i><span>${escapeHTML(term)}</span>
      </button>`).join('');
  }

  function renderSearchSuggestions(query) {
    if (!searchSuggestList) return;
    const q = query.trim();
    const terms = q
      ? [q, `${q} 教程`, `${q} 4K`, `${q} 合集`, `${q} 最新`]
      : [];
    searchSuggestList.innerHTML = terms.map((term) => `
      <button class="search-suggest" type="button" data-search-term="${escapeHTML(term)}">
        <span>⌕</span><b>${escapeHTML(term)}</b>
      </button>`).join('');
  }

  function updateSearch() {
    const query = searchInput.value.trim();
    const hasQuery = query.length > 0;
    searchClear.hidden = !hasQuery;
    if (searchHotSection) searchHotSection.hidden = hasQuery;
    if (searchSuggestSection) searchSuggestSection.hidden = !hasQuery;
    renderSearchSuggestions(query);
  }

  function renderDockHotSearches() {
    if (!dockHotSearchList) return;
    dockHotSearchList.innerHTML = HOT_SEARCHES.map((term, index) => `
      <button class="search-chip" type="button" data-search-term="${escapeHTML(term)}">
        <i>${index + 1}</i><span>${escapeHTML(term)}</span>
      </button>`).join('');
  }

  function renderDockSearchSuggestions(query) {
    if (!dockSearchSuggestList) return;
    const q = query.trim();
    if (!q) {
      dockSearchSuggestList.innerHTML = '';
      return;
    }
    const terms = [q, `${q} 教程`, `${q} 4K`, `${q} 合集`, `${q} 最新`];
    dockSearchSuggestList.innerHTML = terms.map((term) => `
      <button class="search-suggest" type="button" data-search-term="${escapeHTML(term)}">
        <span>⌕</span><b>${escapeHTML(term)}</b>
      </button>`).join('');
  }

  function updateDockSearch() {
    const query = pdSearchInput ? pdSearchInput.value.trim() : '';
    const hasQuery = query.length > 0;
    if (dockSearchHot) dockSearchHot.hidden = hasQuery;
    if (dockSearchSuggest) dockSearchSuggest.hidden = !hasQuery;
    if (hasQuery) renderDockSearchSuggestions(query);
    else renderDockHotSearches();
  }

  function performSearch(term) {
    const query = String(term || (pdSearchInput && pdSearchInput.value) || searchInput.value || '').trim();
    if (!query) return;
    exitDockSearch();
    setDockExpanded(false);
    searchInput.value = query;
    searchClear.hidden = false;
    state.searchReturn = state.searchReturn && state.searchReturn !== 'search' && state.searchReturn !== 'search-home'
      ? state.searchReturn
      : 'home';
    if (searchResultsPage) {
      searchResultsPage.classList.remove('dragging');
      searchResultsPage.style.transition = '';
      searchResultsPage.style.transform = '';
      searchResultsPage.style.boxShadow = '';
    }
    showPage('search');
    if (searchResultsLabel) searchResultsLabel.textContent = `“${query}”的视频`;
    searchResults.hidden = false;
    searchEmpty.hidden = true;
    searchInput.blur();
    if (window.O11A1NativeData && typeof window.O11A1NativeData.search === 'function') {
      window.O11A1NativeData.search(query);
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
    applyAppearance();
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
    const active = document.activeElement;
    const focused = Boolean(active && (
      active === searchInput
      || active === pdSearchInput
      || active.tagName === 'INPUT'
      || active.tagName === 'TEXTAREA'
      || active.isContentEditable
    ));
    const raw = focused && vv
      ? Math.max(0, window.innerHeight - vv.height - vv.offsetTop)
      : 0;
    const offset = raw > 24 ? Math.round(raw) : 0;
    document.documentElement.style.setProperty('--kb', `${offset}px`);
    document.body.classList.toggle('kb-open', offset > 0);
  }

  if (window.visualViewport) {
    window.visualViewport.addEventListener('resize', syncKeyboardOffset);
    window.visualViewport.addEventListener('scroll', syncKeyboardOffset);
  }
  window.addEventListener('resize', syncKeyboardOffset);
  syncKeyboardOffset();

  function isEditableTarget(target) {
    return Boolean(target && target.closest
      && target.closest('input, textarea, select, [contenteditable="true"]'));
  }

  document.addEventListener('contextmenu', (event) => {
    if (isEditableTarget(event.target)) return;
    event.preventDefault();
  }, true);
  document.addEventListener('selectstart', (event) => {
    if (isEditableTarget(event.target)) return;
    event.preventDefault();
  }, true);
  document.addEventListener('dragstart', (event) => {
    if (isEditableTarget(event.target)) return;
    event.preventDefault();
  }, true);

  /* ---------- event wiring ---------- */
  document.addEventListener('click', (event) => {
    const searchTerm = event.target.closest('[data-search-term]');
    if (searchTerm) {
      event.preventDefault();
      performSearch(searchTerm.dataset.searchTerm);
      return;
    }
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

  if (searchClose) searchClose.addEventListener('click', closeSearch);
  if (searchBack) searchBack.addEventListener('click', closeSearchFromSwipe);
  searchClear.addEventListener('click', () => {
    searchInput.value = '';
    updateSearch();
    searchInput.focus();
  });
  searchInput.addEventListener('input', updateSearch);
  searchInput.addEventListener('focus', syncKeyboardOffset);
  searchInput.addEventListener('blur', syncKeyboardOffset);
  if (pdSearchInput) {
    pdSearchInput.addEventListener('focus', syncKeyboardOffset);
    pdSearchInput.addEventListener('blur', syncKeyboardOffset);
  }
  searchInput.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
      event.preventDefault();
      performSearch(searchInput.value);
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
  const loginSms = $('#loginSms');
  if (loginSms) loginSms.addEventListener('click', openSmsLogin);
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
  pcDanmaku.addEventListener('click', () => {
    state.settings.danmaku = !state.settings.danmaku;
    updatePlayerLabels();
    save();
  });
  pcLoop.addEventListener('click', cycleLoop);
  pcSide.addEventListener('click', openPlayerSideSheet);
  pcSettings.addEventListener('click', openPlayerMoreSheet);
  pcShot.addEventListener('click', () => {
    let ok = false;
    if (window.O11A1NativeData && typeof window.O11A1NativeData.screenshot === 'function') {
      ok = window.O11A1NativeData.screenshot() === '已保存';
    }
    state.shot = ok;
    pcShotValue.textContent = ok ? '已存' : '失败';
    pcShot.classList.toggle('done', ok);
    setTimeout(() => {
      pcShotValue.textContent = '当前帧';
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

  sidebarBackdrop.addEventListener('click', () => {
    if (Date.now() < suppressSidebarClickUntil) return;
    closeSidebar();
  });
  playlistBack.addEventListener('click', () => closePlaylistPage(true));
  playlistPage.addEventListener('pointerdown', (event) => {
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    if (!playlistPage.classList.contains('active')) return;
    if (event.target.closest('button, .pl-remove')) return;
    const header = event.target.closest('.playlist-grab, .playlist-page-top');
    if (!header && appScroll.scrollTop > 0) return;
    playlistDrag = {
      id: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      dy: 0,
      active: false,
      header: Boolean(header),
      lastY: event.clientY,
      lastT: performance.now(),
      velocity: 0,
    };
  });
  window.addEventListener('pointermove', (event) => {
    if (!playlistDrag || event.pointerId !== playlistDrag.id) return;
    const dx = event.clientX - playlistDrag.startX;
    const dy = event.clientY - playlistDrag.startY;
    if (!playlistDrag.active) {
      if (Math.abs(dx) < 8 && Math.abs(dy) < 8) return;
      if (dy < -8 || Math.abs(dx) > Math.abs(dy) * 1.15) {
        playlistDrag = null;
        return;
      }
      if (dy <= 8) return;
      if (!playlistDrag.header && appScroll.scrollTop > 0) {
        playlistDrag = null;
        return;
      }
      playlistDrag.active = true;
      suppressPlaylistClickUntil = Date.now() + 420;
      playlistPage.classList.add('dragging');
      playlistPage.style.transition = 'none';
    }
    if (event.cancelable) event.preventDefault();
    const now = performance.now();
    const elapsed = Math.max(1, now - playlistDrag.lastT);
    playlistDrag.velocity = (event.clientY - playlistDrag.lastY) / elapsed;
    playlistDrag.lastY = event.clientY;
    playlistDrag.lastT = now;
    playlistDrag.dy = Math.max(0, dy);
    applyPlaylistDrag(playlistDrag.dy);
  }, { passive: false });
  window.addEventListener('pointerup', (event) => {
    if (!playlistDrag || event.pointerId !== playlistDrag.id) return;
    const drag = playlistDrag;
    playlistDrag = null;
    if (!drag.active) return;
    if (drag.dy > 90 || drag.velocity > 0.55) closePlaylistWithDrag();
    else resetPlaylistPageDrag();
  });
  window.addEventListener('pointercancel', () => {
    if (!playlistDrag) return;
    playlistDrag = null;
    resetPlaylistPageDrag();
  });
  playlistPage.addEventListener('click', (event) => {
    if (Date.now() < suppressPlaylistClickUntil) {
      event.preventDefault();
      event.stopPropagation();
    }
  }, true);

  function enterDockSearch() {
    if (!pdSearchInput || !playlistDock.classList.contains('show')) return;
    setDockExpanded(false);
    playlistDock.classList.remove('receiving', 'absorbing');
    playlistDock.classList.add('searching');
    pdSearchInput.value = '';
    updateDockSearch();
    void pdSearchInput.offsetWidth;
    try {
      pdSearchInput.focus({ preventScroll: true });
      pdSearchInput.setSelectionRange(0, 0);
    } catch (_) {}
  }

  function exitDockSearch() {
    if (!pdSearchInput) return;
    playlistDock.classList.remove('searching');
    pdSearchInput.blur();
    pdSearchInput.value = '';
  }

  function dockContentTarget() {
    return Math.min(window.innerHeight * 0.55, 540);
  }

  function launchPlayerFromDock() {
    if (!state.playlist.length) {
      setDockExpanded(true);
      return;
    }
    suppressDockClickUntil = Date.now() + 600;
    const rect = playlistDock.getBoundingClientRect();
    const style = getComputedStyle(playlistDock);
    if (!rect.width || !rect.height) {
      openPlayer({ resume: true });
      return;
    }
    const topLeft = style.borderTopLeftRadius || '0px';
    const topRight = style.borderTopRightRadius || topLeft;
    pendingPlayerOrigin = {
      rect,
      radius: `${topLeft} ${topRight} 0 0`,
      time: Date.now(),
    };
    dockLaunching = true;
    clearTimeout(dockLaunchTimer);
    playlistDock.style.pointerEvents = 'none';
    openPlayer({ resume: true });
    dockLaunchTimer = setTimeout(() => {
      dockLaunchTimer = null;
      dockLaunching = false;
      playlistDock.style.pointerEvents = '';
      if (state.playerOpen) setDockExpanded(false);
      updatePlaylistDock();
    }, 460);
  }

  playlistDock.addEventListener('pointerdown', (event) => {
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    if (playlistDock.classList.contains('searching')) return;
    if (event.target.closest('.pd-body')) return;
    if (event.target.closest('button, input, .pd-search, .pd-search-input')) return;
    dockDrag = {
      id: event.pointerId,
      x: event.clientX,
      y: event.clientY,
      dy: 0,
      moved: false,
      expanded: playlistDock.classList.contains('expanded'),
    };
  });
  window.addEventListener('pointermove', (event) => {
    if (!dockDrag || event.pointerId !== dockDrag.id) return;
    const dy = event.clientY - dockDrag.y;
    dockDrag.dy = dy;
    if (Math.abs(dy) > 6) dockDrag.moved = true;
    if (!dockDrag.moved) return;
    if (!playlistDock.classList.contains('dragging')) playlistDock.classList.add('dragging');
    const target = dockContentTarget();
    const startContent = dockDrag.expanded ? target : 88;
    const content = Math.max(88, Math.min(target, startContent - dy));
    const progress = (content - 88) / Math.max(1, target - 88);
    playlistDock.style.height = `calc(${content.toFixed(1)}px + env(safe-area-inset-bottom))`;
    const radius = 24 + progress * 10;
    playlistDock.style.borderTopLeftRadius = `${radius.toFixed(1)}px`;
    playlistDock.style.borderTopRightRadius = `${radius.toFixed(1)}px`;
    playlistDock.style.boxShadow = `0 -${(10 + progress * 20).toFixed(0)}px ${(28 + progress * 28).toFixed(0)}px rgba(20,22,30,${(0.10 + progress * 0.11).toFixed(2)})`;
  });
  window.addEventListener('pointerup', (event) => {
    if (!dockDrag || event.pointerId !== dockDrag.id) return;
    const gesture = dockDrag;
    dockDrag = null;
    playlistDock.classList.remove('dragging');
    if (!gesture.moved) return;
    suppressDockClickUntil = Date.now() + 420;
    let expanded = gesture.expanded;
    if (!gesture.expanded && gesture.dy < -52) expanded = true;
    if (gesture.expanded && gesture.dy > 52) expanded = false;
    setDockExpanded(expanded);
  });
  window.addEventListener('pointercancel', () => {
    if (!dockDrag) return;
    const wasExpanded = dockDrag.expanded;
    dockDrag = null;
    setDockExpanded(wasExpanded);
  });
  playlistDock.addEventListener('click', (event) => {
    if (playlistDock.classList.contains('searching')) return;
    if (event.target.closest('.pd-search, .pd-search-input, .pd-body')) return;
    if (Date.now() < suppressDockClickUntil) return;
    launchPlayerFromDock();
  });
  playlistDock.addEventListener('keydown', (event) => {
    if (event.target !== playlistDock) return;
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      if (playlistDock.classList.contains('searching')) return;
      if (Date.now() < suppressDockClickUntil) return;
      launchPlayerFromDock();
    }
  });
  if (pdSearch) {
    pdSearch.addEventListener('click', (event) => {
      event.stopPropagation();
      enterDockSearch();
    });
  }
  if (pdSearchBack) {
    pdSearchBack.addEventListener('click', (event) => {
      event.stopPropagation();
      exitDockSearch();
    });
  }
  if (pdSearchInput) {
    pdSearchInput.addEventListener('click', (event) => event.stopPropagation());
    pdSearchInput.addEventListener('input', updateDockSearch);
    pdSearchInput.addEventListener('keydown', (event) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        exitDockSearch();
        return;
      }
      if (event.key !== 'Enter') return;
      event.preventDefault();
      const query = pdSearchInput.value.trim();
      if (!query) return;
      exitDockSearch();
      performSearch(query);
    });
    pdSearchInput.addEventListener('blur', () => {
      setTimeout(() => {
        if (document.activeElement !== pdSearchInput) {
          playlistDock.classList.remove('searching');
        }
      }, 120);
    });
  }

  function startFeedGesture(event, surface) {
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    if (event.target.closest('input, textarea')) return;
    if (app.classList.contains('sidebar-open')) return;
    const row = event.target.closest('.video-row');
    rowSwipe = {
      id: event.pointerId,
      x: event.clientX,
      y: event.clientY,
      row,
      wrapper: row ? row.closest('.feed-item') : null,
      offset: 0,
      direction: null,
      surface,
      sidebarActive: false,
      sidebarProgress: 0,
      sidebarSelecting: false,
      sidebarHoldTimer: null,
      sidebarLastX: event.clientX,
      sidebarLastY: event.clientY,
    };
  }

  document.addEventListener('click', (event) => {
    if (state.playerOpen) return;
    if (Date.now() < suppressFeedClickUntil) return;
    const row = event.target.closest('.video-row');
    if (!row) return;
    const thumb = row.querySelector('.row-thumb');
    if (!thumb) return;
    const rect = thumb.getBoundingClientRect();
    if (!rect.width || !rect.height) return;
    const origin = {
      thumb,
      rect,
      radius: getComputedStyle(thumb).borderRadius || '0px',
      time: Date.now(),
    };
    pendingPlayerOrigin = origin;
    setTimeout(() => {
      if (pendingPlayerOrigin === origin) pendingPlayerOrigin = null;
    }, 900);
  }, true);
  appScroll.addEventListener('pointerdown', (event) => startFeedGesture(event, 'scroll'));
  if (upPage) upPage.addEventListener('pointerdown', (event) => startFeedGesture(event, 'up'));
  if (searchResultsPage) searchResultsPage.addEventListener('pointerdown', (event) => startFeedGesture(event, 'search'));
  if (videoDetailScroll) videoDetailScroll.addEventListener('pointerdown', (event) => startFeedGesture(event, 'detail'));
  window.addEventListener('pointermove', (event) => {
    if (!rowSwipe || event.pointerId !== rowSwipe.id) return;
    const dx = event.clientX - rowSwipe.x;
    const dy = event.clientY - rowSwipe.y;
    if (!rowSwipe.direction) {
      if (Math.abs(dx) < 8 && Math.abs(dy) < 8) return;
      if (Math.abs(dy) > Math.abs(dx) * 1.15) {
        rowSwipe.direction = 'vertical';
        return;
      }
      if (dx > 8) {
        if (rowSwipe.surface === 'detail') {
          rowSwipe.direction = 'vertical';
          return;
        }
        if (state.page === 'search' && searchResultsPage) {
          rowSwipe.direction = 'search-close';
          rowSwipe.searchOffset = 0;
          searchResultsPage.classList.add('dragging');
          return;
        }
        if (rowSwipe.surface === 'up') {
          rowSwipe.direction = 'up-close';
          rowSwipe.upOffset = 0;
          upPage.classList.add('up-dragging');
          upPage.style.transition = 'none';
          return;
        }
        if (!beginSidebarDrag()) {
          rowSwipe.direction = 'vertical';
          return;
        }
        rowSwipe.direction = 'right';
        rowSwipe.sidebarActive = true;
        applySidebarDrag(0);
        rowSwipe.sidebarHoldTimer = setTimeout(() => {
          if (!rowSwipe || rowSwipe.direction !== 'right' || rowSwipe.sidebarProgress < 0.18) return;
          rowSwipe.sidebarSelecting = true;
          sidebar.classList.add('selecting');
          beginSidebarSelect(rowSwipe);
        }, 240);
        return;
      }
      if (dx < -8) {
        if (!rowSwipe.wrapper) {
          rowSwipe.direction = 'vertical';
          return;
        }
        rowSwipe.direction = 'left';
        rowSwipe.wrapper.classList.add('swiping');
      }
    }
    if (rowSwipe.direction === 'search-close') {
      if (event.cancelable) event.preventDefault();
      const width = app.clientWidth || window.innerWidth;
      const offset = Math.max(0, Math.min(width, dx));
      rowSwipe.searchOffset = offset;
      searchResultsPage.style.transform = `translate3d(${offset}px,0,0)`;
      searchResultsPage.style.boxShadow = offset > 0 ? '-18px 0 46px rgba(10,12,20,.18)' : '';
      return;
    }
    if (rowSwipe.direction === 'up-close') {
      if (event.cancelable) event.preventDefault();
      const width = app.clientWidth || window.innerWidth;
      const offset = Math.max(0, Math.min(width, dx));
      rowSwipe.upOffset = offset;
      upPage.style.transform = `translate3d(${offset}px,0,0)`;
      upPage.style.boxShadow = offset > 0 ? '-18px 0 46px rgba(10,12,20,.18)' : '';
      return;
    }
    if (rowSwipe.direction === 'right') {
      if (event.cancelable) event.preventDefault();
      rowSwipe.sidebarLastX = event.clientX;
      rowSwipe.sidebarLastY = event.clientY;
      const width = app.clientWidth || window.innerWidth;
      const progress = Math.min(1, Math.max(0, dx / (width * 0.5)));
      rowSwipe.sidebarProgress = progress;
      applySidebarDrag(progress);
      if (rowSwipe.sidebarSelecting) moveSidebarSelect(rowSwipe, event.clientY);
      return;
    }
    if (rowSwipe.direction !== 'left') return;
    if (event.cancelable) event.preventDefault();
    const offset = Math.min(ROW_ACTION_MAX, Math.max(0, -dx));
    rowSwipe.offset = offset;
    setRowSwipe(rowSwipe.wrapper, offset);
  }, { passive: false });
  window.addEventListener('pointerup', (event) => {
    if (!rowSwipe || event.pointerId !== rowSwipe.id) return;
    const start = rowSwipe;
    rowSwipe = null;
    if (start.direction === 'right') {
      endSidebarDrag(start, event);
      return;
    }
    if (start.direction === 'search-close') {
      suppressFeedClickUntil = Date.now() + 420;
      const width = app.clientWidth || window.innerWidth;
      if ((start.searchOffset || 0) > width * 0.24) closeSearchFromSwipe();
      else resetSearchResultsDrag();
      return;
    }
    if (start.direction === 'up-close') {
      suppressFeedClickUntil = Date.now() + 420;
      const width = app.clientWidth || window.innerWidth;
      if ((start.upOffset || 0) > width * 0.24) closeUpPageFromSwipe();
      else resetUpPageDrag();
      return;
    }
    if (start.direction !== 'left') return;
    suppressFeedClickUntil = Date.now() + 420;
    const action = rowActionForOffset(start.offset);
    if (action) {
      triggerRowAction(start.wrapper, action);
      return;
    }
    resetRowSwipe(start.wrapper);
  });
  window.addEventListener('pointercancel', () => {
    const start = rowSwipe;
    rowSwipe = null;
    if (!start) return;
    if (start.direction === 'right') endSidebarDrag(start, { type: 'pointercancel' });
    else if (start.direction === 'left') resetRowSwipe(start.wrapper);
    else if (start.direction === 'up-close') resetUpPageDrag();
    else if (start.direction === 'search-close') resetSearchResultsDrag();
  });

  appScroll.addEventListener('scroll', maybeAppendMockFeed);

  function resetSearchDrag() {
    if (!searchHomePage) return;
    searchHomePage.classList.remove('dragging');
    searchHomePage.style.transition = '';
    searchHomePage.style.transform = '';
    searchHomePage.style.opacity = '';
  }

  function closeSearchWithDrag() {
    if (!searchHomePage) {
      closeSearch();
      return;
    }
    searchHomePage.style.transition = 'transform .24s cubic-bezier(.4,0,1,1),opacity .2s ease';
    searchHomePage.style.transform = 'translateY(-105%)';
    searchHomePage.style.opacity = '0';
    setTimeout(() => {
      resetSearchDrag();
      closeSearch();
    }, 220);
  }

  if (searchHomePage) {
    searchHomePage.addEventListener('pointerdown', (event) => {
      if (event.pointerType === 'mouse' && event.button !== 0) return;
      if (event.target.closest('button')) return;
      searchDrag = { id: event.pointerId, y: event.clientY, dy: 0 };
      searchHomePage.classList.add('dragging');
      searchHomePage.style.transition = 'none';
    });
    window.addEventListener('pointermove', (event) => {
      if (!searchDrag || event.pointerId !== searchDrag.id) return;
      const dy = Math.min(0, event.clientY - searchDrag.y);
      searchDrag.dy = dy;
      searchHomePage.style.transform = `translateY(${dy}px)`;
      searchHomePage.style.opacity = String(Math.max(0.25, 1 + dy / 320));
      if (dy < -4 && event.cancelable) event.preventDefault();
    }, { passive: false });
    window.addEventListener('pointerup', (event) => {
      if (!searchDrag || event.pointerId !== searchDrag.id) return;
      const dy = searchDrag.dy;
      searchDrag = null;
      if (dy < -70) closeSearchWithDrag();
      else resetSearchDrag();
    });
    window.addEventListener('pointercancel', () => {
      if (!searchDrag) return;
      searchDrag = null;
      resetSearchDrag();
    });
  }

  function sidebarCloseGesture(event) {
    if (sidebarSwipeStart && sidebarSwipeStart.id === event.pointerId) return sidebarSwipeStart;
    if (menuSwipeStart && menuSwipeStart.id === event.pointerId) return menuSwipeStart;
    return null;
  }

  function moveSidebarCloseDrag(start, event) {
    if (!start) return;
    const dx = event.clientX - start.x;
    const dy = event.clientY - start.y;
    if (!start.active) {
      if (start.vertical) return;
      if (Math.abs(dx) < 8 && Math.abs(dy) < 8) return;
      if (dx >= 0 || Math.abs(dy) > Math.abs(dx) * 1.15) {
        start.vertical = true;
        return;
      }
      start.active = true;
      app.classList.add('sidebar-dragging');
      sidebar.classList.remove('selecting');
    }
    if (event.cancelable) event.preventDefault();
    const width = app.clientWidth || window.innerWidth;
    const progress = Math.max(0, Math.min(1, 1 + dx / (width * 0.5)));
    start.progress = progress;
    applySidebarDrag(progress);
  }

  function endSidebarCloseDrag(start) {
    if (!start) return;
    suppressSidebarClickUntil = Date.now() + 360;
    if (start.progress < 0.78) closeSidebarFromDrag();
    else finishSidebarDrag();
  }

  sidebar.addEventListener('pointerdown', (event) => {
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    sidebarSwipeStart = {
      id: event.pointerId,
      x: event.clientX,
      y: event.clientY,
      progress: 1,
      active: false,
      vertical: false,
    };
  });
  sidebarBackdrop.addEventListener('pointerdown', (event) => {
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    menuSwipeStart = {
      id: event.pointerId,
      x: event.clientX,
      y: event.clientY,
      progress: 1,
      active: false,
      vertical: false,
    };
  });
  window.addEventListener('pointermove', (event) => {
    const start = sidebarCloseGesture(event);
    if (start) moveSidebarCloseDrag(start, event);
  }, { passive: false });
  window.addEventListener('pointerup', (event) => {
    const start = sidebarCloseGesture(event);
    if (!start) return;
    if (start === sidebarSwipeStart) sidebarSwipeStart = null;
    if (start === menuSwipeStart) menuSwipeStart = null;
    if (start.active) {
      suppressFeedClickUntil = Date.now() + 420;
      endSidebarCloseDrag(start);
      return;
    }
    const dx = event.clientX - start.x;
    const dy = event.clientY - start.y;
    if (dx < -56 && Math.abs(dx) > Math.abs(dy) * 1.4) {
      suppressSidebarClickUntil = Date.now() + 360;
      closeSidebarFromDrag();
    }
  });
  sidebar.addEventListener('click', (event) => {
    if (Date.now() < suppressSidebarClickUntil) {
      event.preventDefault();
      event.stopPropagation();
    }
  }, true);
  window.addEventListener('pointercancel', (event) => {
    const start = sidebarCloseGesture(event);
    if (!start) return;
    if (start === sidebarSwipeStart) sidebarSwipeStart = null;
    if (start === menuSwipeStart) menuSwipeStart = null;
    if (start.active) finishSidebarDrag();
  });

  playerStage.addEventListener('pointerdown', startStageGesture);
  playerStage.addEventListener('pointerdown', () => {
    if (state.playerOpen) startGyro();
  }, { passive: true });
  window.addEventListener('pointermove', moveStageGesture);
  window.addEventListener('pointerup', endStageGesture);
  window.addEventListener('pointercancel', endStageGesture);

  player.addEventListener('pointerdown', (event) => {
    if (!state.playerOpen || commentsPanel.classList.contains('open')) return;
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    showControls();
  }, true);
  player.addEventListener('pointermove', (event) => {
    if (!state.playerOpen || commentsPanel.classList.contains('open')) return;
    if (event.pointerType === 'mouse' && event.buttons === 0) return;
    scheduleHide();
  }, { passive: true });
  player.addEventListener('input', () => {
    if (state.playerOpen) scheduleHide();
  });
  playerTop.addEventListener('click', (event) => {
    if (!state.playerOpen) return;
    if (event.target.closest('button')) return;
    showControls();
  });

  commentsPanel.addEventListener('pointerdown', startCommentsGesture);
  if (videoDetailPanel) {
    videoDetailPanel.addEventListener('pointerdown', startVideoDetailSwipe);
    videoDetailPanel.addEventListener('click', (event) => {
      if (Date.now() < suppressFeedClickUntil) return;
      if (!event.target.closest('.video-row')) return;
      setTimeout(() => {
        if (videoDetailOpen) closeVideoDetail();
      }, 40);
    }, true);
  }
  window.addEventListener('pointermove', moveVideoDetailSwipe);
  window.addEventListener('pointerup', endVideoDetailSwipe);
  window.addEventListener('pointercancel', endVideoDetailSwipe);
  window.addEventListener('pointermove', moveCommentsGesture);
  window.addEventListener('pointerup', endCommentsGesture);
  window.addEventListener('pointercancel', endCommentsGesture);

  progressBar.addEventListener('click', (event) => {
    const rect = progressBar.getBoundingClientRect();
    const percent = (event.clientX - rect.left) / rect.width * 100;
    setProgress(percent, true);
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
      enterDockSearch();
      return;
    }
    if (event.key === 'Escape') {
      if (sidebar.classList.contains('open')) { closeSidebar(); return; }
      if (commentsPanel.classList.contains('open')) { closeComments(); return; }
      if (psheet.classList.contains('open')) { closeSheet(); return; }
      if (protoDrawer.classList.contains('open')) { closeDrawer(); return; }
      if (state.playerOpen) { minimizePlayer(); return; }
      if (state.page === 'search' || state.page === 'search-home') { closeSearch(); return; }
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

  /* ---------- native host bridge (Android WebView) ---------- */
  window.O11A1Host = {
    state,
    app,
    showPage,
    openPlayer,
    minimizePlayer,
    stopPlayback,
    updatePlayerLabels,
    updatePlaylistDock,
    updatePlaylistCounts,
    addToPlaylist,
    setCurrent,
    save,
    setProgress,
    togglePlay,
    stepTrack,
    resetInteractionState,
    openSheet,
    actionRow,
    closeSheet,
    openSettingsSheet,
    activeFeed,
    refreshPlaylistPage,
    isFeedClickSuppressed: () => Date.now() < suppressFeedClickUntil,
    openComments,
    closeVideoDetail,
    openUpFromDetail,
    playerVideo,
    playerTitle,
    playerSub,
    pcPlay,
    setPlayIcon,
    pcTime,
    pdTitle,
    pdMeta,
    pdProgress,
    homeFeed,
    searchResults,
    searchResultsLabel,
    searchEmpty,
    searchInput,
    moduleFeed,
    commentsBody,
    loginStatus,
    playlistDock,
  };

  /* init */
  document.body.dataset.platform = state.platform;
  app.classList.toggle('auth-gate', !state.loggedIn);
  $$('#platformSwitch button').forEach((button) => {
    button.classList.toggle('on', button.dataset.platform === state.platform);
  });
  applyAppearance();
  applyHiddenEntries();
  updatePlayerLabels();
  renderHotSearches();
  updateSearch();
  syncLandscape();
  initDebugHud();
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
    await sleep(80);
    if (typeof DeviceOrientationEvent === 'function') {
      window.dispatchEvent(new DeviceOrientationEvent('deviceorientation', { alpha: 0, beta: 0, gamma: 85 }));
      await sleep(520);
      const gyroLandscape = state.playerLandscape === true;
      window.dispatchEvent(new DeviceOrientationEvent('deviceorientation', { alpha: 0, beta: 90, gamma: 0 }));
      await sleep(520);
      results.push(`gyro=${gyroLandscape && state.playerLandscape === false}`);
    } else {
      results.push('gyro=skip');
    }

    await sleep(140);
    dispatchSwipe('middle', 0, -150);
    results.push(`noRotate=${state.playerLandscape === false}`);

    await sleep(180);
    dispatchSwipe('middle', 0, 190);
    results.push(`collapsed=${!state.playerOpen && state.miniVisible}`);

    await sleep(420);
    openPlayer({ resume: true });
    await sleep(360);
    dispatchSwipe('middle', 240, 0);
    await sleep(650);
    results.push(`detail=${videoDetailPanel.classList.contains('open')}`);
    results.push(`detailRows=${videoDetailBody.querySelectorAll('.feed-item').length >= 4}`);
    const detailRect = videoDetailPanel.getBoundingClientRect();
    const detailStartX = detailRect.left + detailRect.width * 0.62;
    const detailStartY = detailRect.top + 120;
    videoDetailPanel.dispatchEvent(pointerEvent('pointerdown', detailStartX, detailStartY, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', detailStartX - (150 * step) / 6, detailStartY, 1));
    }
    window.dispatchEvent(pointerEvent('pointerup', detailStartX - 150, detailStartY, 0));
    await sleep(500);
    results.push(`detailClose=${!videoDetailPanel.classList.contains('open')}`);
    dispatchSwipe('middle', -240, 0);
    results.push(`comments=${commentsPanel.classList.contains('open')}`);
    results.push(`commentsClean=${!commentsPanel.querySelector('.comments-top, .comments-input')}`);

    closeComments();
    await sleep(380);

    const hold = pressStage('right');
    await sleep(430);
    results.push(`rate=${rateHud.classList.contains('show') && rateValue.textContent === '2.0×'}`);
    hold.release();
    await sleep(320);
    results.push(`rateEnd=${!rateHud.classList.contains('show')}`);

    const tap = stagePoint('middle');
    playerStage.dispatchEvent(pointerEvent('pointerdown', tap.x, tap.y, 1));
    window.dispatchEvent(pointerEvent('pointerup', tap.x, tap.y, 0));
    await sleep(80);
    const toolbarShown = !playerControls.classList.contains('hidden');
    await sleep(2300);
    results.push(`toolbarHide=${toolbarShown && playerControls.classList.contains('hidden')}`);
    showControls();

    minimizePlayer();
    await sleep(420);
    results.push(`dock=${playlistDock.classList.contains('show')}`);
    const dockRect = playlistDock.getBoundingClientRect();
    const dockX = dockRect.left + dockRect.width * 0.45;
    const dockY = dockRect.top + Math.min(50, dockRect.height * 0.5);
    playlistDock.dispatchEvent(pointerEvent('pointerdown', dockX, dockY, 1));
    window.dispatchEvent(pointerEvent('pointermove', dockX, dockY - 24, 1));
    window.dispatchEvent(pointerEvent('pointermove', dockX, dockY - 82, 1));
    window.dispatchEvent(pointerEvent('pointerup', dockX, dockY - 82, 0));
    await sleep(480);
    const dockExpanded = playlistDock.classList.contains('expanded') && state.page !== 'playlist';
    results.push(`dockExpand=${dockExpanded}`);
    openPlaylistPage();
    await sleep(480);
    const playlistOpened = state.page === 'playlist';
    const grab = $('#playlistGrab');
    const grabRect = grab.getBoundingClientRect();
    const grabX = grabRect.left + grabRect.width / 2;
    const grabY = grabRect.top + grabRect.height / 2;
    grab.dispatchEvent(pointerEvent('pointerdown', grabX, grabY, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', grabX, grabY + (140 * step) / 6, 1));
    }
    window.dispatchEvent(pointerEvent('pointerup', grabX, grabY + 140, 0));
    await sleep(520);
    results.push(`playlistSwipe=${playlistOpened && state.page !== 'playlist'}`);

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
    const sideRect = sidebar.getBoundingClientRect();
    const sideX = sideRect.left + sideRect.width * 0.5;
    const sideY = sideRect.top + sideRect.height * 0.5;
    sidebar.dispatchEvent(pointerEvent('pointerdown', sideX, sideY, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', sideX - (120 * step) / 6, sideY, 1));
    }
    window.dispatchEvent(pointerEvent('pointerup', sideX - 120, sideY, 0));
    await sleep(120);
    results.push(`sidebarClose=${!sidebar.classList.contains('open')}`);
    if (sidebar.classList.contains('open')) closeSidebar();

    const row = $('#homeFeed .video-row');
    const countBefore = state.playlist.length;
    const rowRect = row.getBoundingClientRect();
    const rowY = rowRect.top + rowRect.height / 2;
    const rowX = rowRect.left + rowRect.width / 2;
    row.dispatchEvent(pointerEvent('pointerdown', rowX, rowY, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', rowX - (42 * step) / 6, rowY, 1));
    }
    window.dispatchEvent(pointerEvent('pointerup', rowX - 42, rowY, 0));
    await sleep(220);
    results.push(`rowQueue=${state.playlist.length > countBefore}`);
    if (state.playlist.length > countBefore) {
      state.playlist.pop();
      state.currentIndex = Math.min(state.currentIndex, Math.max(0, state.playlist.length - 1));
      updatePlayerLabels();
      updatePlaylistCounts();
      save();
    }

    const upRow = $('#homeFeed .video-row');
    const upRect = upRow.getBoundingClientRect();
    const upY = upRect.top + upRect.height / 2;
    const upX = upRect.left + upRect.width / 2;
    upRow.dispatchEvent(pointerEvent('pointerdown', upX, upY, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', upX - (260 * step) / 6, upY, 1));
    }
    window.dispatchEvent(pointerEvent('pointerup', upX - 260, upY, 0));
    await sleep(560);
    results.push(`rowUp=${state.page === 'up' && $$('#upFeed .real-row').length > 0}`);
    const upOverlay = $('.page[data-page="up"]');
    const upOverlayRect = upOverlay.getBoundingClientRect();
    const upOverlayX = upOverlayRect.left + upOverlayRect.width * 0.5;
    const upOverlayY = upOverlayRect.top + Math.min(120, upOverlayRect.height * 0.3);
    upOverlay.dispatchEvent(pointerEvent('pointerdown', upOverlayX, upOverlayY, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', upOverlayX + (150 * step) / 6, upOverlayY, 1));
    }
    window.dispatchEvent(pointerEvent('pointerup', upOverlayX + 150, upOverlayY, 0));
    await sleep(420);
    results.push(`upBack=${state.page === 'home'}`);

    const chunksBefore = Array.from(new Set($$('#homeFeed [data-chunk]').map((row) => row.dataset.chunk)));
    const rowsBefore = $$('#homeFeed .video-row').length;
    appScroll.scrollTop = appScroll.scrollHeight;
    appScroll.dispatchEvent(new Event('scroll'));
    await sleep(900);
    const chunksAfter = Array.from(new Set($$('#homeFeed [data-chunk]').map((row) => row.dataset.chunk)));
    const rowsAfter = $$('#homeFeed .video-row').length;
    results.push(`feedWindow=${chunksAfter.length === 2 && rowsAfter > rowsBefore}`);

    appScroll.scrollTop = appScroll.scrollHeight;
    appScroll.dispatchEvent(new Event('scroll'));
    await sleep(900);
    const chunksNext = Array.from(new Set($$('#homeFeed [data-chunk]').map((row) => row.dataset.chunk)));
    results.push(`feedSlide=${chunksNext.length === 2 && !chunksNext.includes(chunksBefore[0] || '1')}`);

    const sideStartX = appScroll.getBoundingClientRect().left + 60;
    const sideStartY = appScroll.getBoundingClientRect().top + appScroll.getBoundingClientRect().height * 0.5;
    appScroll.dispatchEvent(pointerEvent('pointerdown', sideStartX, sideStartY, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', sideStartX + (160 * step) / 6, sideStartY, 1));
    }
    await sleep(320);
    const sideItems = $$('.sidebar-nav .sidebar-item', sidebar);
    const homeRow = sideItems.find((row) => row.dataset.nav === 'home');
    const pickVisible = Boolean($('.sidebar-item.picked'));
    const initialPick = pickVisible ? $('.sidebar-item.picked').dataset.nav : '';
    const sideStep = Math.min(320, Math.max(180, window.innerHeight * 0.28)) / Math.max(1, sideItems.length - 1);
    const sideTravel = Math.round(sideStep * 4 + 4);
    window.dispatchEvent(pointerEvent('pointermove', sideStartX + 160, sideStartY + sideTravel, 1));
    await sleep(80);
    const sidePickedRow = $('.sidebar-item.picked');
    const sideTargetPicked = Boolean(sidePickedRow && sidePickedRow !== homeRow);
    window.dispatchEvent(pointerEvent('pointerup', sideStartX + 160, sideStartY + sideTravel, 0));
    await sleep(460);
    results.push(`sidebarPick=${pickVisible && initialPick === 'home'}`);
    results.push(`sidebarSelect=${sideTargetPicked && !sidebar.classList.contains('open') && state.page !== 'home'}`);

    document.title = `SELFTEST ${results.join(' ')}`;
  }

  const reviewParams = new URLSearchParams(window.location.search);
  const demo = reviewParams.get('demo');
  if (window.O11A1Native && typeof window.O11A1Native.setOrientation === 'function') {
    try { window.O11A1Native.setOrientation('portrait'); } catch (_) {}
  }
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
  } else if (demo === 'feed') {
    setTimeout(() => {
      appScroll.scrollTop = appScroll.scrollHeight;
      appScroll.dispatchEvent(new Event('scroll'));
    }, 700);
  } else if (demo === 'queue') {
    setTimeout(() => {
      const row = $('#homeFeed .video-row');
      if (row) addFeedRowToPlaylist(row);
    }, 700);
  } else if (demo === 'rate') {
    openPlayer();
    setTimeout(() => {
      showRateHud('right');
      hideRateHud(9000);
    }, 220);
  }
  if (reviewParams.has('selftest')) setTimeout(runGestureSelfTest, 400);
})();

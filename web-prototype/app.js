(() => {
  const $ = (selector, root = document) => root.querySelector(selector);
  const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));

  const app = $('#app');
  const appMain = $('.app-main');
  const appScroll = $('#appScroll');
  const homeFeed = $('#homeFeed');
  const moduleFeed = $('#moduleFeed');
  const player = $('#player');
  const playerStage = $('#playerStage');
  const playerRotor = $('#playerRotor');
  const playerBody = $('.player-body');
  const playerControls = $('#playerControls');
  const pcPlay = $('#pcPlay');
  const pcQuality = $('#pcQuality');
  const pcQualityValue = $('#pcQualityValue');
  const pcDanmaku = $('#pcDanmaku');
  const pcDanmakuValue = $('#pcDanmakuValue');
  const pcLoop = $('#pcLoop');
  const pcLoopValue = $('#pcLoopValue');
  const progressBar = $('#progressBar');
  const gridProgress = $('#gridProgress');
  const wheelStrip = $('#wheelStrip');
  const seekBubble = $('#seekBubble');
  const playerSettings = $('#playerSettings');
  const playerSettingsCard = $('#playerSettingsCard');
  const playerSettingsScrim = $('#playerSettingsScrim');
  const playerDrop = $('#playerDrop');
  const playerDropZones = playerDrop ? $$('.player-drop-zone', playerDrop) : [];
  const seekRipple = $('#seekRipple');
  const lockBadge = $('#lockBadge');
  const rateHud = $('#rateHud');
  const rateValue = $('#rateValue');
  const rateLabel = $('#rateLabel');
  const playerNotice = $('#playerNotice');
  const playerNoticeTitle = $('#playerNoticeTitle');
  const playerNoticeText = $('#playerNoticeText');
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
  const psheet = $('#psheet');
  const psheetBackdrop = $('#psheetBackdrop');
  const psheetTitle = $('#psheetTitle');
  const psheetSub = $('#psheetSub');
  const psheetBody = $('#psheetBody');
  const psheetClose = $('#psheetClose');
  const homeNote = $('#homeNote');
  const sidebar = $('#sidebar');
  const sidebarBackdrop = $('#sidebarBackdrop');
  const sidebarNav = $('#sidebarNav');
  const sidebarFoot = $('#sidebarFoot');
  const floatToolbar = $('#floatToolbar');
  const searchBack = $('#searchBack');
  const searchHotSection = $('#searchHotSection');
  const searchSuggestSection = $('#searchSuggestSection');
  const hotSearchList = $('#hotSearchList');
  const searchSuggestList = $('#searchSuggestList');
  const searchResultsBlock = $('#searchResultsBlock');
  const searchPanel = $('#searchPanel');
  const searchPanelBody = $('#searchPanelBody');
  const playlistDock = $('#playlistDock');
  const dockBackdrop = $('#dockBackdrop');
  const playlistPage = $('.page[data-page="playlist"]');
  const upPage = $('.page[data-page="up"]');
  const myPage = $('.page[data-page="my"]');
  const pdCollapsed = $('#pdCollapsed');
  const pdDisc = $('#pdDisc');
  const pdDiscArt = $('#pdDiscArt');
  const pdTitle = $('#pdTitle');
  const pdMeta = $('#pdMeta');
  const pdProgress = $('#pdProgress');
  const pdTools = $('#pdTools');
  const pdMode = $('#pdMode');
  const pdModeValue = $('#pdModeValue');
  const pdClear = $('#pdClear');
  const pdSearch = $('#pdSearch');
  const pdSearchInput = $('#pdSearchInput');
  const pdSearchBack = $('#pdSearchBack');
  const dockSearchHot = $('#dockSearchHot');
  const dockSearchPanel = $('#dockSearchPanel');
  const dockSearchSuggest = $('#dockSearchSuggest');
  const dockHotSearchList = $('#dockHotSearchList');
  const dockSearchSuggestList = $('#dockSearchSuggestList');
  const searchResultsPage = $('#searchPanel');
  const dockPlaylistBody = $('#dockPlaylistBody');
  const dockPlaylistList = $('#dockPlaylistList');
  const playlistPageList = $('#playlistPageList');
  const playlistPageCount = $('#playlistPageCount');
  const playlistPageHint = $('.playlist-page-hint');
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
  const loginStart = $('#loginStart');
  const loginCid = $('#loginCid');
  const loginPhone = $('#loginPhone');
  const loginCode = $('#loginCode');
  const loginSend = $('#loginSend');
  const loginSubmit = $('#loginSubmit');
  const searchClear = $('#searchClear');
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

  const NAV_ITEMS = [
    { id: 'live', label: '直播', icon: 'live', type: 'module', target: '直播', group: '移动端' },
    { id: 'bangumi', label: '番剧', icon: 'bangumi', type: 'module', target: '番剧', group: '移动端' },
    { id: 'messages', label: '消息', icon: 'messages', type: 'page', target: 'messages', group: '移动端' },
    { id: 'history', label: '历史', icon: 'history', type: 'module', target: '历史', group: '移动端' },
    { id: 'my', label: '用户', icon: 'my', type: 'page', target: 'my', group: '移动端' },
  ];

  const BOTTOM_NAV_ITEMS = [
    { id: 'home', label: '推荐', icon: 'home', type: 'page', target: 'home' },
    { id: 'follow', label: '关注', icon: 'follow', type: 'module', target: '关注' },
    { id: 'dynamic', label: '动态', icon: 'dynamic', type: 'page', target: 'dynamic' },
    { id: 'search', label: '搜索', icon: 'search', type: 'search' },
  ];

  const NAV_ICONS = {
    home: '<path d="M3.5 10.7 12 3.5l8.5 7.2V20a1 1 0 0 1-1 1h-5v-6h-5v6h-5a1 1 0 0 1-1-1z"/>',
    favorite: '<path d="M6.5 3.5h11a1 1 0 0 1 1 1v16l-6.5-4-6.5 4v-16a1 1 0 0 1 1-1z"/>',
    fish: '<path d="M3.5 12c2.4-3.1 5.5-4.6 9.1-4.6 3.1 0 5.7 1.5 7.9 4.6-2.2 3.1-4.8 4.6-7.9 4.6-3.6 0-6.7-1.5-9.1-4.6z"/><path d="M3.5 12 1.5 8.7v6.6L3.5 12z"/><circle cx="15.8" cy="10.5" r="0.8" fill="currentColor" stroke="none"/>',
    live: '<rect x="3" y="4.5" width="18" height="12.5" rx="2"/><path d="m10 8 5 2.75L10 13.5z"/><path d="M8.5 21h7M12 17v4"/>',
    bangumi: '<rect x="3" y="4.5" width="18" height="15" rx="2"/><path d="M7.5 4.5v15M16.5 4.5v15"/><path d="M3 9h4.5M3 14.5h4.5M16.5 9H21M16.5 14.5H21"/>',
    dynamic: '<path d="M3 12h3.4l2.4-5.8 4.4 11.6 2.4-5.8H21"/>',
    messages: '<path d="M4 4.5h16a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H9l-5 4v-4a1 1 0 0 1-1-1v-10a1 1 0 0 1 1-1z"/><path d="M8 9h8M8 12.5h5"/>',
    history: '<path d="M3.2 12a8.8 8.8 0 1 0 2.7-6.3"/><path d="M3 4.2v4.4h4.4"/><path d="M12 7.4V12l3.1 1.9"/>',
    follow: '<circle cx="10" cy="8" r="3.2"/><path d="M4 20a6 6 0 0 1 12 0"/><path d="M18 7v6M15 10h6"/>',
    search: '<circle cx="11" cy="11" r="6.5"/><path d="m16 16 4.5 4.5"/>',
    my: '<circle cx="12" cy="8" r="3.8"/><path d="M4.5 21v-1.5A5.5 5.5 0 0 1 10 14h4a5.5 5.5 0 0 1 5.5 5.5V21"/>',
  };

  function navIcon(name) {
    const body = NAV_ICONS[name];
    if (!body) return '';
    return `<svg class="nav-svg" viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${body}</svg>`;
  }

  function sidebarIconMarkup(item) {
    if (item.id === 'my' && state.userFace) {
      return `<img class="nav-avatar" src="${escapeHTML(state.userFace)}" alt="">`;
    }
    return navIcon(item.icon);
  }

  function refreshUserNav() {
    $$('.sidebar-item[data-nav="my"] .sidebar-ico').forEach((icon) => {
      icon.innerHTML = sidebarIconMarkup({ id: 'my', icon: 'my' });
    });
    const launchAvatar = document.getElementById('launchAvatar');
    if (launchAvatar && state.userFace) {
      launchAvatar.style.backgroundImage = `url("${String(state.userFace).replace(/"/g, '%22')}")`;
      launchAvatar.textContent = '';
    }
    const launchName = document.getElementById('launchName');
    if (launchName && state.userName) launchName.textContent = state.userName;
  }

  const DEFAULT_NAV_SELECTED = ['home', 'favorite', 'dynamic', 'messages', 'my'];
  const PAGE_NAV = { home: 'home', search: 'search', dynamic: 'dynamic', messages: 'messages', my: 'my' };

  const DEFAULT_SETTINGS = {
    defaultQuality: '最高',
    quality: '1080P',
    speed: '1.0×',
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

  let prefsPostTimer = null;

  const loaded = (() => {
    try {
      if (new URLSearchParams(window.location.search).has('reset')) {
        localStorage.removeItem(STORAGE_KEY);
      }
      if (!localStorage.getItem(STORAGE_KEY)
        && typeof window.__O11A1_SAVED_PREFS__ === 'string'
        && window.__O11A1_SAVED_PREFS__.length > 2) {
        localStorage.setItem(STORAGE_KEY, window.__O11A1_SAVED_PREFS__);
      }
    } catch (_) {}
    return loadPersisted();
  })();

  const state = {
    page: 'home',
    loggedIn: loaded?.loggedIn === true,
    userFace: typeof loaded?.userFace === 'string' ? loaded.userFace : '',
    userName: typeof loaded?.userName === 'string' ? loaded.userName : '',
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
    streamInfo: { videoBitrate: 0, audioBitrate: 0, sourceWidth: 0, sourceHeight: 0, frameRate: 0, netBps: 0, netAt: 0, direct: false },
    availableQualities: [],
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
    searchOpen: false,
    searchReturn: 'home',
    searchReturnNav: null,
    myReturn: 'home',
    myReturnNav: null,
    playlistReturn: 'home',
    playlistReturnNav: null,
  };

  /* Native UserDefaults is a second copy of the theme choice; it survives a
     changed loopback origin or a cleared WKWebView storage. */
  /* Only use the native theme copy when no Web state exists. A valid seeded
     state (including the theme) is newer and must win over a stale setting. */
  if (!loaded) {
    const nativeThemeSetting = window.__O11A1_THEME_SETTING__;
    if (nativeThemeSetting === '浅色' || nativeThemeSetting === '深色' || nativeThemeSetting === '跟随系统') {
      state.settings.theme = nativeThemeSetting;
    } else if (window.__O11A1_THEME_FALLBACK__ === 'light'
      || window.__O11A1_THEME_FALLBACK__ === 'dark') {
      state.settings.theme = window.__O11A1_THEME_FALLBACK__ === 'dark' ? '深色' : '浅色';
    }
  }
  if (loaded?.bgStyleVersion !== 2) {
    state.settings.bgTransparency = 0;
    state.settings.bgBlur = 100;
  }
  if (loaded?.playbackVersion !== 3) {
    state.settings.quality = '1080P';
    state.playbackVersion = 3;
    save();
  }
  if (!state.modules.some((mod) => mod.id === state.moduleId && mod.on)) {
    state.moduleId = state.modules.find((mod) => mod.on)?.id || null;
  }
  if (state.currentIndex >= state.playlist.length) {
    state.currentIndex = Math.max(0, state.playlist.length - 1);
  }
  /* Playlist feature retired: never restore or keep a queue across launches. */
  state.playlist = [];
  state.currentIndex = 0;

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
  let dockClearArmed = false;
  let dockClearTimer = null;
  let stageGesture = null;
  let stageTapTimer = null;
  let lastStageTap = { time: 0, zone: '' };
  let playerSettingsOpen = false;
  let settingsDrawGesture = null;
  let settingsListTouch = null;
  let settingsSuppressClick = false;
  let sheetSwipe = null;
  let sheetSwipeSuppressClickUntil = 0;
  let sheetSwipeTimer = null;
  let precisionDrag = null;
  let gridDrag = null;
  let wheelDragBasis = null;
  const GRID_CELLS = 36;
  let gridCells = [];
  let rateHudTimer = null;
  let playerNoticeTimer = null;
  let gyroBound = false;
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
  let playerMediaOpenTimer = null;
  let playerMediaOpenToken = 0;
  let playerPrefetchTimer = null;
  let playerCollapseAnim = null;
  let playerCollapseRadiusAnim = null;
  let playerCollapseTimer = null;
  let playerCollapseToken = 0;
  let playerDockForced = false;
  let playerDropZone = null;
  let playerDropHideTimer = null;
  let playerDropExitToken = 0;
  let playerDropExitAnim = null;
  let playerDropControlsVisible = false;
  let panelTransitionGuardUntil = 0;
  let rowSwipe = null;
  let sidebarPicked = null;
  let menuSwipeStart = null;
  let searchDrag = null;
  let sidebarSwipeStart = null;
  let sidebarSettleRaf = 0;
  let sidebarCompact = window.matchMedia('(max-width:760px)').matches;
  window.addEventListener('resize', () => {
    sidebarCompact = window.matchMedia('(max-width:760px)').matches;
  });
  let suppressFeedClickUntil = 0;
  let suppressSidebarClickUntil = 0;
  let suppressSidebarBackdropUntil = 0;
  let suppressPlaylistClickUntil = 0;
  let suppressDockClickUntil = 0;
  let dockDismissClickUntil = 0;
  let suppressDetailClickUntil = 0;
  let dockLaunching = false;
  let dockLaunchTimer = null;
  let dockDrag = null;
  let dockBodyTouch = null;
  let dockAbsorbTimer = null;
  let pdSearchPressTimer = null;
  let dockSearchDrag = null;
  let dockSearchTouch = null;
  let dockSearchPullTimer = null;
  let suppressDockSearchClickUntil = 0;
  let playlistDrag = null;
  let playlistRowPress = null;
  let playlistRowSwipe = null;
  let playlistRowSwipeSuppressClickUntil = 0;
  let playlistRowReorder = null;
  let playlistRowReorderSuppressClickUntil = 0;
  let toolbarDrag = null;
  let mockFeedLoading = false;
  let mockFeedLoadedAt = 0;

  const FEED_PREFETCH = 900;
  const ROW_ACTION_ARM = 24;
  const ROW_ACTION_MAX = 230;
  const ROW_ACTION_HOLD_MS = 460;
  const ROW_ACTION_HOLD_SLOP = 7;

  const MODULE_NOTES = {
    收藏: '真实收藏夹 · 第一页 20 条',
    历史: '真实观看历史 · 触底翻页',
    关注: '关注的 UP 主动态',
    养鱼: '入口默认隐藏',
    会员: '账号大会员状态',
    番剧: '番剧 / 国创 / 电影',
    影视: '电影 / 纪录片 / 电视剧',
    直播: '直播推荐 · HLS',
    分区: '分区最新投稿',
  };

  const DYNAMIC_FILTERS = ['全部', '视频', '图文'];
  const MESSAGE_FILTERS = ['回复', '@', '赞', '私信'];
  const MODULE_FILTERS = ['全部', '最新', '热门'];

  const QUALITY_FALLBACK_OPTIONS = [
    { label: '4K 超清', value: '4K' },
    { label: '1080P60', value: '1080P60' },
    { label: '1080P 高码', value: '1080P+' },
    { label: '1080P 高清', value: '1080P' },
    { label: '720P60', value: '720P60' },
    { label: '720P', value: '720P' },
    { label: '480P', value: '480P' },
    { label: '仅音频', value: '仅音频' },
  ];
  const QUALITY_ORDER = {
    '8K': 127, '杜比': 126, 'HDR': 125, '4K': 120,
    '2160P': 120, '1440P': 112,
    '1080P60': 116, '1080P+': 112, '1080P': 80,
    '720P60': 74, '720P': 64, '480P': 32, '360P': 16, '240P': 6,
    '仅音频': 0, '最高': 999,
  };
  const QUALITY_DISPLAY = {
    '8K': '8K 超清', '杜比': '杜比视界', 'HDR': 'HDR 真彩', '4K': '4K 超清',
    '2160P': '2160P', '1440P': '1440P',
    '1080P60': '1080P60', '1080P+': '1080P 高码', '1080P': '1080P 高清',
    '720P60': '720P60', '720P': '720P', '480P': '480P', '360P': '360P',
    '240P': '240P', '仅音频': '仅音频', '最高': '最高（视频支持的最高）',
  };

  function qualityDisplay(value) {
    return QUALITY_DISPLAY[value] || String(value || '');
  }

  /* Resolutions must come from the current video's accept_quality list, not a
     fixed menu. The selected value is kept in the list even if it was carried
     over from another video so it can still be shown/disabled. */
  function qualityOptionValues() {
    const list = Array.isArray(state.availableQualities)
      ? state.availableQualities.filter((value) => value && value !== '最高')
      : [];
    const values = list.slice();
    const current = state.settings.quality;
    if (current && current !== '最高' && !values.includes(current)) values.push(current);
    values.sort((a, b) => (QUALITY_ORDER[b] || 0) - (QUALITY_ORDER[a] || 0));
    return values;
  }

  const sheetData = {
    quality: {
      title: '画质',
      sub: () => {
        const available = Array.isArray(state.availableQualities) ? state.availableQualities : [];
        const base = '当前视频提供的分辨率 · 高画质需要大会员';
        return available.length ? `${base} · 可用：${available.join(' / ')}` : base;
      },
      options: () => {
        const values = qualityOptionValues();
        if (!values.length) return QUALITY_FALLBACK_OPTIONS.slice();
        return values.map((value) => ({ label: qualityDisplay(value), value }));
      },
      selected: () => state.settings.quality,
      available: () => (Array.isArray(state.availableQualities) && state.availableQualities.length
        ? state.availableQualities
        : null),
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
  };

  const pcPanels = {
    quality: {
      group: $('#pcQualityGroup'),
      row: $('#pcQuality'),
      panel: $('#pcQualityPanel'),
      data: sheetData.quality,
    },
    danmaku: {
      group: $('#pcDanmakuGroup'),
      row: $('#pcDanmaku'),
      panel: $('#pcDanmakuPanel'),
      data: null,
    },
  };
  const pcOpenPanels = new Set();

  function renderPcChoicePanel(panel, data) {
    if (!panel || !data) return;
    panel.innerHTML = '';
    const available = typeof data.available === 'function' ? data.available() : null;
    const options = typeof data.options === 'function' ? data.options() : data.options;
    (options || []).forEach((option) => {
      const blocked = Array.isArray(available) && available.length > 0
        && !available.includes(option.value)
        && option.value !== data.selected();
      const button = document.createElement('button');
      button.type = 'button';
      button.className = `pc-choice${data.selected() === option.value ? ' on' : ''}${blocked ? ' off' : ''}`;
      button.textContent = option.label;
      button.disabled = blocked;
      if (blocked) button.title = '当前视频不支持该画质';
      button.addEventListener('click', () => {
        data.apply(option.value);
        renderPcChoicePanel(panel, data);
      });
      panel.appendChild(button);
    });
  }

  function renderPcDanmakuPanel(panel) {
    if (!panel) return;
    panel.innerHTML = '';
    settingsDefinition('settings-danmaku').rows
      .filter((row) => row.type !== 'static')
      .forEach((row) => panel.appendChild(buildSettingRow(row)));
  }

  function ensureQualityOptions() {
    const api = window.O11A1NativeData;
    if (!api || typeof api.ensureQualityOptions !== 'function') return;
    try { api.ensureQualityOptions(); } catch (_) {}
  }

  function refreshQualityChoices() {
    if (pcOpenPanels.has('quality')) {
      renderPcChoicePanel(pcPanels.quality.panel, pcPanels.quality.data);
    }
    if (!psheetBody || !psheet.classList.contains('open')
      || psheetBody.dataset.settingsId !== 'settings-playback') return;
    const def = settingsDefinition('settings-playback');
    if (!def) return;
    $$('.choice-btn', psheetBody).forEach((button) => {
      const row = def.rows.find((item) => (
        item.type === 'choice' && item.key === button.dataset.choiceKey
      ));
      if (!row || typeof row.available !== 'function') return;
      const blocked = row.available(button.dataset.choiceValue) === false;
      button.disabled = blocked;
      button.classList.toggle('off', blocked);
      if (blocked) button.title = '当前视频不支持该画质';
      else button.removeAttribute('title');
    });
  }

  function setPcPanel(name) {
    const opening = !pcOpenPanels.has(name);
    if (opening && name === 'quality') ensureQualityOptions();
    pcOpenPanels.clear();
    if (opening) pcOpenPanels.add(name);
    Object.entries(pcPanels).forEach(([key, config]) => {
      const open = pcOpenPanels.has(key);
      config.group.classList.toggle('open', open);
      config.row.setAttribute('aria-expanded', open ? 'true' : 'false');
      if (!open) return;
      if (key === 'danmaku') renderPcDanmakuPanel(config.panel);
      else renderPcChoicePanel(config.panel, config.data);
    });
  }

  function closePcPanels() {
    pcOpenPanels.clear();
    Object.values(pcPanels).forEach((config) => {
      config.group.classList.remove('open');
      config.row.setAttribute('aria-expanded', 'false');
    });
  }

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

  function postNativePrefs(payload) {
    try {
      if (window.ReactNativeWebView && typeof window.ReactNativeWebView.postMessage === 'function') {
        window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'prefs', data: payload }));
      }
    } catch (_) {}
  }

  function scheduleNativePrefs(payload) {
    clearTimeout(prefsPostTimer);
    prefsPostTimer = setTimeout(() => {
      prefsPostTimer = null;
      postNativePrefs(payload);
    }, 120);
  }

  function flushNativePrefs() {
    clearTimeout(prefsPostTimer);
    prefsPostTimer = null;
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) postNativePrefs(raw);
    } catch (_) {}
  }

  function save() {
    try {
      const modules = {};
      state.modules.forEach((mod) => { modules[mod.id] = mod.on; });
      const payload = JSON.stringify({
        loggedIn: state.loggedIn,
        userFace: state.userFace,
        userName: state.userName,
        platform: state.platform,
        moduleId: state.moduleId,
        modules,
        playlist: state.playlist,
        currentIndex: state.currentIndex,
        settings: state.settings,
        navAllVisible: state.navAllVisible,
        navSelected: state.navSelected,
        bgStyleVersion: 2,
        playbackVersion: 3,
        savedAt: Date.now(),
      });
      localStorage.setItem(STORAGE_KEY, payload);
      scheduleNativePrefs(payload);
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

  let statusBarTone = '';
  function syncStatusBarStyle() {
    let light = false;
    try {
      light = app.classList.contains('player-open') || resolvedTheme() === 'dark';
    } catch (_) {}
    const tone = light ? 'light' : 'dark';
    if (tone === statusBarTone) return;
    statusBarTone = tone;
    try {
      if (window.ReactNativeWebView && typeof window.ReactNativeWebView.postMessage === 'function') {
        window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'statusbar', style: tone }));
      }
    } catch (_) {}
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
    style.setProperty('--wallpaper-opacity', (0.12 + (100 - bg) / 100 * 0.78).toFixed(3));
    style.setProperty('--wallpaper-blur', `${(bgBlur / 100 * 60).toFixed(1)}px`);
    style.setProperty('--glass-blur', `blur(${(glass / 100 * 30).toFixed(1)}px) saturate(${dark ? 1.25 : 1.6})`);
    style.setProperty('--topbar-blur', `blur(${(glass / 100 * 26).toFixed(1)}px) saturate(1.5)`);
    const glassAlpha = 0.5 + (100 - glass) / 100 * 0.38;
    const sheetAlpha = 0.62 + (100 - glass) / 100 * 0.3;
    if (dark) {
      style.setProperty('--glass-bg', ios
        ? `linear-gradient(135deg,rgba(24,25,30,${(glassAlpha + 0.02).toFixed(2)}),rgba(15,16,19,${(glassAlpha - 0.14).toFixed(2)}))`
        : `rgba(24,25,30,${glassAlpha.toFixed(2)})`);
      style.setProperty('--glass-border', 'rgba(255,255,255,.10)');
      style.setProperty('--sheet-bg', `rgba(24,25,30,${sheetAlpha.toFixed(2)})`);
      style.setProperty('--sheet-border', 'rgba(255,255,255,.10)');
      style.setProperty('--topbar-bg', `linear-gradient(180deg,rgba(15,16,19,${(sheetAlpha + 0.04).toFixed(2)}),rgba(15,16,19,${(sheetAlpha - 0.28).toFixed(2)}))`);
      style.setProperty('--topbar-border', 'rgba(255,255,255,.08)');
    } else {
      style.setProperty('--glass-bg', ios
        ? `linear-gradient(135deg,rgba(255,252,246,${(glassAlpha + 0.16).toFixed(2)}),rgba(255,252,246,${(glassAlpha - 0.12).toFixed(2)}))`
        : `rgba(255,252,246,${glassAlpha.toFixed(2)})`);
      style.setProperty('--glass-border', 'rgba(31,28,23,.10)');
      style.setProperty('--sheet-bg', `rgba(255,252,246,${sheetAlpha.toFixed(2)})`);
      style.setProperty('--sheet-border', 'rgba(31,28,23,.10)');
      style.setProperty('--topbar-bg', `linear-gradient(180deg,rgba(243,239,231,${(sheetAlpha + 0.04).toFixed(2)}),rgba(243,239,231,${(sheetAlpha - 0.3).toFixed(2)}))`);
      style.setProperty('--topbar-border', 'rgba(31,28,23,.08)');
    }
    const meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute('content', dark ? '#0F1013' : '#F3EFE7');
    syncStatusBarStyle();
    try {
      if (window.ReactNativeWebView && typeof window.ReactNativeWebView.postMessage === 'function') {
        window.ReactNativeWebView.postMessage(JSON.stringify({
          type: 'theme', theme, setting: state.settings.theme,
        }));
      }
    } catch (_) {}
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
    return NAV_ITEMS.filter((item) => {
      if (state.settings.hideFish && item.id === 'fish') return false;
      if (state.settings.hideLive && item.id === 'live') return false;
      if (state.settings.hideBangumi && item.id === 'bangumi') return false;
      return true;
    });
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
        <span class="sidebar-ico">${sidebarIconMarkup(item)}</span>
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

  let floatToolbarIndicator = null;
  let floatIndicatorFrame = 0;

  function syncFloatToolbarIndicator() {
    if (!floatToolbar) return;
    if (!floatToolbarIndicator || !floatToolbarIndicator.isConnected) {
      floatToolbarIndicator = floatToolbar.querySelector('.float-tool-indicator');
    }
    if (!floatToolbarIndicator) return;
    const active = floatToolbar.querySelector('.float-tool.on');
    if (!active || !active.offsetWidth) {
      floatToolbarIndicator.style.opacity = '0';
      return;
    }
    floatToolbarIndicator.style.opacity = '1';
    floatToolbarIndicator.style.width = `${active.offsetWidth}px`;
    floatToolbarIndicator.style.transform = `translateX(${active.offsetLeft}px)`;
  }

  function scheduleFloatToolbarIndicator() {
    if (floatIndicatorFrame) cancelAnimationFrame(floatIndicatorFrame);
    floatIndicatorFrame = requestAnimationFrame(() => {
      floatIndicatorFrame = 0;
      syncFloatToolbarIndicator();
    });
  }

  function updateNavActive() {
    $$('.sidebar-item', sidebar).forEach((row) => {
      row.classList.toggle('on', row.dataset.nav === state.navActive);
    });
    if (floatToolbar) {
      $$('.float-tool', floatToolbar).forEach((row) => {
        row.classList.toggle('on', row.dataset.navTool === state.navActive);
      });
      scheduleFloatToolbarIndicator();
    }
  }

  function renderFloatToolbar() {
    if (!floatToolbar) return;
    floatToolbar.innerHTML = '';
    BOTTOM_NAV_ITEMS.forEach((item) => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'float-tool';
      button.dataset.navTool = item.id;
      button.innerHTML = `<svg viewBox="0 0 24 24" aria-hidden="true">${NAV_ICONS[item.icon] || ''}</svg><span>${escapeHTML(item.label)}</span>`;
      button.addEventListener('click', () => handleNav(item, button));
      floatToolbar.appendChild(button);
    });
    floatToolbarIndicator = document.createElement('span');
    floatToolbarIndicator.className = 'float-tool-indicator';
    floatToolbarIndicator.setAttribute('aria-hidden', 'true');
    floatToolbar.appendChild(floatToolbarIndicator);
    updateNavActive();
    scheduleFloatToolbarIndicator();
  }

  renderFloatToolbar();
  window.addEventListener('resize', scheduleFloatToolbarIndicator);

  function openSidebar() {
    if (!state.loggedIn) {
      showPage('login');
      return;
    }
    stopFeedPreview();
    cancelSidebarSettle();
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
    try { window.__sidebarCloseDebug = { at: Date.now(), stack: String((new Error()).stack || '') }; } catch (_) {}
    cancelSidebarSettle();
    appMain.style.transform = '';
    appMain.style.borderRadius = '';
    appMain.style.boxShadow = '';
    sidebar.style.transform = '';
    sidebarBackdrop.style.opacity = '';
    app.classList.remove('sidebar-dragging');
    sidebar.classList.remove('open');
    sidebarBackdrop.classList.remove('show');
    sidebar.setAttribute('aria-hidden', 'true');
    sidebar.inert = true;
    app.classList.remove('sidebar-open');
    updatePlaylistDock();
    if (sidebar.contains(document.activeElement)) document.activeElement.blur();
    setTimeout(refreshFeedPreview, 420);
  }

  function stopFeedPreview() {
    if (window.O11A1Host && typeof window.O11A1Host.stopFeedPreview === 'function') {
      window.O11A1Host.stopFeedPreview();
    }
  }

  function refreshFeedPreview() {
    if (window.O11A1Host && typeof window.O11A1Host.updateFeedPreview === 'function') {
      window.O11A1Host.updateFeedPreview();
    }
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
    if (state.page === item.target && item.target !== 'login') {
      // Re-selecting the current page from the sidebar must not reset the feed.
      if (item.id) {
        state.navActive = item.id;
        updateNavActive();
      }
      return;
    }
    showPage(item.target, item.id);
  }

  function showSearchHome() {
    if (searchResultsBlock) searchResultsBlock.hidden = true;
    if (searchResults) searchResults.hidden = true;
    if (searchEmpty) searchEmpty.hidden = true;
    if (searchHotSection) searchHotSection.hidden = false;
    if (searchSuggestSection) searchSuggestSection.hidden = true;
    if (searchPanelBody) searchPanelBody.scrollTop = 0;
    updateSearch();
  }

  function showSearchResults(query) {
    const value = String(query || '').trim();
    if (searchResultsBlock) searchResultsBlock.hidden = false;
    if (searchResults) searchResults.hidden = false;
    if (searchEmpty) searchEmpty.hidden = true;
    if (searchHotSection) searchHotSection.hidden = true;
    if (searchSuggestSection) searchSuggestSection.hidden = true;
    if (searchResultsLabel) searchResultsLabel.textContent = value ? `“${value}”的视频` : '热门视频';
    if (searchPanelBody) searchPanelBody.scrollTop = 0;
  }

  let searchDismissing = false;
  let searchOpeningTimer = null;
  let searchDismissTimer = null;
  let keyboardSyncFrame = 0;

  function openSearch() {
    stopFeedPreview();
    if (!state.loggedIn) {
      showPage('login');
      return;
    }
    if (!searchPanel) return;
    if (state.searchOpen) {
      focusSearchInput();
      return;
    }
    if (app.classList.contains('sidebar-open')) closeSidebar();
    state.searchOpen = true;
    state.searchReturn = state.page;
    state.searchReturnNav = state.navActive;
    searchInput.value = '';
    searchClear.hidden = true;
    searchPanel.classList.remove('dragging', 'settling');
    searchPanel.style.transition = '';
    searchPanel.style.transform = '';
    searchPanel.style.opacity = '';
    searchPanel.style.boxShadow = '';
    showSearchHome();
    if (searchPanelBody) searchPanelBody.scrollTop = 0;
    searchPanel.inert = false;
    searchPanel.setAttribute('aria-hidden', 'false');
    searchPanel.classList.add('open');
    app.classList.add('search-open');
    document.body.classList.add('search-mode', 'search-opening');
    clearTimeout(searchOpeningTimer);
    searchOpeningTimer = setTimeout(() => {
      document.body.classList.remove('search-opening');
    }, 420);
    setDockExpanded(false);
    // Let the slide-in start on the compositor before the keyboard resize.
    setTimeout(() => {
      if (state.searchOpen) focusSearchInput();
    }, 90);
    setTimeout(() => {
      if (state.searchOpen && document.activeElement !== searchInput) focusSearchInput();
    }, 240);
  }

  function focusSearchInput() {
    try {
      searchInput.focus({ preventScroll: true });
      searchInput.setSelectionRange(0, 0);
    } catch (_) {
      try { searchInput.focus(); } catch (_) {}
    }
  }

  function beginSearchDismiss() {
    if (!searchPanel || !state.searchOpen) return false;
    state.searchOpen = false;
    app.classList.remove('search-open');
    finishSearchRecede();
    document.body.classList.remove('search-mode', 'search-opening');
    document.body.classList.add('search-dismissing');
    clearTimeout(searchDismissTimer);
    searchDismissTimer = setTimeout(() => {
      document.body.classList.remove('search-dismissing');
    }, 420);
    if (document.activeElement === searchInput) searchInput.blur();
    syncKeyboardOffset();
    searchPanel.setAttribute('aria-hidden', 'true');
    searchPanel.inert = true;
    return true;
  }

  function closeSearch() {
    if (!beginSearchDismiss()) return;
    searchPanel.classList.remove('open', 'dragging', 'settling');
    searchPanel.style.transition = '';
    searchPanel.style.transform = '';
    searchPanel.style.opacity = '';
    searchPanel.style.boxShadow = '';
    setTimeout(refreshFeedPreview, 420);
  }

  let searchRecedeActive = false;

  function applySearchRecede(progress) {
    if (!appMain) return;
    const p = Math.max(0, Math.min(1, Number(progress) || 0));
    searchRecedeActive = true;
    app.classList.add('search-dragging');
    appMain.style.transform = `translate3d(${(-7 * p).toFixed(3)}%,0,0) scale(${(1 - 0.06 * p).toFixed(4)})`;
  }

  function finishSearchRecede() {
    if (!searchRecedeActive) return;
    requestAnimationFrame(() => {
      app.classList.remove('search-dragging');
      appMain.style.transform = '';
      searchRecedeActive = false;
    });
  }

  function resetSearchResultsDrag() {
    if (!searchResultsPage) return;
    searchResultsPage.classList.remove('dragging');
    searchResultsPage.classList.add('settling');
    searchResultsPage.style.transition = 'transform .32s cubic-bezier(.16,1,.3,1),opacity .22s ease';
    searchResultsPage.style.transform = '';
    searchResultsPage.style.opacity = '';
    searchResultsPage.style.boxShadow = '';
    finishSearchRecede();
    setTimeout(() => {
      if (!searchResultsPage.classList.contains('dragging')) {
        searchResultsPage.style.transition = '';
        searchResultsPage.classList.remove('settling');
      }
    }, 340);
  }

  function closeSearchFromSwipe() {
    if (!searchPanel || !state.searchOpen || searchDismissing) return;
    state.searchOpen = false;
    searchDismissing = true;
    /* Return the page underneath at the same moment the panel starts leaving;
       waiting for the panel to finish made the background pop back late. */
    app.classList.remove('search-open');
    finishSearchRecede();
    document.body.classList.remove('search-mode', 'search-opening');
    document.body.classList.add('search-dismissing');
    clearTimeout(searchDismissTimer);
    searchDismissTimer = setTimeout(() => {
      document.body.classList.remove('search-dismissing');
    }, 420);
    if (document.activeElement === searchInput) searchInput.blur();
    searchPanel.classList.remove('dragging');
    searchPanel.classList.add('settling');
    searchPanel.style.transition = 'transform .36s cubic-bezier(.22,1,.36,1)';
    searchPanel.style.transform = 'translate3d(105%,0,0)';
    searchPanel.style.boxShadow = '';
    searchPanel.style.pointerEvents = 'none';
    setTimeout(() => {
      searchDismissing = false;
      if (state.searchOpen) return;
      searchPanel.classList.remove('open', 'settling');
      searchPanel.style.transition = '';
      searchPanel.style.transform = '';
      searchPanel.style.pointerEvents = '';
      searchPanel.style.opacity = '';
      searchPanel.style.boxShadow = '';
      searchPanel.setAttribute('aria-hidden', 'true');
      searchPanel.inert = true;
      syncKeyboardOffset();
      refreshFeedPreview();
    }, 320);
  }

  /* ---------- login ---------- */

  let loginPollTimer = null;

  function setLoginStatus(text, tone) {
    if (!loginStatus) return;
    loginStatus.textContent = text || '';
    loginStatus.className = 'login-status'
      + (tone === 'error' ? ' error' : tone === 'success' ? ' success' : '');
  }

  function nativeLoginCall(name, args) {
    const native = window.O11A1Native;
    if (!native || typeof native[name] !== 'function') {
      return { ok: false, error: '当前环境不支持原生登录' };
    }
    try {
      const raw = native[name].apply(native, args);
      const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;
      return parsed && typeof parsed === 'object' ? parsed : { ok: false, error: '返回数据异常' };
    } catch (_) {
      return { ok: false, error: '请求失败，请稍后重试' };
    }
  }

  function resetLoginForm() {
    setLoginStatus('');
    if (loginCode) loginCode.value = '';
    loginCaptchaKey = '';
    loginCaptchaPhone = '';
    clearLoginPending();
  }

  function loginSucceeded(options = {}) {
    if (!state.loggedIn) {
      state.loggedIn = true;
      app.classList.remove('auth-gate');
      save();
    }
    if (!options.silent) setLoginStatus('登录成功', 'success');
    setTimeout(() => {
      if (state.loggedIn) showPage('home');
      resetLoginForm();
    }, options.immediate ? 0 : 600);
  }

  let loginCaptchaKey = '';
  let loginCaptchaPhone = '';
  let loginCountdownTimer = null;
  let loginSending = false;
  const LOGIN_PENDING_KEY = 'o11a1.login.pending.v1';
  const LOGIN_PENDING_TTL = 30 * 60 * 1000;

  function saveLoginPending() {
    try {
      if (!loginCaptchaKey) {
        localStorage.removeItem(LOGIN_PENDING_KEY);
        return;
      }
      const [cid, phone] = String(loginCaptchaPhone || '').split(':');
      localStorage.setItem(LOGIN_PENDING_KEY, JSON.stringify({
        key: loginCaptchaKey,
        phone: phone || loginPhoneValue(),
        cid: cid || loginCountryCode(),
        at: Date.now(),
      }));
    } catch (_) {}
  }

  function clearLoginPending() {
    try { localStorage.removeItem(LOGIN_PENDING_KEY); } catch (_) {}
  }

  function restoreLoginPending() {
    if (state.loggedIn) return;
    try {
      const raw = localStorage.getItem(LOGIN_PENDING_KEY);
      if (!raw) return;
      const saved = JSON.parse(raw);
      if (!saved || !saved.key || Date.now() - Number(saved.at || 0) > LOGIN_PENDING_TTL) {
        clearLoginPending();
        return;
      }
      loginCaptchaKey = String(saved.key);
      loginCaptchaPhone = `${saved.cid || '86'}:${saved.phone || ''}`;
      if (loginCid) loginCid.value = saved.cid || '86';
      if (loginPhone) loginPhone.value = saved.phone || '';
      if (state.page === 'login') {
        setLoginStatus('已恢复验证码登录状态，请输入短信验证码', 'success');
      }
    } catch (_) {}
  }

  function loginCountryCode() {
    const value = loginCid ? loginCid.value.replace(/\D/g, '') : '86';
    return value || '86';
  }

  function loginPhoneValue() {
    return loginPhone ? loginPhone.value.replace(/\D/g, '') : '';
  }

  function setLoginSending(sending, message) {
    loginSending = sending;
    if (loginSend) loginSend.disabled = sending;
    if (loginSubmit) loginSubmit.disabled = sending;
    if (message) setLoginStatus(message);
  }

  function startLoginCountdown(seconds) {
    clearInterval(loginCountdownTimer);
    let left = Math.max(1, Number(seconds) || 60);
    if (loginSend) loginSend.textContent = `${left}s 后重发`;
    loginCountdownTimer = setInterval(() => {
      left -= 1;
      if (left <= 0) {
        clearInterval(loginCountdownTimer);
        loginCountdownTimer = null;
        if (loginSend) {
          loginSend.disabled = false;
          loginSend.textContent = '获取验证码';
        }
        return;
      }
      if (loginSend) loginSend.textContent = `${left}s 后重发`;
    }, 1000);
  }

  function sendLoginCode() {
    if (loginSending) return;
    const phone = loginPhoneValue();
    if (!/^\d{5,20}$/.test(phone)) {
      setLoginStatus('请输入正确的手机号', 'error');
      return;
    }
    const cid = loginCountryCode();
    if (typeof window.O11A1Native?.sendSmsCode !== 'function') {
      setLoginStatus('当前环境不支持原生短信登录', 'error');
      return;
    }
    setLoginSending(true, '正在准备 B 站安全验证…');
    requestAnimationFrame(() => setTimeout(() => {
      const result = nativeLoginCall('sendSmsCode', [phone, cid]);
      if (!result || (!result.ok && !result.pending)) {
        setLoginSending(false);
        setLoginStatus(result?.error || (result?.cancelled ? '已取消安全验证' : '短信发送失败'), 'error');
        return;
      }
      if (result.pending) {
        setLoginSending(true, '请在安全验证窗口完成验证…');
        return;
      }
      applySmsCodeResult(result);
    }, 40));
  }

  function applySmsCodeResult(value) {
    setLoginSending(false);
    if (!value || !value.ok) {
      setLoginStatus(value?.error || (value?.cancelled ? '已取消安全验证' : '短信发送失败'), 'error');
      return false;
    }
    const phone = value.tel || loginPhoneValue();
    const cid = value.cid || loginCountryCode();
    loginCaptchaKey = value.captchaKey || '';
    loginCaptchaPhone = `${cid}:${phone}`;
    if (!loginCaptchaKey) {
      setLoginStatus('验证码已发送，但未返回登录凭据，请重新获取', 'error');
      return false;
    }
    saveLoginPending();
    setLoginStatus('验证码已发送，请在有效期内输入', 'success');
    startLoginCountdown(60);
    if (loginCode) loginCode.focus();
    return true;
  }

  window.O11A1Login = {
    onSmsCode(result) {
      let value = result;
      try {
        if (typeof value === 'string') value = JSON.parse(value);
      } catch (_) {
        value = null;
      }
      applySmsCodeResult(value);
    },
  };

  function submitSmsLogin() {
    if (loginSending) return;
    const phone = loginPhoneValue();
    const code = loginCode ? loginCode.value.replace(/\D/g, '') : '';
    const cid = loginCountryCode();
    if (!/^\d{5,20}$/.test(phone)) {
      setLoginStatus('请输入正确的手机号', 'error');
      return;
    }
    if (!code) {
      setLoginStatus('请输入短信验证码', 'error');
      return;
    }
    if (!loginCaptchaKey || loginCaptchaPhone !== `${cid}:${phone}`) {
      setLoginStatus('请先获取当前手机号的短信验证码', 'error');
      return;
    }
    setLoginSending(true, '正在登录…');
    setTimeout(() => {
      const result = nativeLoginCall('smsLogin', [phone, cid, code, loginCaptchaKey]);
      setLoginSending(false);
      if (!result || !result.ok) {
        setLoginStatus(result?.error || '登录失败，请检查验证码', 'error');
        return;
      }
      loginSucceeded();
    }, 30);
  }

  restoreLoginPending();



  function logout() {
    state.loggedIn = false;
    clearInterval(loginPollTimer);
    loginPollTimer = null;
    if (window.O11A1Native && typeof window.O11A1Native.logout === 'function') {
      try { window.O11A1Native.logout(); } catch (_) {}
    }
    if (window.O11A1Host && typeof window.O11A1Host.clearPreloadCaches === 'function') {
      try { window.O11A1Host.clearPreloadCaches(); } catch (_) {}
    }
    if (state.playerOpen) stopPlayback();
    closeSheet();
    closeSidebar();
    app.classList.add('auth-gate');
    state.navActive = '';
    save();
    updateNavActive();
    showPage('login');
    resetLoginForm();
  }

  let loginSyncAt = 0;

  function syncNativeLogin() {
    if (state.loggedIn) return;
    if (!window.O11A1Native || typeof window.O11A1Native.session !== 'function') return;
    const now = Date.now();
    if (now - loginSyncAt < 1200) return;
    loginSyncAt = now;
    const session = nativeLoginCall('session', []);
    if (!session || !session.ok || !session.loggedIn) return;
    state.loggedIn = true;
    app.classList.remove('auth-gate');
    save();
    if (state.page === 'login') showPage('home');
  }

  function setUpRecede(progress, options = {}) {
    const p = Math.max(0, Math.min(1, Number(progress) || 0));
    app.style.setProperty('--up-x', `${(-7 * p).toFixed(2)}%`);
    app.style.setProperty('--up-scale', (1 - p * 0.06).toFixed(4));
    app.classList.toggle('up-open', p > 0.001);
    app.classList.toggle('up-dragging', options.dragging === true && p > 0.001);
  }

  function setMyRecede(progress, options = {}) {
    const p = Math.max(0, Math.min(1, Number(progress) || 0));
    app.style.setProperty('--my-x', `${(-7 * p).toFixed(2)}%`);
    app.style.setProperty('--my-scale', (1 - p * 0.06).toFixed(4));
    app.classList.toggle('my-open', p > 0.001);
    app.classList.toggle('my-dragging', options.dragging === true && p > 0.001);
  }

  let pageEnterAnim = null;

  function animatePageEnter(pageName, direction) {
    if (!pageName || document.body.classList.contains('reduce-motion')) return;
    const node = document.querySelector(`.page[data-page="${pageName}"]`);
    if (!node) return;
    if (pageEnterAnim) {
      try { pageEnterAnim.cancel(); } catch (_) {}
      pageEnterAnim = null;
    }
    if (typeof node.animate !== 'function') return;
    const dx = Number(direction) * 18;
    pageEnterAnim = node.animate([
      { opacity: 0, transform: `translate3d(${dx}px, 10px, 0) scale(.996)` },
      { opacity: 1, transform: 'translate3d(0, 0, 0) scale(1)' },
    ], { duration: 320, easing: 'cubic-bezier(.22,1,.36,1)' });
    if (pageEnterAnim.finished && pageEnterAnim.finished.then) {
      pageEnterAnim.finished.then(() => {
        pageEnterAnim = null;
      }).catch(() => {});
    }
  }

  function navSwitchDirection(previousNav, nextNav) {
    const order = BOTTOM_NAV_ITEMS.map((item) => item.id);
    const from = order.indexOf(previousNav);
    const to = order.indexOf(nextNav);
    if (from < 0 || to < 0 || from === to) return 0;
    return to > from ? 1 : -1;
  }

  function showPage(page, navId) {
    const previousPage = state.page;
    const previousNav = state.navActive;
    if (!state.loggedIn && page !== 'login') {
      page = 'login';
      navId = null;
    }
    requestAnimationFrame(() => { if (typeof updateDebugHud === 'function') updateDebugHud(); });
    if (page !== previousPage) stopFeedPreview();
    if (page !== 'up') setUpRecede(0);
    if (page !== 'my') setMyRecede(0);
    if (page === 'my' && myPage) {
      const fromSubpage = ['modules', 'settings', 'nav'].includes(previousPage);
      const base = previousPage !== 'my' && !fromSubpage
        ? previousPage
        : (state.myReturn || 'home');
      if (previousPage !== 'my' && !fromSubpage) {
        state.myReturn = previousPage || 'home';
        state.myReturnNav = state.navActive;
      }
      state.page = 'my';
      app.classList.toggle('auth-gate', !state.loggedIn);
      $$('.page').forEach((section) => {
        if (section === myPage) return;
        if (section === upPage) return;
        if (section === searchResultsPage) return;
        section.classList.toggle('active', section.dataset.page === base);
      });
      app.dataset.page = 'my';
      setMyRecede(1);
      document.body.classList.toggle('search-mode', false);
      if (searchResultsPage && base !== 'search') {
        searchResultsPage.classList.remove('active', 'dragging', 'settling', 'entering');
        searchResultsPage.style.transition = '';
        searchResultsPage.style.transform = '';
        searchResultsPage.style.opacity = '';
        searchResultsPage.style.boxShadow = '';
      }
      myPage.classList.remove('my-dragging', 'my-settling', 'entering');
      myPage.style.transition = '';
      myPage.style.transform = '';
      myPage.style.opacity = '';
      myPage.style.boxShadow = '';
      myPage.classList.add('active');
      myPage.setAttribute('aria-hidden', 'false');
      myPage.inert = false;
      void myPage.offsetWidth;
      myPage.classList.add('entering');
      setTimeout(() => myPage.classList.remove('entering'), 430);
      const myScroller = $('#myScroll');
      if (myScroller) myScroller.scrollTop = 0;
      updatePlaylistDock();
      return;
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
      setUpRecede(1);
      document.body.classList.toggle('search-mode', false);
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
      const upScroller = $('#upScroll');
      if (upScroller) upScroller.scrollTop = 0;
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
      if (searchPanelBody) searchPanelBody.scrollTop = 0;
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
    if (previousPage === 'my' && myPage) {
      myPage.classList.remove('active', 'my-dragging', 'my-settling', 'entering');
      myPage.style.transition = '';
      myPage.style.transform = '';
      myPage.style.opacity = '';
      myPage.style.boxShadow = '';
      myPage.setAttribute('aria-hidden', 'true');
      myPage.inert = true;
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
    app.classList.toggle('module-wide', page === 'module'
      && (state.moduleName === '直播' || state.moduleName === '番剧' || state.moduleName === '影视'));
    document.body.classList.toggle('search-mode', page === 'search' || page === 'search-home');
    if (page !== 'search-home' && document.activeElement === searchInput) {
      searchInput.blur();
    }
    if (page === 'login') {
      state.navActive = '';
      setLoginStatus('');
    } else if (navId !== undefined && navId !== null) {
      state.navActive = navId;
    } else if (PAGE_NAV[page]) {
      state.navActive = PAGE_NAV[page];
    }
    updateNavActive();
    if (page !== previousPage) animatePageEnter(page, navSwitchDirection(previousNav, state.navActive));
    updatePlaylistDock();
    if (!returningToBase && !returningFromSearch) appScroll.scrollTop = 0;
    setTimeout(refreshFeedPreview, 260);
  }

  function openModulePage(name, navId) {
    if (!state.loggedIn) {
      showPage('login');
      return;
    }
    if (state.page === 'module' && state.moduleName === name) {
      // Re-selecting the current module from the sidebar must not reset the feed.
      if (navId) {
        state.navActive = navId;
        updateNavActive();
      }
      return;
    }
    if (PAGE_NAV[state.page]) {
      state.moduleReturn = state.page;
    } else if (['modules', 'nav', 'my'].includes(state.page)) {
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
        <span class="row-copy">
          <span class="row-avatar"><span>O</span></span>
          <span class="row-text">
            <span class="ph-title"><i class="ph-line ${v.w1}"></i><i class="ph-line ${v.w2}"></i></span>
            <span class="row-meta"><i class="ph-line ${v.m1}"></i><i class="ph-line ${v.m2}"></i></span>
          </span>
        </span>
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
            <span class="row-avatar skel-avatar"></span>
            <span class="row-text">
              <span class="ph-line w80"></span>
              <span class="ph-line w55"></span>
              <span class="ph-line w30"></span>
            </span>
          </span>
        </span>`;
      fragment.appendChild(row);
    }
    feed.appendChild(fragment);
  }

  function mockChunkNodes(feed, page) {
    const nodes = [];
    $$(`[data-chunk="${page}"]`, feed).forEach((node) => {
      const item = node.closest('.feed-item');
      const target = item && feed.contains(item) ? item : node;
      if (!nodes.includes(target)) nodes.push(target);
    });
    return nodes;
  }

  function topVisibleMockRow(feed, exclude) {
    const viewportTop = appScroll.getBoundingClientRect().top;
    const nodes = [];
    $$('[data-chunk]', feed).forEach((node) => {
      const item = node.closest('.feed-item');
      const target = item && feed.contains(item) ? item : node;
      if (!nodes.includes(target)) nodes.push(target);
    });
    for (let index = 0; index < nodes.length; index += 1) {
      const node = nodes[index];
      if (exclude && exclude.includes(node)) continue;
      if (node.getBoundingClientRect().bottom > viewportTop + 1) return node;
    }
    return null;
  }

  function trimMockFeed(feed) {
    if (activeFeed() !== feed) return;
    const pages = Array.isArray(feed.__chunkPages) ? feed.__chunkPages : [];
    if (pages.length <= 2) return;
    const viewportTop = appScroll.getBoundingClientRect().top;
    const removablePages = [];
    const removableRows = [];
    for (let index = 0; index < pages.length - 2; index += 1) {
      const page = pages[index];
      const rows = mockChunkNodes(feed, page);
      if (!rows.length) {
        removablePages.push(page);
        continue;
      }
      const last = rows[rows.length - 1];
      if (last.getBoundingClientRect().bottom > viewportTop + 4) break;
      removablePages.push(page);
      rows.forEach((row) => removableRows.push(row));
    }
    if (!removablePages.length) return;
    const anchor = topVisibleMockRow(feed, removableRows);
    const anchorTop = anchor ? anchor.getBoundingClientRect().top : 0;
    const first = removableRows[0];
    const last = removableRows[removableRows.length - 1];
    const oldHeight = first && last
      ? last.getBoundingClientRect().bottom - first.getBoundingClientRect().top
      : 0;
    removableRows.forEach((row) => row.remove());
    feed.__chunkPages = pages.filter((page) => !removablePages.includes(page));
    if (anchor) {
      const afterTop = anchor.getBoundingClientRect().top;
      if (afterTop !== anchorTop) {
        window.__o11a1ScrollAdjust = Date.now();
        appScroll.scrollTop = Math.max(0, appScroll.scrollTop + (afterTop - anchorTop));
      }
    } else if (oldHeight > 0) {
      window.__o11a1ScrollAdjust = Date.now();
      appScroll.scrollTop = Math.max(0, appScroll.scrollTop - oldHeight);
    }
  }

  function scheduleMockTrim(feed) {
    if (!feed) return;
    clearTimeout(feed.__trimTimer);
    feed.__trimTimer = setTimeout(() => {
      feed.__trimTimer = null;
      trimMockFeed(feed);
    }, 280);
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
    scheduleMockTrim(feed);
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
    if (!mod) {
      homeNote.textContent = '所有主页模块已关闭 · 在「主页模块」中启用';
      return;
    }
    homeNote.textContent = `${mod.name} · 触底加载 · 每块 10 条 · 保留 3 块`;
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
    moduleCount.textContent = `已启用 ${enabledCount} / ${visibleModules.length} 个模块`;
    renderDistractionSettings();
  }

  function renderDistractionSettings() {
    const box = $('#distractionSettings');
    if (!box) return;
    const def = settingsDefinition('settings-distraction');
    box.innerHTML = '';
    if (!def) return;
    def.rows
      .filter((row) => row.type !== 'static')
      .forEach((row) => box.appendChild(buildSettingRow(row)));
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
  function playlistCoverUrl(item) {
    let value = String(item && (item.pic || item.cover || item.image) || '').trim();
    if (!value) return '';
    if (value.startsWith('//')) value = `https:${value}`;
    if (!/^https?:\/\//i.test(value)) return '';
    if (/hdslb\.com\//i.test(value) && !/@[^/?#]+/.test(value)) {
      value += '@480w_270h_1c.webp';
    }
    return value;
  }

  function playlistItemMarkup(item, index) {
    const number = String(index + 1).padStart(2, '0');
    const current = index === state.currentIndex;
    const meta = item.meta || [item.owner, item.duration].filter(Boolean).join(' · ');
    const cover = playlistCoverUrl(item);
    return `
      <span class="pl-swipe-track">
        <span class="pl-swipe-bg" aria-hidden="true">
          <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 7h16"/><path d="M9 7V4h6v3"/><path d="M6 7l1.2 13h9.6L18 7"/><path d="M10 11v5"/><path d="M14 11v5"/></svg>
          <b>删除</b>
        </span>
        <span class="pl-swipe-content">
          <span class="pl-queue">${number}</span>
          <span class="pl-thumb">
            <span class="pl-thumb-fallback" aria-hidden="true">
              <svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>
            </span>
            ${cover ? `<img src="${escapeHTML(cover)}" alt="" draggable="false" loading="lazy" decoding="async" referrerpolicy="no-referrer" onerror="this.style.display='none'">` : ''}
          </span>
          <span class="pl-copy">
            <span class="pl-title">${escapeHTML(item.title || '视频')}</span>
            <span class="pl-meta">
              <span class="pl-meta-text">${escapeHTML(meta)}</span>
              ${current ? '<span class="pl-now">当前</span>' : ''}
            </span>
          </span>
        </span>
      </span>`;
  }

  function setDockExpanded(expanded) {
    const next = Boolean(expanded);
    if (next && window.O11A1Host && typeof window.O11A1Host.stopFeedPreview === 'function') {
      window.O11A1Host.stopFeedPreview();
    }
    playlistDock.classList.remove('dragging');
    playlistDock.classList.toggle('expanded', next);
    if (dockBackdrop) {
      dockBackdrop.classList.toggle('show', next);
      dockBackdrop.setAttribute('aria-hidden', next ? 'false' : 'true');
    }
    if (pdTools) pdTools.setAttribute('aria-hidden', next ? 'false' : 'true');
    if (pdCollapsed) pdCollapsed.setAttribute('aria-hidden', next ? 'true' : 'false');
    resetDockClear();
    void playlistDock.offsetWidth;
    playlistDock.style.height = '';
    playlistDock.style.borderTopLeftRadius = '';
    playlistDock.style.borderTopRightRadius = '';
    playlistDock.style.boxShadow = '';
    if (next) renderDockPlaylist();
    else if (window.O11A1Host && typeof window.O11A1Host.updateFeedPreview === 'function') {
      setTimeout(() => window.O11A1Host.updateFeedPreview(), 220);
    }
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
    dockPlaylistList.innerHTML = '';
    if (!count) {
      dockPlaylistList.innerHTML = '<div class="pd-empty">播放列表是空的</div>';
      return;
    }
    state.playlist.forEach((item, index) => {
      const row = document.createElement('div');
      row.className = `playlist-page-item${index === state.currentIndex ? ' on' : ''}`;
      row.setAttribute('role', 'button');
      row.tabIndex = 0;
      row.innerHTML = playlistItemMarkup(item, index);
      const open = () => openPlaylistItem(index, row);
      row.addEventListener('click', (event) => {
        if (Date.now() < playlistRowReorderSuppressClickUntil) return;
        if (Date.now() < playlistRowSwipeSuppressClickUntil) return;
        open();
      });
      row.addEventListener('keydown', (event) => {
        if (event.key === 'Delete') {
          event.preventDefault();
          removeFromPlaylist(index);
          return;
        }
        if (event.key !== 'Enter' && event.key !== ' ') return;
        event.preventDefault();
        open();
      });
      dockPlaylistList.appendChild(row);
    });
  }

  function updatePlaylistCounts() {
    updatePlaylistDock();
  }

  function playlistOwnerName(item) {
    if (!item) return '';
    const owner = String(item.owner || '').trim();
    if (owner) return owner;
    const meta = String(item.meta || '').trim();
    if (!meta) return '';
    const first = meta.split('·')[0].trim();
    if (!first || first === '播放列表') return '';
    return first;
  }

  function resetDockClear() {
    dockClearArmed = false;
    clearTimeout(dockClearTimer);
    dockClearTimer = null;
    if (pdClear) {
      pdClear.classList.remove('confirm');
      pdClear.textContent = '清空列表';
    }
  }

  function handleDockClear(event) {
    if (event) event.stopPropagation();
    if (!state.playlist.length) return;
    if (!dockClearArmed) {
      dockClearArmed = true;
      if (pdClear) {
        pdClear.textContent = '确认清空';
        pdClear.classList.add('confirm');
      }
      clearTimeout(dockClearTimer);
      dockClearTimer = setTimeout(resetDockClear, 3200);
      return;
    }
    resetDockClear();
    clearPlaylist();
  }

  function setPlaylistDisc(item) {
    const src = item ? playlistCoverUrl(item) : '';
    if (pdDisc) {
      pdDisc.classList.toggle('playing', Boolean(item && state.playing));
    }
    if (!pdDiscArt) return;
    if (!src) {
      pdDiscArt.hidden = true;
      pdDiscArt.removeAttribute('src');
      pdDiscArt.dataset.src = '';
      return;
    }
    if (pdDiscArt.dataset.src === src) {
      if (pdDiscArt.complete && pdDiscArt.naturalWidth) pdDiscArt.hidden = false;
      return;
    }
    pdDiscArt.dataset.src = src;
    pdDiscArt.hidden = true;
    pdDiscArt.src = src;
    if (pdDiscArt.complete && pdDiscArt.naturalWidth) pdDiscArt.hidden = false;
  }

  if (pdDiscArt) {
    pdDiscArt.addEventListener('load', () => {
      if (pdDiscArt.dataset.src) pdDiscArt.hidden = false;
    });
    pdDiscArt.addEventListener('error', () => {
      pdDiscArt.hidden = true;
    });
  }

  function updatePlaylistDock() {
    /* The playlist dock is retired. Keep this no-op so the many playback
       callbacks that refresh player chrome do not need to special-case it. */
    app.classList.remove('has-playlist');
    if (!playlistDock) return;
    playlistDock.classList.remove('show');
    playlistDock.setAttribute('aria-hidden', 'true');
    playlistDock.inert = true;
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

  function playlistDockTargetRect() {
    const dock = playlistDock.getBoundingClientRect();
    const head = $('.pd-head', playlistDock);
    const base = head ? head.getBoundingClientRect() : dock;
    const width = 64;
    const height = 38;
    return {
      left: dock.left + dock.width / 2 - width / 2,
      top: base.top + base.height / 2 - height / 2,
      width,
      height,
    };
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
      ? playlistDockTargetRect()
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
    if (state.playerOpen) prefetchPlayerMedia();
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
    if (playlistPageHint) playlistPageHint.hidden = count === 0;
    playlistPageList.innerHTML = '';
    if (!count) {
      const empty = document.createElement('div');
      empty.className = 'playlist-empty';
      empty.innerHTML = `
        <b>播放列表是空的</b>
        <p>左滑任意视频即可加入</p>
        <button class="playlist-empty-home" type="button" id="playlistEmptyHome">去首页</button>`;
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
      row.innerHTML = playlistItemMarkup(item, index);
      const openItem = () => openPlaylistItem(index, row);
      row.addEventListener('click', (event) => {
        if (Date.now() < playlistRowReorderSuppressClickUntil) return;
        if (Date.now() < playlistRowSwipeSuppressClickUntil) return;
        openItem();
      });
      row.addEventListener('keydown', (event) => {
        if (event.key === 'Delete') {
          event.preventDefault();
          removeFromPlaylist(index);
          return;
        }
        if (event.key !== 'Enter' && event.key !== ' ') return;
        event.preventDefault();
        openItem();
      });
      playlistPageList.appendChild(row);
    });

    const clear = document.createElement('button');
    clear.type = 'button';
    clear.className = 'playlist-clear';
    clear.innerHTML = '<span>清空播放列表</span>';
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

  /* ---------- playlist row long-press reorder ---------- */
  const PLAYLIST_ROW_HOLD_MS = 380;
  const PLAYLIST_ROW_HOLD_SLOP = 10;
  const PLAYLIST_SWIPE_ARM = 58;
  const PLAYLIST_SWIPE_MAX = 96;

  function cancelPlaylistRowPress() {
    if (!playlistRowPress) return;
    clearTimeout(playlistRowPress.timer);
    playlistRowPress = null;
  }

  function resetPlaylistRowSwipe(swipe = playlistRowSwipe) {
    if (!swipe) return;
    if (swipe.content) swipe.content.style.transform = '';
    if (swipe.row) {
      swipe.row.classList.remove('pl-swiping');
      swipe.row.style.removeProperty('--pl-swipe');
      swipe.row.style.removeProperty('--pl-swipe-px');
    }
    if (playlistRowSwipe === swipe) playlistRowSwipe = null;
  }

  function updatePlaylistRowSwipe(swipe) {
    if (!swipe || !swipe.content) return;
    const progress = Math.min(1, Math.max(0, -swipe.offset / PLAYLIST_SWIPE_MAX));
    swipe.content.style.transform = `translate3d(${swipe.offset}px,0,0)`;
    swipe.row.style.setProperty('--pl-swipe', progress.toFixed(3));
    swipe.row.style.setProperty('--pl-swipe-px', `${Math.max(0, -swipe.offset).toFixed(1)}px`);
  }

  function deletePlaylistRow(swipe) {
    if (!swipe || swipe.deleting) return;
    const rows = Array.from(swipe.list.querySelectorAll('.playlist-page-item'));
    const index = rows.indexOf(swipe.row);
    if (index < 0) return;
    const item = state.playlist[index];
    if (!item) return;
    swipe.deleting = true;
    swipe.row.classList.remove('pl-swiping');
    swipe.row.classList.add('pl-removing');
    swipe.row.style.setProperty('--pl-swipe', '1');
    swipe.row.style.setProperty('--pl-swipe-px', '100%');
    setTimeout(() => {
      const at = state.playlist.indexOf(item);
      if (at >= 0) removeFromPlaylist(at);
    }, 220);
  }

  function handlePlaylistRowPointerDown(event) {
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    if (playlistRowReorder) return;
    const list = event.currentTarget;
    const row = event.target.closest('.playlist-page-item');
    if (!row || row.parentElement !== list) return;
    if (event.target.closest('button, a, input, textarea')) return;
    const content = row.querySelector('.pl-swipe-content');
    if (!content) return;
    cancelPlaylistRowPress();
    resetPlaylistRowSwipe();
    const press = {
      id: event.pointerId,
      list,
      row,
      startX: event.clientX,
      startY: event.clientY,
      lastY: event.clientY,
      timer: 0,
    };
    press.timer = setTimeout(() => {
      if (playlistRowPress !== press) return;
      startPlaylistRowReorder(press);
    }, PLAYLIST_ROW_HOLD_MS);
    playlistRowPress = press;
    playlistRowSwipe = {
      id: event.pointerId,
      list,
      row,
      content,
      startX: event.clientX,
      startY: event.clientY,
      offset: 0,
      active: false,
      deleting: false,
    };
  }

  function startPlaylistRowReorder(press) {
    playlistRowPress = null;
    playlistRowSwipe = null;
    if (!press.row.isConnected || playlistRowReorder) return;
    const rows = Array.from(press.list.querySelectorAll('.playlist-page-item'));
    const startIndex = rows.indexOf(press.row);
    if (startIndex < 0) return;
    const rect = press.row.getBoundingClientRect();
    if (rect.width < 1 || rect.height < 1) return;
    const rowInfo = rows.map((row) => {
      const bounds = row.getBoundingClientRect();
      return { el: row, top: bounds.top, height: bounds.height };
    });
    const ghost = press.row.cloneNode(true);
    ghost.classList.add('reorder-ghost');
    ghost.removeAttribute('role');
    ghost.removeAttribute('tabindex');
    ghost.setAttribute('aria-hidden', 'true');
    ghost.style.position = 'fixed';
    ghost.style.left = `${rect.left}px`;
    ghost.style.top = `${rect.top}px`;
    ghost.style.width = `${rect.width}px`;
    ghost.style.height = `${rect.height}px`;
    ghost.style.margin = '0';
    document.body.appendChild(ghost);
    press.row.classList.add('reorder-source');
    press.list.classList.add('reordering');
    document.body.classList.add('playlist-reordering');
    const scrollEl = press.list === dockPlaylistList ? dockPlaylistBody : appScroll;
    playlistRowReorder = {
      id: press.id,
      list: press.list,
      row: press.row,
      item: state.playlist[startIndex] || null,
      startIndex,
      targetIndex: startIndex,
      rows: rowInfo,
      rowHeight: rect.height,
      ghost,
      startY: press.startY,
      lastClientY: press.lastY,
      scrollEl,
      scrollStart: scrollEl ? scrollEl.scrollTop : 0,
      scrollSpeed: 0,
      raf: 0,
    };
    playlistDrag = null;
    resetPlaylistPageDrag();
    dockDrag = null;
    dockBodyTouch = null;
    playlistDock.classList.remove('dragging');
    playlistDock.style.height = '';
    playlistDock.style.borderTopLeftRadius = '';
    playlistDock.style.borderTopRightRadius = '';
    playlistDock.style.boxShadow = '';
    if (navigator.vibrate) {
      try { navigator.vibrate(8); } catch (_) {}
    }
    updatePlaylistRowReorder(press.lastY);
  }

  function updatePlaylistRowReorder(clientY) {
    const drag = playlistRowReorder;
    if (!drag) return;
    if (!drag.row.isConnected || !drag.list.isConnected) {
      finishPlaylistRowReorder(false);
      return;
    }
    drag.lastClientY = clientY;
    drag.ghost.style.top = `${drag.rows[drag.startIndex].top + (clientY - drag.startY)}px`;
    const scrollDelta = drag.scrollEl ? drag.scrollEl.scrollTop - drag.scrollStart : 0;
    let target = drag.startIndex;
    drag.rows.forEach((info, index) => {
      if (index === drag.startIndex) return;
      const mid = info.top - scrollDelta + info.height / 2;
      if (index < drag.startIndex && clientY < mid) target = Math.min(target, index);
      else if (index > drag.startIndex && clientY > mid) target = Math.max(target, index);
    });
    drag.targetIndex = target;
    drag.rows.forEach((info, index) => {
      if (index === drag.startIndex) return;
      let shift = 0;
      if (target < drag.startIndex && index >= target && index < drag.startIndex) shift = drag.rowHeight;
      else if (target > drag.startIndex && index > drag.startIndex && index <= target) shift = -drag.rowHeight;
      const next = shift ? `translateY(${shift}px)` : '';
      if (info.el.style.transform !== next) info.el.style.transform = next;
    });
  }

  function playlistRowScrollSpeed(clientY) {
    const drag = playlistRowReorder;
    if (!drag || !drag.scrollEl) return 0;
    const bounds = drag.scrollEl.getBoundingClientRect();
    if (bounds.height < 1) return 0;
    const edge = Math.min(64, Math.max(28, bounds.height * 0.12));
    if (clientY < bounds.top + edge) {
      return -Math.min(12, Math.max(2, Math.ceil((bounds.top + edge - clientY) / 5)));
    }
    if (clientY > bounds.bottom - edge) {
      return Math.min(12, Math.max(2, Math.ceil((clientY - (bounds.bottom - edge)) / 5)));
    }
    return 0;
  }

  function runPlaylistRowScroll() {
    const drag = playlistRowReorder;
    if (!drag) return;
    drag.raf = 0;
    if (!drag.scrollSpeed || !drag.scrollEl) return;
    const before = drag.scrollEl.scrollTop;
    drag.scrollEl.scrollTop = before + drag.scrollSpeed;
    if (drag.scrollEl.scrollTop !== before) updatePlaylistRowReorder(drag.lastClientY);
    drag.raf = requestAnimationFrame(runPlaylistRowScroll);
  }

  function finishPlaylistRowReorder(commit) {
    const drag = playlistRowReorder;
    if (!drag) return;
    playlistRowReorder = null;
    if (drag.raf) cancelAnimationFrame(drag.raf);
    drag.ghost.remove();
    drag.list.classList.remove('reordering');
    drag.rows.forEach((info) => {
      info.el.style.transform = '';
    });
    drag.row.classList.remove('reorder-source');
    document.body.classList.remove('playlist-reordering');
    playlistRowReorderSuppressClickUntil = Date.now() + 460;
    suppressPlaylistClickUntil = Math.max(suppressPlaylistClickUntil, playlistRowReorderSuppressClickUntil);
    suppressDockClickUntil = Math.max(suppressDockClickUntil, playlistRowReorderSuppressClickUntil);
    if (!commit) return;
    const from = drag.startIndex;
    const to = drag.targetIndex;
    if (from === to) return;
    if (!drag.item || state.playlist[from] !== drag.item) return;
    const moved = state.playlist.splice(from, 1)[0];
    if (!moved) return;
    state.playlist.splice(to, 0, moved);
    if (state.currentIndex === from) state.currentIndex = to;
    else if (from < state.currentIndex && to >= state.currentIndex) state.currentIndex -= 1;
    else if (from > state.currentIndex && to <= state.currentIndex) state.currentIndex += 1;
    save();
    refreshPlaylistPage();
  }

  window.addEventListener('pointermove', (event) => {
    if (playlistRowSwipe && event.pointerId === playlistRowSwipe.id) {
      const swipe = playlistRowSwipe;
      if (swipe.deleting) return;
      const dx = event.clientX - swipe.startX;
      const dy = event.clientY - swipe.startY;
      if (!swipe.active) {
        if (Math.abs(dx) < 9 && Math.abs(dy) < 9) return;
        if (dx < -9 && Math.abs(dx) > Math.abs(dy) * 1.12) {
          cancelPlaylistRowPress();
          swipe.active = true;
          swipe.row.classList.add('pl-swiping');
          playlistRowSwipeSuppressClickUntil = Date.now() + 420;
          suppressPlaylistClickUntil = Math.max(suppressPlaylistClickUntil, playlistRowSwipeSuppressClickUntil);
          suppressDockClickUntil = Math.max(suppressDockClickUntil, playlistRowSwipeSuppressClickUntil);
        } else {
          playlistRowSwipe = null;
          cancelPlaylistRowPress();
          return;
        }
      }
      if (event.cancelable) event.preventDefault();
      swipe.offset = Math.max(-PLAYLIST_SWIPE_MAX, Math.min(0, dx));
      updatePlaylistRowSwipe(swipe);
      return;
    }
    if (playlistRowReorder && event.pointerId === playlistRowReorder.id) {
      if (event.cancelable) event.preventDefault();
      updatePlaylistRowReorder(event.clientY);
      const speed = playlistRowScrollSpeed(event.clientY);
      playlistRowReorder.scrollSpeed = speed;
      if (speed && !playlistRowReorder.raf) playlistRowReorder.raf = requestAnimationFrame(runPlaylistRowScroll);
      return;
    }
    if (!playlistRowPress || event.pointerId !== playlistRowPress.id) return;
    const dx = event.clientX - playlistRowPress.startX;
    const dy = event.clientY - playlistRowPress.startY;
    if (Math.abs(dx) > PLAYLIST_ROW_HOLD_SLOP || Math.abs(dy) > PLAYLIST_ROW_HOLD_SLOP) {
      cancelPlaylistRowPress();
      return;
    }
    playlistRowPress.lastY = event.clientY;
  }, { passive: false });

  window.addEventListener('pointerup', (event) => {
    if (playlistRowSwipe && event.pointerId === playlistRowSwipe.id) {
      const swipe = playlistRowSwipe;
      playlistRowSwipe = null;
      cancelPlaylistRowPress();
      if (swipe.active) {
        playlistRowSwipeSuppressClickUntil = Date.now() + 420;
        suppressPlaylistClickUntil = Math.max(suppressPlaylistClickUntil, playlistRowSwipeSuppressClickUntil);
        suppressDockClickUntil = Math.max(suppressDockClickUntil, playlistRowSwipeSuppressClickUntil);
        if (swipe.offset <= -PLAYLIST_SWIPE_ARM) {
          deletePlaylistRow(swipe);
        } else {
          swipe.row.classList.remove('pl-swiping');
          swipe.content.style.transform = '';
          swipe.row.style.removeProperty('--pl-swipe');
          swipe.row.style.removeProperty('--pl-swipe-px');
        }
      }
      return;
    }
    if (playlistRowPress && event.pointerId === playlistRowPress.id) cancelPlaylistRowPress();
    if (playlistRowReorder && event.pointerId === playlistRowReorder.id) finishPlaylistRowReorder(true);
  });

  window.addEventListener('pointercancel', (event) => {
    if (playlistRowSwipe && event.pointerId === playlistRowSwipe.id) {
      const swipe = playlistRowSwipe;
      playlistRowSwipe = null;
      if (swipe.active) {
        swipe.row.classList.remove('pl-swiping');
        swipe.content.style.transform = '';
        swipe.row.style.removeProperty('--pl-swipe');
        swipe.row.style.removeProperty('--pl-swipe-px');
      }
      cancelPlaylistRowPress();
    }
    if (playlistRowPress && event.pointerId === playlistRowPress.id) cancelPlaylistRowPress();
    if (playlistRowReorder && event.pointerId === playlistRowReorder.id) finishPlaylistRowReorder(false);
  });

  window.addEventListener('touchmove', (event) => {
    if (!playlistRowReorder) return;
    if (event.cancelable) event.preventDefault();
  }, { passive: false });

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
    stopFeedPreview();
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
    const label = state.searchOpen
      ? (searchResultsLabel.textContent || '搜索')
      : state.page === 'module'
        ? state.moduleName
        : '推荐';
    return `${label}视频占位 ${String(index).padStart(2, '0')}`;
  }

  function addFeedRowToPlaylist(row, options = {}) {
    if (!row || !state.loggedIn) return;
    const item = row.__nativeItem;
    if (item) {
      const key = item.bvid ? `bvid:${item.bvid}` : item.aid ? `aid:${item.aid}` : feedRowKey(row);
      if (options.preserveCurrent && state.playlist.some((entry) => entry.key === key)) {
        flyRowToPlaylist(row);
        return;
      }
      const meta = item.meta || [item.owner, item.duration].filter(Boolean).join(' · ');
      addToPlaylist(item.title, meta, key, item);
    } else {
      addToPlaylist(feedRowTitle(row), 'UP 占位 · 左滑加入', feedRowKey(row));
    }
    flyRowToPlaylist(row);
  }

  function ensureRowMask(row) {
    let mask = row.querySelector('.row-swipe-mask');
    if (mask) return mask;
    mask = document.createElement('span');
    mask.className = 'row-swipe-mask';
    mask.dataset.action = 'queue';
    mask.setAttribute('aria-hidden', 'true');
    mask.innerHTML = '<b class="rsm-label">加入播放列表</b><small class="rsm-hint">左滑加入 · 按住切换 UP 主</small>';
    row.appendChild(mask);
    return mask;
  }

  function setRowSwipe(wrapper, offset) {
    if (!wrapper) return;
    const row = wrapper.querySelector('.video-row');
    if (!row) return;
    const mask = ensureRowMask(row);
    const armedQueue = offset >= ROW_ACTION_ARM;
    const armedUp = Boolean(wrapper.__rowUpMode);
    const action = armedUp ? 'up' : 'queue';
    const armed = armedUp ? 'up' : armedQueue ? 'queue' : '';
    const opacity = Math.min(1, Math.max(0, offset / 24));
    mask.dataset.action = 'queue';
    mask.style.opacity = String(opacity);
    const label = mask.querySelector('.rsm-label');
    const hint = mask.querySelector('.rsm-hint');
    if (label) label.textContent = armedUp ? '查看 UP 主' : '加入播放列表';
    if (hint) hint.textContent = armedUp
      ? '松开查看 UP 主'
      : armedQueue ? '松开加入 · 按住不动切换 UP 主' : '左滑加入 · 按住切换 UP 主';
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
    wrapper.__rowUpMode = false;
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
    setUpRecede(1);
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
    setUpRecede(0);
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

  function closeMyPageThen(callback) {
    if (!myPage || !myPage.classList.contains('active')) {
      if (callback) callback();
      return;
    }
    setMyRecede(0);
    myPage.classList.remove('my-dragging', 'entering');
    myPage.classList.add('my-settling');
    myPage.style.transition = 'transform .36s cubic-bezier(.16,1,.3,1)';
    myPage.style.transform = 'translate3d(105%,0,0)';
    myPage.style.boxShadow = '-18px 0 46px rgba(10,12,20,.18)';
    setTimeout(() => {
      myPage.classList.remove('my-settling', 'active');
      myPage.style.transition = '';
      myPage.style.transform = '';
      myPage.style.opacity = '';
      myPage.style.boxShadow = '';
      myPage.setAttribute('aria-hidden', 'true');
      myPage.inert = true;
      if (callback) callback();
    }, 370);
  }

  function closeMyPageFromSwipe() {
    closeMyPageThen(() => showPage(state.myReturn || 'home', state.myReturnNav || undefined));
  }

  function resetMyPageDrag() {
    if (!myPage) return;
    setMyRecede(1);
    myPage.classList.remove('my-dragging');
    myPage.classList.add('my-settling');
    myPage.style.transition = 'transform .3s cubic-bezier(.16,1,.3,1)';
    myPage.style.transform = '';
    myPage.style.boxShadow = '';
    setTimeout(() => {
      if (!myPage.classList.contains('my-dragging')) {
        myPage.style.transition = '';
        myPage.classList.remove('my-settling');
      }
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
    cancelSidebarSettle();
    /* Rebuilding the whole nav at the first drag frame caused a visible hitch.
       The list is already rendered at launch and refreshed when settings change. */
    if (sidebarNav.childElementCount || sidebarFoot.childElementCount) {
      updateNavActive();
      updatePlaylistCounts();
    } else {
      renderSidebar();
    }
    updateMiniPlayer();
    clearSidebarPicked();
    sidebar.classList.remove('selecting');
    sidebar.inert = false;
    sidebar.setAttribute('aria-hidden', 'false');
    app.classList.add('sidebar-open', 'sidebar-dragging');
    sidebar.classList.add('open', 'dragging');
    sidebarBackdrop.classList.add('show', 'dragging');
    appMain.style.boxShadow = sidebarCompact
      ? '0 12px 30px rgba(10,12,20,.24)'
      : '0 12px 32px rgba(10,12,20,.26)';
    playlistDock.classList.remove('receiving', 'absorbing');
    updatePlaylistDock();
    return true;
  }

  function applySidebarDrag(progress) {
    const p = Math.max(0, Math.min(1, progress));
    const compact = sidebarCompact;
    const shift = compact ? 10 : 14;
    const scaleDrop = compact ? 0.10 : 0.14;
    const rotate = compact ? 0 : 7;
    const radius = compact ? 24 : 26;
    appMain.style.transform = `translate3d(${(p * shift).toFixed(2)}%,0,0) scale(${(1 - p * scaleDrop).toFixed(4)})${rotate ? ` rotateY(${(p * rotate).toFixed(2)}deg)` : ''}`;
    appMain.style.borderRadius = compact
      ? `${(p * radius).toFixed(1)}px`
      : `${(p * radius).toFixed(1)}px ${(34 - p * 8).toFixed(1)}px ${(34 - p * 8).toFixed(1)}px ${(p * radius).toFixed(1)}px`;
    sidebar.style.transform = `translate3d(${((p - 1) * 100).toFixed(2)}%,0,0)`;
    sidebarBackdrop.style.opacity = String(p);
  }

  function cancelSidebarSettle() {
    if (!sidebarSettleRaf) return;
    cancelAnimationFrame(sidebarSettleRaf);
    sidebarSettleRaf = 0;
  }

  function settleSidebarDrag(from, to, done) {
    cancelSidebarSettle();
    const start = performance.now();
    const distance = to - from;
    const duration = to === 1 ? 260 : 220;
    const frame = (now) => {
      sidebarSettleRaf = 0;
      const t = Math.min(1, (now - start) / duration);
      const eased = 1 - Math.pow(1 - t, 3);
      applySidebarDrag(from + distance * eased);
      if (t < 1) {
        sidebarSettleRaf = requestAnimationFrame(frame);
        return;
      }
      applySidebarDrag(to);
      done();
    };
    sidebarSettleRaf = requestAnimationFrame(frame);
  }

  function finishSidebarDrag() {
    app.classList.remove('sidebar-dragging');
    sidebar.classList.remove('selecting', 'dragging');
    sidebarBackdrop.classList.remove('dragging');
    clearSidebarPicked();
    appMain.style.transform = '';
    appMain.style.borderRadius = '';
    appMain.style.boxShadow = '';
    sidebar.style.transform = '';
    sidebarBackdrop.style.opacity = '';
  }

  function closeSidebarFromDrag() {
    app.classList.remove('sidebar-dragging');
    sidebar.classList.remove('selecting', 'dragging');
    sidebarBackdrop.classList.remove('dragging');
    clearSidebarPicked();
    closeSidebar();
    appMain.style.transform = '';
    appMain.style.borderRadius = '';
    appMain.style.boxShadow = '';
    sidebar.style.transform = '';
    sidebarBackdrop.style.opacity = '';
  }

  function endSidebarDrag(start, event, vx) {
    if (!start) return;
    clearTimeout(start.sidebarHoldTimer);
    start.sidebarHoldTimer = null;
    const progress = start.sidebarProgress || 0;
    const velocity = typeof vx === 'number' ? vx : (start.vx || 0);
    const selecting = start.sidebarSelecting === true;
    const picked = sidebarPicked;
    const cancelled = event && event.type === 'pointercancel';
    try {
      window.__swipeDebug = {
        kind: 'end', at: Date.now(), progress, velocity, cancelled, selecting,
        eventType: event && event.type,
      };
    } catch (_) {}
    suppressFeedClickUntil = Date.now() + 1200;
    suppressSidebarClickUntil = Date.now() + 180;
    suppressSidebarBackdropUntil = Date.now() + 1200;
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
    /* If the system cancels a slow touch after the drawer is already mostly
       open, keep it open instead of snapping it shut. */
    if ((!cancelled && (progress >= 0.14 || velocity > 0.32)) || progress >= 0.12) {
      settleSidebarDrag(progress, 1, () => {
        finishSidebarDrag();
        updatePlaylistDock();
      });
      return;
    }
    settleSidebarDrag(progress, 0, closeSidebarFromDrag);
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
          const indicated = Number(stats.indicatedBitrate || 0);
          const observed = Number(stats.observedBitrate || 0);
          if (state.streamInfo) {
            if (!state.streamInfo.videoBitrate && (indicated > 0 || observed > 0)) {
              state.streamInfo.videoBitrate = indicated || observed;
            }
            if (!state.streamInfo.sourceWidth && Number(stats.videoWidth) > 0) {
              state.streamInfo.sourceWidth = Number(stats.videoWidth);
              state.streamInfo.sourceHeight = Number(stats.videoHeight);
            }
          }
          const nativeBps = Number(stats.downloadBps || 0);
          if (nativeBps > 0) {
            debugState.bitrate = Math.round(nativeBps / 1000);
            debugState.bitrateAt = now;
            if (state.streamInfo) {
              state.streamInfo.netBps = nativeBps;
              state.streamInfo.netAt = now;
            }
          } else if (debugNetBytes !== null && now > debugNetAt) {
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
    let network = '↓— / 码率 —';
    if (netBps > 0) {
      network = totalBps > 0
        ? `↓${formatDebugBitrate(netBps)} / 码率 ${formatDebugBitrate(videoBps)} (${(netBps / totalBps).toFixed(1)}×)`
        : `↓${formatDebugBitrate(netBps)} / 码率 —`;
    } else if (totalBps > 0) {
      network = `↓— / 码率 ${formatDebugBitrate(videoBps)}`;
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
    if (pdDisc) {
      pdDisc.classList.toggle('playing', playing === true && Boolean(state.playlist[state.currentIndex]));
    }
    if (!pcPlay) return;
    pcPlay.classList.toggle('playing', playing === true);
    pcPlay.setAttribute('aria-label', playing ? '暂停' : '播放');
  }

  function applyDanmakuSettings() {
    if (pcDanmakuValue) pcDanmakuValue.textContent = state.settings.danmaku ? '开' : '关';
    if (window.O11A1NativeData && typeof window.O11A1NativeData.applyDanmakuStyle === 'function') {
      try {
        window.O11A1NativeData.applyDanmakuStyle();
        return;
      } catch (_) {}
    }
    if (window.O11A1Media && typeof window.O11A1Media.onSettings === 'function') {
      window.O11A1Media.onSettings();
    }
  }

  function updatePlayerLabels() {
    pcQualityValue.textContent = state.settings.quality;
    if (pcDanmakuValue) pcDanmakuValue.textContent = state.settings.danmaku ? '开' : '关';
    pcLoopValue.textContent = state.settings.loop;
    setProgress(state.progress);
    updatePlaylistDock();
    if (window.O11A1Media && typeof window.O11A1Media.onSettings === 'function') {
      window.O11A1Media.onSettings();
    }
  }

  function prefetchPlayerMedia() {
    if (window.O11A1NativeData && typeof window.O11A1NativeData.prefetchCurrent === 'function') {
      try {
        window.O11A1NativeData.prefetchCurrent();
      } catch (_) {}
    }
  }

  function updateMiniPlayer() {
    // Playback continues without a persistent mini card; the playlist page owns playback state.
  }

  function setPlayerRecede(side, amount, options = {}) {
    if (!playerBody) return;
    const p = Math.max(0, Math.min(1, Number(amount) || 0));
    const restoreTransition = options.instant === true;
    if (restoreTransition) playerBody.style.transition = 'none';
    if (options.dragging) player.classList.add('panel-dragging');
    else player.classList.remove('panel-dragging');
    if (p <= 0.001) {
      player.classList.remove('panel-shifted', 'panel-left', 'panel-right');
      playerBody.style.transformOrigin = '';
      playerBody.style.transform = '';
      playerBody.style.borderRadius = '';
      playerBody.style.boxShadow = '';
      playerBody.style.setProperty('--player-dim', '0');
      if (restoreTransition) {
        requestAnimationFrame(() => { playerBody.style.transition = ''; });
      }
      return;
    }
    if (side !== 'left' && side !== 'right') return;
    const dir = side === 'left' ? 1 : -1;
    player.classList.add('panel-shifted');
    player.classList.toggle('panel-left', side === 'left');
    player.classList.toggle('panel-right', side === 'right');
    playerBody.style.transformOrigin = side === 'left' ? 'left center' : 'right center';
    playerBody.style.transform = `translate3d(${(p * 9 * dir).toFixed(2)}%,0,0) scale(${(1 - p * 0.09).toFixed(4)}) rotateY(${(p * 4 * dir).toFixed(2)}deg)`;
    playerBody.style.borderRadius = `${(p * 26).toFixed(1)}px`;
    playerBody.style.boxShadow = `0 ${Math.round(18 * p)}px ${Math.round(56 * p)}px rgba(0,0,0,${(p * 0.34).toFixed(2)})`;
    playerBody.style.setProperty('--player-dim', (p * 0.28).toFixed(3));
    if (restoreTransition) {
      requestAnimationFrame(() => { playerBody.style.transition = ''; });
    }
  }

  function guardPanelTransition(ms = 480) {
    panelTransitionGuardUntil = Date.now() + ms;
  }

  function panelTransitionActive() {
    if (!commentsPanel || !videoDetailPanel) return false;
    return commentsPanel.classList.contains('open')
      || commentsPanel.classList.contains('peeking')
      || commentsPanel.classList.contains('closing')
      || videoDetailOpen
      || videoDetailPanel.classList.contains('peeking')
      || videoDetailPanel.classList.contains('closing');
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

  function formatTimeMs(seconds) {
    const totalMs = Math.max(0, Math.round(Number(seconds || 0) * 1000));
    const hours = Math.floor(totalMs / 3600000);
    const minutes = Math.floor((totalMs % 3600000) / 60000);
    const secs = Math.floor((totalMs % 60000) / 1000);
    const millis = totalMs % 1000;
    const body = `${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}.${String(millis).padStart(3, '0')}`;
    return hours > 0 ? `${hours}:${body}` : body;
  }

  function precisionContext() {
    const total = state.duration > 0 ? state.duration : TOTAL_SECONDS;
    const current = total * state.progress / 100;
    return { total, current };
  }

  function initGridProgress() {
    if (!gridProgress || gridCells.length) return;
    const fragment = document.createDocumentFragment();
    for (let index = 0; index < GRID_CELLS; index += 1) {
      const cell = document.createElement('span');
      cell.className = 'grid-cell';
      cell.setAttribute('aria-hidden', 'true');
      fragment.appendChild(cell);
      gridCells.push(cell);
    }
    gridProgress.replaceChildren(fragment);
  }

  function renderGridProgress(percentOverride) {
    if (!gridProgress || !gridCells.length) return;
    const source = Number.isFinite(percentOverride) ? percentOverride : state.progress;
    const percent = Math.max(0, Math.min(100, Number(source) || 0));
    const filled = percent / 100 * GRID_CELLS;
    gridProgress.setAttribute('aria-valuenow', percent.toFixed(1));
    gridCells.forEach((cell, index) => {
      const active = percent > 0 && index < Math.ceil(filled - 1e-6);
      cell.classList.toggle('on', active);
    });
  }

  function gridLocalPoint(event) {
    const width = gridProgress.clientWidth || gridProgress.getBoundingClientRect().width || 1;
    const height = gridProgress.clientHeight || 14;
    const rect = gridProgress.getBoundingClientRect();
    if (!state.playerLandscape) {
      return { x: event.clientX - rect.left, y: event.clientY - rect.top, width };
    }
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;
    const dir = state.playerLandscapeDir;
    return {
      x: width / 2 + (event.clientY - centerY) * dir,
      y: height / 2 + (event.clientX - centerX) * -dir,
      width,
    };
  }

  function startGridDrag(event) {
    if (!state.playerOpen || state.locked || precisionDrag || gridDrag) return;
    if (event.button !== undefined && event.button !== 0) return;
    clearTimeout(hideTimer);
    const point = gridLocalPoint(event);
    const percent = Math.max(0, Math.min(100, point.x / point.width * 100));
    gridDrag = {
      pointerId: event.pointerId,
      startX: point.x,
      lastX: point.x,
      startY: point.y,
      preview: percent,
      moved: false,
    };
    gridProgress.classList.add('dragging');
    playerControls.classList.remove('hidden');
    player.classList.remove('ui-hidden');
    previewPrecisionTime(percent / 100 * precisionContext().total);
    if (event.cancelable) event.preventDefault();
  }

  function moveGridDrag(event) {
    const drag = gridDrag;
    if (!drag || event.pointerId !== drag.pointerId) return;
    const point = gridLocalPoint(event);
    const dx = point.x - drag.lastX;
    drag.lastX = point.x;
    const lift = Math.max(0, drag.startY - point.y);
    if (!drag.moved) {
      if (Math.abs(point.x - drag.startX) < 2.5 && lift < 6) return;
      drag.moved = true;
    }
    const damping = Math.pow(0.5, Math.max(0, lift - 6) / 80);
    drag.preview = Math.max(0, Math.min(100, drag.preview + (dx / point.width) * 100 * damping));
    previewPrecisionTime(drag.preview / 100 * precisionContext().total);
    if (event.cancelable) event.preventDefault();
  }

  function endGridDrag(event) {
    const drag = gridDrag;
    if (!drag || (event && event.pointerId !== undefined && event.pointerId !== drag.pointerId)) return;
    const percent = drag.preview;
    gridDrag = null;
    gridProgress.classList.remove('dragging');
    seekBubble.classList.remove('show');
    setProgress(percent, true);
    showControls();
  }

  function precisionWheelScale(width) {
    const pxPerSecond = Math.max(4.5, Math.min(11, width / 72));
    const steps = [1, 2, 5, 10, 15, 30, 60, 120, 300, 600];
    let minorStep = steps[steps.length - 1];
    for (let index = 0; index < steps.length; index += 1) {
      if (steps[index] * pxPerSecond >= 11) {
        minorStep = steps[index];
        break;
      }
    }
    return { pxPerSecond, minorStep };
  }

  function renderPrecisionWheel(centerOverride) {
    if (!wheelStrip || !progressBar) return;
    const context = precisionContext();
    const width = progressBar.clientWidth || progressBar.getBoundingClientRect().width || 1;
    const center = Math.max(0, Math.min(context.total, Number.isFinite(centerOverride) ? centerOverride : context.current));
    const { pxPerSecond, minorStep } = precisionWheelScale(width);
    const halfSpan = width / 2 / pxPerSecond;
    const start = Math.max(0, center - halfSpan);
    const end = Math.min(context.total, center + halfSpan);
    const centerX = width / 2;
    const fragment = document.createDocumentFragment();
    const firstIndex = Math.ceil(start / minorStep);
    const lastIndex = Math.floor(end / minorStep);
    for (let index = firstIndex; index <= lastIndex; index += 1) {
      const seconds = index * minorStep;
      const x = centerX + (seconds - center) * pxPerSecond;
      const major = index % 5 === 0;
      const tick = document.createElement('span');
      tick.className = `wheel-tick${major ? ' major' : (index % 2 === 0 ? ' mid' : '')}${seconds <= center ? ' past' : ''}`;
      tick.style.left = `${x.toFixed(2)}px`;
      fragment.appendChild(tick);
      if (major && x > 22 && x < width - 22) {
        const label = document.createElement('span');
        label.className = `wheel-tick-label${seconds <= center ? ' past' : ''}`;
        label.textContent = formatTime(seconds);
        label.style.left = `${x.toFixed(2)}px`;
        fragment.appendChild(label);
      }
    }
    wheelStrip.replaceChildren(fragment);
    wheelStrip.style.transform = 'translate3d(0,0,0)';
    wheelDragBasis = null;
  }

  /* Dragging rebuilds the ruler window once and then only moves the strip on
     the compositor. Replacing the tick nodes on every pointermove made the
     ruler advance in visible steps. */
  function beginWheelDrag(center) {
    if (!wheelStrip || !progressBar) return;
    const context = precisionContext();
    const width = progressBar.clientWidth || progressBar.getBoundingClientRect().width || 1;
    const base = Math.max(0, Math.min(context.total, Number.isFinite(center) ? center : context.current));
    const { pxPerSecond, minorStep } = precisionWheelScale(width);
    const halfSpan = width / 2 / pxPerSecond;
    const span = halfSpan * 2.4;
    const start = Math.max(0, base - span);
    const end = Math.min(context.total, base + span);
    const centerX = width / 2;
    const fragment = document.createDocumentFragment();
    const firstIndex = Math.ceil(start / minorStep);
    const lastIndex = Math.floor(end / minorStep);
    for (let index = firstIndex; index <= lastIndex; index += 1) {
      const seconds = index * minorStep;
      const x = centerX + (seconds - base) * pxPerSecond;
      const major = index % 5 === 0;
      const tick = document.createElement('span');
      tick.className = `wheel-tick${major ? ' major' : (index % 2 === 0 ? ' mid' : '')}${seconds <= base ? ' past' : ''}`;
      tick.style.left = `${x.toFixed(2)}px`;
      tick.dataset.t = String(seconds);
      fragment.appendChild(tick);
      if (major && x > 22 && x < width - 22) {
        const label = document.createElement('span');
        label.className = `wheel-tick-label${seconds <= base ? ' past' : ''}`;
        label.textContent = formatTime(seconds);
        label.style.left = `${x.toFixed(2)}px`;
        fragment.appendChild(label);
      }
    }
    wheelStrip.replaceChildren(fragment);
    wheelStrip.style.transform = 'translate3d(0,0,0)';
    wheelDragBasis = { center: base, pxPerSecond, minorStep, halfSpan };
  }

  function scrollWheelTo(center) {
    if (!wheelStrip) return;
    const context = precisionContext();
    const value = Math.max(0, Math.min(context.total, Number(center) || 0));
    if (!wheelDragBasis) {
      beginWheelDrag(value);
      return;
    }
    const dx = (value - wheelDragBasis.center) * wheelDragBasis.pxPerSecond;
    if (Math.abs(dx) > wheelDragBasis.halfSpan * 0.8) {
      beginWheelDrag(value);
      return;
    }
    wheelStrip.style.transform = `translate3d(${(-dx).toFixed(2)}px,0,0)`;
  }

  function setProgress(percent, seek) {
    if ((precisionDrag || gridDrag) && !seek) return;
    state.progress = Math.min(100, Math.max(0, percent));
    pdProgress.style.width = `${state.progress}%`;
    renderPrecisionWheel();
    renderGridProgress();
    if (seek && window.O11A1Media && typeof window.O11A1Media.seek === 'function') {
      window.O11A1Media.seek(state.progress);
    }
  }

  function previewPrecisionTime(seconds, wheelDrag) {
    const context = precisionContext();
    const value = Math.max(0, Math.min(context.total, Number(seconds) || 0));
    seekBubble.textContent = formatTimeMs(value);
    seekBubble.classList.add('show');
    if (wheelDrag) scrollWheelTo(value);
    else renderPrecisionWheel(value);
    renderGridProgress(context.total > 0 ? value / context.total * 100 : 0);
  }

  function precisionLocalX(event, width) {
    const localWidth = width || progressBar.clientWidth || 1;
    const rect = progressBar.getBoundingClientRect();
    if (!state.playerLandscape) {
      return Math.max(0, Math.min(localWidth, event.clientX - rect.left));
    }
    const centerY = rect.top + rect.height / 2;
    const offset = (event.clientY - centerY) * state.playerLandscapeDir;
    return Math.max(0, Math.min(localWidth, localWidth / 2 + offset));
  }

  function startPrecisionDrag(event) {
    if (!state.playerOpen || gridDrag) return;
    if (event.button !== undefined && event.button !== 0) return;
    clearTimeout(hideTimer);
    const context = precisionContext();
    const width = progressBar.clientWidth || progressBar.getBoundingClientRect().width || 1;
    const { pxPerSecond } = precisionWheelScale(width);
    const localX = precisionLocalX(event, width);
    const tapTime = context.current + (localX - width / 2) / pxPerSecond;
    precisionDrag = {
      pointerId: event.pointerId,
      startLocalX: localX,
      startTime: context.current,
      preview: context.current,
      tapTime,
      moved: false,
    };
    progressBar.classList.add('dragging');
    beginWheelDrag(context.current);
    if (event.cancelable) event.preventDefault();
  }

  function movePrecisionDrag(event) {
    const drag = precisionDrag;
    if (!drag || event.pointerId !== drag.pointerId) return;
    const width = progressBar.clientWidth || progressBar.getBoundingClientRect().width || 1;
    const localX = precisionLocalX(event, width);
    const delta = localX - drag.startLocalX;
    if (!drag.moved) {
      if (Math.abs(delta) < 3) return;
      drag.moved = true;
    }
    const context = precisionContext();
    const { pxPerSecond } = precisionWheelScale(width);
    drag.preview = Math.max(0, Math.min(context.total, drag.startTime - delta / pxPerSecond));
    previewPrecisionTime(drag.preview, true);
    if (event.cancelable) event.preventDefault();
  }

  function endPrecisionDrag(event) {
    const drag = precisionDrag;
    if (!drag || (event && event.pointerId !== undefined && event.pointerId !== drag.pointerId)) return;
    const context = precisionContext();
    const target = drag.moved ? drag.preview : drag.tapTime;
    precisionDrag = null;
    wheelDragBasis = null;
    progressBar.classList.remove('dragging');
    seekBubble.classList.remove('show');
    const clamped = Math.max(0, Math.min(context.total, Number(target) || 0));
    setProgress(context.total > 0 ? clamped / context.total * 100 : 0, true);
    showControls();
  }

  function openPlayerSettings() {
    if (!playerSettings || playerSettingsOpen || !state.playerOpen) return;
    playerSettingsOpen = true;
    clearTimeout(hideTimer);
    closePcPanels();
    const settingsList = $('.player-settings-list');
    if (settingsList) settingsList.scrollTop = 0;
    playerSettings.inert = false;
    playerSettings.setAttribute('aria-hidden', 'false');
    playerSettings.classList.add('open');
    player.classList.add('settings-open');
    playerSettingsCard.style.transition = '';
    playerSettingsCard.style.transform = '';
    playerSettingsScrim.style.opacity = '';
    playerControls.classList.add('hidden');
    player.classList.add('ui-hidden');
  }

  function closePlayerSettings(options = {}) {
    if (!playerSettingsOpen) return;
    playerSettingsOpen = false;
    settingsDrawGesture = null;
    playerSettingsCard.classList.remove('dragging');
    playerSettingsCard.style.transition = options.instant ? 'none' : '';
    playerSettingsCard.style.transform = '';
    playerSettingsScrim.style.opacity = '';
    playerSettings.classList.remove('open');
    playerSettings.setAttribute('aria-hidden', 'true');
    playerSettings.inert = true;
    player.classList.remove('settings-open');
    if (options.instant) {
      playerSettingsCard.style.transition = '';
    } else if (state.playerOpen) {
      showControls();
    }
  }

  function startSettingsDraw(event) {
    if (!playerSettingsOpen) return;
    if (event.button !== undefined && event.button !== 0) return;
    const list = event.target.closest('.player-settings-list');
    if (list && list.scrollTop > 0) return;
    settingsDrawGesture = {
      pointerId: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      moved: false,
      dy: 0,
    };
    settingsSuppressClick = false;
  }

  function moveSettingsDraw(event) {
    const gesture = settingsDrawGesture;
    if (!gesture || event.pointerId !== gesture.pointerId) return;
    const dx = event.clientX - gesture.startX;
    const dy = event.clientY - gesture.startY;
    const dir = state.playerLandscapeDir;
    const localY = state.playerLandscape ? -dx * dir : dy;
    if (!gesture.moved) {
      if (Math.hypot(dx, dy) < 8) return;
      if (localY <= 0) return;
      gesture.moved = true;
      settingsSuppressClick = true;
      playerSettingsCard.classList.add('dragging');
    }
    if (event.cancelable) event.preventDefault();
    gesture.dy = Math.max(0, localY);
    playerSettingsCard.style.transition = 'none';
    playerSettingsCard.style.transform = `translate3d(0,${gesture.dy}px,0)`;
    playerSettingsScrim.style.opacity = String(1 - Math.min(0.55, gesture.dy / 720) * 0.55);
  }

  function endSettingsDraw(event) {
    const gesture = settingsDrawGesture;
    if (!gesture) return;
    settingsDrawGesture = null;
    if (event && event.pointerId !== undefined && event.pointerId !== gesture.pointerId) return;
    playerSettingsCard.classList.remove('dragging');
    playerSettingsCard.style.transition = '';
    playerSettingsScrim.style.opacity = '';
    if (!gesture.moved) return;
    if (gesture.dy > 64) {
      closePlayerSettings();
    } else {
      playerSettingsCard.style.transform = '';
    }
    setTimeout(() => {
      if (!settingsDrawGesture) settingsSuppressClick = false;
    }, 260);
  }

  function hideControlsInstant() {
    clearTimeout(hideTimer);
    playerControls.classList.add('hidden');
    player.classList.add('ui-hidden');
  }

  function showControls() {
    clearTimeout(hideTimer);
    if (!state.playerOpen || state.locked) return;
    player.classList.remove('ui-hidden');
    playerControls.classList.remove('hidden');
    renderPrecisionWheel();
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

  function setPlayerOrientation(mode) {
    const dir = playerLandscapeDirection(mode);
    state.playerLandscape = dir !== 0;
    state.playerLandscapeDir = dir;
    player.classList.toggle('landscape', dir !== 0);
    player.classList.toggle('landscape-left', dir === -1);
    player.classList.toggle('landscape-right', dir === 1);
    if (state.playerOpen) {
      renderPrecisionWheel();
      renderGridProgress();
    }
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
    }, 180);
  }

  function setTiltDirection(dir) {
    if (!state.playerOpen || state.locked || state.settings.autoLandscape === false) return;
    if (psheet && psheet.classList.contains('open')) return;
    queueGyroOrientation(dir < 0 ? -1 : dir > 0 ? 1 : 0);
  }

  function onDeviceOrientation(event) {
    if (window.__O11A1_NATIVE_TILT) return;
    if (!state.playerOpen || state.locked || state.settings.autoLandscape === false) return;
    if (psheet && psheet.classList.contains('open')) return;
    if (window.innerWidth > window.innerHeight) return;
    const gamma = Number(event.gamma);
    if (!Number.isFinite(gamma)) return;
    const magnitude = Math.abs(gamma);
    let next = null;
    if (magnitude >= 48) next = gamma > 0 ? -1 : 1;
    else if (magnitude <= 30) next = 0;
    if (next === null) return;
    setTiltDirection(next);
  }

  function attachGyro() {
    if (gyroBound) return;
    gyroBound = true;
    window.addEventListener('deviceorientation', onDeviceOrientation, true);
  }

  function postTiltWatch(on) {
    try {
      if (window.ReactNativeWebView && typeof window.ReactNativeWebView.postMessage === 'function') {
        window.ReactNativeWebView.postMessage(JSON.stringify({ type: 'tilt-watch', on: Boolean(on) }));
        return;
      }
      /* The native iOS shell has no React Native bridge. Post the same message
         to its WKScriptMessageHandler, which reads a JSON string body. */
      const handlers = window.webkit && window.webkit.messageHandlers;
      const native = handlers && handlers.o11a1;
      if (native && typeof native.postMessage === 'function') {
        native.postMessage(JSON.stringify({ type: 'tilt-watch', on: Boolean(on) }));
      }
    } catch (_) {}
  }

  function startGyro() {
    if (state.settings.autoLandscape === false) return;
    /* Never request motion permission: opening a video must not show a system
       permission dialog. The native shell feeds tilt from the accelerometer on
       platforms where the web sensor APIs are gated; elsewhere the raw
       deviceorientation event is used when the WebView exposes it. */
    postTiltWatch(true);
    if (!window.DeviceOrientationEvent) return;
    attachGyro();
  }

  function stopGyro() {
    postTiltWatch(false);
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
    player.classList.remove('window-opening', 'promoting-preview');
    app.classList.remove('player-opening');
    player.style.pointerEvents = '';
    player.style.transform = '';
    player.style.borderRadius = '';
    player.style.boxShadow = '';
    player.style.animation = '';
    playerRotor.style.backgroundImage = '';
  }

  function expandPlayerWindowFromOrigin(origin) {
    const source = origin && origin.rect;
    const finish = () => {
      clearTimeout(playerOpenWindowTimer);
      playerOpenWindowTimer = null;
      player.classList.remove('window-opening', 'promoting-preview');
      app.classList.remove('player-opening');
      player.style.pointerEvents = '';
      player.style.transform = '';
      player.style.borderRadius = '';
      player.style.boxShadow = '';
      player.style.animation = '';
      playerRotor.style.backgroundImage = '';
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

  let playerPoster = null;

  function hidePlayerPoster(immediate) {
    const node = playerPoster || (playerVideo && playerVideo.querySelector('.player-poster'));
    playerPoster = null;
    if (!node) return;
    if (immediate) {
      node.remove();
      return;
    }
    node.classList.add('hide');
    setTimeout(() => node.remove(), 220);
  }

  function showPlayerPoster(url, thumb) {
    hidePlayerPoster(true);
    if (!playerVideo || !url) return;
    const poster = document.createElement('div');
    poster.className = 'player-poster';
    poster.style.backgroundImage = `url("${String(url).replace(/"/g, '%22')}")`;
    /* CSS background images cannot set a referrer policy. Bilibili image
       hotlinking then returns a placeholder; use a real <img> for the blur.
       The feed thumbnail has already decoded this cover, so clone its bitmap
       for the first paint instead of waiting on a fresh decode. */
    const source = thumb && thumb.querySelector('img');
    const background = document.createElement('img');
    background.className = 'player-poster-bg';
    background.src = url;
    background.alt = '';
    background.draggable = false;
    background.decoding = 'sync';
    background.loading = 'eager';
    background.referrerPolicy = 'no-referrer';
    poster.appendChild(background);
    let image;
    if (source && source.complete && source.naturalWidth > 0) {
      image = source.cloneNode(false);
      image.className = 'player-poster-fg';
      image.removeAttribute('loading');
      image.alt = '';
      image.draggable = false;
      image.decoding = 'sync';
      image.referrerPolicy = 'no-referrer';
    } else {
      image = document.createElement('img');
      image.className = 'player-poster-fg';
      image.src = url;
      image.alt = '';
      image.draggable = false;
      image.decoding = 'sync';
      image.loading = 'eager';
      image.referrerPolicy = 'no-referrer';
    }
    poster.appendChild(image);
    playerVideo.insertBefore(poster, playerVideo.firstChild);
    playerPoster = poster;
  }

  function setPlayerOriginFromRow(row) {
    if (!row) return false;
    const thumb = row.querySelector('.row-thumb');
    if (!thumb) return false;
    const rect = thumb.getBoundingClientRect();
    if (!rect.width || !rect.height) return false;
    pendingPlayerOrigin = {
      thumb,
      rect,
      radius: getComputedStyle(thumb).borderRadius || '0px',
      time: Date.now(),
    };
    return true;
  }

  function openPlayer(options = {}) {
    endPlayerDragSnapshot();
    const origin = pendingPlayerOrigin;
    pendingPlayerOrigin = null;
    if (!state.loggedIn) {
      stopFeedPreview();
      showPage('login');
      return;
    }
    const promotedPreview = Boolean(origin && origin.thumb
      && window.O11A1Host && typeof window.O11A1Host.promoteFeedPreview === 'function'
      && window.O11A1Host.promoteFeedPreview(origin.thumb));
    stopFeedPreview();
    const wasOpen = state.playerOpen;
    const openToken = ++playerMediaOpenToken;
    clearTimeout(playerMediaOpenTimer);
    playerMediaOpenTimer = null;
    clearTimeout(playerPrefetchTimer);
    playerPrefetchTimer = null;
    closePlayerSettings({ instant: true });
    cancelPlayerOpenExpansion();
    cancelPlayerCollapse();
    cancelPlayerDropExit();
    hidePlayerDrop();
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
    if (typeof updateDebugHud === 'function') updateDebugHud();
    if (!wasOpen) setPlayerOrientation(false, { silent: true });
    hideMiniPlayer();
    clearTimeout(hideTimer);
    const mediaApi = window.O11A1Media;
    const hasMediaApi = Boolean(mediaApi && typeof mediaApi.onOpen === 'function');
    const mediaReady = hasMediaApi && typeof mediaApi.isCurrentReady === 'function'
      ? Boolean(mediaApi.isCurrentReady())
      : !hasMediaApi;
    setPlayIcon(state.playing);
    updatePlayerLabels();
    player.style.animation = '';
    player.style.transition = '';
    player.style.transform = '';
    player.style.opacity = '';
    player.style.pointerEvents = '';
    player.classList.remove('dragging', 'collapsing', 'window-opening', 'promoting-preview');
    playerRotor.style.backgroundImage = '';
    const nativeMedia = Boolean(window.O11A1NativeMedia && window.O11A1NativeMedia.available);
    if (playerVideo) {
      // The poster follows the player design: blurred fill behind, sharp
      // aspect-fit image on top, acting as the video until the native item has
      // its first frame.
      playerVideo.style.backgroundImage = '';
      const currentEntry = state.playlist[state.currentIndex];
      const posterUrl = (origin && origin.image)
        || (currentEntry ? playlistCoverUrl(currentEntry) : '')
        || '';
      if (posterUrl) {
        app.style.setProperty('--player-backdrop', `url("${String(posterUrl).replace(/"/g, '%22')}")`);
      } else {
        app.style.removeProperty('--player-backdrop');
      }
      showPlayerPoster(posterUrl, origin && origin.thumb);
    }
    const expandFromRow = !wasOpen && Boolean(origin && origin.rect && origin.rect.width && origin.rect.height);
    if (expandFromRow) {
      app.classList.add('player-opening');
      player.classList.add('window-opening');
      if (promotedPreview) player.classList.add('promoting-preview');
      player.style.animation = 'none';
      player.style.pointerEvents = 'none';
      if (!nativeMedia && origin.image) {
        playerRotor.style.backgroundImage = `url("${String(origin.image).replace(/"/g, '%22')}")`;
        playerRotor.style.backgroundSize = 'cover';
        playerRotor.style.backgroundPosition = 'center';
        playerRotor.style.backgroundRepeat = 'no-repeat';
      }
    }
    player.classList.add('open');
    player.setAttribute('aria-hidden', 'false');
    player.inert = false;
    player.classList.remove('ui-hidden');
    app.classList.add('player-open');
    syncStatusBarStyle();
    lockBadge.classList.remove('show');
    updatePlaylistDock();
    closeSheet();
    resetComments();
    hidePlayerNotice();
    hideRateHud(0);
    hideControlsInstant();
    startGyro();
    if (expandFromRow) {
      requestAnimationFrame(() => {
        if (state.playerOpen) expandPlayerWindowFromOrigin(origin);
      });
    }
    if (!hasMediaApi) return;
    const startMedia = () => {
      if (openToken !== playerMediaOpenToken || !state.playerOpen) return;
      try {
        if (window.O11A1Media && typeof window.O11A1Media.onOpen === 'function') {
          window.O11A1Media.onOpen();
        }
      } catch (_) {}
      clearTimeout(playerPrefetchTimer);
      playerPrefetchTimer = setTimeout(() => {
        playerPrefetchTimer = null;
        if (openToken === playerMediaOpenToken && state.playerOpen) prefetchPlayerMedia();
      }, 350);
    };
    if (mediaReady) {
      startMedia();
    } else {
      playerMediaOpenTimer = setTimeout(() => {
        playerMediaOpenTimer = null;
        if (openToken !== playerMediaOpenToken || !state.playerOpen) return;
        requestAnimationFrame(() => startMedia());
      }, promotedPreview ? 60 : 0);
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
    player.style.borderRadius = '';
    if (playerDockForced) {
      playlistDock.style.transition = '';
      playlistDock.style.transform = '';
      playlistDock.style.opacity = '';
      playerDockForced = false;
    }
    player.classList.remove('to-playlist');
  }

  function setPlayerDropZone(zone) {
    if (playerDropZone === zone) return;
    const previous = playerDropZone;
    playerDropZone = zone;
    playerDropZones.forEach((element) => {
      element.classList.toggle('hot', Number(element.dataset.dropZone) === zone);
    });
    if (previous !== null && zone !== null && previous !== zone && navigator.vibrate) {
      navigator.vibrate(4);
    }
  }

  function showPlayerDrop() {
    if (!playerDrop) return;
    clearTimeout(playerDropHideTimer);
    playerDropHideTimer = null;
    playerDropControlsVisible = !playerControls.classList.contains('hidden')
      && !player.classList.contains('ui-hidden');
    if (playerDropControlsVisible) {
      playerControls.classList.add('hidden');
      player.classList.add('ui-hidden');
      clearTimeout(hideTimer);
    }
    playerDropZones.forEach((element) => element.classList.remove('fired', 'armed'));
    playerDrop.style.setProperty('--drop-opacity', '0.4');
    playerDrop.classList.add('show');
    playerDrop.setAttribute('aria-hidden', 'false');
  }

  function hidePlayerDrop(delay = 0, options = {}) {
    if (!playerDrop) return;
    clearTimeout(playerDropHideTimer);
    const restoreControls = options.restore === true && playerDropControlsVisible;
    playerDropControlsVisible = false;
    const run = () => {
      playerDropHideTimer = null;
      playerDrop.classList.remove('show');
      playerDrop.setAttribute('aria-hidden', 'true');
      playerDropZones.forEach((element) => element.classList.remove('hot', 'fired', 'armed'));
      playerDrop.style.removeProperty('--drop-opacity');
      playerDropZone = null;
      if (restoreControls && state.playerOpen) showControls();
    };
    if (delay > 0) playerDropHideTimer = setTimeout(run, delay);
    else run();
  }

  function firePlayerDropZone(zone) {
    playerDropZones.forEach((element) => {
      const active = Number(element.dataset.dropZone) === zone;
      element.classList.toggle('hot', active);
      element.classList.toggle('fired', active);
    });
    playerDropZone = zone;
  }

  function cancelPlayerDropExit() {
    playerDropExitToken += 1;
    if (playerDropExitAnim) {
      try { playerDropExitAnim.cancel(); } catch (_) {}
      playerDropExitAnim = null;
    }
    player.classList.remove('dropping');
  }

  function closePlayerFromDrop(direction, fromY, scale) {
    if (!state.playerOpen) return;
    holdNativePageChrome();
    app.classList.add('player-dragging');
    syncStatusBarStyle();
    const token = ++playerDropExitToken;
    const width = window.innerWidth || 1;
    const sideways = direction === -1 || direction === 1;
    const exitX = sideways ? direction * width * 1.02 : 0;
    const exitY = sideways ? fromY + 28 : fromY + (window.innerHeight || 1) * 1.02;
    const exitRotate = sideways ? direction * 3.5 : 0;
    const exitScale = Math.max(0.6, scale * 0.8);
    let finished = false;
    player.classList.add('dropping');
    const finish = () => {
      if (finished || token !== playerDropExitToken) return;
      finished = true;
      stopPlayback();
      player.classList.remove('dropping');
      if (playerDropExitAnim) {
        try { playerDropExitAnim.cancel(); } catch (_) {}
        playerDropExitAnim = null;
      }
    };
    if (typeof player.animate === 'function') {
      playerDropExitAnim = player.animate([
        {
          transform: `translate(0px, ${fromY}px) scale(${scale})`,
          opacity: 1,
          borderRadius: player.style.borderRadius || '28px',
        },
        {
          transform: `translate(${exitX}px, ${exitY}px) scale(${exitScale}) rotate(${exitRotate}deg)`,
          opacity: 0,
          borderRadius: '44px',
        },
      ], {
        duration: 340,
        easing: 'cubic-bezier(.3,.8,.2,1)',
        fill: 'forwards',
      });
      const done = () => {
        if (token !== playerDropExitToken) return;
        finish();
      };
      if (playerDropExitAnim.finished && playerDropExitAnim.finished.then) {
        playerDropExitAnim.finished.then(done).catch(done);
      }
      setTimeout(done, 460);
    } else {
      player.style.transition = 'transform .34s cubic-bezier(.3,.8,.2,1),opacity .3s ease,border-radius .34s ease';
      player.style.transform = `translate(${exitX}px, ${exitY}px) scale(${exitScale}) rotate(${exitRotate}deg)`;
      player.style.opacity = '0';
      player.style.borderRadius = '44px';
      setTimeout(finish, 370);
    }
  }

  function holdNativePageChrome() {
    /* The player surfaces are transparent only while this class is present.
       Keep it through a collapse so the outgoing window never repaints as an
       opaque dark rectangle over the feed. */
    document.documentElement.classList.add('native-player-ready');
    document.body.classList.add('native-player-ready');
  }

  function minimizePlayer(fromY = 0, fromScale = 1) {
    if (!state.playerOpen) return;
    closePlayerFromDrop(0, fromY, fromScale);
  }

  function stopPlayback() {
    playerMediaOpenToken += 1;
    clearTimeout(playerMediaOpenTimer);
    playerMediaOpenTimer = null;
    clearTimeout(playerPrefetchTimer);
    playerPrefetchTimer = null;
    closePlayerSettings({ instant: true });
    cancelPlayerOpenExpansion();
    cancelPlayerCollapse();
    hidePlayerDrop();
    resetVideoDetail();
    state.playerOpen = false;
    if (typeof updateDebugHud === 'function') updateDebugHud();
    app.classList.remove('player-open', 'player-opening');
    syncStatusBarStyle();
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
    player.style.borderRadius = '';
    player.style.boxShadow = '';
    playerControls.classList.remove('hidden');
    lockBadge.classList.remove('show');
    updatePlaylistDock();
    resetComments();
    hideRateHud(0);
    setPlayIcon(false);
    closeSheet();
    if (document.fullscreenElement && document.exitFullscreen) {
      document.exitFullscreen().catch(() => {});
    }
    if (window.O11A1Media && typeof window.O11A1Media.onStop === 'function') {
      window.O11A1Media.onStop();
    }
    updatePlayerLabels();
    hidePlayerPoster(true);
    endPlayerDragSnapshot();
  }

  function lockPlayer() {
    state.locked = true;
    clearTimeout(hideTimer);
    player.classList.add('ui-hidden');
    playerControls.classList.add('hidden');
    lockBadge.classList.add('show');
    resetComments();
    hideRateHud(0);
    closeSheet();
  }

  function unlockPlayer() {
    state.locked = false;
    lockBadge.classList.remove('show');
    showControls();
  }

  function togglePlay(options = {}) {
    const reveal = options.reveal !== false;
    if (window.O11A1Media && typeof window.O11A1Media.togglePlay === 'function'
      && window.O11A1Media.togglePlay()) {
      if (state.playerOpen && reveal) showControls();
      return;
    }
    state.playing = !state.playing;
    setPlayIcon(state.playing);
    updateMiniPlayer();
    if (state.playerOpen && reveal) showControls();
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
    prefetchPlayerMedia();
    if (window.O11A1Media && typeof window.O11A1Media.onTrackChange === 'function') {
      window.O11A1Media.onTrackChange();
    }
  }

  function cyclePlaybackMode() {
    const list = ['循环', '继续', '下一分P', '暂停'];
    state.settings.loop = list[(list.indexOf(state.settings.loop) + 1) % list.length];
    if (pcLoopValue) pcLoopValue.textContent = state.settings.loop;
    if (pdModeValue) pdModeValue.textContent = state.settings.loop;
    if (pdMode) pdMode.setAttribute('aria-label', `播放模式：${state.settings.loop}，点击切换`);
    save();
    return state.settings.loop;
  }

  function cycleLoop() {
    cyclePlaybackMode();
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
    openSheet('播放器面板', '信息 / 评论 / 性能 / 设置', (body) => {
      actionRow(body, '信息', '标题 / UP / 数据', () => {
        closeSheet();
        openPlayerInfoSheet();
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
      return;
    }
    if (document.documentElement.requestFullscreen) {
      document.documentElement.requestFullscreen().catch(() => {});
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

  function showPlayerNotice(title, text, duration = 2800) {
    if (!playerNotice) return;
    clearTimeout(playerNoticeTimer);
    if (playerNoticeTitle) playerNoticeTitle.textContent = title || '';
    if (playerNoticeText) playerNoticeText.textContent = text || '';
    playerNotice.classList.add('show');
    playerNoticeTimer = setTimeout(() => {
      playerNoticeTimer = null;
      playerNotice.classList.remove('show');
    }, Math.max(800, Number(duration) || 2800));
  }

  function hidePlayerNotice() {
    clearTimeout(playerNoticeTimer);
    playerNoticeTimer = null;
    if (playerNotice) playerNotice.classList.remove('show');
  }

  /* ---------- main page landscape ---------- */
  function syncLandscape() {
    // The main app is portrait-only. Video landscape is drawn inside the player rotor.
    app.classList.remove('landscape');
    document.body.classList.remove('landscape');
  }

  /* ---------- video detail overlay ---------- */
  const detailSkeletonMarkup = videoDetailBody ? videoDetailBody.innerHTML : '';

  function openVideoDetail(fromPeek) {
    if (!videoDetailPanel || !state.playerOpen || videoDetailOpen) return;
    const native = window.O11A1NativeData;
    const canRenderCached = Boolean(native
      && typeof native.hasVideoDetail === 'function'
      && native.hasVideoDetail()
      && typeof native.renderVideoDetail === 'function');
    clearTimeout(videoDetailCloseTimer);
    clearTimeout(videoDetailRenderTimer);
    videoDetailOpen = true;
    videoDetailPanel.inert = false;
    videoDetailPanel.classList.remove('closing', 'peeking', 'dragging');
    videoDetailPanel.style.transition = '';
    videoDetailPanel.setAttribute('aria-hidden', 'false');
    setPlayerRecede('left', 1);
    if (canRenderCached) {
      native.renderVideoDetail();
    } else if (videoDetailBody) {
      videoDetailBody.innerHTML = detailSkeletonMarkup;
    }
    videoDetailScroll.scrollTop = 0;
    if (fromPeek) {
      videoDetailPanel.classList.add('open');
      requestAnimationFrame(() => { videoDetailPanel.style.transform = ''; });
    } else {
      videoDetailPanel.style.transform = '';
      videoDetailPanel.classList.add('open');
    }
    swipeHint.classList.remove('show', 'left');
    clearTimeout(hideTimer);
    playerControls.classList.add('hidden');
    player.classList.add('ui-hidden');
    if (!canRenderCached) {
      videoDetailRenderTimer = setTimeout(() => {
        videoDetailRenderTimer = null;
        if (!videoDetailOpen) return;
        if (window.O11A1NativeData && typeof window.O11A1NativeData.renderVideoDetail === 'function') {
          window.O11A1NativeData.renderVideoDetail();
        }
      }, 320);
    }
  }

  function cancelVideoDetailPeek() {
    if (!videoDetailPanel || videoDetailOpen
      || !videoDetailPanel.classList.contains('peeking')) return;
    setPlayerRecede('left', 0);
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
    guardPanelTransition();
    cancelCommentsPeek();
    setPlayerRecede('left', 0);
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
    const local = localPlayerDelta(event.clientX - gesture.startX, event.clientY - gesture.startY);
    if (!gesture.dragging) {
      const intent = swipeIntent(local.x, local.y);
      if (intent !== 'left') return;
      gesture.dragging = true;
      gesture.base = Math.min(SWIPE_LOCK_PX, -local.x);
      suppressDetailClickUntil = Date.now() + 420;
      videoDetailPanel.classList.add('dragging');
    }
    if (event.cancelable) event.preventDefault();
    gesture.dx = Math.min(0, local.x + (gesture.base || 0));
    videoDetailPanel.style.transform = `translate3d(${gesture.dx}px,0,0)`;
    const width = videoDetailPanel.getBoundingClientRect().width || 1;
    const closed = Math.min(1, Math.max(0, -gesture.dx / width));
    setPlayerRecede('left', 1 - closed, { dragging: true });
  }

  function endVideoDetailSwipe() {
    const gesture = videoDetailSwipe;
    videoDetailSwipe = null;
    if (!gesture || !gesture.dragging) return;
    suppressDetailClickUntil = Date.now() + 420;
    videoDetailPanel.classList.remove('dragging');
    if (gesture.dx < -90) {
      closeVideoDetail();
      return;
    }
    videoDetailPanel.style.transition = 'transform .3s cubic-bezier(.16,1,.3,1)';
    videoDetailPanel.style.transform = '';
    setPlayerRecede('left', 1);
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
    setPlayerRecede('', 0, { instant: true });
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
    setPlayerRecede('right', 1);
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
    setPlayerRecede('', 0, { instant: true });
    swipeHint.classList.remove('show');
  }

  function closeComments(options = {}) {
    const wasOpen = commentsPanel.classList.contains('open') || commentsPanel.classList.contains('peeking');
    if (!wasOpen) return;
    guardPanelTransition();
    cancelVideoDetailPeek();
    setPlayerRecede('right', 0);
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
    setPlayerRecede('right', 0);
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

  let playerDragSnapshot = null;

  function playerCollapseScale(dragY) {
    return 1 - Math.min(0.17, Math.max(0, Number(dragY) || 0) / 820);
  }

  function beginPlayerDragSnapshot() {
    if (!state.playerOpen) return;
    /* Keep the native player visible while the window is dragged/collapsed.
       A captured still frame made the video look paused; the live layer now
       follows the transformed player rect instead. */
    app.classList.add('player-dragging');
  }

  function endPlayerDragSnapshot() {
    window.__o11a1HideMainVideo = false;
    app.classList.remove('player-dragging');
    app.style.setProperty('--player-reveal', '0px');
    if (playerDragSnapshot) {
      playerDragSnapshot.remove();
      playerDragSnapshot = null;
    }
  }

  function startStageGesture(event) {
    if (!state.playerOpen || state.locked) return;
    if (event.button !== undefined && event.button !== 0) return;
    if (event.target.closest('.player-controls, .lock-badge, button, input, textarea')) return;
    if (panelTransitionActive()) return;
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
      settingsY: 0,
      lastDy: 0,
      dropShown: false,
      dropZone: null,
      dropArmed: false,
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
      } else if (localY > 0 && state.settings.middleCollapse) {
        gesture.mode = 'collapse';
        beginPlayerDragSnapshot();
      } else if (localY < 0) {
        gesture.mode = 'settings';
      } else {
        gesture.mode = 'none';
        return;
      }
    }

    if (gesture.mode === 'settings') {
      gesture.settingsY = Math.min(gesture.settingsY || 0, localY);
    } else if (gesture.mode === 'collapse') {
      const dragY = Math.max(0, localY);
      gesture.collapseY = dragY;
      if (!state.playerLandscape) {
        if (!gesture.dropShown && dragY > 14) {
          gesture.dropShown = true;
          swipeHint.textContent = '松开关闭';
          swipeHint.classList.remove('left');
          swipeHint.classList.add('show');
          if (navigator.vibrate) navigator.vibrate(3);
        }
      }
      const scale = playerCollapseScale(dragY);
      if (state.playerLandscape) {
        player.style.transform = `scale(${scale})`;
      } else {
        player.style.transform = `translateY(${dragY}px) scale(${scale})`;
      }
      player.style.opacity = '1';
      player.style.borderRadius = `${Math.min(30, 8 + dragY * 0.18)}px`;
      player.style.boxShadow = dragY > 6 ? '0 28px 78px rgba(0,0,0,.52)' : '';
      if (!state.playerLandscape) {
        const height = player.clientHeight || window.innerHeight || 1;
        const reveal = Math.max(0, Math.min(height, dragY + height * (1 - scale) / 2));
        app.style.setProperty('--player-reveal', `${reveal.toFixed(1)}px`);
      } else {
        app.style.setProperty('--player-reveal', '0px');
      }
    } else if (gesture.mode === 'horizontal') {
      gesture.horizontal = localX;
      if (Date.now() < panelTransitionGuardUntil) {
        gesture.mode = 'none';
        return;
      }
      const rect = playerStage.getBoundingClientRect();
      const localWidth = state.playerLandscape ? rect.height : rect.width;
      if (localX < 0 && state.settings.swipeComments) {
        const progress = Math.min(1, -localX / Math.max(1, localWidth * 0.62));
        commentsPanel.classList.add('peeking');
        commentsPanel.setAttribute('aria-hidden', 'false');
        commentsPanel.inert = true;
        commentsPanel.style.transform = `translateX(${(1 - progress) * 100}%)`;
        setPlayerRecede('right', progress, { dragging: true });
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
        setPlayerRecede('left', progress, { dragging: true });
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
    if (lastStageTap.zone === zone && now - lastStageTap.time < 280) {
      lastStageTap = { time: 0, zone: '' };
      clearTimeout(stageTapTimer);
      stageTapTimer = null;
      if (zone === 'middle') {
        const controlsHidden = playerControls.classList.contains('hidden')
          || player.classList.contains('ui-hidden');
        togglePlay({ reveal: !controlsHidden });
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
    }, 320);
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
      const fromY = state.playerLandscape ? 0 : gesture.collapseY;
      const scale = playerCollapseScale(gesture.collapseY);
      if (!cancelled && gesture.collapseY > 110) {
        hidePlayerDrop();
        closePlayerFromDrop(0, fromY, scale);
        setTimeout(endPlayerDragSnapshot, 720);
        return;
      }
      hidePlayerDrop(0, { restore: true });
      setTimeout(endPlayerDragSnapshot, 280);
      player.style.transition = 'transform .24s cubic-bezier(.16,1,.3,1), opacity .2s ease, border-radius .2s ease, box-shadow .24s ease';
      player.style.transform = 'none';
      player.style.opacity = '1';
      player.style.borderRadius = '0px';
      player.style.boxShadow = '';
      setTimeout(() => {
        if (state.playerOpen) {
          player.style.transition = '';
          player.style.transform = '';
          player.style.opacity = '';
          player.style.borderRadius = '';
          player.style.boxShadow = '';
        }
      }, 260);
    } else if (gesture.mode === 'settings') {
      if ((gesture.settingsY || 0) < -36) openPlayerSettings();
      else showControls();
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
    const local = localPlayerDelta(event.clientX - gesture.startX, event.clientY - gesture.startY);
    gesture.dx = local.x;
    if (!gesture.moved) {
      const intent = swipeIntent(local.x, local.y);
      if (!intent) return;
      gesture.moved = true;
      if (intent === 'right') {
        gesture.dragging = true;
        gesture.base = Math.min(SWIPE_LOCK_PX, local.x);
        commentsPanel.classList.add('dragging');
      }
    }
    if (!gesture.dragging) return;
    const width = commentsPanel.getBoundingClientRect().width || 1;
    const progress = Math.min(1, Math.max(0, (local.x - (gesture.base || 0)) / (width * 0.75)));
    commentsPanel.style.transform = `translateX(${progress * 100}%)`;
    setPlayerRecede('right', 1 - progress, { dragging: true });
  }

  function endCommentsGesture() {
    const gesture = commentsGesture;
    if (!gesture) return;
    commentsGesture = null;
    if (!gesture.dragging) return;
    commentsPanel.classList.remove('dragging');
    if (gesture.dx > 90) closeComments();
    else {
      commentsPanel.style.transform = '';
      setPlayerRecede('right', 1);
    }
  }

  /* ---------- sheets ---------- */
  function mountPlayerSheet() {
    if (!psheet || !psheetBackdrop) return;
    const host = state.playerOpen && state.playerLandscape ? playerRotor : document.body;
    if (psheetBackdrop.parentElement !== host) host.appendChild(psheetBackdrop);
    if (psheet.parentElement !== host) host.appendChild(psheet);
  }

  function openSheet(title, sub, build, options = {}) {
    const minimal = options.minimal === true;
    mountPlayerSheet();
    sheetSwipe = null;
    clearTimeout(sheetSwipeTimer);
    sheetSwipeTimer = null;
    psheet.dataset.kind = '';
    psheet.classList.toggle('minimal', minimal);
    psheetTitle.textContent = minimal ? '' : title;
    psheetSub.textContent = minimal ? '' : (sub || '');
    psheetBody.innerHTML = '';
    if (build) build(psheetBody);
    psheet.style.transition = '';
    psheet.style.transform = '';
    psheetBackdrop.style.opacity = '';
    psheet.inert = false;
    psheet.classList.add('open');
    psheetBackdrop.classList.add('show');
    psheetBody.scrollTop = 0;
  }

  function closeSheet() {
    if (psheet.contains(document.activeElement)) document.activeElement.blur();
    sheetSwipe = null;
    clearTimeout(sheetSwipeTimer);
    sheetSwipeTimer = null;
    psheet.style.transition = '';
    psheet.style.transform = '';
    psheetBackdrop.style.opacity = '';
    psheet.classList.remove('open');
    psheetBackdrop.classList.remove('show');
    psheet.inert = true;
  }

  function startSheetSwipe(event) {
    if (!psheet.classList.contains('open') || !psheet.classList.contains('minimal')) return;
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    if (event.target.closest('input, textarea')) return;
    sheetSwipe = {
      id: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      dy: 0,
      dragging: false,
    };
  }

  function moveSheetSwipe(event) {
    const gesture = sheetSwipe;
    if (!gesture || event.pointerId !== gesture.id) return;
    const local = localPlayerDelta(event.clientX - gesture.startX, event.clientY - gesture.startY);
    if (!gesture.dragging) {
      if (local.y < 10 || Math.abs(local.y) < Math.abs(local.x) * 1.1) return;
      gesture.dragging = true;
      sheetSwipeSuppressClickUntil = Date.now() + 320;
      psheet.style.transition = 'none';
    }
    if (event.cancelable) event.preventDefault();
    gesture.dy = Math.max(0, local.y);
    psheet.style.transform = `translate(-50%, ${gesture.dy}px)`;
    psheetBackdrop.style.opacity = String(Math.max(0, 1 - gesture.dy / 420));
  }

  function endSheetSwipe(event) {
    const gesture = sheetSwipe;
    if (!gesture) return;
    sheetSwipe = null;
    if (event && event.pointerId !== undefined && event.pointerId !== gesture.id) return;
    if (!gesture.dragging) return;
    sheetSwipeSuppressClickUntil = Date.now() + 350;
    clearTimeout(sheetSwipeTimer);
    if (gesture.dy > 92) {
      psheet.style.transition = 'transform .28s cubic-bezier(.4,0,.2,1)';
      psheet.style.transform = 'translate(-50%, 110%)';
      psheetBackdrop.style.opacity = '0';
      sheetSwipeTimer = setTimeout(() => {
        sheetSwipeTimer = null;
        closeSheet();
      }, 280);
      return;
    }
    psheet.style.transition = 'transform .26s cubic-bezier(.16,1,.3,1)';
    psheet.style.transform = '';
    psheetBackdrop.style.opacity = '';
    sheetSwipeTimer = setTimeout(() => {
      sheetSwipeTimer = null;
      if (!sheetSwipe) psheet.style.transition = '';
    }, 280);
  }

  function openOptionsSheet(kind, options = {}) {
    const data = sheetData[kind];
    if (!data) return;
    const minimal = options.minimal === true;
    const sub = minimal ? '' : (typeof data.sub === 'function' ? data.sub() : data.sub);
    openSheet(data.title, sub, (body) => {
      const options = typeof data.options === 'function' ? data.options() : data.options;
      (options || []).forEach((option) => {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = `opt${data.selected() === option.value ? ' on' : ''}`;
        button.innerHTML = `
          <span class="opt-copy">
            <span>${escapeHTML(option.label)}</span>
            ${!minimal && option.meta ? `<small>${escapeHTML(option.meta)}</small>` : ''}
          </span>
          <span class="opt-dot"></span>`;
        button.addEventListener('click', () => {
          data.apply(option.value);
          closeSheet();
        });
        body.appendChild(button);
      });
    }, { minimal });
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
      if (psheet.classList.contains('open')) {
        event.preventDefault();
        if (!psheet.classList.contains('minimal')) closeSheet();
        return;
      }
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
    if (lower === 'd') {
      event.preventDefault();
      state.settings.danmaku = !state.settings.danmaku;
      updatePlayerLabels();
      save();
      return;
    }
    if (lower === 'l') { event.preventDefault(); state.locked ? unlockPlayer() : lockPlayer(); return; }
    if (key === '[') { event.preventDefault(); changeSpeed(-1); return; }
    if (key === ']') { event.preventDefault(); changeSpeed(1); return; }
    if (lower === 'p') {
      event.preventDefault();
      if (window.O11A1NativeData && typeof window.O11A1NativeData.screenshot === 'function') {
        window.O11A1NativeData.screenshot();
      }
      return;
    }
    if (lower === 'n') { event.preventDefault(); stepTrack(1); return; }
    if (lower === 'b') { event.preventDefault(); stepTrack(-1); return; }
    if (/^[1-6]$/.test(key)) {
      event.preventDefault();
      const quality = ['4K', '1080P60', '1080P', '720P', '480P', '仅音频'][Number(key) - 1];
      if (Array.isArray(state.availableQualities) && state.availableQualities.length
        && !state.availableQualities.includes(quality)) return;
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
      actionRow(body, '播放设置', '画质 / 硬解 / 默认', () => {
        openSettingsSheet('settings-playback');
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
      actionRow(body, '举报', '', () => '暂未接入');
      actionRow(body, '关闭播放', '停止并清空进度', () => {
        stopPlayback();
      });
    });
  }

  function openModulesSheet() {
    openSheet('主页模块', '选择要在首页显示的模块', (body) => {
      const visible = state.modules.filter((mod) => !(state.settings.hideFish && mod.id === 'fish'));
      visible.forEach((mod) => {
        const row = document.createElement('button');
        row.type = 'button';
        row.className = 'sheet-row tapable';
        row.innerHTML = `<span class="sr-label">${escapeHTML(mod.name)}</span>`
          + `<span class="sr-value">${escapeHTML(mod.desc || '')}</span>`
          + `<span class="sheet-switch${mod.on ? ' on' : ''}" aria-hidden="true"></span>`;
        row.addEventListener('click', () => {
          mod.on = !mod.on;
          if (!mod.on && state.moduleId === mod.id) {
            state.moduleId = state.modules.find((item) => item.on)?.id || null;
          }
          if (!state.moduleId) {
            state.moduleId = state.modules.find((item) => item.on)?.id || null;
          }
          row.querySelector('.sheet-switch')?.classList.toggle('on', mod.on);
          renderModuleSettings();
          refreshHomeHeader();
          save();
        });
        body.appendChild(row);
      });
    });
  }

  function openSettingsSheet(id, options = {}) {
    if (id === 'settings-modules') {
      openModulesSheet();
      return;
    }
    const def = settingsDefinition(id);
    if (!def) return;
    if (id === 'settings-playback') ensureQualityOptions();
    const minimal = options.minimal === true;
    openSheet(def.title, def.sub, (body) => {
      body.dataset.settingsId = id;
      def.rows
        .filter((row) => !minimal || row.type !== 'static')
        .forEach((row) => body.appendChild(buildSettingRow(row)));
    }, { minimal });
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
      const options = typeof row.options === 'function' ? row.options() : row.options;
      (options || []).forEach((option) => {
        const blocked = typeof row.available === 'function' && row.available(option) === false;
        const button = document.createElement('button');
        button.type = 'button';
        button.className = `choice-btn${state.settings[row.key] === option ? ' on' : ''}${blocked ? ' off' : ''}`;
        button.dataset.choiceKey = row.key;
        button.dataset.choiceValue = option;
        button.textContent = option;
        button.disabled = blocked;
        if (blocked) button.title = '当前视频不支持该画质';
        button.addEventListener('click', () => {
          state.settings[row.key] = option;
          $$('.choice-btn', line).forEach((item) => item.classList.toggle('on', item === button));
          save();
          if (row.key === 'theme') flushNativePrefs();
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
      const paintFill = () => {
        const min = Number(row.min) || 0;
        const max = Number(row.max);
        const value = Number(input.value);
        const percent = max > min ? ((value - min) / (max - min)) * 100 : 0;
        input.style.setProperty('--fill', `${Math.max(0, Math.min(100, percent)).toFixed(2)}%`);
      };
      paintFill();
      input.addEventListener('input', () => {
        state.settings[row.key] = Number(input.value);
        output.textContent = format(input.value);
        paintFill();
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
        sub: '默认播放视频支持的最高画质；也可固定默认画质，高画质需大会员',
        rows: [
          { type: 'choice', label: '默认画质', key: 'defaultQuality', options: () => {
            const values = qualityOptionValues();
            const list = ['最高', ...(values.length ? values : ['4K', '1080P60', '1080P+', '1080P', '720P60', '720P', '480P', '360P'])];
            if (state.settings.defaultQuality && !list.includes(state.settings.defaultQuality)) {
              list.push(state.settings.defaultQuality);
            }
            return list;
          } },
          { type: 'choice', label: '当前画质', key: 'quality', options: () => {
            const values = qualityOptionValues();
            return values.length ? values : ['4K', '1080P60', '1080P+', '1080P', '720P60', '720P', '480P', '360P'];
          }, available: (option) => {
            const list = state.availableQualities;
            return !Array.isArray(list) || !list.length || list.includes(option) || option === state.settings.quality;
          }, onChange: () => {
            updatePlayerLabels();
            if (window.O11A1Media && typeof window.O11A1Media.onQualityChange === 'function') {
              window.O11A1Media.onQualityChange(state.settings.quality);
            }
          } },
          { type: 'switch', label: '陀螺仪自动横屏', key: 'autoLandscape', onChange: () => { if (state.settings.autoLandscape) { if (state.playerOpen) startGyro(); } else { stopGyro(); setPlayerOrientation(false); } } },
          { type: 'switch', label: '视频调试 HUD', key: 'debugHud', onChange: updateDebugHud },
          { type: 'switch', label: '视频流刷新率', key: 'feedDebug', onChange: updateDebugHud },
          { type: 'static', label: '解码策略', value: '系统硬解 · 渐进优先 · 60Hz' },
        ],
      },
      'settings-danmaku': {
        title: '弹幕',
        sub: '实时生效，现有弹幕不清空；屏蔽规则在「我的 → 屏蔽」',
        rows: [
          { type: 'switch', label: '弹幕显示', key: 'danmaku', onChange: applyDanmakuSettings },
          { type: 'slider', label: '不透明度', key: 'danmakuOpacity', min: 0, max: 100, unit: '%', onChange: applyDanmakuSettings },
          { type: 'slider', label: '字号', key: 'danmakuSize', min: 50, max: 150, unit: '%', onChange: applyDanmakuSettings },
          { type: 'slider', label: '速度', key: 'danmakuSpeed', min: 50, max: 200, step: 10, format: (v) => `${(v / 100).toFixed(1)}×`, onChange: applyDanmakuSettings },
          { type: 'choice', label: '显示区域', key: 'danmakuArea', options: ['全屏', '1/2 屏', '1/3 屏'], onChange: applyDanmakuSettings },
          { type: 'switch', label: '分布密度', key: 'danmakuDensity', onChange: applyDanmakuSettings },
          { type: 'static', label: '弹幕节拍', value: 'CSS 动画 · 跟随显示刷新' },
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
          { type: 'switch', label: '隐藏直播入口', key: 'hideLive', onChange: applyHiddenEntries },
          { type: 'switch', label: '隐藏番剧入口', key: 'hideBangumi', onChange: applyHiddenEntries },
          { type: 'switch', label: '隐藏养鱼入口', key: 'hideFish', onChange: applyHiddenEntries },
          { type: 'switch', label: '隐藏热搜', key: 'hideHotSearch' },
          { type: 'static', label: '应用范围', value: '首页 / 底栏 / 搜索' },
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
        sub: '页面缓存与本地数据',
        rows: [
          { type: 'static', label: '页面缓存', value: '由系统 WebView 管理' },
          { type: 'action', label: '清理缓存', value: '', run: () => '暂未接入' },
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
      <button class="search-hot-row" type="button" data-search-term="${escapeHTML(term)}">
        <i class="shr-rank${index < 3 ? ' top' : ''}">${index + 1}</i>
        <span class="shr-text">${escapeHTML(term)}</span>
      </button>`).join('');
  }

  const suggestCache = new Map();
  const suggestPending = new Map();
  let suggestToken = 0;
  let suggestTimer = 0;
  let suggestAbort = null;
  let lastSuggestQuery = '';

  function fetchSuggestions(query, signal) {
    const q = String(query || '').trim();
    if (!q) return Promise.resolve([]);
    const cached = suggestCache.get(q);
    if (cached) return Promise.resolve(cached);
    const pending = suggestPending.get(q);
    if (pending) return pending;
    const bridge = window.O11A1Native;
    if (!bridge || typeof bridge.suggestAsync !== 'function') return Promise.resolve([]);
    const request = bridge.suggestAsync(q, signal).then((raw) => {
      let result = {};
      try { result = JSON.parse(raw); } catch (_) {}
      const items = Array.isArray(result.items)
        ? result.items
          .map((item) => String(item.value || item.term || item.name || '').trim())
          .filter(Boolean)
          .slice(0, 8)
        : [];
      suggestCache.set(q, items);
      if (suggestCache.size > 60) {
        const first = suggestCache.keys().next().value;
        if (first) suggestCache.delete(first);
      }
      suggestPending.delete(q);
      return items;
    }).catch(() => {
      suggestPending.delete(q);
      return [];
    });
    suggestPending.set(q, request);
    return request;
  }

  function suggestionMarkup(terms) {
    return terms.map((term) => `
      <button class="search-suggest" type="button" data-search-term="${escapeHTML(term)}">
        <span class="ss-icon" aria-hidden="true"><svg viewBox="0 0 24 24"><circle cx="11" cy="11" r="6.6"/><path d="m16 16 4.4 4.4"/></svg></span><b>${escapeHTML(term)}</b>
      </button>`).join('');
  }

  function renderSearchSuggestions(query) {
    if (!searchSuggestList) return;
    const q = String(query || '').trim();
    const token = ++suggestToken;
    clearTimeout(suggestTimer);
    if (suggestAbort) {
      try { suggestAbort.abort(); } catch (_) {}
      suggestAbort = null;
    }
    if (!q) {
      lastSuggestQuery = '';
      searchSuggestList.innerHTML = '';
      return;
    }
    /* Same query (e.g. cursor/IME churn): keep the current list and do not
       issue another suggestion request. */
    if (q === lastSuggestQuery) return;
    lastSuggestQuery = q;
    const cached = suggestCache.get(q);
    if (cached) {
      searchSuggestList.innerHTML = suggestionMarkup(cached);
      return;
    }
    // Keep the input responsive: only ask after the user pauses on a segment.
    suggestTimer = setTimeout(() => {
      const controller = typeof AbortController === 'function' ? new AbortController() : null;
      suggestAbort = controller;
      fetchSuggestions(q, controller ? controller.signal : undefined).then((terms) => {
        if (controller && suggestAbort !== controller) return;
        suggestAbort = null;
        if (token !== suggestToken || searchInput.value.trim() !== q) return;
        searchSuggestList.innerHTML = suggestionMarkup(terms);
      }).catch(() => {
        if (controller && suggestAbort === controller) suggestAbort = null;
      });
    }, 240);
  }

  function updateSearch() {
    const query = searchInput.value.trim();
    const hasQuery = query.length > 0;
    searchClear.hidden = !hasQuery;
    if (searchResultsBlock) searchResultsBlock.hidden = true;
    if (searchResults) searchResults.hidden = true;
    if (searchHotSection) searchHotSection.hidden = hasQuery;
    if (searchSuggestSection) searchSuggestSection.hidden = !hasQuery;
    if (searchPanelBody && hasQuery && searchPanelBody.scrollTop) searchPanelBody.scrollTop = 0;
    renderSearchSuggestions(query);
  }

  function renderDockHotSearches() {
    if (!dockHotSearchList) return;
    dockHotSearchList.innerHTML = HOT_SEARCHES.map((term, index) => `
      <button class="search-hot-row" type="button" data-search-term="${escapeHTML(term)}">
        <i class="shr-rank${index < 3 ? ' top' : ''}">${index + 1}</i>
        <span class="shr-text">${escapeHTML(term)}</span>
      </button>`).join('');
  }

  let dockSuggestToken = 0;
  let dockSuggestTimer = 0;
  function renderDockSearchSuggestions(query) {
    if (!dockSearchSuggestList) return;
    const q = String(query || '').trim();
    const token = ++dockSuggestToken;
    clearTimeout(dockSuggestTimer);
    if (!q) {
      dockSearchSuggestList.innerHTML = '';
      return;
    }
    dockSuggestTimer = setTimeout(() => {
      fetchSuggestions(q).then((terms) => {
        if (token !== dockSuggestToken || pdSearchInput.value.trim() !== q) return;
        dockSearchSuggestList.innerHTML = suggestionMarkup(terms);
      });
    }, 90);
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
    const query = String(term || searchInput.value).trim();
    if (!query) return;
    if (!state.searchOpen) openSearch();
    setDockExpanded(false);
    if (playlistDock.classList.contains('searching')) exitDockSearch();
    searchInput.value = query;
    searchClear.hidden = false;
    showSearchResults(query);
    searchInput.blur();
    syncKeyboardOffset();
    if (window.O11A1NativeData && typeof window.O11A1NativeData.searchAsync === 'function') {
      window.O11A1NativeData.searchAsync(query);
    } else if (window.O11A1NativeData && typeof window.O11A1NativeData.search === 'function') {
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
    if (searchDismissing) return;
    if (keyboardSyncFrame) return;
    keyboardSyncFrame = requestAnimationFrame(() => {
      keyboardSyncFrame = 0;
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
    });
  }

  if (window.visualViewport) {
    window.visualViewport.addEventListener('resize', syncKeyboardOffset);
    window.visualViewport.addEventListener('scroll', syncKeyboardOffset);
  }
  window.addEventListener('resize', syncKeyboardOffset);
  syncKeyboardOffset();

  document.addEventListener('contextmenu', (event) => {
    event.preventDefault();
  }, true);
  document.addEventListener('selectstart', (event) => {
    event.preventDefault();
  }, true);
  document.addEventListener('dragstart', (event) => {
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
      if (Date.now() < suppressFeedClickUntil) return;
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
      const fromPlayerSettings = Boolean(sheet.closest('#playerSettings'));
      if (sheetData[kind]) openOptionsSheet(kind, { minimal: fromPlayerSettings });
      else if (kind.startsWith('settings-')) openSettingsSheet(kind, { minimal: fromPlayerSettings });
      return;
    }
  });

  if (searchBack) searchBack.addEventListener('click', closeSearchFromSwipe);
  const myBackButton = $('#myBack');
  if (myBackButton) myBackButton.addEventListener('click', closeMyPageFromSwipe);
  searchClear.addEventListener('click', () => {
    searchInput.value = '';
    updateSearch();
    searchInput.focus();
  });
  let searchComposing = false;
  searchInput.addEventListener('compositionstart', () => {
    searchComposing = true;
  });
  searchInput.addEventListener('compositionend', () => {
    searchComposing = false;
    updateSearch();
  });
  searchInput.addEventListener('input', (event) => {
    /* Do not run suggestions against half-composed Pinyin/IME text. */
    if (searchComposing || event.isComposing) return;
    updateSearch();
  });
  searchInput.addEventListener('focus', syncKeyboardOffset);
  searchInput.addEventListener('blur', syncKeyboardOffset);
  if (pdSearchInput) {
    pdSearchInput.addEventListener('focus', syncKeyboardOffset);
    pdSearchInput.addEventListener('blur', syncKeyboardOffset);
  }
  searchInput.addEventListener('keydown', (event) => {
    if (event.isComposing || searchComposing) return;
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

  if (loginSend) loginSend.addEventListener('click', sendLoginCode);
  if (loginSubmit) loginSubmit.addEventListener('click', submitSmsLogin);
  if (loginCode) loginCode.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') submitSmsLogin();
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
  });

  /* player */
  pcQuality.addEventListener('click', () => setPcPanel('quality'));
  pcDanmaku.addEventListener('click', () => setPcPanel('danmaku'));
  pcLoop.addEventListener('click', cycleLoop);
  lockBadge.addEventListener('click', unlockPlayer);

  if (playerSettings) {
    playerSettings.addEventListener('pointerdown', startSettingsDraw);
  }
  window.addEventListener('pointermove', moveSettingsDraw);
  window.addEventListener('pointerup', endSettingsDraw);
  window.addEventListener('pointercancel', endSettingsDraw);

  const playerSettingsList = $('.player-settings-list');
  function startSettingsListTouch(event) {
    if (!playerSettingsOpen || event.touches.length !== 1) return;
    settingsListTouch = { y: event.touches[0].clientY, list: event.currentTarget };
  }
  function moveSettingsListTouch(event) {
    if (!settingsListTouch || event.touches.length !== 1) return;
    const list = settingsListTouch.list;
    const dy = event.touches[0].clientY - settingsListTouch.y;
    if (list.scrollTop > 0 || dy < -6) {
      settingsListTouch = null;
      return;
    }
    if (dy < 6) return;
    if (event.cancelable) event.preventDefault();
  }
  function endSettingsListTouch() {
    settingsListTouch = null;
  }
  if (playerSettingsList) {
    playerSettingsList.addEventListener('touchstart', startSettingsListTouch, { passive: true });
    playerSettingsList.addEventListener('touchmove', moveSettingsListTouch, { passive: false });
    playerSettingsList.addEventListener('touchend', endSettingsListTouch);
    playerSettingsList.addEventListener('touchcancel', endSettingsListTouch);
  }

  if (playerSettings) {
    playerSettings.addEventListener('click', (event) => {
      if (!settingsSuppressClick) return;
      event.preventDefault();
      event.stopPropagation();
      settingsSuppressClick = false;
    }, true);
  }
  if (progressBar) {
    progressBar.addEventListener('pointerdown', startPrecisionDrag);
    window.addEventListener('pointermove', movePrecisionDrag);
    window.addEventListener('pointerup', endPrecisionDrag);
    window.addEventListener('pointercancel', endPrecisionDrag);
  }
  if (gridProgress) {
    gridProgress.addEventListener('pointerdown', startGridDrag);
    window.addEventListener('pointermove', moveGridDrag);
    window.addEventListener('pointerup', endGridDrag);
    window.addEventListener('pointercancel', endGridDrag);
  }

  playerControls.addEventListener('pointerdown', (event) => {
    if (event.target.closest('button, input, .precision-wheel, .grid-progress')) return;
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
    try {
      window.__backdropDebug = {
        at: Date.now(), suppressed: Date.now() < suppressSidebarBackdropUntil,
        until: suppressSidebarBackdropUntil,
      };
    } catch (_) {}
    if (Date.now() < suppressSidebarBackdropUntil) return;
    closeSidebar();
  });
  playlistBack.addEventListener('click', () => closePlaylistPage(true));
  [playlistPageList, dockPlaylistList].forEach((list) => {
    if (!list) return;
    list.addEventListener('pointerdown', handlePlaylistRowPointerDown);
    list.addEventListener('contextmenu', (event) => {
      if (event.target.closest('.playlist-page-item')) event.preventDefault();
    });
  });
  playlistPage.addEventListener('pointerdown', (event) => {
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    if (!playlistPage.classList.contains('active')) return;
    if (event.target.closest('button')) return;
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
    clearTimeout(dockSearchPullTimer);
    dockSearchPullTimer = null;
    playlistDock.style.transition = '';
    playlistDock.style.transform = '';
    playlistDock.style.opacity = '';
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
    if (dockSearchPanel) dockSearchPanel.scrollTop = 0;
  }

  function resetDockSearchPull() {
    clearTimeout(dockSearchPullTimer);
    playlistDock.style.transition = 'transform .26s cubic-bezier(.16,1,.3,1), opacity .2s ease';
    playlistDock.style.transform = 'translate(-50%, 0)';
    playlistDock.style.opacity = '';
    dockSearchPullTimer = setTimeout(() => {
      dockSearchPullTimer = null;
      playlistDock.style.transition = '';
      playlistDock.style.transform = '';
    }, 270);
  }

  function closeDockSearchFromPull() {
    clearTimeout(dockSearchPullTimer);
    playlistDock.style.transition = 'transform .24s cubic-bezier(.22,1,.36,1), opacity .18s ease';
    playlistDock.style.transform = 'translate(-50%, 105%)';
    playlistDock.style.opacity = '0';
    dockSearchPullTimer = setTimeout(() => {
      exitDockSearch();
      playlistDock.style.transition = 'none';
      playlistDock.style.transform = 'translate(-50%, 100%)';
      playlistDock.style.opacity = '0';
      void playlistDock.offsetWidth;
      playlistDock.style.transition = 'transform .28s cubic-bezier(.16,1,.3,1), opacity .2s ease';
      playlistDock.style.transform = 'translate(-50%, 0)';
      playlistDock.style.opacity = '';
      dockSearchPullTimer = setTimeout(() => {
        dockSearchPullTimer = null;
        playlistDock.style.transition = '';
        playlistDock.style.transform = '';
        playlistDock.style.opacity = '';
      }, 300);
    }, 220);
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
    const expanded = playlistDock.classList.contains('expanded');
    const body = event.target.closest('.pd-body');
    if (!expanded && body) return;
    if (!expanded && event.target.closest('.pd-search, .pd-search-input')) return;
    if (!expanded && event.target.closest('button, input')) return;
    dockDrag = {
      id: event.pointerId,
      x: event.clientX,
      y: event.clientY,
      dy: 0,
      moved: false,
      expanded,
      body,
    };
  });
  window.addEventListener('pointermove', (event) => {
    if (!dockDrag || event.pointerId !== dockDrag.id) return;
    const dy = event.clientY - dockDrag.y;
    if (dockDrag.body) {
      if (dy < -6 || dockDrag.body.scrollTop > 0) {
        dockDrag = null;
        return;
      }
      if (dy < 8) return;
    }
    dockDrag.dy = dy;
    if (Math.abs(dy) > 6) dockDrag.moved = true;
    if (!dockDrag.moved) return;
    if (!playlistDock.classList.contains('dragging')) playlistDock.classList.add('dragging');
    const target = dockContentTarget();
    const startContent = dockDrag.expanded ? target : 96;
    const content = Math.max(96, Math.min(target, startContent - dy));
    const progress = (content - 96) / Math.max(1, target - 96);
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

  function startDockBodyTouch(event) {
    if (!playlistDock.classList.contains('expanded')) return;
    if (playlistDock.classList.contains('searching')) return;
    if (!dockPlaylistBody || dockPlaylistBody.scrollTop > 0) return;
    if (event.touches.length !== 1) return;
    dockBodyTouch = { y: event.touches[0].clientY, mode: null };
  }

  function moveDockBodyTouch(event) {
    if (!dockBodyTouch) return;
    if (event.touches.length !== 1) {
      dockBodyTouch = null;
      return;
    }
    const dy = event.touches[0].clientY - dockBodyTouch.y;
    if (!dockBodyTouch.mode) {
      if (dy < -6) {
        dockBodyTouch = null;
        return;
      }
      if (dy < 6) return;
      dockBodyTouch.mode = 'dock';
    }
    if (event.cancelable) event.preventDefault();
  }

  function endDockBodyTouch() {
    dockBodyTouch = null;
  }

  if (dockPlaylistBody) {
    dockPlaylistBody.addEventListener('touchstart', startDockBodyTouch, { passive: true });
    dockPlaylistBody.addEventListener('touchmove', moveDockBodyTouch, { passive: false });
    dockPlaylistBody.addEventListener('touchend', endDockBodyTouch);
    dockPlaylistBody.addEventListener('touchcancel', endDockBodyTouch);
  }

  playlistDock.addEventListener('pointerdown', (event) => {
    if (!playlistDock.classList.contains('searching')) return;
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    if (event.target.closest('input, textarea')) return;
    const panel = event.target.closest('.pd-search-panel');
    if (panel && dockSearchPanel && dockSearchPanel.scrollTop > 0) return;
    clearTimeout(dockSearchPullTimer);
    dockSearchPullTimer = null;
    dockSearchDrag = {
      id: event.pointerId,
      y: event.clientY,
      dy: 0,
      moved: false,
      panel: Boolean(panel),
    };
  });
  window.addEventListener('pointermove', (event) => {
    if (!dockSearchDrag || event.pointerId !== dockSearchDrag.id) return;
    const dy = event.clientY - dockSearchDrag.y;
    if (dockSearchDrag.panel && dockSearchPanel && dockSearchPanel.scrollTop > 0) {
      dockSearchDrag = null;
      return;
    }
    if (dy < -6) {
      dockSearchDrag = null;
      return;
    }
    if (dy < 6) return;
    dockSearchDrag.dy = dy;
    dockSearchDrag.moved = true;
    suppressDockSearchClickUntil = Date.now() + 420;
    if (event.cancelable) event.preventDefault();
    playlistDock.style.transition = 'none';
    playlistDock.style.transform = `translate(-50%, ${dy}px)`;
    playlistDock.style.opacity = String(Math.max(0.35, 1 - dy / 900));
  });
  window.addEventListener('pointerup', (event) => {
    if (!dockSearchDrag || event.pointerId !== dockSearchDrag.id) return;
    const gesture = dockSearchDrag;
    dockSearchDrag = null;
    if (!gesture.moved) return;
    if (gesture.dy > 96) closeDockSearchFromPull();
    else resetDockSearchPull();
  });
  window.addEventListener('pointercancel', () => {
    if (!dockSearchDrag) return;
    dockSearchDrag = null;
    resetDockSearchPull();
  });

  function startDockSearchTouch(event) {
    if (!playlistDock.classList.contains('searching')) return;
    if (!event.touches || event.touches.length !== 1) return;
    if (event.target.closest('input, textarea')) return;
    const panel = event.target.closest('.pd-search-panel');
    if (panel && dockSearchPanel && dockSearchPanel.scrollTop > 0) return;
    dockSearchTouch = { y: event.touches[0].clientY, panel: Boolean(panel) };
  }

  function moveDockSearchTouch(event) {
    if (!dockSearchTouch) return;
    if (!event.touches || event.touches.length !== 1) {
      dockSearchTouch = null;
      return;
    }
    const dy = event.touches[0].clientY - dockSearchTouch.y;
    if (dockSearchTouch.panel && dockSearchPanel && dockSearchPanel.scrollTop > 0) {
      dockSearchTouch = null;
      return;
    }
    if (dy < -6) {
      dockSearchTouch = null;
      return;
    }
    if (dy < 6) return;
    if (event.cancelable) event.preventDefault();
  }

  function endDockSearchTouch() {
    dockSearchTouch = null;
  }

  playlistDock.addEventListener('touchstart', startDockSearchTouch, { passive: true });
  playlistDock.addEventListener('touchmove', moveDockSearchTouch, { passive: false });
  playlistDock.addEventListener('touchend', endDockSearchTouch);
  playlistDock.addEventListener('touchcancel', endDockSearchTouch);

  playlistDock.addEventListener('click', (event) => {
    if (Date.now() < suppressDockSearchClickUntil) {
      event.preventDefault();
      event.stopPropagation();
    }
  }, true);

  playlistDock.addEventListener('click', (event) => {
    if (playlistDock.classList.contains('searching')) return;
    if (playlistDock.classList.contains('expanded')) return;
    if (event.target.closest('.pd-search, .pd-search-input, .pd-body, .pd-tools')) return;
    if (Date.now() < suppressDockClickUntil) return;
    launchPlayerFromDock();
  });
  playlistDock.addEventListener('keydown', (event) => {
    if (event.target !== playlistDock) return;
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      if (playlistDock.classList.contains('searching')) return;
      if (playlistDock.classList.contains('expanded')) return;
      if (Date.now() < suppressDockClickUntil) return;
      launchPlayerFromDock();
    }
  });
  if (dockBackdrop) {
    dockBackdrop.addEventListener('pointerdown', (event) => {
      if (event.pointerType === 'mouse' && event.button !== 0) return;
      // A tap or downward swipe outside the expanded playlist only dismisses
      // the playlist; it must never fall through and open the feed row below.
      dockDismissClickUntil = Date.now() + 420;
      suppressFeedClickUntil = Date.now() + 420;
      event.preventDefault();
      event.stopPropagation();
      setDockExpanded(false);
    });
  }
  document.addEventListener('click', (event) => {
    if (Date.now() >= dockDismissClickUntil) return;
    event.preventDefault();
    event.stopImmediatePropagation();
  }, true);
  if (pdMode) {
    pdMode.addEventListener('click', (event) => {
      event.stopPropagation();
      cyclePlaybackMode();
      pdMode.classList.remove('switching');
      void pdMode.offsetWidth;
      pdMode.classList.add('switching');
      setTimeout(() => pdMode.classList.remove('switching'), 380);
    });
  }
  if (pdClear) {
    pdClear.addEventListener('click', handleDockClear);
  }
  if (pdSearch) {
    pdSearch.addEventListener('click', (event) => {
      event.stopPropagation();
      if (playlistDock.classList.contains('searching')) return;
      openSearch();
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

  /* A swipe only needs a clear horizontal intent; a little vertical drift while
     opening/closing a drawer must not hand the gesture back to the feed scroll.
     The right side is deliberately more forgiving (1.55:1) because opening the
     sidebar is the most common horizontal gesture. */
  const SWIPE_LOCK_PX = 8;
  const SWIPE_RIGHT_BIAS = 1.55;
  const SWIPE_LEFT_BIAS = 1.15;

  function swipeIntent(dx, dy) {
    const ax = Math.abs(dx);
    const ay = Math.abs(dy);
    if (ax < SWIPE_LOCK_PX && ay < SWIPE_LOCK_PX) return null;
    if (dx >= SWIPE_LOCK_PX && ay <= dx * SWIPE_RIGHT_BIAS) return 'right';
    if (dx <= -SWIPE_LOCK_PX && ay <= ax * SWIPE_LEFT_BIAS) return 'left';
    if (ay >= SWIPE_LOCK_PX) return 'vertical';
    return null;
  }

  /* The landscape player is a portrait WebView with a rotor rotated 90deg.
     Pointer deltas arrive in screen space; gestures inside the rotor must use
     the rotor's local axes or a horizontal finger movement is mistaken for a
     panel swipe instead of a vertical list scroll. */
  function localPlayerDelta(dx, dy) {
    if (!state.playerLandscape) return { x: dx, y: dy };
    const dir = state.playerLandscapeDir < 0 ? -1 : 1;
    return { x: dy * dir, y: -dx * dir };
  }

  /* `touch-action: pan-y` lets WebKit take over a vertical scroll before a
     pointermove-based gesture can lock its axis. This capture-phase guard
     claims horizontal touches early so a right swipe with some vertical wobble
     still reaches the drawer instead of scrolling the feed. */
  function guardIntent(dx, dy) {
    const ax = Math.abs(dx);
    const ay = Math.abs(dy);
    if (dx >= 4 && ay <= dx * 1.25) return 'right';
    if (dx <= -4 && ay <= ax * 1.05) return 'left';
    if (ay >= 6) return 'vertical';
    return null;
  }

  function installSwipeGuard(surface) {
    if (!surface) return;
    /* Panels inside the landscape rotor scroll along the rotated axis. Block
       only local horizontal drags there, or the axis that scrolls the list
       would be prevented as if it were a panel-swipe gesture. */
    const rotated = Boolean(surface.closest && surface.closest('#playerRotor'));
    let guard = null;
    surface.addEventListener('touchstart', (event) => {
      if (event.touches.length !== 1) { guard = null; return; }
      if (event.target.closest('input, textarea, select, [contenteditable="true"], .no-swipe-guard')) {
        guard = null;
        return;
      }
      const point = event.touches[0];
      guard = { x: point.clientX, y: point.clientY, horizontal: false, decided: false };
    }, { capture: true, passive: true });
    surface.addEventListener('touchmove', (event) => {
      if (!guard || event.touches.length !== 1) return;
      const point = event.touches[0];
      if (!guard.decided) {
        const local = rotated
          ? localPlayerDelta(point.clientX - guard.x, point.clientY - guard.y)
          : { x: point.clientX - guard.x, y: point.clientY - guard.y };
        const intent = guardIntent(local.x, local.y);
        if (!intent) return;
        guard.decided = true;
        guard.horizontal = intent === 'right' || intent === 'left';
      }
      if (guard.horizontal && event.cancelable) event.preventDefault();
    }, { capture: true, passive: false });
    const clear = () => { guard = null; };
    surface.addEventListener('touchend', clear, { capture: true, passive: true });
    surface.addEventListener('touchcancel', clear, { capture: true, passive: true });
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
      holdTimer: null,
      holdX: event.clientX,
      holdY: event.clientY,
      upMode: false,
      sidebarActive: false,
      sidebarProgress: 0,
      sidebarSelecting: false,
      sidebarHoldTimer: null,
      sidebarLastX: event.clientX,
      sidebarLastY: event.clientY,
      vx: 0,
      lastX: event.clientX,
      lastAt: performance.now(),
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
    const image = thumb.querySelector('img');
    const origin = {
      thumb,
      rect,
      radius: getComputedStyle(thumb).borderRadius || '0px',
      image: image ? (image.currentSrc || image.src || '') : '',
      time: Date.now(),
    };
    pendingPlayerOrigin = origin;
    setTimeout(() => {
      if (pendingPlayerOrigin === origin) pendingPlayerOrigin = null;
    }, 900);
  }, true);
  appScroll.addEventListener('pointerdown', (event) => startFeedGesture(event, 'scroll'));
  if (upPage) upPage.addEventListener('pointerdown', (event) => startFeedGesture(event, 'up'));
  if (myPage) myPage.addEventListener('pointerdown', (event) => startFeedGesture(event, 'my'));
  if (searchResultsPage) searchResultsPage.addEventListener('pointerdown', (event) => startFeedGesture(event, 'search'));
  if (videoDetailScroll) videoDetailScroll.addEventListener('pointerdown', (event) => startFeedGesture(event, 'detail'));
  installSwipeGuard(appScroll);
  installSwipeGuard(sidebar);
  installSwipeGuard(sidebarBackdrop);
  installSwipeGuard(searchPanel);
  installSwipeGuard(upPage);
  installSwipeGuard(myPage);
  installSwipeGuard(commentsPanel);
  installSwipeGuard(videoDetailPanel);

  window.addEventListener('pointermove', (event) => {
    if (!rowSwipe || event.pointerId !== rowSwipe.id) return;
    const now = performance.now();
    const elapsed = now - rowSwipe.lastAt;
    if (elapsed > 0) {
      const instant = (event.clientX - rowSwipe.lastX) / elapsed;
      rowSwipe.vx = rowSwipe.vx * 0.55 + instant * 0.45;
      rowSwipe.lastX = event.clientX;
      rowSwipe.lastAt = now;
    }
    const dx = event.clientX - rowSwipe.x;
    const dy = event.clientY - rowSwipe.y;
    if (!rowSwipe.direction) {
      const intent = swipeIntent(dx, dy);
      if (!intent) return;
      if (intent === 'right') {
        if (event.cancelable) event.preventDefault();
        if (rowSwipe.surface === 'detail') {
          rowSwipe.direction = 'vertical';
          return;
        }
        if (rowSwipe.surface === 'my') {
          rowSwipe.direction = 'my-close';
          rowSwipe.myBase = Math.min(SWIPE_LOCK_PX, dx);
          rowSwipe.myOffset = 0;
          setMyRecede(1, { dragging: true });
          myPage.classList.add('my-dragging');
          myPage.style.transition = 'none';
          return;
        }
        if (state.searchOpen && searchResultsPage) {
          rowSwipe.direction = 'search-close';
          rowSwipe.searchBase = Math.min(SWIPE_LOCK_PX, dx);
          rowSwipe.searchOffset = 0;
          searchResultsPage.classList.add('dragging');
          app.classList.add('search-dragging');
          applySearchRecede(1);
          return;
        }
        if (rowSwipe.surface === 'up') {
          rowSwipe.direction = 'up-close';
          rowSwipe.upBase = Math.min(SWIPE_LOCK_PX, dx);
          rowSwipe.upOffset = 0;
          setUpRecede(1, { dragging: true });
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
        rowSwipe.sidebarBase = Math.min(SWIPE_LOCK_PX, dx);
        applySidebarDrag(0);
        return;
      }
      if (intent === 'left') {
        /* Row-left actions (queue / UP page) and the long-press shortcut are
           gone; a left drag is just a vertical scroll now. */
        rowSwipe.direction = 'vertical';
        return;
      }
      rowSwipe.direction = 'vertical';
      // A fling that starts on a row must never turn its lift into a click.
      suppressFeedClickUntil = Date.now() + 420;
      return;
    }
    if (rowSwipe.direction === 'search-close') {
      if (event.cancelable) event.preventDefault();
      const width = app.clientWidth || window.innerWidth;
      const offset = Math.max(0, Math.min(width, dx - (rowSwipe.searchBase || 0)));
      rowSwipe.searchOffset = offset;
      searchResultsPage.style.transform = `translate3d(${offset}px,0,0)`;
      applySearchRecede(1 - offset / Math.max(1, width));
      return;
    }
    if (rowSwipe.direction === 'up-close') {
      if (event.cancelable) event.preventDefault();
      const width = app.clientWidth || window.innerWidth;
      const offset = Math.max(0, Math.min(width, dx - (rowSwipe.upBase || 0)));
      rowSwipe.upOffset = offset;
      upPage.style.transform = `translate3d(${offset}px,0,0)`;
      upPage.style.boxShadow = offset > 0 ? '-18px 0 46px rgba(10,12,20,.18)' : '';
      setUpRecede(1 - offset / width, { dragging: true });
      return;
    }
    if (rowSwipe.direction === 'my-close') {
      if (event.cancelable) event.preventDefault();
      const width = app.clientWidth || window.innerWidth;
      const offset = Math.max(0, Math.min(width, dx - (rowSwipe.myBase || 0)));
      rowSwipe.myOffset = offset;
      myPage.style.transform = `translate3d(${offset}px,0,0)`;
      myPage.style.boxShadow = offset > 0 ? '-18px 0 46px rgba(10,12,20,.18)' : '';
      setMyRecede(1 - offset / width, { dragging: true });
      return;
    }
    if (rowSwipe.direction === 'right') {
      if (event.cancelable) event.preventDefault();
      rowSwipe.sidebarLastX = event.clientX;
      rowSwipe.sidebarLastY = event.clientY;
      const width = app.clientWidth || window.innerWidth;
      const travel = Math.max(0, dx - (rowSwipe.sidebarBase || 0));
      const progress = Math.min(1, Math.max(0, travel / (width * 0.5)));
      rowSwipe.sidebarProgress = progress;
      applySidebarDrag(progress);
      if (rowSwipe.sidebarSelecting) moveSidebarSelect(rowSwipe, event.clientY);
      return;
    }
    if (rowSwipe.direction !== 'left') return;
    if (event.cancelable) event.preventDefault();
    const swipe = rowSwipe;
    const offset = Math.min(ROW_ACTION_MAX, Math.max(0, -dx - (swipe.swipeBase || 0)));
    swipe.offset = offset;
    if (swipe.upMode) {
      if (offset < ROW_ACTION_ARM) {
        swipe.upMode = false;
        if (swipe.wrapper) swipe.wrapper.__rowUpMode = false;
        clearTimeout(swipe.holdTimer);
        swipe.holdTimer = null;
      }
      setRowSwipe(swipe.wrapper, offset);
      return;
    }
    if (offset < ROW_ACTION_ARM) {
      clearTimeout(swipe.holdTimer);
      swipe.holdTimer = null;
      swipe.holdX = event.clientX;
      swipe.holdY = event.clientY;
      setRowSwipe(swipe.wrapper, offset);
      return;
    }
    const moved = Math.abs(event.clientX - swipe.holdX) > ROW_ACTION_HOLD_SLOP
      || Math.abs(event.clientY - swipe.holdY) > ROW_ACTION_HOLD_SLOP;
    if (!swipe.holdTimer || moved) {
      clearTimeout(swipe.holdTimer);
      swipe.holdX = event.clientX;
      swipe.holdY = event.clientY;
      swipe.holdTimer = setTimeout(() => {
        if (rowSwipe !== swipe || swipe.direction !== 'left' || swipe.upMode) return;
        if (swipe.offset < ROW_ACTION_ARM) return;
        swipe.upMode = true;
        if (swipe.wrapper) swipe.wrapper.__rowUpMode = true;
        setRowSwipe(swipe.wrapper, swipe.offset);
        if (navigator.vibrate) navigator.vibrate(8);
      }, ROW_ACTION_HOLD_MS);
    }
    setRowSwipe(swipe.wrapper, offset);
  }, { passive: false });
  window.addEventListener('pointerup', (event) => {
    if (!rowSwipe || event.pointerId !== rowSwipe.id) return;
    const start = rowSwipe;
    rowSwipe = null;
    clearTimeout(start.holdTimer);
    start.holdTimer = null;
    const vx = performance.now() - (start.lastAt || 0) > 90 ? 0 : (start.vx || 0);
    if (start.direction === 'right') {
      endSidebarDrag(start, event, vx);
      return;
    }
    if (start.direction === 'search-close') {
      suppressFeedClickUntil = Date.now() + 420;
      const width = app.clientWidth || window.innerWidth;
      if ((start.searchOffset || 0) > width * 0.24 || vx > 0.35) closeSearchFromSwipe();
      else resetSearchResultsDrag();
      return;
    }
    if (start.direction === 'up-close') {
      suppressFeedClickUntil = Date.now() + 420;
      const width = app.clientWidth || window.innerWidth;
      if ((start.upOffset || 0) > width * 0.24 || vx > 0.35) closeUpPageFromSwipe();
      else resetUpPageDrag();
      return;
    }
    if (start.direction === 'my-close') {
      suppressFeedClickUntil = Date.now() + 420;
      const width = app.clientWidth || window.innerWidth;
      if ((start.myOffset || 0) > width * 0.24 || vx > 0.35) closeMyPageFromSwipe();
      else resetMyPageDrag();
      return;
    }
    if (start.direction !== 'left') return;
    suppressFeedClickUntil = Date.now() + 420;
    const action = start.upMode ? 'up' : (start.offset >= ROW_ACTION_ARM ? 'queue' : '');
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
    try {
      window.__swipeCancelDebug = {
        at: Date.now(), direction: start.direction,
        progress: start.sidebarProgress || 0,
      };
    } catch (_) {}
    clearTimeout(start.holdTimer);
    start.holdTimer = null;
    if (start.direction === 'right') endSidebarDrag(start, { type: 'pointercancel' });
    else if (start.direction === 'left') resetRowSwipe(start.wrapper);
    else if (start.direction === 'up-close') resetUpPageDrag();
    else if (start.direction === 'my-close') resetMyPageDrag();
    else if (start.direction === 'search-close') resetSearchResultsDrag();
  });

  appScroll.addEventListener('scroll', () => {
    if (document.body.classList.contains('native-app')) return;
    maybeAppendMockFeed();
    const feed = activeFeed();
    if (feed) scheduleMockTrim(feed);
  });

  function sidebarCloseGesture(event) {
    if (sidebarSwipeStart && sidebarSwipeStart.id === event.pointerId) return sidebarSwipeStart;
    if (menuSwipeStart && menuSwipeStart.id === event.pointerId) return menuSwipeStart;
    return null;
  }

  function moveSidebarCloseDrag(start, event) {
    if (!start) return;
    const now = performance.now();
    const elapsed = now - (start.lastAt || now);
    if (elapsed > 0) {
      const instant = (event.clientX - (start.lastX ?? start.x)) / elapsed;
      start.vx = (start.vx || 0) * 0.55 + instant * 0.45;
      start.lastX = event.clientX;
      start.lastAt = now;
    }
    const dx = event.clientX - start.x;
    const dy = event.clientY - start.y;
    if (!start.active) {
      if (start.vertical) return;
      const intent = swipeIntent(dx, dy);
      if (!intent) return;
      if (intent !== 'left') {
        if (intent === 'vertical') start.vertical = true;
        return;
      }
      start.active = true;
      start.base = Math.min(SWIPE_LOCK_PX, -dx);
      app.classList.add('sidebar-dragging');
      sidebar.classList.remove('selecting');
    }
    if (event.cancelable) event.preventDefault();
    const width = app.clientWidth || window.innerWidth;
    const travel = Math.max(0, -dx - (start.base || 0));
    const progress = Math.max(0, Math.min(1, 1 - travel / (width * 0.5)));
    start.progress = progress;
    applySidebarDrag(progress);
  }

  function endSidebarCloseDrag(start) {
    if (!start) return;
    suppressSidebarClickUntil = Date.now() + 180;
    suppressSidebarBackdropUntil = Date.now() + 360;
    const vx = performance.now() - (start.lastAt || 0) > 90 ? 0 : (start.vx || 0);
    if (start.progress < 0.78 || vx < -0.32) closeSidebarFromDrag();
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
      vx: 0,
      lastX: event.clientX,
      lastAt: performance.now(),
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
      vx: 0,
      lastX: event.clientX,
      lastAt: performance.now(),
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
      suppressSidebarClickUntil = Date.now() + 180;
      suppressSidebarBackdropUntil = Date.now() + 360;
      closeSidebarFromDrag();
      return;
    }
    /* A vertical drag that starts on the dimmed backdrop must never fall
       through as a backdrop tap (which would instantly close the menu). */
    if (Math.hypot(dx, dy) > 8) {
      suppressSidebarClickUntil = Math.max(suppressSidebarClickUntil, Date.now() + 180);
      suppressSidebarBackdropUntil = Math.max(suppressSidebarBackdropUntil, Date.now() + 360);
      suppressFeedClickUntil = Math.max(suppressFeedClickUntil, Date.now() + 360);
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
    /* Only interactions with the visible toolbar keep it awake; a tap on the
       video itself must fall through to the show/hide toggle. */
    if (!event.target.closest('.player-controls')) return;
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

  commentsPanel.addEventListener('pointerdown', startCommentsGesture);
  if (videoDetailPanel) {
    videoDetailPanel.addEventListener('pointerdown', startVideoDetailSwipe);
    videoDetailPanel.addEventListener('click', (event) => {
      if (Date.now() < suppressDetailClickUntil) {
        event.preventDefault();
        event.stopPropagation();
        return;
      }
      const row = event.target.closest('.video-row');
      if (!row) return;
      if (Date.now() < suppressFeedClickUntil) return;
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

  psheetBackdrop.addEventListener('click', () => {
    if (psheet.classList.contains('minimal')) return;
    closeSheet();
  });
  psheetClose.addEventListener('click', closeSheet);
  psheet.addEventListener('pointerdown', startSheetSwipe);
  window.addEventListener('pointermove', moveSheetSwipe, { passive: false });
  window.addEventListener('pointerup', endSheetSwipe);
  window.addEventListener('pointercancel', endSheetSwipe);
  psheet.addEventListener('click', (event) => {
    if (Date.now() >= sheetSwipeSuppressClickUntil) return;
    event.preventDefault();
    event.stopPropagation();
  }, true);

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
      if (psheet.classList.contains('open')) {
        event.preventDefault();
        if (!psheet.classList.contains('minimal')) closeSheet();
        return;
      }
      if (protoDrawer.classList.contains('open')) { closeDrawer(); return; }
      if (state.searchOpen) { closeSearch(); return; }
      if (state.page === 'my') { closeMyPageFromSwipe(); return; }
      if (state.playerOpen) { minimizePlayer(); return; }
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
    openSearch,
    closeSearch: closeSearchFromSwipe,
    closeMyPage: closeMyPageFromSwipe,
    openPlaylistPage,
    setPlayerOrientation,
    openPlayer,
    setPlayerOrigin: setPlayerOriginFromRow,
    minimizePlayer,
    stopPlayback,
    updatePlayerLabels,
    updatePlaylistDock,
    setDockExpanded,
    beginPlayerDragSnapshot,
    endPlayerDragSnapshot,
    refreshQualityChoices,
    updatePlaylistCounts,
    showPlayerNotice,
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
    suppressFeedClicks: (ms) => {
      suppressFeedClickUntil = Math.max(
        suppressFeedClickUntil,
        Date.now() + Math.max(0, Math.min(1200, Number(ms) || 0))
      );
    },
    openComments,
    closeVideoDetail,
    openUpFromDetail,
    setTiltDir: setTiltDirection,
    playerVideo,
    pcPlay,
    setPlayIcon,
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
    setUserIdentity: (face, name) => {
      const nextFace = typeof face === 'string' ? face : '';
      const nextName = typeof name === 'string' ? name : '';
      if (state.userFace === nextFace && state.userName === nextName) return;
      state.userFace = nextFace;
      state.userName = nextName;
      save();
      refreshUserNav();
      try {
        if (window.ReactNativeWebView && typeof window.ReactNativeWebView.postMessage === 'function') {
          window.ReactNativeWebView.postMessage(JSON.stringify({
            type: 'user', face: nextFace, name: nextName,
          }));
        }
      } catch (_) {}
    },
  };

  /* init */
  document.body.dataset.platform = state.platform;

  const launchScreen = $('#launchScreen');
  const launchAvatar = $('#launchAvatar');
  const launchName = $('#launchName');
  const launchBarFill = $('#launchBarFill');
  let launchHideTimer = null;
  let launchPollTimer = null;

  function paintLaunchIdentity() {
    if (!launchAvatar) return;
    if (state.userFace) {
      launchAvatar.style.backgroundImage = `url("${String(state.userFace).replace(/"/g, '%22')}")`;
      launchAvatar.textContent = '';
    } else {
      launchAvatar.style.backgroundImage = '';
      launchAvatar.textContent = (state.userName || 'B').slice(0, 1);
    }
    if (launchName) launchName.textContent = state.userName || '正在进入';
  }

  function hideLaunchSplash(delay = 140) {
    if (!launchScreen || !launchScreen.classList.contains('show')) return;
    if (launchBarFill) launchBarFill.style.width = '100%';
    clearTimeout(launchHideTimer);
    launchHideTimer = setTimeout(() => {
      launchScreen.classList.add('hide');
      setTimeout(() => {
        launchScreen.classList.remove('show', 'hide');
        launchScreen.setAttribute('aria-hidden', 'true');
      }, 300);
    }, delay);
  }

  function waitForLaunchReady() {
    clearInterval(launchPollTimer);
    let elapsed = 0;
    launchPollTimer = setInterval(() => {
      elapsed += 100;
      const feed = document.querySelector('#homeFeed');
      const ready = Boolean(feed && (feed.querySelector('.real-row') || feed.querySelector('.feed-item:not(.feed-skeleton)')));
      if (launchBarFill) {
        const target = ready ? 100 : Math.min(92, 16 + elapsed / 16);
        launchBarFill.style.width = `${target}%`;
      }
      if (ready || elapsed >= 1700) {
        clearInterval(launchPollTimer);
        launchPollTimer = null;
        hideLaunchSplash(ready ? 90 : 0);
      }
    }, 100);
  }

  /* A native cookie/session is enough to skip the SMS gate on launch. */
  if (!state.loggedIn) {
    const nativeSession = nativeLoginCall('session', []);
    if (nativeSession && nativeSession.ok && nativeSession.loggedIn) {
      state.loggedIn = true;
      save();
    }
  }
  const showLaunch = state.loggedIn;
  if (showLaunch && launchScreen) {
    paintLaunchIdentity();
    launchScreen.setAttribute('aria-hidden', 'false');
    launchScreen.classList.add('show');
    if (launchBarFill) launchBarFill.style.width = '8%';
    requestAnimationFrame(() => {
      if (launchBarFill) launchBarFill.style.width = '22%';
    });
  } else if (launchScreen) {
    launchScreen.classList.remove('show', 'hide');
    launchScreen.setAttribute('aria-hidden', 'true');
  }

  app.classList.toggle('auth-gate', !state.loggedIn);
  $$('#platformSwitch button').forEach((button) => {
    button.classList.toggle('on', button.dataset.platform === state.platform);
  });
  applyAppearance();
  applyHiddenEntries();
  initGridProgress();
  updatePlayerLabels();
  initDebugHud();
  renderHotSearches();
  updateSearch();
  syncLandscape();
  showPage(state.loggedIn ? 'home' : 'login');
  if (showLaunch) waitForLaunchReady();
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden) syncNativeLogin();
  });
  window.addEventListener('focus', () => syncNativeLogin());
  setTimeout(syncNativeLogin, 800);

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
    await sleep(1000);
    playerControls.classList.add('hidden');
    player.classList.add('ui-hidden');
    const sideTap = stagePoint('left');
    playerStage.dispatchEvent(pointerEvent('pointerdown', sideTap.x, sideTap.y, 1));
    window.dispatchEvent(pointerEvent('pointerup', sideTap.x, sideTap.y, 0));
    await sleep(420);
    results.push(`sideTap=${!playerControls.classList.contains('hidden')}`);
    window.O11A1Host.setTiltDir(1);
    await sleep(480);
    const nativeTilt = state.playerLandscape === true && state.playerLandscapeDir === 1;
    window.O11A1Host.setTiltDir(0);
    await sleep(480);
    results.push(`tiltDir=${nativeTilt && state.playerLandscape === false}`);
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
    dispatchSwipe('left', 0, -150);
    await sleep(450);
    results.push(`noRotate=${state.playerLandscape === false}`);
    const settingsOpened = playerSettingsOpen;
    const settingsRect = playerSettingsCard.getBoundingClientRect();
    const settingsTitleLeft = $('.player-settings-titlebar b').getBoundingClientRect().left;
    const qualityRow = $('#pcQuality');
    const qualityTop = qualityRow.getBoundingClientRect().top;
    qualityRow.click();
    await sleep(160);
    const settingsFixed = Math.abs(playerSettingsCard.getBoundingClientRect().height - settingsRect.height) < 1.5
      && Math.abs(qualityRow.getBoundingClientRect().top - qualityTop) < 1.5
      && $('#pcQualityGroup').classList.contains('open');
    qualityRow.click();
    await sleep(100);
    results.push(`settingsFixed=${settingsFixed}`);
    results.push(`settingsTitleLeft=${settingsTitleLeft < settingsRect.left + 80}`);
    const settingsX = settingsRect.left + settingsRect.width * 0.5;
    const settingsY = settingsRect.top + 30;
    playerSettingsCard.dispatchEvent(pointerEvent('pointerdown', settingsX, settingsY, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', settingsX, settingsY + (110 * step) / 6, 1));
    }
    window.dispatchEvent(pointerEvent('pointerup', settingsX, settingsY + 110, 0));
    await sleep(500);
    results.push(`settings=${settingsOpened && !playerSettingsOpen}`);

    await sleep(180);
    const collapseStart = stagePoint('middle');
    playerStage.dispatchEvent(pointerEvent('pointerdown', collapseStart.x, collapseStart.y, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', collapseStart.x, collapseStart.y + (190 * step) / 6, 1));
    }
    await sleep(90);
    const dropDown = playerDrop.classList.contains('show')
      && playerDrop.querySelector('.player-drop-zone.hot')?.dataset.dropZone === '0';
    window.dispatchEvent(pointerEvent('pointerup', collapseStart.x, collapseStart.y + 190, 0));
    await sleep(620);
    results.push(`dropDown=${dropDown}`);
    results.push(`dropCloseDown=${!state.playerOpen && !state.miniVisible}`);

    await sleep(260);
    openPlayer({ resume: true });
    await sleep(650);
    const closeStart = stagePoint('middle');
    playerStage.dispatchEvent(pointerEvent('pointerdown', closeStart.x, closeStart.y, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', closeStart.x - (150 * step) / 6, closeStart.y + (190 * step) / 6, 1));
    }
    await sleep(90);
    const dropLeft = playerDrop.querySelector('.player-drop-zone.hot')?.dataset.dropZone === '-1';
    window.dispatchEvent(pointerEvent('pointerup', closeStart.x - 150, closeStart.y + 190, 0));
    await sleep(900);
    results.push(`dropZones=${dropLeft}`);
    results.push(`collapsed=${!state.playerOpen && state.miniVisible}`);

    await sleep(260);
    const detailSeedRow = $('#homeFeed .video-row');
    const detailSeedItem = detailSeedRow ? detailSeedRow.__nativeItem : null;
    const detailCurrent = state.playlist[state.currentIndex];
    if (detailSeedItem && detailCurrent && !detailCurrent.bvid) {
      Object.assign(detailCurrent, {
        bvid: detailSeedItem.bvid,
        aid: detailSeedItem.aid,
        cid: detailSeedItem.cid,
        mid: detailSeedItem.mid,
        title: detailSeedItem.title,
        owner: detailSeedItem.owner,
        pic: detailSeedItem.pic,
        duration: detailSeedItem.duration,
        durationSec: detailSeedItem.durationSec,
      });
      updatePlayerLabels();
      save();
    }
    openPlayer({ resume: true });
    await sleep(360);
    dispatchSwipe('middle', 240, 0);
    await sleep(650);
    results.push(`detail=${videoDetailPanel.classList.contains('open')}`);
    results.push(`detailNoRelated=${!videoDetailBody.querySelector('.detail-related, .vd-section')}`);
    const detailRect = videoDetailPanel.getBoundingClientRect();
    const detailRow = videoDetailBody.querySelector('.feed-item .video-row');
    const detailRowRect = detailRow ? detailRow.getBoundingClientRect() : detailRect;
    const detailStartX = detailRow
      ? detailRowRect.left + Math.max(20, detailRowRect.width * 0.7)
      : detailRect.left + detailRect.width * 0.62;
    const detailStartY = detailRow
      ? detailRowRect.top + detailRowRect.height * 0.5
      : detailRect.top + 120;
    const detailSwipeTarget = detailRow || videoDetailPanel;
    detailSwipeTarget.dispatchEvent(pointerEvent('pointerdown', detailStartX, detailStartY, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', detailStartX - (150 * step) / 6, detailStartY, 1));
    }
    window.dispatchEvent(pointerEvent('pointerup', detailStartX - 150, detailStartY, 0));
    const playlistBeforeDetailClick = state.playlist.length;
    if (detailRow) {
      detailRow.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
    }
    await sleep(500);
    results.push(`detailClose=${!videoDetailPanel.classList.contains('open')}`);
    results.push(`detailSwipeNoClick=${state.playlist.length === playlistBeforeDetailClick}`);
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
    await sleep(420);
    const tapHidden = playerControls.classList.contains('hidden');
    playerStage.dispatchEvent(pointerEvent('pointerdown', tap.x, tap.y, 1));
    window.dispatchEvent(pointerEvent('pointerup', tap.x, tap.y, 0));
    await sleep(420);
    const tapShown = !playerControls.classList.contains('hidden');
    await sleep(2300);
    results.push(`toolbarHide=${tapShown && playerControls.classList.contains('hidden')}`);
    results.push(`tapToggle=${tapHidden && tapShown}`);
    playerStage.dispatchEvent(pointerEvent('pointerdown', tap.x, tap.y, 1));
    window.dispatchEvent(pointerEvent('pointerup', tap.x, tap.y, 0));
    await sleep(100);
    playerStage.dispatchEvent(pointerEvent('pointerdown', tap.x, tap.y, 1));
    window.dispatchEvent(pointerEvent('pointerup', tap.x, tap.y, 0));
    await sleep(380);
    const doubleKeptHidden = playerControls.classList.contains('hidden');
    playerStage.dispatchEvent(pointerEvent('pointerdown', tap.x, tap.y, 1));
    window.dispatchEvent(pointerEvent('pointerup', tap.x, tap.y, 0));
    await sleep(420);
    const singleAfterDouble = !playerControls.classList.contains('hidden');
    results.push(`doubleTapSingle=${doubleKeptHidden && singleAfterDouble}`);
    showControls();
    await sleep(40);
    setProgress(20, false);
    await sleep(30);
    const gridTest = $('#gridProgress');
    const wheelTest = $('#progressBar');
    const gridTestRect = gridTest.getBoundingClientRect();
    const gridTestX = gridTestRect.left + gridTestRect.width * 0.2;
    const gridTestY = gridTestRect.top + gridTestRect.height / 2;
    const gridStep = gridTestRect.width * 0.25;
    gridTest.dispatchEvent(pointerEvent('pointerdown', gridTestX, gridTestY, 1));
    for (let step = 1; step <= 5; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', gridTestX + (gridStep * step) / 5, gridTestY, 1));
    }
    const gridFlat = Number(gridTest.getAttribute('aria-valuenow'));
    window.dispatchEvent(pointerEvent('pointerup', gridTestX + gridStep, gridTestY, 0));
    await sleep(60);
    setProgress(20, false);
    await sleep(30);
    gridTest.dispatchEvent(pointerEvent('pointerdown', gridTestX, gridTestY, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', gridTestX, gridTestY - (160 * step) / 6, 1));
    }
    for (let step = 1; step <= 5; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', gridTestX + (gridStep * step) / 5, gridTestY - 160, 1));
    }
    const gridLifted = Number(gridTest.getAttribute('aria-valuenow'));
    window.dispatchEvent(pointerEvent('pointerup', gridTestX + gridStep, gridTestY - 160, 0));
    await sleep(60);
    results.push(`grid=${gridTest.children.length === 36 && Math.abs(gridFlat - 45) < 1.2 && gridLifted > 20 && gridLifted - 20 < 12}`);
    const litCells = Array.from(gridTest.querySelectorAll('.grid-cell.on'));
    const litColors = new Set(litCells.map((cell) => getComputedStyle(cell).backgroundColor));
    const litColor = litColors.size === 1 ? Array.from(litColors)[0] : '';
    const rgbMatch = /^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/.exec(litColor);
    results.push(`gridBlue=${Boolean(rgbMatch)
      && Number(rgbMatch[3]) > Number(rgbMatch[1])
      && Number(rgbMatch[3]) > Number(rgbMatch[2])}`);
    const wheelTestRect = wheelTest.getBoundingClientRect();
    const needleTestRect = $('.wheel-needle').getBoundingClientRect();
    const bandTestRect = $('.wheel-band').getBoundingClientRect();
    results.push(`needle=${Math.abs(needleTestRect.height - wheelTestRect.height) < 1 && Math.abs(bandTestRect.height - wheelTestRect.height) < 1}`);
    setProgress(41.6667, false);
    await sleep(30);
    const wheelCenter = wheelTestRect.left + wheelTestRect.width / 2;
    const labelCenters = Array.from(wheelTest.querySelectorAll('.wheel-tick-label'))
      .map((label) => {
        const labelRect = label.getBoundingClientRect();
        return labelRect.left + labelRect.width / 2;
      })
      .sort((left, right) => left - right);
    let centerGap = Infinity;
    for (let index = 1; index < labelCenters.length; index += 1) {
      if (labelCenters[index - 1] <= wheelCenter && labelCenters[index] >= wheelCenter) {
        centerGap = labelCenters[index] - labelCenters[index - 1];
      }
    }
    results.push(`labels=${labelCenters.length >= 4 && centerGap < 90}`);

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
    if (dockPlaylistBody) dockPlaylistBody.scrollTop = 0;
    const dockBodyRect = dockPlaylistBody.getBoundingClientRect();
    const dockBodyX = dockBodyRect.left + dockBodyRect.width * 0.5;
    const dockBodyY = dockBodyRect.top + Math.min(36, dockBodyRect.height * 0.5);
    dockPlaylistBody.dispatchEvent(pointerEvent('pointerdown', dockBodyX, dockBodyY, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', dockBodyX, dockBodyY + (90 * step) / 6, 1));
    }
    window.dispatchEvent(pointerEvent('pointerup', dockBodyX, dockBodyY + 90, 0));
    await sleep(480);
    results.push(`dockBodyClose=${!playlistDock.classList.contains('expanded') && playlistDock.classList.contains('show')}`);
    let searchPanelFocus = false;
    let searchInlineResults = false;
    let searchPanelClosed = false;
    if (pdSearch && searchPanel && searchInput) {
      pdSearch.click();
      searchPanelFocus = state.searchOpen
        && searchPanel.classList.contains('open')
        && document.activeElement === searchInput;
      const hotChip = $('#hotSearchList .search-hot-row');
      if (hotChip) hotChip.click();
      await sleep(420);
      searchInlineResults = Boolean(hotChip)
        && !searchResultsBlock.hidden
        && searchPanel.classList.contains('open');
      closeSearch();
      await sleep(420);
      searchPanelClosed = !state.searchOpen
        && !searchPanel.classList.contains('open')
        && !app.classList.contains('search-open');
    }
    results.push(`searchPanel=${searchPanelFocus && searchPanelClosed}`);
    results.push(`searchInline=${searchInlineResults}`);
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

    const reorderBackup = state.playlist.slice();
    const reorderCurrentBackup = state.currentIndex;
    if (state.playlist.length < 4) {
      for (let index = state.playlist.length; index < 4; index += 1) {
        addToPlaylist(`排序自测 ${index + 1}`, 'UP · 00:30', `selftest:reorder:${index}`, { duration: '00:30', owner: 'UP' });
      }
    }
    openPlaylistPage();
    await sleep(480);
    const reorderRows = $$('#playlistPageList .playlist-page-item');
    let rowReorder = false;
    if (reorderRows.length >= 3) {
      const reorderFrom = reorderRows[0];
      const reorderTo = reorderRows[2];
      const fromRect = reorderFrom.getBoundingClientRect();
      const toRect = reorderTo.getBoundingClientRect();
      const reorderX = fromRect.left + fromRect.width * 0.5;
      const reorderY = fromRect.top + fromRect.height * 0.5;
      const reorderTargetY = toRect.top + toRect.height * 0.6;
      const reorderBefore = state.playlist.map((item) => item.title).join('|');
      reorderFrom.dispatchEvent(pointerEvent('pointerdown', reorderX, reorderY, 1));
      await sleep(480);
      const reorderLifted = Boolean($('.reorder-ghost'));
      window.dispatchEvent(pointerEvent('pointermove', reorderX, reorderTargetY, 1));
      await sleep(140);
      window.dispatchEvent(pointerEvent('pointerup', reorderX, reorderTargetY, 0));
      await sleep(420);
      rowReorder = reorderLifted
        && !$('.reorder-ghost')
        && state.playlist.map((item) => item.title).join('|') !== reorderBefore;
    }
    results.push(`rowReorder=${rowReorder}`);
    state.playlist = reorderBackup;
    state.currentIndex = Math.min(reorderCurrentBackup, Math.max(0, state.playlist.length - 1));
    updatePlayerLabels();
    updatePlaylistCounts();
    save();
    closePlaylistPage();
    await sleep(460);

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

    const metaEl = row.querySelector('.real-meta');
    const metaFresh = row.querySelector('.meta-fresh');
    const metaPlay = row.querySelector('.meta-play');
    const metaTitle = row.querySelector('.real-title');
    const copyEl = row.querySelector('.row-copy');
    const avatarEl = row.querySelector('.row-avatar');
    const thumbEl = row.querySelector('.row-thumb');
    let feedMeta = false;
    if (metaEl && metaFresh && metaPlay && metaTitle && copyEl && avatarEl && thumbEl) {
      const copyRect = copyEl.getBoundingClientRect();
      const avatarRect = avatarEl.getBoundingClientRect();
      const titleRect = metaTitle.getBoundingClientRect();
      feedMeta = Math.abs(thumbEl.getBoundingClientRect().width - row.getBoundingClientRect().width) < 1
        && parseFloat(getComputedStyle(thumbEl).borderRadius) <= 1
        && Math.abs(avatarRect.left - (copyRect.left + 16)) < 3
        && Math.abs(titleRect.left - (avatarRect.right + 12)) < 3
        && metaPlay.textContent.includes('播放')
        && Boolean(metaFresh.style.color)
        && parseFloat(getComputedStyle(metaTitle).fontSize) >= 15
        && parseFloat(getComputedStyle(metaEl).fontSize) >= 11;
    }
    results.push(`feedMeta=${feedMeta}`);

    const upRow = $('#homeFeed .video-row');
    const upRect = upRow.getBoundingClientRect();
    const upY = upRect.top + upRect.height / 2;
    const upX = upRect.left + upRect.width / 2;
    upRow.dispatchEvent(pointerEvent('pointerdown', upX, upY, 1));
    for (let step = 1; step <= 6; step += 1) {
      window.dispatchEvent(pointerEvent('pointermove', upX - (120 * step) / 6, upY, 1));
    }
    await sleep(560);
    window.dispatchEvent(pointerEvent('pointerup', upX - 120, upY, 0));
    await sleep(560);
    results.push(`rowUp=${state.page === 'up' && $$('#upFeed .real-row').length > 0}`);
    const upSortClick = $('#upSort [data-up-sort="click"]');
    if (upSortClick) upSortClick.click();
    await sleep(420);
    const firstUpTitle = $('#upFeed .real-title') ? $('#upFeed .real-title').textContent : '';
    results.push(`upSort=${upSortClick ? upSortClick.classList.contains('on') && /最多播放/.test(firstUpTitle) : false}`);
    const upRowCheck = $('#upFeed .video-row');
    const homeRowCheck = $('#homeFeed .video-row');
    const upSortBar = $('#upSort');
    const upInfoCard = $('.up-info-card');
    let upRowMatch = false;
    let upSortFloat = false;
    if (upRowCheck && homeRowCheck && upSortBar && upInfoCard && upScroll) {
      const upThumbCheck = upRowCheck.querySelector('.row-thumb');
      const homeThumbCheck = homeRowCheck.querySelector('.row-thumb');
      const upRowStyle = getComputedStyle(upRowCheck);
      const homeRowStyle = getComputedStyle(homeRowCheck);
      upRowMatch = Math.abs(upRowCheck.offsetWidth - homeRowCheck.offsetWidth) < 1.5
        && Math.abs(upRowCheck.offsetHeight - homeRowCheck.offsetHeight) < 1.5
        && Math.abs(upThumbCheck.offsetWidth - homeThumbCheck.offsetWidth) < 1.5
        && Math.abs(upThumbCheck.offsetHeight - homeThumbCheck.offsetHeight) < 1.5
        && upRowStyle.borderRadius === homeRowStyle.borderRadius
        && Math.abs(parseFloat(upRowStyle.paddingRight) - parseFloat(homeRowStyle.paddingRight)) < 0.5;
      const sortRect = upSortBar.getBoundingClientRect();
      const sortStyle = getComputedStyle(upSortBar);
      const infoRect = upInfoCard.getBoundingClientRect();
      const scrollRect = upScroll.getBoundingClientRect();
      const commentsDock = $('#commentsSort');
      const commentsButton = commentsDock ? commentsDock.querySelector('.comments-sort:not(.on)') : null;
      const upButton = upSortBar.querySelector('.up-sort-btn:not(.on)');
      const dockStyle = commentsDock ? getComputedStyle(commentsDock) : null;
      const commentsButtonStyle = commentsButton ? getComputedStyle(commentsButton) : null;
      const upButtonStyle = upButton ? getComputedStyle(upButton) : null;
      const glassMatch = Boolean(dockStyle
        && Math.abs(parseFloat(sortStyle.paddingLeft) - parseFloat(dockStyle.paddingLeft)) < 0.5
        && sortStyle.borderRadius === dockStyle.borderRadius
        && sortStyle.backgroundColor === dockStyle.backgroundColor
        && sortStyle.boxShadow === dockStyle.boxShadow
        && sortStyle.backdropFilter === dockStyle.backdropFilter
        && sortStyle.borderColor === dockStyle.borderColor
        && sortStyle.gap === dockStyle.gap);
      const buttonMatch = Boolean(commentsButtonStyle && upButtonStyle
        && upButtonStyle.backgroundColor === commentsButtonStyle.backgroundColor
        && upButtonStyle.color === commentsButtonStyle.color
        && Math.abs(parseFloat(upButtonStyle.height) - parseFloat(commentsButtonStyle.height)) < 0.5
        && Math.abs(parseFloat(upButtonStyle.minWidth) - parseFloat(commentsButtonStyle.minWidth)) < 0.5
        && Math.abs(parseFloat(upButtonStyle.paddingLeft) - parseFloat(commentsButtonStyle.paddingLeft)) < 0.5
        && upButtonStyle.borderRadius === commentsButtonStyle.borderRadius);
      upSortFloat = sortStyle.position === 'absolute'
        && glassMatch
        && buttonMatch
        && sortRect.top >= scrollRect.top
        && sortRect.bottom <= scrollRect.bottom
        && sortRect.top < infoRect.top;
    }
    results.push(`upRowMatch=${upRowMatch}`);
    results.push(`upSortFloat=${upSortFloat}`);
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

    const feedViewHeight = appScroll.style.height;
    const feedViewBottom = appScroll.style.bottom;
    if (window.innerHeight > 1100) {
      appScroll.style.bottom = 'auto';
      appScroll.style.height = '844px';
    }
    for (let wait = 0; wait < 30; wait += 1) {
      if ($('#homeFeed [data-block="2"]')) break;
      await sleep(100);
    }
    const blocksBefore = Array.from(new Set($$('#homeFeed [data-block]').map((row) => row.dataset.block)));
    const blockTwo = $('#homeFeed [data-block="2"]');
    const blockTwoTop = blockTwo
      ? blockTwo.getBoundingClientRect().top - appScroll.getBoundingClientRect().top + appScroll.scrollTop
      : appScroll.scrollHeight;
    appScroll.scrollTop = blockTwoTop;
    appScroll.dispatchEvent(new Event('scroll'));
    const feedAnchorRow = $$('#homeFeed .feed-item:not(.feed-skeleton)')
      .find((row) => row.getBoundingClientRect().bottom > appScroll.getBoundingClientRect().top + 1);
    const feedAnchorTitle = feedAnchorRow ? feedAnchorRow.querySelector('.real-title')?.textContent : '';
    const feedAnchorTop = feedAnchorRow ? feedAnchorRow.getBoundingClientRect().top : 0;
    await sleep(700);
    const feedAnchorAfter = feedAnchorTitle
      ? $$('#homeFeed .feed-item:not(.feed-skeleton)')
        .find((row) => row.querySelector('.real-title')?.textContent === feedAnchorTitle)
      : null;
    const feedAnchor = Boolean(feedAnchorAfter
      && Math.abs(feedAnchorAfter.getBoundingClientRect().top - feedAnchorTop) < 3);
    const blocksAfter = Array.from(new Set($$('#homeFeed [data-block]').map((row) => row.dataset.block)));
    const rowsAfter = $$('#homeFeed .feed-item:not(.feed-skeleton)').length;
    results.push(`feedWindow=${blocksBefore.length === 3 && blocksBefore[0] === '0'
      && blocksAfter.length === 3 && !blocksAfter.includes('0')
      && rowsAfter >= 20 && rowsAfter <= 30}`);
    results.push(`feedAnchor=${feedAnchor}`);

    await sleep(900);
    const blockThree = $('#homeFeed [data-block="3"]');
    const blockThreeTop = blockThree
      ? blockThree.getBoundingClientRect().top - appScroll.getBoundingClientRect().top + appScroll.scrollTop
      : appScroll.scrollHeight;
    appScroll.scrollTop = blockThreeTop;
    appScroll.dispatchEvent(new Event('scroll'));
    await sleep(700);
    const blocksNext = Array.from(new Set($$('#homeFeed [data-block]').map((row) => row.dataset.block)));
    const rowsNext = $$('#homeFeed .feed-item:not(.feed-skeleton)').length;
    results.push(`feedSlide=${blocksNext.length === 3 && rowsNext >= 20 && rowsNext <= 30
      && Number(blocksNext[0]) > Number(blocksAfter[0])}`);
    appScroll.style.height = feedViewHeight;
    appScroll.style.bottom = feedViewBottom;
    appScroll.dispatchEvent(new Event('scroll'));

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

    const myBefore = state.page;
    showPage('my');
    await sleep(540);
    const myOpened = state.page === 'my'
      && app.classList.contains('my-open')
      && myPage.classList.contains('active')
      && myPage.getAttribute('aria-hidden') === 'false';
    const myRows = $$('.my-page .my-row').length;
    const myCard = $('.my-page .my-account-card');
    const myCardRect = myCard ? myCard.getBoundingClientRect() : null;
    const myPageRect = myPage.getBoundingClientRect();
    const myCardFixed = Boolean(myCardRect)
      && Math.abs(myCardRect.bottom - myPageRect.bottom) <= 2
      && myCardRect.height >= 60;
    closeMyPageFromSwipe();
    await sleep(640);
    const myClosed = state.page === myBefore
      && !app.classList.contains('my-open')
      && !myPage.classList.contains('active');
    results.push(`myPage=${myOpened && myCardFixed && myRows >= 10}`);
    results.push(`myBack=${myClosed}`);

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
  if (demo === 'comments') {
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

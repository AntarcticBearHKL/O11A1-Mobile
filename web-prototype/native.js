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
  const NATIVE_MEDIA = Boolean(window.O11A1NativeMedia && window.O11A1NativeMedia.available);
  const NATIVE_IOS = /iPhone|iPad|iPod/i.test(navigator.userAgent);
  const nativeUrl = (result) => NATIVE_MEDIA
    ? String(result && (result.remote || '') || '')
    : String(result && (result.url || '') || '');
  const nativeBackup = (result) => NATIVE_MEDIA
    ? String(result && (result.backupRemote || '') || '')
    : String(result && (result.backup || '') || '');

  let netBytes = 0;
  let netAt = 0;
  function resetNetMeter() {
    netBytes = 0;
    netAt = 0;
    if (state.streamInfo) {
      state.streamInfo.netBps = 0;
      state.streamInfo.netAt = 0;
    }
  }
  function addNetBytes(count) {
    const bytes = Number(count) || 0;
    if (bytes <= 0) return;
    const now = performance.now();
    if (!netAt) netAt = now;
    netBytes += bytes;
    const elapsed = now - netAt;
    if (elapsed >= 500) {
      if (state.streamInfo) {
        state.streamInfo.netBps = Math.round(netBytes * 8 / (elapsed / 1000));
        state.streamInfo.netAt = now;
      }
      netBytes = 0;
      netAt = now;
    }
  }

  const feeds = {
    home: host.homeFeed,
    search: host.searchResults,
    module: host.moduleFeed,
    up: $('#upFeed'),
  };
  const upScroll = $('#upScroll');
  const pages = { dynamic: 1, messages: 1 };
  const windows = {
    home: { page: 0, cursor: '', hasMore: true, loading: false, lastLoadAt: 0, token: 0, query: '' },
    search: { page: 0, cursor: '', hasMore: true, loading: false, lastLoadAt: 0, token: 0, query: '' },
    module: { page: 0, cursor: '', hasMore: true, loading: false, lastLoadAt: 0, token: 0, name: '' },
    up: { page: 0, cursor: '', hasMore: true, loading: false, lastLoadAt: 0, token: 0, name: '' },
    detail: { page: 1, cursor: '', hasMore: false, loading: false, lastLoadAt: 0, token: 0, name: '' },
  };
  const FEED_PREFETCH = 900;
  const FEED_BLOCK_SIZE = 10;
  const FEED_WINDOW_BLOCKS = 2;
  const FEED_SCROLL_IDLE = 900;
  const DASH_PLAYBACK = true;
  let lastFeedScrollAt = 0;
  const more = { dynamic: true, messages: true };
  let upSort = 'pubdate';
  let recommendSeed = 1;
  let recommendSeen = new Set();
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
  let accountFetchedAt = 0;

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

  function feedTime(value) {
    return timeAgo(value).replace(/\s+(分钟前|小时前|天前)$/, '$1');
  }

  function feedFreshness(value) {
    const raw = Number(value || 0);
    if (!raw) return '';
    const seconds = raw > 100000000000 ? raw / 1000 : raw;
    const age = Math.max(0, Date.now() / 1000 - seconds);
    const hour = 3600;
    const day = 86400;
    if (age < hour) return '刚刚';
    if (age < day) return `${Math.floor(age / hour)}小时前`;
    if (age < day * 7) return `${Math.floor(age / day)}天前`;
    if (age < day * 30) return `${Math.floor(age / (7 * day))}周前`;
    if (age < day * 90) return `${Math.floor(age / (30 * day))}个月前`;
    if (age < day * 365) return `${Math.floor(age / (90 * day))}季度前`;
    return `${Math.floor(age / (365 * day))}年前`;
  }

  function feedFreshnessColor(value) {
    const raw = Number(value || 0);
    if (!raw) return '#8a909b';
    const seconds = raw > 100000000000 ? raw / 1000 : raw;
    const age = Math.max(0, Date.now() / 1000 - seconds);
    const day = 86400;
    if (age < day) return '#d97862';
    if (age < day * 7) return '#c9984f';
    if (age < day * 30) return '#4f9a83';
    if (age < day * 90) return '#5c84c6';
    if (age < day * 365) return '#8a78b8';
    return '#8a909b';
  }

  function setNote(text) {
    const note = $('#homeNote');
    if (note) note.textContent = text;
  }

  function tailFor(feed) {
    if (feed.__tail && feed.__tail.isConnected) return feed.__tail;
    const tail = document.createElement('div');
    tail.className = 'feed-tail';
    tail.innerHTML = `
      <span class="feed-tail-spinner" aria-hidden="true"></span>
      <span class="feed-tail-text"></span>
      <button class="feed-tail-retry" type="button">重试</button>`;
    feed.insertAdjacentElement('afterend', tail);
    tail.querySelector('.feed-tail-retry').addEventListener('click', () => {
      if (typeof tail.__retry === 'function') tail.__retry();
    });
    feed.__tail = tail;
    return tail;
  }

  function setTail(feed, mode, text, retry) {
    const tail = tailFor(feed);
    tail.classList.toggle('show', mode !== 'idle');
    tail.classList.toggle('loading', mode === 'loading');
    tail.classList.toggle('end', mode === 'end');
    tail.classList.toggle('error', mode === 'error');
    const copy = tail.querySelector('.feed-tail-text');
    if (copy) {
      copy.textContent = text || (mode === 'loading' ? '正在加载下一段…'
        : mode === 'end' ? '已经到底了' : '');
    }
    tail.__retry = retry || null;
  }

  function clearFeedSkeletons(feed, page) {
    if (!feed) return;
    const rows = page
      ? $$(`.feed-skeleton[data-skeleton-page="${page}"]`, feed)
      : $$('.feed-skeleton', feed);
    rows.forEach((row) => row.remove());
  }

  function showFeedSkeleton(feed, page, count) {
    if (!feed) return;
    clearFeedSkeletons(feed);
    const total = Math.max(1, Number(count) || 20);
    const fragment = document.createDocumentFragment();
    for (let index = 0; index < total; index += 1) {
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

  const loadingTokens = Object.create(null);

  function deferLoading(key, paint, run) {
    const token = (loadingTokens[key] || 0) + 1;
    loadingTokens[key] = token;
    paint();
    requestAnimationFrame(() => {
      setTimeout(() => {
        if (loadingTokens[key] !== token) return;
        try {
          run();
        } catch (error) {
          log('deferred load failed ' + error);
        }
      }, 36);
    });
  }

  function showInitialFeedSkeleton(feed, count = 8) {
    if (!feed) return;
    resetFeedWindow(feed);
    feed.innerHTML = '';
    setTail(feed, 'idle');
    showFeedSkeleton(feed, 1, count);
  }

  function showDynamicSkeleton(count = 4) {
    const feed = $('#dynamicFeed');
    if (!feed) return;
    feed.innerHTML = Array.from({ length: Math.max(1, count) }, () => `
      <article class="dynamic-card skeleton-card" aria-hidden="true">
        <div class="dynamic-head">
          <span class="skeleton-avatar"></span>
          <div><span class="skeleton-line w30"></span><span class="skeleton-line w20"></span></div>
        </div>
        <span class="skeleton-line w90"></span>
        <span class="skeleton-line w65"></span>
        <div class="skeleton-media"></div>
      </article>`).join('');
    const empty = $('#dynamicEmpty');
    if (empty) empty.hidden = true;
  }

  function showMessageSkeleton(count = 5) {
    const feed = $('#messageFeed');
    if (!feed) return;
    feed.innerHTML = Array.from({ length: Math.max(1, count) }, () => `
      <div class="message-row skeleton-message" aria-hidden="true">
        <span class="skeleton-avatar"></span>
        <div class="message-copy">
          <span class="skeleton-line w30"></span>
          <span class="skeleton-line w80"></span>
          <span class="skeleton-line w40"></span>
        </div>
      </div>`).join('');
    const empty = $('#messageEmpty');
    if (empty) empty.hidden = true;
  }

  function clearMoreSkeletons(feed) {
    if (!feed) return;
    feed.querySelectorAll('[data-more-skeleton]').forEach((node) => node.remove());
  }

  function appendDynamicSkeleton() {
    const feed = $('#dynamicFeed');
    if (!feed) return;
    clearMoreSkeletons(feed);
    const card = document.createElement('article');
    card.className = 'dynamic-card skeleton-card';
    card.dataset.moreSkeleton = '1';
    card.setAttribute('aria-hidden', 'true');
    card.innerHTML = `
      <div class="dynamic-head">
        <span class="skeleton-avatar"></span>
        <div><span class="skeleton-line w30"></span><span class="skeleton-line w20"></span></div>
      </div>
      <span class="skeleton-line w80"></span>
      <div class="skeleton-media"></div>`;
    feed.appendChild(card);
  }

  function appendMessageSkeleton() {
    const feed = $('#messageFeed');
    if (!feed) return;
    clearMoreSkeletons(feed);
    const row = document.createElement('div');
    row.className = 'message-row skeleton-message';
    row.dataset.moreSkeleton = '1';
    row.setAttribute('aria-hidden', 'true');
    row.innerHTML = `
      <span class="skeleton-avatar"></span>
      <div class="message-copy">
        <span class="skeleton-line w30"></span>
        <span class="skeleton-line w80"></span>
      </div>`;
    feed.appendChild(row);
  }

  function showAccountSkeleton() {
    const card = $('.my-account-card');
    if (!card) return;
    card.classList.add('is-loading');
    const avatar = $('#myAvatar');
    if (avatar) {
      avatar.style.backgroundImage = '';
      avatar.innerHTML = '<span class="skeleton-avatar"></span>';
    }
    const name = $('#myName');
    if (name) name.innerHTML = '<span class="skeleton-line w40"></span>';
    const meta = $('#myMeta');
    if (meta) meta.innerHTML = '<span class="skeleton-line w65"></span>';
    const action = $('#myAccountAction');
    if (action) action.hidden = true;
  }

  function showMemberSkeleton() {
    const feed = feeds.module;
    if (!feed) return;
    feed.innerHTML = `
      <div class="special-page" aria-hidden="true">
        <div class="member-card skeleton-card">
          <span class="skeleton-line w30"></span>
          <span class="skeleton-line w60"></span>
          <span class="skeleton-line w80"></span>
        </div>
        <div class="special-title"><span class="skeleton-line w20"></span></div>
        <div class="task-list">
          ${Array.from({ length: 4 }, () => `
            <div class="task-row">
              <span class="skeleton-avatar"></span>
              <span class="task-copy"><span class="skeleton-line w30"></span><span class="skeleton-line w55"></span></span>
            </div>`).join('')}
        </div>
      </div>`;
  }

  function sheetSkeletonMarkup(count = 6) {
    return `<div class="sheet-skeleton" aria-hidden="true">${Array.from({ length: Math.max(1, count) }, () => `
      <div class="sheet-skeleton-row"><span class="skeleton-line w30"></span><span class="skeleton-line w55 sheet-skeleton-value"></span></div>`).join('')}</div>`;
  }

  function renderEmpty(feed, title, detail, actionLabel, action) {
    resetFeedWindow(feed);
    feed.innerHTML = `
      <div class="native-empty">
        <b>${esc(title || '暂无内容')}</b>
        ${detail ? `<span>${esc(detail)}</span>` : ''}
        ${actionLabel ? `<button class="pill-btn" type="button">${esc(actionLabel)}</button>` : ''}
      </div>`;
    setTail(feed, 'idle');
    const button = feed.querySelector('button');
    if (button && action) button.addEventListener('click', action);
  }

  function metaMarkup(item, label) {
    const season = item.seasonId || item.epId;
    if (season && item.meta) {
      return `<span class="real-meta season-meta"><span class="meta-owner"><span class="meta-owner-name">${esc(item.meta)}</span></span></span>`;
    }
    const owner = item.owner || '';
    const fresh = item.live ? '直播中' : feedFreshness(item.pubdate);
    const color = item.live ? '#d97862' : feedFreshnessColor(item.pubdate);
    const playText = item.playText || (item.play ? countText(item.play) : '');
    const ownerMarkup = owner
      ? `<span class="meta-owner"><span class="meta-owner-name">${esc(owner)}</span></span>`
      : '';
    const playMarkup = playText && !item.live
      ? `<span class="meta-play">${esc(playText)}播放</span>`
      : '';
    const freshMarkup = fresh
      ? `<span class="meta-fresh" style="color:${color}">${esc(fresh)}</span>`
      : '';
    const parts = [ownerMarkup, playMarkup, freshMarkup].filter(Boolean);
    return parts.length
      ? `<span class="real-meta">${parts.join('<span class="meta-dot">·</span>')}</span>`
      : '';
  }

  function biliImage(url, width, height) {
    const value = String(url || '');
    if (!/^https?:\/\/[^/]*hdslb\.com\//i.test(value)) return value;
    if (/@[^/?#]+/.test(value)) return value;
    return `${value}@${width}w_${height}h_1c.webp`;
  }

  function buildRow(item, label, page, index) {
    const row = document.createElement('button');
    row.type = 'button';
    row.className = `video-row real-row${item.live ? ' live-row' : ''}${item.seasonId ? ' season-row' : ''}`;
    row.__nativeItem = item;
    row.dataset.nativeIndex = String(index);
    const pic = biliImage(item.pic, 960, 540);
    const progress = item.durationSec > 0 && item.progress > 0
      ? Math.min(100, Math.round(item.progress / item.durationSec * 100))
      : 0;
    row.innerHTML = `
      <span class="row-thumb real">
        ${pic ? `<img src="${attr(pic)}" alt="" loading="lazy" decoding="async" referrerpolicy="no-referrer">` : ''}
        ${item.live ? '<span class="live-badge">LIVE</span>' : ''}
        ${item.live ? '' : `<span class="dur-ph">${esc(item.duration || item.badge || (item.seasonId ? '番剧' : '00:00'))}</span>`}
        ${progress ? `<span class="row-progress"><span style="width:${progress}%"></span></span>` : ''}
      </span>
      <span class="row-copy">
        <span class="row-avatar">${item.ownerFace ? `<img src="${attr(biliImage(item.ownerFace, 96, 96))}" alt="" loading="lazy" decoding="async" referrerpolicy="no-referrer">` : `<span>${esc((item.owner || 'UP').slice(0, 1))}</span>`}</span>
        <span class="row-text">
          <span class="real-title">${esc(item.title || '视频')}</span>
          ${metaMarkup(item, label)}
        </span>
      </span>
      <span class="row-swipe-mask" aria-hidden="true" data-action="queue">
        <b class="rsm-label">加入播放列表</b>
        <small class="rsm-hint">左滑加入</small>
      </span>`;
    const image = $('.row-thumb img', row);
    if (image) {
      const reveal = () => image.classList.add('loaded');
      if (image.complete && image.naturalWidth) reveal();
      else image.addEventListener('load', reveal, { once: true });
      image.addEventListener('error', () => image.remove());
    }
    const avatarImage = $('.row-avatar img', row);
    if (avatarImage) {
      avatarImage.addEventListener('error', () => {
        avatarImage.parentNode.textContent = (item.owner || 'UP').slice(0, 1);
      }, { once: true });
    }
    row.addEventListener('click', (event) => {
      if (host.isFeedClickSuppressed && host.isFeedClickSuppressed()) return;
      // iOS can synthesize a click when a finger lift ends a fling. Only block
      // taps that are still inside the fling, not every tap after a scroll.
      if (Date.now() - (lastFeedScrollAt || 0) < 80) return;
      event.preventDefault();
      event.stopPropagation();
      if (item.live) playLive(item);
      else if (item.seasonId && !item.epId) playSeason(item);
      else playItem(item);
    });
    const wrapper = document.createElement('div');
    wrapper.className = 'feed-item';
    wrapper.dataset.chunk = String(page);
    wrapper.dataset.block = String(page);
    wrapper.dataset.start = String(index);
    wrapper.__nativeItem = item;
    wrapper.appendChild(row);
    return wrapper;
  }

  function feedWindowState(feed) {
    if (!feed.__feedWindow) {
      feed.__feedWindow = {
        blocks: [],
        queue: [],
        nextBlockId: 0,
        nextItemIndex: 0,
        firstItemIndex: 0,
        label: '',
        fillTimer: null,
        renderTimer: null,
        frame: 0,
        scrollTimer: null,
        touchActive: false,
        touchActiveAt: 0,
        lastScrollAt: 0,
      };
    }
    return feed.__feedWindow;
  }

  function resetFeedWindow(feed) {
    if (!feed) return;
    const previous = feed.__feedWindow;
    if (previous) {
      clearTimeout(previous.fillTimer);
      clearTimeout(previous.renderTimer);
      clearTimeout(previous.scrollTimer);
      if (previous.frame) cancelAnimationFrame(previous.frame);
    }
    feed.__feedWindow = {
      blocks: [],
      queue: [],
      nextBlockId: 0,
      nextItemIndex: 0,
      firstItemIndex: 0,
      label: '',
      fillTimer: null,
      renderTimer: null,
      frame: 0,
      scrollTimer: null,
      touchActive: false,
      touchActiveAt: 0,
      lastScrollAt: 0,
    };
    feed.__nativeItems = [];
    feed.__chunkPages = [];
    feed.__chunkItems = {};
  }

  function syncWindowItems(feed) {
    const fw = feed.__feedWindow;
    feed.__nativeItems = fw ? fw.blocks.flatMap((block) => block.items) : [];
  }

  function releaseWindowBlock(block) {
    if (!block) return;
    block.nodes.forEach((node) => {
      const row = node.querySelector ? node.querySelector('.video-row') : null;
      const image = node.querySelector ? node.querySelector('img') : null;
      if (image) {
        image.removeAttribute('src');
        image.removeAttribute('srcset');
      }
      node.__nativeItem = null;
      if (row) row.__nativeItem = null;
      if (node.remove) node.remove();
    });
    block.nodes.length = 0;
    block.items.length = 0;
  }

  function prewarmPreviewItems(items) {
    if (!items || !items.length || typeof bridge.prewarmPreviews !== 'function') return;
    const rows = [];
    for (let index = 0; index < items.length; index += 1) {
      const item = items[index];
      if (!item || item.live || item.epId || !item.bvid) continue;
      rows.push({ bvid: item.bvid, cid: Number(item.cid) || 0 });
    }
    if (!rows.length) return;
    try { bridge.prewarmPreviews(JSON.stringify(rows)); } catch (_) {}
  }

  function appendWindowBlock(feed) {
    const fw = feed.__feedWindow;
    if (!fw) return null;
    const win = windows[feedKey(feed)];
    if (!win) return null;
    const remaining = fw.queue.length;
    if (!remaining) return null;
    if (remaining < FEED_BLOCK_SIZE && win.hasMore) return null;
    const take = Math.min(FEED_BLOCK_SIZE, remaining);
    const items = fw.queue.splice(0, take);
    const blockId = fw.nextBlockId;
    fw.nextBlockId += 1;
    const startIndex = fw.nextItemIndex;
    fw.nextItemIndex += take;
    const nodes = items.map((item, index) => buildRow(
      item,
      fw.label,
      blockId,
      startIndex + index,
    ));
    const fragment = document.createDocumentFragment();
    nodes.forEach((node) => fragment.appendChild(node));
    feed.appendChild(fragment);
    const block = {
      id: blockId,
      items,
      nodes,
      startIndex,
      endIndex: startIndex + take,
    };
    fw.blocks.push(block);
    prewarmPreviewItems(items);
    return block;
  }

  function renderWindowBlocks(feed) {
    const fw = feed.__feedWindow;
    if (!fw) return;
    const win = windows[feedKey(feed)];
    if (!win) return;
    while (fw.blocks.length < FEED_WINDOW_BLOCKS) {
      if (fw.queue.length >= FEED_BLOCK_SIZE) {
        appendWindowBlock(feed);
        continue;
      }
      if (!win.hasMore && fw.queue.length > 0) {
        appendWindowBlock(feed);
        continue;
      }
      break;
    }
    syncWindowItems(feed);
  }

  function renderRows(feed, items, label, page) {
    stopFeedPreview();
    prewarmFeedRows(items);
    clearFeedSkeletons(feed);
    resetFeedWindow(feed);
    feed.innerHTML = '';
    const fw = feed.__feedWindow;
    fw.label = label || '';
    for (let index = 0; index < items.length; index += 1) fw.queue.push(items[index]);
    renderWindowBlocks(feed);
    scheduleWindowSettle(feed);
    scheduleBufferFill(feed);
  }

  function feedViewport(feed) {
    const scroll = feed === feeds.up
      ? upScroll
      : feed === feeds.search
        ? $('#searchPanelBody')
        : $('#appScroll');
    const isActive = (feed === feeds.home && state.page === 'home')
      || (feed === feeds.search && state.searchOpen === true)
      || (feed === feeds.module && state.page === 'module')
      || (feed === feeds.up && state.page === 'up');
    return { scroll, isActive: Boolean(scroll && isActive) };
  }

  function feedIsBusy(feed) {
    const fw = feed && feed.__feedWindow;
    if (!fw) return false;
    if (fw.touchActive && Date.now() - fw.touchActiveAt < 1200) return true;
    return Date.now() - (fw.lastScrollAt || 0) < FEED_SCROLL_IDLE;
  }

  function topVisibleRow(feed, scroll, exclude) {
    if (!scroll) return null;
    const viewportTop = scroll.getBoundingClientRect().top;
    const rows = $$('.feed-item:not(.feed-skeleton)', feed);
    for (let index = 0; index < rows.length; index += 1) {
      const row = rows[index];
      if (exclude && exclude.includes(row)) continue;
      if (row.getBoundingClientRect().bottom > viewportTop + 1) return row;
    }
    return null;
  }

  function feedFocusRow(feed, scroll) {
    if (!scroll) return null;
    const viewport = scroll.getBoundingClientRect();
    const middle = viewport.top + viewport.height * 0.5;
    const bandTop = viewport.top + viewport.height / 6;
    const bandBottom = viewport.top + viewport.height * 5 / 6;
    const rows = $$('.feed-item:not(.feed-skeleton)', feed);
    let best = null;
    let bestOverlap = 0;
    let bestDistance = Infinity;
    for (let index = 0; index < rows.length; index += 1) {
      const row = rows[index];
      const rect = row.getBoundingClientRect();
      const overlap = Math.min(rect.bottom, bandBottom) - Math.max(rect.top, bandTop);
      if (overlap <= 0) continue;
      const distance = Math.abs(rect.top + rect.height / 2 - middle);
      if (overlap > bestOverlap + 0.5 || (Math.abs(overlap - bestOverlap) <= 0.5 && distance < bestDistance)) {
        best = row;
        bestOverlap = overlap;
        bestDistance = distance;
      }
    }
    return best || rows[rows.length - 1] || null;
  }

  /* ---------- inline focused-card preview ---------- */
  const previewUrlCache = new Map();
  const previewPending = new Set();
  const previewWarmPending = new Set();
  const playerWarmPending = new Set();
  const PREVIEW_URL_TTL = 10 * 60 * 1000;
  let previewVideo = null;
  let previewRow = null;
  let previewToken = 0;
  let previewTimer = null;
  let previewProgressFill = null;
  let lastPreviewProgress = null;
  let pendingMediaStart = null;
  let promotedPreview = null;
  let promotedBackdrop = null;
  let preloadVideo = null;
  let preloadRow = null;
  let preloadReady = false;
  let preloadStartedAt = 0;
  let previewCommitTimer = null;
  let previewCandidate = null;
  let previewCandidateTimer = 0;
  let previewProgressGuardUntil = 0;

  function mediaKeyFor(item) {
    if (!item) return '';
    if (item.key) return String(item.key);
    if (item.epId) return `ep:${item.epId}`;
    if (item.roomId) return `live:${item.roomId}`;
    return item.bvid ? `bvid:${item.bvid}` : '';
  }

  function takePreviewStart(item) {
    const progress = lastPreviewProgress;
    lastPreviewProgress = null;
    if (!progress || Date.now() - progress.at > 5000) return 0;
    if (mediaKeyFor(item) !== progress.key) return 0;
    return progress.time;
  }

  function createPreviewVideo(preload) {
    const video = document.createElement('video');
    video.className = preload ? 'feed-preview-video preview-preload' : 'feed-preview-video';
    // Feed previews stay in the WebView. An inline HTML video is part of the
    // scrolled compositor, so it follows a 120 Hz fling natively instead of
    // waiting for a message-handler rect update. The full-screen player still
    // uses the native AVPlayer path.
    video.muted = true;
    video.defaultMuted = true;
    video.loop = true;
    video.playsInline = true;
    video.setAttribute('playsinline', '');
    video.setAttribute('webkit-playsinline', '');
    video.setAttribute('aria-hidden', 'true');
    video.preload = 'auto';
    video.addEventListener('timeupdate', () => {
      if (promotedPreview && promotedPreview.video === video) {
        if (!video.duration || !Number.isFinite(video.duration)) return;
        state.duration = video.duration;
        state.progress = video.currentTime / video.duration * 100;
        host.setProgress(state.progress);
        tickDanmaku(video.currentTime || 0);
        maybeFinishPromotedPreview();
        return;
      }
      if (video !== previewVideo || !previewProgressFill || !video.duration) return;
      if (performance.now() < previewProgressGuardUntil) {
        previewProgressFill.style.transform = 'scaleX(0)';
        return;
      }
      previewProgressFill.style.transform = `scaleX(${Math.min(1, Math.max(0, video.currentTime / video.duration))})`;
    });
    video.addEventListener('play', () => {
      if (!promotedPreview || promotedPreview.video !== video) return;
      state.playing = true;
      host.setPlayIcon(true);
      host.updatePlaylistDock();
    });
    video.addEventListener('pause', () => {
      if (!promotedPreview || promotedPreview.video !== video) return;
      state.playing = false;
      host.setPlayIcon(false);
      host.updatePlaylistDock();
    });
    video.addEventListener('error', () => {
      if (promotedPreview && promotedPreview.video === video) return;
      if (video === preloadVideo) stopPreviewPreload();
      else if (previewVideo === video) stopFeedPreview();
    });
    return video;
  }

  function ensurePreviewVideo() {
    if (previewVideo) return previewVideo;
    previewVideo = createPreviewVideo(false);
    return previewVideo;
  }

  function attachPreviewOverlays(thumb) {
    const live = document.createElement('span');
    live.className = 'preview-live';
    live.innerHTML = '<i aria-hidden="true"></i><b>预览中</b>';
    const ring = document.createElement('span');
    ring.className = 'preview-ring';
    ring.setAttribute('aria-hidden', 'true');
    const progress = document.createElement('span');
    progress.className = 'preview-progress';
    const fill = document.createElement('span');
    progress.appendChild(fill);
    thumb.appendChild(live);
    thumb.appendChild(ring);
    thumb.appendChild(progress);
    previewProgressGuardUntil = performance.now() + 380;
    fill.style.transition = 'none';
    fill.style.transform = 'scaleX(0)';
    requestAnimationFrame(() => { fill.style.transition = ''; });
    return fill;
  }

  function retirePreviewVideo(video) {
    if (!video) return;
    try { video.pause(); } catch (_) {}
    video.removeAttribute('src');
    /* video.load() tears down media synchronously and used to block the first
       frame of opening the player. Let the tap/transition start first. */
    setTimeout(() => {
      try { video.load(); } catch (_) {}
      if (video.parentNode) video.parentNode.removeChild(video);
    }, 36);
  }

  function stopPreviewPreload() {
    clearTimeout(previewCommitTimer);
    previewCommitTimer = null;
    preloadReady = false;
    preloadRow = null;
    preloadStartedAt = 0;
    if (!preloadVideo) return;
    const video = preloadVideo;
    preloadVideo = null;
    retirePreviewVideo(video);
  }

  function stopFeedPreview() {
    if (promotedPreview) return;
    stopPreviewPreload();
    previewToken += 1;
    clearTimeout(previewTimer);
    previewTimer = null;
    if (previewRow && previewVideo) {
      const item = previewRow.__nativeItem;
      const key = mediaKeyFor(item);
      const time = Number(previewVideo.currentTime) || 0;
      if (key && time > 0.25) {
        lastPreviewProgress = { key, time, at: Date.now() };
      }
    }
    if (previewRow) {
      previewRow.classList.remove('preview-active');
      const thumb = previewRow.querySelector('.row-thumb');
      if (thumb) {
        thumb.classList.remove('preview-loading');
        thumb.querySelectorAll('.preview-live, .preview-ring, .preview-progress').forEach((node) => node.remove());
      }
      previewRow = null;
    }
    if (!previewVideo) return;
    const retiring = previewVideo;
    previewVideo = null;
    previewProgressFill = null;
    retiring.classList.remove('show');
    retirePreviewVideo(retiring);
  }

  function startPreviewPreload(feed, row) {
    if (window.__O11A1_NO_PRELOAD) return;
    if (!row || row === previewRow) return;
    if (preloadRow === row && preloadVideo) return;
    const item = row.__nativeItem;
    if (!item || item.live || !item.bvid) return;
    const thumb = row.querySelector('.row-thumb');
    if (!thumb) return;
    stopPreviewPreload();
    preloadRow = row;
    prewarmPlayerUrl(item);
    const url = previewUrlFor(item);
    if (!url) return;
    const video = createPreviewVideo(true);
    loadPreviewNative(video, item, url, false);
    thumb.appendChild(video);
    preloadVideo = video;
    preloadStartedAt = Date.now();
    preloadReady = video.readyState >= 2;
    try { video.playbackRate = 1; } catch (_) {}
    video.play().catch(() => {});
    const ready = () => {
      if (preloadVideo === video && video.readyState >= 2) preloadReady = true;
    };
    video.addEventListener('loadeddata', ready, { once: true });
    video.addEventListener('canplay', ready, { once: true });
  }

  function commitPreview(feed, row) {
    if (!row || row === previewRow) return true;
    if (!preloadVideo || preloadRow !== row || !preloadReady) return false;
    const thumb = row.querySelector('.row-thumb');
    if (!thumb) return false;
    const video = preloadVideo;
    preloadVideo = null;
    preloadRow = null;
    preloadReady = false;
    clearTimeout(previewCommitTimer);
    previewCommitTimer = null;
    if (previewRow) {
      previewRow.classList.remove('preview-active');
      const oldThumb = previewRow.querySelector('.row-thumb');
      if (oldThumb) {
        oldThumb.classList.remove('preview-loading');
        oldThumb.querySelectorAll('.preview-live, .preview-ring, .preview-progress').forEach((node) => node.remove());
      }
    }
    const previousVideo = previewVideo;
    let retired = false;
    const retire = () => {
      if (retired || !previousVideo) return;
      retired = true;
      try { previousVideo.pause(); } catch (_) {}
      setTimeout(() => {
        previousVideo.removeAttribute('src');
        try { previousVideo.load(); } catch (_) {}
        if (previousVideo.parentNode) previousVideo.parentNode.removeChild(previousVideo);
      }, 320);
    };
    previewVideo = video;
    previewRow = row;
    row.classList.add('preview-active');
    thumb.appendChild(video);
    video.classList.remove('preview-preload');
    thumb.querySelectorAll('.preview-live, .preview-ring, .preview-progress').forEach((node) => node.remove());
    previewProgressFill = attachPreviewOverlays(thumb);
    const reveal = () => {
      thumb.classList.remove('preview-loading');
      video.classList.add('show');
      retire();
    };
    video.addEventListener('playing', reveal, { once: true });
    thumb.classList.add('preview-loading');
    try { video.playbackRate = 1; } catch (_) {}
    video.play().catch(() => {});
    requestAnimationFrame(reveal);
    prewarmPlayerUrl(row.__nativeItem);
    setTimeout(() => preloadPreviewNeighbor(feed, row), 180);
    setTimeout(retire, 3000);
    return true;
  }

  function preloadPreviewNeighbor(feed, row) {
    if (!feed || !row || state.playerOpen || state.miniVisible || previewRow !== row) return;
    if (preloadVideo || previewCommitTimer) return;
    const rows = $$('.feed-item:not(.feed-skeleton)', feed);
    const index = rows.indexOf(row);
    if (index < 0) return;
    const next = rows[index + 1] || rows[index - 1];
    if (!next || next === previewRow || next === preloadRow) return;
    const item = next.__nativeItem;
    if (!item || item.live || item.epId || !item.bvid) return;
    startPreviewPreload(feed, next);
  }

  function schedulePreviewCommit(feed, row) {
    clearTimeout(previewCommitTimer);
    let tries = 0;
    const attempt = () => {
      previewCommitTimer = null;
      const view = feedViewport(feed);
      if (!view.isActive || state.playerOpen || state.miniVisible) {
        stopPreviewPreload();
        return;
      }
      const focus = feedFocusRow(feed, view.scroll);
      if (!focus || focus === previewRow) {
        if (preloadRow && preloadRow !== previewRow) stopPreviewPreload();
        return;
      }
      if (focus !== row) {
        startPreviewPreload(feed, focus);
        schedulePreviewCommit(feed, focus);
        return;
      }
      if (preloadRow !== row || !preloadVideo) startPreviewPreload(feed, row);
      if (!preloadReady && preloadVideo && preloadVideo.readyState >= 2) preloadReady = true;
      if (preloadReady && commitPreview(feed, row)) return;
      tries += 1;
      if (tries > 30) {
        stopPreviewPreload();
        return;
      }
      previewCommitTimer = setTimeout(attempt, 80);
    };
    previewCommitTimer = setTimeout(attempt, 24);
  }

  function promoteFeedPreview(thumb) {
    if (NATIVE_MEDIA && !NATIVE_IOS) return false;
    if (!previewRow || !previewVideo || !previewVideo.src) return false;
    // A native fallback preview lives above the WebView; promoting it would
    // cover the player controls. Open with the normal poster/main path instead.
    if (previewVideo.__o11a1Native) return false;
    if (previewVideo.error || previewVideo.readyState < 2) return false;
    const rowThumb = previewRow.querySelector('.row-thumb');
    if (thumb && rowThumb !== thumb) return false;
    const item = previewRow.__nativeItem;
    if (!item || item.live || !item.bvid) return false;
    previewToken += 1;
    clearTimeout(previewTimer);
    previewTimer = null;
    stopPreviewPreload();
    const time = Number(previewVideo.currentTime) || 0;
    previewRow.classList.remove('preview-active');
    previewRow.querySelectorAll('.preview-live, .preview-ring, .preview-progress').forEach((node) => node.remove());
    previewRow = null;
    previewProgressFill = null;
    lastPreviewProgress = null;
    if (previewVideo.parentNode) previewVideo.parentNode.removeChild(previewVideo);
    previewVideo.classList.remove('feed-preview-video', 'show');
    previewVideo.classList.add('player-promoted-video');
    // Keep the inline preview muted until the native main item is ready. If it
    // owns the audio session, starting AVPlayer pauses the HTML preview and the
    // transition looks frozen. Main audio is unmuted at handoff instead.
    previewVideo.muted = true;
    previewVideo.defaultMuted = true;
    previewVideo.volume = 0;
    // Keep looping while the 1080P DASH item prepares; stopping at the end
    // used to pause the incoming main player and leave a black screen.
    previewVideo.loop = true;
    previewVideo.controls = false;
    previewVideo.playbackRate = 1;
    playerVideo.appendChild(previewVideo);
    playerVideo.classList.add('promoted-preview');
    const promotedVideo = previewVideo;
    previewVideo = null;
    removePromotedBackdrop();
    const backdropSource = promotedVideo.currentSrc || promotedVideo.src;
    if (backdropSource) {
      const backdrop = document.createElement('video');
      backdrop.className = 'player-promoted-backdrop';
      backdrop.muted = true;
      backdrop.defaultMuted = true;
      backdrop.loop = true;
      backdrop.playsInline = true;
      backdrop.setAttribute('playsinline', '');
      backdrop.setAttribute('webkit-playsinline', '');
      backdrop.setAttribute('aria-hidden', 'true');
      backdrop.src = backdropSource;
      playerVideo.insertBefore(backdrop, promotedVideo);
      backdrop.play().catch(() => {});
      promotedBackdrop = backdrop;
    }
    const key = mediaKeyFor(item);
    promotedPreview = { video: promotedVideo, key, time };
    pendingMediaStart = time > 0.25 ? { key, time } : pendingMediaStart;
    try { video.muted = true; video.pause(); } catch (_) {}
    if (Number.isFinite(promotedVideo.duration) && promotedVideo.duration > 0) {
      state.duration = promotedVideo.duration;
      state.progress = time / promotedVideo.duration * 100;
      host.setProgress(state.progress);
      host.updatePlaylistDock();
    }
    promotedVideo.play().catch(() => {});
    return true;
  }

  function removePromotedBackdrop() {
    if (!promotedBackdrop) return;
    try { promotedBackdrop.pause(); } catch (_) {}
    try { promotedBackdrop.removeAttribute('src'); } catch (_) {}
    try { promotedBackdrop.load(); } catch (_) {}
    if (promotedBackdrop.parentNode) promotedBackdrop.parentNode.removeChild(promotedBackdrop);
    promotedBackdrop = null;
  }

  function removePromotedPreview() {
    if (!promotedPreview) return;
    const promoted = promotedPreview;
    promotedPreview = null;
    removePromotedBackdrop();
    try { promoted.video.pause(); } catch (_) {}
    promoted.video.removeAttribute('src');
    try { promoted.video.load(); } catch (_) {}
    if (promoted.video.parentNode) promoted.video.parentNode.removeChild(promoted.video);
    if (previewVideo === promoted.video) previewVideo = null;
    playerVideo.classList.remove('promoted-preview');
    playerVideo.classList.remove('has-video', 'video-loading', 'video-error');
    try { video.muted = false; } catch (_) {}
  }

  function maybeFinishPromotedPreview() {
    if (!promotedPreview || !video || !video.src) return;
    if (video.readyState < 2 || playerVideo.classList.contains('video-error')) return;
    if (NATIVE_MEDIA && video.__o11a1Native && !video.__o11a1Native.gotFirstFrame) {
      if (video.paused && !video.__o11a1HandoffPlay) {
        video.__o11a1HandoffPlay = true;
        video.play().catch(() => {});
      }
      return;
    }
    const promoted = promotedPreview;
    if (promoted.video.paused && !promoted.video.ended) {
      // Starting the native main item can take the audio session away from the
      // inline preview and pause it. Try to wake it once; if the main item is
      // already ready, hand off immediately instead of pausing the whole player.
      promoted.video.play().catch(() => {});
      if (!(video.__o11a1Native && video.__o11a1Native.gotFirstFrame)) return;
    }
    const duration = Number(video.duration);
    const overlayTime = Number(promoted.video.currentTime) || promoted.time;
    const target = Number.isFinite(duration) && duration > 0
      ? Math.min(overlayTime, Math.max(0, duration - 0.2))
      : overlayTime;
    if (video.__o11a1Native && video.__o11a1Native.seeking) return;
    const rate = parseFloat(state.settings.speed || '1');
    const playbackRate = Number.isFinite(rate) && rate > 0 ? rate : 1;
    const delta = Number(video.currentTime) - target;
    if (delta < -0.45 || delta > 0.8) {
      // Seek the ready native item to the overlay's playhead instead of
      // letting it crawl there at 2-3x. The preview stays visible for the
      // ~120 ms seek, then the normal seeked event completes the handoff.
      try { video.currentTime = target; } catch (_) {}
      return;
    }
    try { video.playbackRate = playbackRate; } catch (_) {}
    try { promoted.video.pause(); } catch (_) {}
    removePromotedBackdrop();
    if (promoted.video.parentNode) promoted.video.parentNode.removeChild(promoted.video);
    promotedPreview = null;
    if (previewVideo === promoted.video) previewVideo = null;
    playerVideo.classList.remove('promoted-preview');
    video.muted = false;
    video.volume = 1;
    state.duration = Number.isFinite(duration) ? duration : 0;
    state.progress = duration > 0 ? target / duration * 100 : 0;
    host.setProgress(state.progress);
    host.updatePlaylistDock();
    video.play().catch(() => {
      state.playing = false;
      host.setPlayIcon(false);
    });
  }

  function warmPreviewPrefix(item) {
    if (!item || !item.bvid || typeof bridge.previewWarm !== 'function') return;
    const key = `${item.bvid}:${item.cid || 0}`;
    if (previewWarmPending.has(key)) return;
    previewWarmPending.add(key);
    setTimeout(() => previewWarmPending.delete(key), 30000);
    try { bridge.previewWarm(item.bvid, item.cid || 0); } catch (_) {}
  }

  function prewarmFeedRows(items) {
    if (!NATIVE_MEDIA || typeof bridge.prewarmPreviews !== 'function' || !Array.isArray(items)) return;
    const list = [];
    for (let index = 0; index < items.length && list.length < 12; index += 1) {
      const item = items[index];
      if (!item || item.live || item.epId || !item.bvid) continue;
      list.push({ bvid: item.bvid, cid: Number(item.cid) || 0 });
    }
    if (!list.length) return;
    try { bridge.prewarmPreviews(JSON.stringify(list)); } catch (_) {}
  }

  function previewFocusRow(feed, scroll) {
    if (!scroll) return null;
    const viewport = scroll.getBoundingClientRect();
    if (viewport.width < 2 || viewport.height < 2) return null;
    const cx = viewport.left + viewport.width * 0.5;
    const cy = viewport.top + viewport.height * 0.5;
    let row = null;
    const hit = document.elementFromPoint(cx, cy);
    if (hit) row = hit.closest && hit.closest('.feed-item:not(.feed-skeleton)');
    if (!row || !feed.contains(row)) {
      const rows = $$('.feed-item:not(.feed-skeleton)', feed);
      let best = Infinity;
      for (let index = 0; index < rows.length; index += 1) {
        const rect = rows[index].getBoundingClientRect();
        if (rect.bottom <= viewport.top || rect.top >= viewport.bottom) continue;
        const distance = Math.abs(rect.top + rect.height / 2 - cy);
        if (distance < best) { best = distance; row = rows[index]; }
      }
    }
    if (!row) return null;
    // A small hysteresis keeps a row from flapping while its edge sits on the
    // viewport centre; switch as soon as the new row is genuinely closer.
    if (previewRow && previewRow !== row && feed.contains(previewRow)) {
      const active = previewRow.getBoundingClientRect();
      const next = row.getBoundingClientRect();
      const activeDistance = Math.abs(active.top + active.height / 2 - cy);
      const nextDistance = Math.abs(next.top + next.height / 2 - cy);
      if (activeDistance < nextDistance - viewport.height * 0.025) return previewRow;
    }
    return row;
  }

  function warmFocusPreview(feed) {
    if (!feed || state.playerOpen || state.miniVisible) return;
    const view = feedViewport(feed);
    if (!view.isActive) return;
    const row = previewFocusRow(feed, view.scroll);
    if (!row || row === previewRow) return;
    const item = row.__nativeItem;
    if (!item || item.live || !item.bvid) return;
    warmPreviewPrefix(item);
  }

  function previewUrlFor(item) {
    const key = `${item.bvid}:${item.cid || 0}`;
    const cached = previewUrlCache.get(key);
    if (cached && Date.now() - cached.at < PREVIEW_URL_TTL) {
      if (!item.cid && cached.cid) {
        item.cid = Number(cached.cid) || 0;
        prefetchDanmaku(item.cid);
      }
      return cached.url;
    }
    if (typeof bridge.previewCached === 'function') {
      const cachedResult = call('previewCached', item.bvid, item.cid || 0);
      const cachedUrl = cachedResult && cachedResult.ok
        ? (NATIVE_MEDIA ? String(cachedResult.remote || '') : String(cachedResult.url || ''))
        : '';
      if (cachedUrl) {
        previewUrlCache.set(key, {
          url: cachedUrl,
          backup: cachedResult.backupRemote || '',
          cid: Number(cachedResult.cid) || 0,
          at: Date.now(),
        });
        if (!item.cid && cachedResult.cid) {
          item.cid = Number(cachedResult.cid) || 0;
          if (previewRow && previewRow.__nativeItem === item) previewRow.__nativeItem.cid = item.cid;
          prefetchDanmaku(item.cid);
        }
        return cachedUrl;
      }
      if (!previewPending.has(key) && typeof bridge.prewarmPreviews === 'function') {
        previewPending.add(key);
        setTimeout(() => previewPending.delete(key), 2500);
        try { bridge.prewarmPreviews(JSON.stringify([{ bvid: item.bvid, cid: Number(item.cid) || 0 }])); } catch (_) {}
      }
      return '';
    }
    const result = call('playLow', item.bvid, item.cid || 0);
    const url = result && result.ok
      ? (NATIVE_MEDIA ? String(result.remote || '') : String(result.url || ''))
      : '';
    if (url) {
      previewUrlCache.set(key, {
        url,
        backup: NATIVE_MEDIA ? String(result.backupRemote || '') : String(result.backup || ''),
        cid: Number(result.cid) || 0,
        at: Date.now(),
      });
      if (!item.cid && result.cid) {
        item.cid = Number(result.cid) || 0;
        if (previewRow && previewRow.__nativeItem === item) previewRow.__nativeItem.cid = item.cid;
        prefetchDanmaku(item.cid);
      }
    } else {
      previewUrlCache.delete(key);
    }
    return url;
  }

  function previewBackupFor(item) {
    const key = `${item.bvid}:${item.cid || 0}`;
    const cached = previewUrlCache.get(key);
    return cached ? String(cached.backup || '') : '';
  }

  function loadPreviewNative(video, item, url, autoplay) {
    if (!NATIVE_MEDIA || typeof video.__nativeLoad !== 'function') {
      const nativeFallback = () => {
        if (video.__o11a1NativeFallback) return;
        if (video !== previewVideo || !document.contains(video)) return;
        if (state.playerOpen || (video.closest && video.closest('#playerVideo'))) return;
        if (promotedPreview && promotedPreview.video === video) return;
        video.__o11a1NativeFallback = true;
        log('preview html fallback native ' + (item.bvid || ''));
        if (NATIVE_MEDIA && window.O11A1NativeMedia) {
          try { window.O11A1NativeMedia.attach(video); } catch (_) {}
        }
        if (typeof video.__nativeLoad === 'function') {
          video.__nativeLoad({
            videoUrl: url,
            backupUrl: previewBackupFor(item),
            kind: 'file',
            loop: true,
            muted: true,
            autoplay: true,
          });
        }
      };
      if (!video.__o11a1HtmlWired) {
        video.__o11a1HtmlWired = true;
        video.addEventListener('error', () => {
          log('preview html error ' + String(video.error && video.error.code) + ' ' + String(video.currentSrc || '').split('?')[0]);
          nativeFallback();
        });
      }
      video.src = url;
      video.load();
      if (autoplay) video.play().catch((error) => {
        log('preview html play failed ' + error);
        nativeFallback();
      });
      return;
    }
    video.__nativeLoad({
      videoUrl: url,
      backupUrl: previewBackupFor(item),
      kind: 'file',
      loop: true,
      muted: true,
      autoplay: Boolean(autoplay),
    });
    if (autoplay) video.play().catch(() => {});
  }

  function prewarmPlayerUrl(item) {
    if (!item || item.live || item.epId || !item.bvid) return;
    const qn = qualityQn(state.settings.quality);
    const key = `${item.bvid}:${item.cid || 0}:${qn}`;
    if (playerWarmPending.has(key)) return;
    playerWarmPending.add(key);
    setTimeout(() => playerWarmPending.delete(key), 60000);
    try {
      if (qn > 64) {
        if (typeof bridge.prewarmDash === 'function') bridge.prewarmDash(item.bvid, item.cid || 0, 120);
      } else if (typeof bridge.prewarmQuality === 'function') {
        bridge.prewarmQuality(item.bvid, item.cid || 0, qn);
      }
    } catch (_) {}
  }

  function updateFeedPreview(feed) {
    if (!feed) return;
    if (previewRow && !document.contains(previewRow)) stopFeedPreview();
    const view = feedViewport(feed);
    const paused = state.playerOpen
      || state.miniVisible
      || host.app.classList.contains('sidebar-open')
      || state.page === 'playlist'
      || (state.searchOpen && feed !== feeds.search)
      || (state.page !== 'home' && state.page !== 'module')
      || Boolean(document.querySelector('#playlistDock.expanded, .page[data-page="playlist"].active, .player-settings.open, .comments-panel.open, #videoDetailPanel.open, #psheet.open, #sheet.open, .proto-drawer.open'));
    if (!view.isActive || paused) {
      previewCandidate = null;
      clearTimeout(previewCandidateTimer);
      previewCandidateTimer = 0;
      if (previewRow && feed.contains(previewRow)) stopFeedPreview();
      stopPreviewPreload();
      return;
    }
    if (previewVideo && !promotedPreview) setPreviewPlaybackRate(1);
    const row = previewFocusRow(feed, view.scroll);
    if (!row || row === previewRow) {
      previewCandidate = null;
      clearTimeout(previewCandidateTimer);
      previewCandidateTimer = 0;
      return;
    }
    if (row !== previewCandidate) {
      previewCandidate = row;
      clearTimeout(previewCandidateTimer);
      // A fast fling crosses several rows in a few frames. Starting a new
      // AVPlayer for every intermediate row starves the main thread and makes
      // the visible preview lag; wait for the row to be the focus for a couple
      // of frames, then swap.
      previewCandidateTimer = setTimeout(() => {
        previewCandidateTimer = 0;
        if (previewCandidate !== row || !document.contains(row)) return;
        const current = previewFocusRow(feed, view.scroll);
        if (current !== row) return;
        activatePreviewFocus(feed, row);
      }, 40);
    }
  }

  function activatePreviewFocus(feed, row) {
    const item = row.__nativeItem;
    if (!item || item.live || !item.bvid) {
      previewCandidate = null;
      return;
    }
    prefetchDanmaku(item.cid);
    if (!previewVideo && !preloadVideo) {
      const thumb = row.querySelector('.row-thumb');
      if (thumb) {
        const url = previewUrlFor(item);
        prefetchDanmaku(item.cid);
        if (!url) {
          // The play URL is still being warmed by /api/prewarm. Retry shortly
          // instead of letting this row become a permanently stuck candidate.
          previewCandidate = null;
          setTimeout(() => updateFeedPreview(feed), 320);
          return;
        }
        stopPreviewPreload();
        const video = ensurePreviewVideo();
        previewRow = row;
        log('preview html ' + (item.bvid || item.epId || ''));
        row.classList.add('preview-active');
        // The video must be in the document before src/play; playing a
        // detached media element makes WebKit reject it with NotSupportedError.
        thumb.appendChild(video);
        loadPreviewNative(video, item, url, true);
        previewProgressFill = attachPreviewOverlays(thumb);
        thumb.classList.add('preview-loading');
        const reveal = () => {
          thumb.classList.remove('preview-loading');
          video.classList.add('show');
        };
        video.addEventListener('canplay', reveal, { once: true });
        video.addEventListener('playing', reveal, { once: true });
        video.currentTime = 0;
        try { video.playbackRate = 1; } catch (_) {}
        video.play().catch((error) => log('preview play failed ' + error));
        prewarmPlayerUrl(item);
        setTimeout(() => preloadPreviewNeighbor(feed, row), 500);
        return;
      }
    }
    if (preloadRow !== row) startPreviewPreload(feed, row);
    schedulePreviewCommit(feed, row);
  }

  setInterval(() => {
    if (document.hidden || state.playerOpen || state.miniVisible) return;
    const feed = state.page === 'home'
      ? feeds.home
      : state.page === 'module'
        ? feeds.module
        : state.searchOpen
          ? feeds.search
          : state.page === 'up'
            ? feeds.up
            : null;
    if (!feed) return;
    if (previewRow && !document.contains(previewRow)) previewRow = null;
    if (previewRow && previewVideo && previewVideo.src) {
      if (previewVideo.paused && !document.hidden) previewVideo.play().catch(() => {});
      return;
    }
    if (previewRow) stopFeedPreview();
    if (preloadVideo && Date.now() - preloadStartedAt > 3000) stopPreviewPreload();
    if (previewCommitTimer || preloadVideo) return;
    const view = feedViewport(feed);
    if (!view.isActive || feedIsBusy(feed)) return;
    updateFeedPreview(feed);
  }, 1200);

  document.addEventListener('visibilitychange', () => {
    if (!document.hidden) return;
    if (promotedPreview) {
      try { promotedPreview.video.pause(); } catch (_) {}
      return;
    }
    stopFeedPreview();
  });

  if (host) {
    host.stopFeedPreview = stopFeedPreview;
    host.previewDebug = () => ({
      previewRow: previewRow && previewRow.__nativeItem ? previewRow.__nativeItem.bvid : null,
      previewState: previewVideo ? previewVideo.readyState : -1,
      previewTime: previewVideo ? Number(previewVideo.currentTime) : 0,
      preloadRow: preloadRow && preloadRow.__nativeItem ? preloadRow.__nativeItem.bvid : null,
      preloadState: preloadVideo ? preloadVideo.readyState : -1,
      preloadReady,
      timer: Boolean(previewCommitTimer),
      lastScrollAgo: Date.now() - lastFeedScrollAt,
      homeBusy: feeds.home ? feedIsBusy(feeds.home) : null,
      homeTouch: feeds.home && feeds.home.__feedWindow ? feeds.home.__feedWindow.touchActive : null,
      homeScrollAgo: feeds.home && feeds.home.__feedWindow && feeds.home.__feedWindow.lastScrollAt
        ? Date.now() - feeds.home.__feedWindow.lastScrollAt : null,
      homeBlocks: feeds.home && feeds.home.__feedWindow ? feeds.home.__feedWindow.blocks.length : -1,
      homeQueue: feeds.home && feeds.home.__feedWindow ? feeds.home.__feedWindow.queue.length : -1,
    });
    host.promoteFeedPreview = promoteFeedPreview;
    host.updateFeedPreview = (feed) => {
      if (feed) {
        updateFeedPreview(feed);
        return;
      }
      if (state.page === 'up') updateFeedPreview(feeds.up);
      else if (state.page === 'module') updateFeedPreview(feeds.module);
      else if (state.searchOpen) updateFeedPreview(feeds.search);
      else updateFeedPreview(feeds.home);
    };
  }

  function trimFirstWindowBlock(feed) {
    const fw = feed.__feedWindow;
    if (!fw || fw.blocks.length <= FEED_WINDOW_BLOCKS) return false;
    const { scroll } = feedViewport(feed);
    const block = fw.blocks[0];
    if (!block) return false;
    if (previewRow && block.nodes.includes(previewRow)) return false;
    if (preloadRow && block.nodes.includes(preloadRow)) stopPreviewPreload();
    const anchor = scroll ? topVisibleRow(feed, scroll, block.nodes) : null;
    const anchorTop = anchor ? anchor.getBoundingClientRect().top : 0;
    const first = block.nodes[0];
    const last = block.nodes[block.nodes.length - 1];
    const removedHeight = first && last
      ? last.getBoundingClientRect().bottom - first.getBoundingClientRect().top
      : 0;
    releaseWindowBlock(block);
    fw.blocks.shift();
    fw.firstItemIndex = block.endIndex;
    syncWindowItems(feed);
    if (scroll) {
      if (anchor) {
        const afterTop = anchor.getBoundingClientRect().top;
        const delta = afterTop - anchorTop;
        if (delta) {
          window.__o11a1ScrollAdjust = Date.now();
          scroll.scrollTop = Math.max(0, scroll.scrollTop + delta);
        }
      } else if (removedHeight > 0) {
        window.__o11a1ScrollAdjust = Date.now();
        scroll.scrollTop = Math.max(0, scroll.scrollTop - removedHeight);
      }
    }
    return true;
  }

  function maybeAdvanceWindow(feed) {
    const fw = feed.__feedWindow;
    if (!fw) return;
    const view = feedViewport(feed);
    if (!view.isActive) return;
    renderWindowBlocks(feed);
    if (fw.blocks.length < FEED_WINDOW_BLOCKS) return;
    const focus = feedFocusRow(feed, view.scroll);
    if (!focus) return;
    const activeBlock = Number(focus.dataset.block);
    if (!Number.isFinite(activeBlock)) return;
    const firstId = fw.blocks[0].id;
    if (activeBlock < firstId + (FEED_WINDOW_BLOCKS - 1)) return;
    const top = topVisibleRow(feed, view.scroll);
    const topBlock = top ? Number(top.dataset.block) : -1;
    if (topBlock < firstId + 1) return;
    const win = windows[feedKey(feed)];
    if (!win) return;
    const canAppend = fw.queue.length >= FEED_BLOCK_SIZE
      || (!win.hasMore && fw.queue.length > 0);
    if (canAppend) {
      appendWindowBlock(feed);
      trimFirstWindowBlock(feed);
      syncWindowItems(feed);
      scheduleBufferFill(feed);
      return;
    }
    if (win.hasMore) requestFeedPage(feedKey(feed), false);
  }

  function maybePrefetchWindow(feed) {
    const fw = feed.__feedWindow;
    const win = windows[feedKey(feed)];
    const view = feedViewport(feed);
    if (!fw || !win || !view.isActive || !view.scroll || !win.hasMore || win.loading) return;
    if (fw.queue.length >= FEED_BLOCK_SIZE) return;
    if (view.scroll.scrollTop + view.scroll.clientHeight
      < view.scroll.scrollHeight - FEED_PREFETCH) return;
    requestFeedPage(feedKey(feed), false);
  }

  function scheduleWindowSettle(feed, delay = 110) {
    if (!feed) return;
    const fw = feedWindowState(feed);
    clearTimeout(fw.scrollTimer);
    fw.scrollTimer = setTimeout(() => {
      fw.scrollTimer = null;
      if (fw.touchActive && Date.now() - fw.touchActiveAt < 1200) {
        scheduleWindowSettle(feed, 180);
        return;
      }
      if (feedIsBusy(feed)) {
        scheduleWindowSettle(feed, 120);
        return;
      }
      fw.touchActive = false;
      maybeAdvanceWindow(feed);
      maybePrefetchWindow(feed);
      updateFeedPreview(feed);
    }, delay);
  }

  function setPreviewPlaybackRate(rate) {
    if (!previewVideo || promotedPreview) return;
    try { previewVideo.playbackRate = rate; } catch (_) {}
  }

  function previewPlaybackRate() {
    return 1;
  }

  let previewFocusFrame = 0;
  function schedulePreviewFocus(feed) {
    if (!feed || previewFocusFrame) return;
    previewFocusFrame = requestAnimationFrame(() => {
      previewFocusFrame = 0;
      updateFeedPreview(feed);
    });
  }

  function scheduleWindowUpdate(feed) {
    if (!feed) return;
    if (host.suppressFeedClicks) host.suppressFeedClicks(80);
    // Do not cancel an in-flight preview preload on every scroll event; the
    // focus row is re-evaluated on the next animation frame now.
    const now = Date.now();
    lastFeedScrollAt = now;
    feedWindowState(feed).lastScrollAt = now;
    schedulePreviewFocus(feed);
    scheduleWindowSettle(feed);
  }

  function setFeedTouch(feed, active) {
    if (!feed) return;
    const fw = feedWindowState(feed);
    fw.touchActive = Boolean(active);
    if (active) {
      fw.touchActiveAt = Date.now();
    } else {
      scheduleWindowSettle(feed, 60);
    }
  }

  function scheduleBufferFill(feed) {
    if (!feed) return;
    const fw = feed.__feedWindow;
    if (!fw) return;
    clearTimeout(fw.fillTimer);
    fw.fillTimer = setTimeout(() => {
      fw.fillTimer = null;
      const win = windows[feedKey(feed)];
      const view = feedViewport(feed);
      if (!win || !view.isActive || !win.hasMore || win.loading) return;
      if (fw.queue.length >= FEED_BLOCK_SIZE) return;
      if (fw.blocks.length < FEED_WINDOW_BLOCKS) {
        requestFeedPage(feedKey(feed), false);
        return;
      }
      if (!view.scroll) return;
      const focus = feedFocusRow(feed, view.scroll);
      const activeBlock = focus ? Number(focus.dataset.block) : -1;
      const nearBottom = view.scroll.scrollTop + view.scroll.clientHeight
        >= view.scroll.scrollHeight - FEED_PREFETCH;
      if (nearBottom || fw.queue.length === 0 || activeBlock >= fw.blocks[0].id + 1) {
        requestFeedPage(feedKey(feed), false);
      }
    }, 180);
  }

  function scheduleDeferredFeedRender(feed) {
    const fw = feed && feed.__feedWindow;
    if (!fw) return;
    clearTimeout(fw.renderTimer);
    const pump = () => {
      fw.renderTimer = null;
      if (feedIsBusy(feed)) {
        fw.renderTimer = setTimeout(pump, 160);
        return;
      }
      renderWindowBlocks(feed);
      scheduleWindowSettle(feed);
      scheduleBufferFill(feed);
    };
    fw.renderTimer = setTimeout(pump, 140);
  }

  function appendRows(feed, items, label, page) {
    if (!feed) return;
    const fw = feed.__feedWindow;
    if (!fw) {
      renderRows(feed, items, label, page);
      return;
    }
    if (label) fw.label = label;
    for (let index = 0; index < items.length; index += 1) fw.queue.push(items[index]);
    if (feedIsBusy(feed)) {
      scheduleDeferredFeedRender(feed);
      return;
    }
    renderWindowBlocks(feed);
    scheduleWindowSettle(feed);
    scheduleBufferFill(feed);
  }

  function feedResult(api, args) {
    return call(api, ...args);
  }

  function feedKey(feed) {
    if (feed === feeds.home) return 'home';
    if (feed === feeds.search) return 'search';
    if (feed === feeds.up) return 'up';
    return 'module';
  }

  function moduleKind(name) {
    const moduleName = name || state.moduleName || '推荐';
    const filterIndex = Math.max(0, Number(state.moduleFilterIndex) || 0);
    if (moduleName === '推荐') return { api: 'recommend', args: [], label: '首页推荐' };
    if (moduleName === '热门') return { api: 'popular', args: [], label: 'B 站热门' };
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
    if (moduleName === '会员') return { api: null, special: 'member', label: '会员任务' };
    if (moduleName === '养鱼') return { api: null, special: 'fish', label: 'AI 养鱼' };
    return { api: 'search', args: [moduleName], label: moduleName };
  }

  function loadFeed(name, feed, page, cursor, append) {
    const kind = moduleKind(name);
    const pageNo = page || 1;
    if (kind.special) {
      if (!append) renderEmpty(feed, kind.label, kind.note);
      setTail(feed, 'idle');
      return { ok: true, items: [], title: kind.label, needLogin: false, hasMore: false };
    }
    if (!kind.api) {
      if (!append) renderEmpty(feed, kind.label, kind.note);
      return { ok: true, items: [], title: kind.label, needLogin: false, hasMore: false };
    }
    if (kind.api === 'favorites' && !state.loggedIn) {
      if (!append) renderEmpty(feed, '登录后查看收藏', '登录后同步收藏夹。', '去登录', () => host.showPage('login'));
      return { ok: true, items: [], title: kind.label, needLogin: true, hasMore: false };
    }
    if ((kind.api === 'history' || kind.api === 'following') && !state.loggedIn) {
      if (!append) renderEmpty(feed, `登录后查看${kind.label}`, '登录后同步 B 站账号。', '去登录', () => host.showPage('login'));
      return { ok: true, items: [], title: kind.label, needLogin: true, hasMore: false };
    }
    if (kind.api === 'recommend' && !append) {
      recommendSeed = 1 + Math.floor(Math.random() * 900);
      recommendSeen = new Set();
    }
    const args = kind.api === 'recommend' ? [pageNo, 30, recommendSeed + pageNo - 1]
      : kind.api === 'popular' ? [pageNo, 20]
      : kind.api === 'history' ? [pageNo, cursor || '']
        : kind.api === 'favorites' || kind.api === 'ranking' || kind.api === 'live' || kind.api === 'following'
          ? [pageNo]
          : kind.api === 'bangumi' ? [pageNo, kind.args[0]]
            : kind.api === 'zone' ? [kind.args[0], pageNo]
              : kind.api === 'search'
                ? [name, pageNo]
                : [pageNo];
    let result = !append && (kind.api === 'live' || kind.api === 'bangumi')
      ? readPreloadPage('feed-' + kind.api, args)
      : null;
    if (!result) {
      result = feedResult(kind.api, args);
      if (result.ok && (kind.api === 'live' || kind.api === 'bangumi')) {
        writePreloadPage('feed-' + kind.api, args, result);
      }
    }
    if (!result.ok) {
      if (!append) {
        if (result.needLogin) {
          renderEmpty(feed, `登录后查看${kind.label}`, '登录后同步 B 站账号。', '去登录', () => host.showPage('login'));
        } else {
          renderEmpty(feed, `${kind.label}加载失败`, result.error || '网络错误', '重试', () => loadFeed(name, feed, 1, ''));
        }
      } else {
        setTail(feed, 'error', result.needLogin ? '登录后继续加载' : '加载失败 · 点击重试',
          () => requestFeedPage(feedKey(feed), true));
      }
      return { ok: false, items: [], title: kind.label, needLogin: Boolean(result.needLogin), hasMore: true };
    }
    let items = Array.isArray(result.items) ? result.items : [];
    if (kind.api === 'recommend') {
      items = items.filter((item) => {
        const key = String(item && item.bvid ? item.bvid : '');
        if (!key) return false;
        if (recommendSeen.has(key)) return false;
        recommendSeen.add(key);
        return true;
      });
    }
    if (items.length === 0) {
      if (!append) renderEmpty(feed, result.note || `${kind.label}暂无内容`, result.hasMore === false ? '' : '稍后再试');
      else setTail(feed, 'idle');
      return {
        ok: true,
        items: [],
        title: result.title || kind.label,
        next: result.next || '',
        hasMore: false,
        needLogin: false,
      };
    }
    if (append) appendRows(feed, items, kind.label, pageNo);
    else renderRows(feed, items, kind.label, pageNo);
    const hasMore = result.hasMore !== false;
    setTail(feed, 'idle');
    return {
      ok: true,
      items,
      title: result.title || kind.label,
      next: result.next || '',
      hasMore,
      needLogin: false,
    };
  }

  function loadHome(page, append, immediate) {
    const module = state.modules.find((mod) => mod.id === state.moduleId && mod.on);
    const name = module ? module.name : '推荐';
    const kind = moduleKind(name);
    const win = windows.home;
    if (!append && !immediate) {
      deferLoading('home', () => {
        showInitialFeedSkeleton(feeds.home, 8);
        setNote('正在加载…');
      }, () => loadHome(1, false, true));
      return true;
    }
    const appendPage = Boolean(append) && win.name === name;
    if (!appendPage) {
      win.token += 1;
      win.page = 0;
      win.cursor = '';
      win.hasMore = true;
      win.loading = false;
      win.name = name;
    }
    const pageNo = appendPage ? (page || 1) : 1;
    const result = loadFeed(name, feeds.home, pageNo, win.cursor, appendPage);
    if (result.ok) {
      win.page = pageNo;
      win.cursor = result.next || '';
      win.hasMore = result.hasMore !== false;
      setNote(`${result.title || kind.label} · 触底加载 · 每块 10 条 · 保留 3 块`);
    } else {
      setNote(`${result.title || kind.label} · 加载失败`);
    }
    win.loading = false;
    return result.ok;
  }

  function loadModule(page, append, immediate) {
    const name = state.moduleName || '推荐';
    const kind = moduleKind(name);
    const win = windows.module;
    const filter = $('#moduleFilter');
    if (!append && !immediate && kind.special !== 'fish') {
      deferLoading('module', () => {
        if (kind.special === 'member') showMemberSkeleton();
        else showInitialFeedSkeleton(feeds.module, 8);
        if (filter) filter.textContent = kind.label || name;
      }, () => loadModule(1, false, true));
      return true;
    }
    if (filter) filter.textContent = kind.label || name;
    const appendPage = Boolean(append) && win.name === name;
    if (!appendPage) {
      win.token += 1;
      win.page = 0;
      win.cursor = '';
      win.hasMore = true;
      win.loading = false;
      win.name = name;
    }
    if (kind.special === 'member') {
      win.hasMore = false;
      win.page = 1;
      win.loading = false;
      if (!appendPage) renderMember();
      setTail(feeds.module, 'idle');
      return true;
    }
    if (kind.special === 'fish') {
      win.hasMore = false;
      win.page = 1;
      win.loading = false;
      if (!appendPage) renderFish();
      setTail(feeds.module, 'idle');
      return true;
    }
    const pageNo = appendPage ? (page || 1) : 1;
    const result = loadFeed(name, feeds.module, pageNo, win.cursor, appendPage);
    if (result.ok) {
      win.page = pageNo;
      win.cursor = result.next || '';
      win.hasMore = result.hasMore !== false;
    }
    win.loading = false;
    return result.ok;
  }

  function syncUpSortUI() {
    $$('#upSort [data-up-sort]').forEach((button) => {
      const on = button.dataset.upSort === upSort;
      button.classList.toggle('on', on);
      button.setAttribute('aria-selected', on ? 'true' : 'false');
    });
  }

  function changeUpSort(next) {
    if (next !== 'click' && next !== 'pubdate') return;
    if (next === upSort) return;
    upSort = next;
    if (upScroll) upScroll.scrollTop = 0;
    syncUpSortUI();
    loadUp(1, false);
  }

  function loadUp(page, append, immediate) {
    const feed = feeds.up;
    const win = windows.up;
    if (!feed) return false;
    if (!append && !immediate) {
      deferLoading('up', () => {
        showInitialFeedSkeleton(feed, 8);
        const note = $('#upNote');
        if (note) note.textContent = '正在加载…';
      }, () => loadUp(1, false, true));
      return true;
    }
    const appendPage = Boolean(append) && win.page > 0;
    if (!appendPage) {
      win.token += 1;
      win.page = 0;
      win.hasMore = true;
      win.loading = false;
    }
    const pageNo = appendPage ? (page || 1) : 1;
    if (typeof bridge.space !== 'function') {
      if (!appendPage) {
        renderEmpty(feed, 'UP 主视频接口未接入', '当前版本只显示 UP 主资料；视频列表需要原生 space 接口。');
      }
      win.hasMore = false;
      win.loading = false;
      setTail(feed, 'idle');
      const note = $('#upNote');
      if (note) note.textContent = 'UP 主视频 · 接口未接入';
      return false;
    }
    const mid = Number(state.upItem && state.upItem.mid ? state.upItem.mid : 0);
    if (!mid) {
      if (!appendPage) {
        renderEmpty(feed, '缺少 UP 主 UID', '从视频详情或视频行进入 UP 主页后再试。');
      }
      win.hasMore = false;
      win.loading = false;
      setTail(feed, 'idle');
      return false;
    }
    const result = call('space', mid, pageNo, upSort);
    if (!result.ok) {
      if (!appendPage) {
        renderEmpty(feed, 'UP 主视频加载失败', result.error || '网络错误', '重试', () => loadUp(1, false));
      } else {
        setTail(feed, 'error', '加载失败 · 点击重试', () => requestFeedPage('up', true));
      }
      win.loading = false;
      return false;
    }
    if (result.name) {
      state.upName = result.name;
      const nameEl = $('#upName');
      if (nameEl) nameEl.textContent = result.name;
    }
    if (result.face) {
      const avatar = $('#upAvatar');
      if (avatar) {
        avatar.style.backgroundImage = `url("${result.face}")`;
        avatar.textContent = '';
      }
    }
    const midEl = $('#upMid');
    if (midEl) {
      const followText = result.follower ? ` · ${countText(result.follower)} 粉丝` : '';
      midEl.textContent = `UID ${mid}${followText}`;
    }
    syncUpSortUI();
    const items = Array.isArray(result.items) ? result.items : [];
    if (!items.length) {
      if (!appendPage) renderEmpty(feed, '这个 UP 主还没有视频', '');
      else setTail(feed, 'idle');
      win.hasMore = false;
      win.loading = false;
      return true;
    }
    if (appendPage) appendRows(feed, items, state.upName || 'UP 主', pageNo);
    else renderRows(feed, items, state.upName || 'UP 主', pageNo);
    win.page = pageNo;
    win.hasMore = result.hasMore !== false;
    win.loading = false;
    setTail(feed, 'idle');
    const note = $('#upNote');
    if (note) note.textContent = `${state.upName || 'UP 主'} · ${upSort === 'click' ? '播放量' : '新发布'} · 触底加载`;
    return true;
  }

  function openUpPage(item) {
    if (!item) return;
    if (state.page !== 'up') {
      state.upReturn = state.page || 'home';
      state.upReturnNav = state.navActive;
    }
    state.upItem = item;
    state.upName = item.owner || 'UP 主';
    const name = state.upName;
    const mid = Number(item.mid || 0);
    const avatar = $('#upAvatar');
    if (avatar) {
      avatar.style.backgroundImage = item.ownerFace ? `url("${item.ownerFace}")` : '';
      avatar.textContent = item.ownerFace ? '' : name.slice(0, 1);
    }
    const nameEl = $('#upName');
    if (nameEl) nameEl.textContent = name;
    const midEl = $('#upMid');
    if (midEl) midEl.textContent = mid ? `UID ${mid}` : 'UID —';
    const follow = $('#upFollow');
    if (follow) {
      follow.textContent = '关注';
      follow.disabled = !mid;
    }
    const note = $('#upNote');
    if (note) note.textContent = `${name} · UP 主视频`;
    syncUpSortUI();
    host.showPage('up');
    windows.up.token += 1;
    windows.up.page = 0;
    windows.up.cursor = '';
    windows.up.hasMore = true;
    windows.up.loading = false;
    windows.up.name = name;
    const feed = feeds.up;
    if (feed) showInitialFeedSkeleton(feed, 8);
    if (note) note.textContent = `${name} · 正在加载…`;
    const token = windows.up.token;
    clearTimeout(windows.up.openTimer);
    windows.up.openTimer = setTimeout(() => {
      windows.up.openTimer = null;
      if (state.page !== 'up' || windows.up.token !== token) return;
      loadUp(1, false, true);
    }, 430);
  }

  /* ---------- member center ---------- */
  function renderMember(immediate) {
    const feed = feeds.module;
    resetFeedWindow(feed);
    if (!state.loggedIn) {
      renderEmpty(feed, '登录后查看会员任务', '登录后同步大会员状态与每日经验。', '去登录', () => host.showPage('login'));
      return;
    }
    if (typeof bridge.memberCenter !== 'function') {
      renderEmpty(feed, '当前版本不支持会员中心', '');
      return;
    }
    if (!immediate) {
      deferLoading('member', showMemberSkeleton, () => renderMember(true));
      return;
    }
    const result = call('memberCenter');
    if (!result.ok) {
      renderEmpty(feed, result.needLogin ? '登录已失效' : '会员中心加载失败', result.error || '', result.needLogin ? '去登录' : '重试', result.needLogin ? () => host.showPage('login') : renderMember);
      return;
    }
    const tasks = Array.isArray(result.tasks) ? result.tasks : [];
    const log = Array.isArray(result.log) ? result.log : [];
    const due = result.vipDue ? new Date(Number(result.vipDue)) : null;
    feed.innerHTML = `
      <div class="special-page">
        <div class="member-card ${result.vip ? 'vip' : ''}">
          <span class="member-badge">${result.vip ? '大会员' : '普通会员'}</span>
          <b>${result.vip ? '大会员权益已生效' : '未开通大会员'}</b>
          <span>${due && result.vip ? `有效期至 ${due.getFullYear()}-${String(due.getMonth() + 1).padStart(2, '0')}-${String(due.getDate()).padStart(2, '0')}` : '大会员画质与权益以 B 站账号为准'}</span>
        </div>
        <div class="special-title">每日任务</div>
        <div class="task-list">
          ${tasks.map((task) => `
            <div class="task-row ${task.done ? 'done' : ''}">
              <span class="task-check">${task.done ? '✓' : ''}</span>
              <span class="task-copy"><b>${esc(task.label)}</b>${task.detail ? `<small>${esc(task.detail)}</small>` : ''}</span>
              <span class="task-reward">+${Number(task.reward || 0)} 经验</span>
            </div>`).join('')}
        </div>
        <div class="special-title">最近经验</div>
        <div class="exp-list">
          ${log.length ? log.map((row) => `
            <div class="exp-row"><span>${esc(row.reason || '经验')}</span><b>+${Number(row.delta || 0)}</b><small>${esc(row.time || '')}</small></div>`).join('') : '<div class="native-empty"><b>暂无经验记录</b></div>'}
        </div>
        <button type="button" class="pill-btn" id="memberRefresh">刷新会员状态</button>
      </div>`;
    const refresh = $('#memberRefresh');
    if (refresh) refresh.addEventListener('click', renderMember);
  }

  /* ---------- AI fish ---------- */
  const FISH_STORE = 'o11a1.fish.config';
  function fishConfig() {
    try {
      return JSON.parse(localStorage.getItem(FISH_STORE) || '{}') || {};
    } catch (_) {
      return {};
    }
  }

  function saveFishConfig(config) {
    try { localStorage.setItem(FISH_STORE, JSON.stringify(config)); } catch (_) {}
  }

  function renderFish() {
    const feed = feeds.module;
    resetFeedWindow(feed);
    const config = fishConfig();
    feed.innerHTML = `
      <div class="special-page fish-page">
        <div class="special-head">
          <div><b>AI 养鱼</b><span>OpenAI 兼容接口 · 真实请求 · 结果只在本机显示</span></div>
        </div>
        <div class="fish-hero">
          <span class="fish-bubble">🐟</span>
          <div><b>给鱼缸投喂一段饲料</b><span>配置接口后，AI 会返回一条真实的生成结果。没有 Key 时不会伪造成功。</span></div>
        </div>
        <form id="fishForm" class="fish-form">
          <label>API 地址<input id="fishEndpoint" value="${attr(config.endpoint || 'https://api.deepseek.com/v1/chat/completions')}" placeholder="https://api.deepseek.com/v1/chat/completions"></label>
          <label>模型<input id="fishModel" value="${attr(config.model || 'deepseek-chat')}" placeholder="deepseek-chat"></label>
          <label>API Key<input id="fishKey" type="password" value="${attr(config.apiKey || '')}" placeholder="sk-..." autocomplete="off"></label>
          <label>饲料 / 提示词<textarea id="fishPrompt" rows="4">${esc(config.prompt || '用三句话点评今天 B 站最热的一条视频，并给出一个养鱼式的比喻。')}</textarea></label>
          <div class="fish-actions">
            <button type="submit" class="pill-btn primary" id="fishRun">投喂并生成</button>
            <button type="button" class="pill-btn" id="fishClearKey">清除 Key</button>
          </div>
        </form>
        <div class="fish-output" id="fishOutput">
          <div class="native-empty"><b>鱼缸很安静</b><span>填写 API Key 后点击「投喂并生成」。</span></div>
        </div>
      </div>`;
    const form = $('#fishForm');
    const output = $('#fishOutput');
    if (form) form.addEventListener('submit', (event) => {
      event.preventDefault();
      const endpoint = $('#fishEndpoint').value.trim();
      const model = $('#fishModel').value.trim();
      const apiKey = $('#fishKey').value.trim();
      const prompt = $('#fishPrompt').value.trim();
      saveFishConfig({ endpoint, model, apiKey, prompt });
      if (!apiKey) {
        output.innerHTML = '<div class="native-empty"><b>需要 API Key</b><span>AI 养鱼不会在没有 Key 时伪造结果。请填写后再试。</span></div>';
        return;
      }
      if (typeof bridge.aiChat !== 'function') {
        output.innerHTML = '<div class="native-empty"><b>当前版本不支持 AI 请求</b></div>';
        return;
      }
      output.innerHTML = '<div class="native-empty"><b>鱼正在思考…</b><span>请求已发往配置的接口，最长等待 75 秒。</span></div>';
      setTimeout(() => {
        const result = call('aiChat', endpoint, apiKey, model, prompt);
        if (!result.ok) {
          output.innerHTML = `<div class="native-empty"><b>${result.needKey ? '需要 API Key' : '生成失败'}</b><span>${esc(result.error || '接口没有返回内容')}</span></div>`;
          return;
        }
        output.innerHTML = `
          <div class="fish-result">
            <div class="fish-result-head"><b>生成结果</b><span>${esc(result.model || model || 'AI')}</span></div>
            <p>${esc(result.text || '接口返回了空内容').replace(/\n/g, '<br>')}</p>
          </div>`;
      }, 60);
    });
    const clear = $('#fishClearKey');
    if (clear) clear.addEventListener('click', () => {
      const key = $('#fishKey');
      if (key) key.value = '';
      saveFishConfig({ ...fishConfig(), apiKey: '' });
      output.innerHTML = '<div class="native-empty"><b>Key 已从本机清除</b><span>接口和模型设置保留。</span></div>';
    });
  }

  const searchResultCache = new Map();
  function searchCacheKey(query, page) {
    return `${String(query || '').trim()}\u0000${Math.max(1, page || 1)}`;
  }

  function searchAsync(query) {
    const q = String(query || '').trim();
    const win = windows.search;
    const cached = searchResultCache.get(searchCacheKey(q, 1));
    if (cached) {
      loadSearch(q, 1, false, true, cached);
      return true;
    }
    win.token += 1;
    const token = win.token;
    win.page = 0;
    win.hasMore = true;
    win.loading = false;
    win.query = q;
    host.searchResultsLabel.textContent = q ? `“${q}”的视频` : '热门视频';
    host.searchEmpty.hidden = true;
    deferLoading('search', () => {
      showInitialFeedSkeleton(feeds.search, 10);
    }, () => {
      if (!bridge || typeof bridge.searchAsync !== 'function') {
        loadSearch(q, 1);
        return;
      }
      bridge.searchAsync(q, 1).then((raw) => {
        if (win.token !== token) return;
        const result = parse(raw);
        if (!result || !result.ok) {
          renderEmpty(feeds.search, q ? `“${q}”加载失败` : '热门视频加载失败',
            (result && result.error) || '网络错误', '重试', () => searchAsync(q));
          host.searchResultsLabel.textContent = q ? `“${q}”的视频` : '热门视频';
          host.searchEmpty.hidden = true;
          return;
        }
        searchResultCache.set(searchCacheKey(q, 1), result);
        if (searchResultCache.size > 8) searchResultCache.delete(searchResultCache.keys().next().value);
        loadSearch(q, 1, false, true, result);
      }).catch(() => {
        if (win.token !== token) return;
        renderEmpty(feeds.search, q ? `“${q}”加载失败` : '热门视频加载失败',
          '网络错误', '重试', () => searchAsync(q));
        host.searchEmpty.hidden = true;
      });
    });
    return true;
  }

  function loadSearch(query, page, append, immediate, prefetched) {
    const win = windows.search;
    const appendPage = Boolean(append) && win.query === query;
    if (!appendPage && !immediate) {
      host.searchResultsLabel.textContent = query ? `“${query}”的视频` : '热门视频';
      host.searchEmpty.hidden = true;
      deferLoading('search', () => {
        showInitialFeedSkeleton(feeds.search, 10);
      }, () => loadSearch(query, 1, false, true));
      return true;
    }
    if (!appendPage) {
      win.token += 1;
      win.page = 0;
      win.hasMore = true;
      win.loading = false;
      win.query = query;
    }
    const pageNo = appendPage ? (page || 1) : 1;
    const result = prefetched
      || (query ? feedResult('search', [query, pageNo]) : feedResult('popular', [pageNo, 20]));
    if (!result.ok) {
      if (!appendPage) {
        renderEmpty(feeds.search, query ? `“${query}”加载失败` : '热门视频加载失败',
          result.error || '网络错误', '重试', () => loadSearch(query, 1));
      } else {
        setTail(feeds.search, 'error', '加载失败 · 点击重试', () => requestFeedPage('search', true));
      }
      host.searchResultsLabel.textContent = query ? `“${query}”的视频` : '热门视频';
      host.searchEmpty.hidden = true;
      win.loading = false;
      return false;
    }
    const items = Array.isArray(result.items) ? result.items : [];
    if (!items.length) {
      if (!appendPage) {
        renderEmpty(feeds.search, query ? `“${query}”暂无结果` : '热门视频暂无内容',
          '', query ? '' : '重试', () => loadSearch(query, 1));
      } else {
        setTail(feeds.search, 'idle');
      }
      host.searchResultsLabel.textContent = query ? `“${query}”的视频` : '热门视频';
      host.searchEmpty.hidden = true;
      win.hasMore = false;
      win.loading = false;
      return true;
    }
    if (appendPage) appendRows(feeds.search, items, query ? '搜索结果' : '热门', pageNo);
    else renderRows(feeds.search, items, query ? '搜索结果' : '热门', pageNo);
    const hasMore = result.hasMore !== false;
    setTail(feeds.search, 'idle');
    win.page = pageNo;
    win.hasMore = hasMore;
    win.loading = false;
    host.searchResultsLabel.textContent = query ? `“${query}”的视频` : '热门视频';
    host.searchEmpty.hidden = true;
    return true;
  }

  function requestFeedPage(key, force) {
    const win = windows[key];
    const feed = feeds[key];
    if (!win || !feed) return;
    if (!force && (win.loading || !win.hasMore)) return;
    if (win.page < 1) return;
    const fw = feed.__feedWindow;
    if (!force && fw && fw.queue.length >= FEED_BLOCK_SIZE) return;
    const now = Date.now();
    if (!force && win.nextRetryAt && now < win.nextRetryAt) return;
    if (!feed.querySelector('.real-row')) return;
    const next = win.page + 1;
    const token = win.token;
    win.lastLoadAt = now;
    win.loading = true;
    setTail(feed, 'loading', '正在加载下一段…');
    clearTimeout(win.loadTimer);
    const run = () => {
      win.loadTimer = null;
      if (win.token !== token) {
        win.loading = false;
        return;
      }
      if (feedIsBusy(feed)) {
        win.loadTimer = setTimeout(run, 180);
        return;
      }
      if (state.page !== key && !(key === 'search' && state.searchOpen)) {
        win.loading = false;
        setTail(feed, 'idle');
        return;
      }
      if (win.page >= next) {
        win.loading = false;
        setTail(feed, 'idle');
        return;
      }
      let loaded = false;
      if (key === 'home') loaded = loadHome(next, true);
      else if (key === 'search') loaded = loadSearch(host.searchInput.value.trim(), next, true);
      else if (key === 'up') loaded = loadUp(next, true);
      else loaded = loadModule(next, true);
      win.loading = false;
      if (!loaded) {
        win.hasMore = false;
        win.nextRetryAt = Date.now() + 5000;
        return;
      }
      win.nextRetryAt = 0;
      scheduleWindowSettle(feed);
      scheduleBufferFill(feed);
    };
    win.loadTimer = setTimeout(run, 80);
  }

  function playItem(item) {
    if (!item) return;
    const preservePreview = Boolean(!item.live && !item.seasonId && previewRow
      && previewRow.__nativeItem
      && mediaKeyFor(previewRow.__nativeItem) === mediaKeyFor(item));
    let previewStart = preservePreview && previewVideo ? (Number(previewVideo.currentTime) || 0) : 0;
    if (!preservePreview) {
      stopFeedPreview();
      previewStart = takePreviewStart(item);
    }
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
    pendingMediaStart = previewStart > 0.25 ? { key, time: previewStart } : null;
    state.duration = 0;
    state.progress = pendingMediaStart && Number(item.durationSec) > 0
      ? Math.min(100, previewStart / Number(item.durationSec) * 100)
      : 0;
    state.playing = true;
    host.save();
    host.updatePlayerLabels();
    prefetchPlayerDanmaku(item);
    host.openPlayer({ resume: true });
  }

  function playSeason(item) {
    stopFeedPreview();
    const detail = call('season', item.seasonId);
    if (!detail.ok || !Array.isArray(detail.episodes) || !detail.episodes.length) {
      renderEmpty(state.page === 'module' ? feeds.module : feeds.home,
        '番剧加载失败', detail.error || '没有可播放的剧集', '重试',
        () => (state.page === 'module' ? loadModule(1) : loadHome(1)));
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
    prefetchPlayerDanmaku(state.playlist[firstIndex]);
    host.openPlayer({ resume: true });
  }

  function playLive(item) {
    stopFeedPreview();
    const room = call('liveRoom', item.roomId);
    if (!room.ok || !room.url) {
      renderEmpty(state.page === 'module' ? feeds.module : feeds.home,
        '直播加载失败', room.error || '直播间暂不可用', '重试',
        () => (state.page === 'module' ? loadModule(1) : loadHome(1)));
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
  const danmakuCache = new Map();
  const danmakuPending = new Map();
  let danmakuToken = 0;
  let posterDanmakuTimer = null;
  let posterDanmakuStart = 0;

  function startPosterDanmaku() {
    if (posterDanmakuTimer) return;
    posterDanmakuStart = performance.now();
    posterDanmakuTimer = setInterval(() => {
      if (!state.playerOpen || promotedPreview) {
        stopPosterDanmaku();
        return;
      }
      tickDanmaku((performance.now() - posterDanmakuStart) / 1000);
    }, 120);
  }

  function stopPosterDanmaku() {
    if (posterDanmakuTimer) clearInterval(posterDanmakuTimer);
    posterDanmakuTimer = null;
  }
  let mediaItem = null;
  let mediaLoadToken = 0;
  let mediaBackup = '';
  let mediaTriedBackup = false;
  const nativeFallbackKeys = new Set();
  let mediaLive = false;
  let hls = null;
  let liveSocket = null;
  let liveHeartbeat = null;
  let liveRetryTimer = null;
  let liveSeen = new Map();
  let liveRoomId = 0;
  let liveDanmakuCount = 0;
  let dashState = null;

  function setStatus(text, mode) {
    if (!status) return;
    status.textContent = text || '';
    playerVideo.classList.toggle('video-loading', mode === 'loading');
    playerVideo.classList.toggle('video-error', mode === 'error');
  }

  function danmakuSettingNumber(value, fallback, min, max) {
    const number = Number(value);
    if (!Number.isFinite(number)) return fallback;
    return Math.max(min, Math.min(max, number));
  }

  function applyDanmakuStyle() {
    if (!danmakuLayer) return;
    const settings = state.settings || {};
    const opacity = danmakuSettingNumber(settings.danmakuOpacity, 85, 0, 100);
    const size = danmakuSettingNumber(settings.danmakuSize, 100, 50, 150);
    const speed = danmakuSettingNumber(settings.danmakuSpeed, 100, 50, 200);
    const areaText = String(settings.danmakuArea || '全屏');
    const area = areaText.includes('1/3') ? 100 / 3 : areaText.includes('1/2') ? 50 : 100;
    danmakuLayer.style.display = settings.danmaku ? 'block' : 'none';
    danmakuLayer.style.setProperty('--dm-opacity', String(opacity / 100));
    danmakuLayer.style.setProperty('--dm-font-size', `${(14 * size / 100).toFixed(2)}px`);
    danmakuLayer.style.setProperty('--dm-area-height', `${area.toFixed(2)}%`);
    const factor = 100 / speed;
    $$('.danmaku-item', danmakuLayer).forEach((item) => {
      if (!item.__dmBaseSeconds) return;
      item.style.animationDuration = `${(item.__dmBaseSeconds * factor).toFixed(2)}s`;
    });
  }

  function normalizeDanmaku(result) {
    if (!result || !result.ok || !Array.isArray(result.items)) return null;
    return result.items
      .filter((row) => row && Number.isFinite(Number(row.t)) && row.text)
      .map((row) => ({
        t: Number(row.t),
        text: String(row.text),
        color: Number(row.color || 0xffffff),
        mode: Number(row.mode || 1),
      }))
      .sort((a, b) => a.t - b.t);
  }

  function fetchDanmaku(cid) {
    const key = String(cid || 0);
    if (!cid) return Promise.resolve([]);
    const cached = danmakuCache.get(key);
    if (cached) return Promise.resolve(cached);
    const pending = danmakuPending.get(key);
    if (pending) return pending;
    let request;
    if (bridge && typeof bridge.danmakuAsync === 'function') {
      request = bridge.danmakuAsync(cid).then((raw) => {
        const items = normalizeDanmaku(parse(raw)) || [];
        danmakuCache.set(key, items);
        if (danmakuCache.size > 80) danmakuCache.delete(danmakuCache.keys().next().value);
        danmakuPending.delete(key);
        return items;
      }).catch(() => {
        danmakuPending.delete(key);
        return [];
      });
    } else if (typeof bridge.danmaku === 'function') {
      const items = normalizeDanmaku(parse(bridge.danmaku(cid))) || [];
      danmakuCache.set(key, items);
      return Promise.resolve(items);
    } else {
      return Promise.resolve([]);
    }
    danmakuPending.set(key, request);
    return request;
  }

  function prefetchDanmaku(cid) {
    if (cid) fetchDanmaku(cid);
  }

  function applyDanmaku(items) {
    danmakuItems = Array.isArray(items) ? items : [];
    danmakuIndex = 0;
    danmakuLastTime = 0;
    danmakuLane = 0;
    if (danmakuLayer) {
      danmakuLayer.innerHTML = '';
      danmakuLayer.style.display = state.settings.danmaku ? 'block' : 'none';
    }
  }

  function loadDanmaku(cid) {
    applyDanmakuStyle();
    const token = ++danmakuToken;
    const numeric = Number(cid) || 0;
    applyDanmaku([]);
    if (!numeric) return;
    const cached = danmakuCache.get(String(numeric));
    if (cached) {
      applyDanmaku(cached);
      return;
    }
    fetchDanmaku(numeric).then((items) => {
      if (token !== danmakuToken) return;
      applyDanmaku(items);
    });
  }

  function spawnDanmaku(row) {
    if (!danmakuLayer || !state.settings.danmaku) return;
    const item = document.createElement('span');
    item.className = 'danmaku-item';
    const color = row.color && row.color !== 0xffffff ? '#' + Number(row.color).toString(16).padStart(6, '0') : '#ffffff';
    item.textContent = row.text;
    item.style.color = color;
    const density = state.settings.danmakuDensity !== false;
    const laneCount = density ? 8 : 5;
    const laneStep = density ? 9 : 13;
    item.style.top = `${8 + (danmakuLane % laneCount) * laneStep}%`;
    const speed = danmakuSettingNumber(state.settings.danmakuSpeed, 100, 50, 200);
    const baseSeconds = Math.max(7, Math.min(14, 8 + String(row.text).length * 0.08));
    item.__dmBaseSeconds = baseSeconds;
    item.style.animationDuration = `${(baseSeconds * 100 / speed).toFixed(2)}s`;
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

  function currentItem() {
    return state.playlist[state.currentIndex] || null;
  }

  /* ---------- live danmaku (Bilibili websocket) ---------- */
  function livePacket(op, body) {
    const payload = new TextEncoder().encode(body || '');
    const buffer = new ArrayBuffer(16 + payload.length);
    const view = new DataView(buffer);
    view.setInt32(0, 16 + payload.length);
    view.setInt16(4, 16);
    view.setInt16(6, 1);
    view.setInt32(8, op);
    view.setInt32(12, 1);
    new Uint8Array(buffer, 16).set(payload);
    return buffer;
  }

  async function inflateZlib(buffer) {
    if (!window.DecompressionStream) return null;
    try {
      const stream = new Blob([buffer]).stream().pipeThrough(new DecompressionStream('deflate'));
      return await new Response(stream).arrayBuffer();
    } catch (error) {
      log('live danmaku inflate failed ' + error);
      return null;
    }
  }

  function spawnLiveDanmaku(text, colorValue) {
    if (!text) return;
    const now = Date.now();
    const last = liveSeen.get(text) || 0;
    if (now - last < 2500) return;
    liveSeen.set(text, now);
    if (liveSeen.size > 200) {
      for (const [key, at] of liveSeen) {
        if (now - at > 60000) liveSeen.delete(key);
      }
    }
    spawnDanmaku({ t: video.currentTime || 0, text, color: Number(colorValue || 0xffffff), mode: 1 });
  }

  function handleLivePacket(payload, op, version) {
    if (op === 5) {
      const text = new TextDecoder().decode(payload);
      let message = null;
      try { message = JSON.parse(text); } catch (_) { return; }
      if (!message || !message.cmd) return;
      if (message.cmd.indexOf('DANMU_MSG') === 0 && Array.isArray(message.info)) {
        const body = String(message.info[1] || '');
        const color = message.info[0] && message.info[0][3] ? message.info[0][3] : 0xffffff;
        spawnLiveDanmaku(body, color);
        liveDanmakuCount += 1;
        setLiveDanmakuBadge(`直播弹幕 ${liveDanmakuCount}`, 'on');
      }
      return;
    }
    if (op === 3) {
      try {
        const popularity = new DataView(payload).getInt32(0);
        const badge = $('#livePopularity');
        if (badge) badge.textContent = countText(popularity);
      } catch (_) {}
    }
  }

  async function parseLivePackets(buffer) {
    const view = new DataView(buffer);
    let offset = 0;
    while (offset + 16 <= buffer.byteLength) {
      const length = view.getInt32(offset);
      if (length < 16 || offset + length > buffer.byteLength) break;
      const headerLength = view.getInt16(offset + 4);
      const version = view.getInt16(offset + 6);
      const op = view.getInt32(offset + 8);
      const payload = buffer.slice(offset + headerLength, offset + length);
      if (op === 5 && version === 2) {
        const inflated = await inflateZlib(payload);
        if (inflated) await parseLivePackets(inflated);
      } else {
        handleLivePacket(payload, op, version);
      }
      offset += length;
    }
  }

  function closeLiveDanmaku() {
    clearInterval(liveHeartbeat);
    liveHeartbeat = null;
    clearTimeout(liveRetryTimer);
    liveRetryTimer = null;
    liveRoomId = 0;
    if (liveSocket) {
      const socket = liveSocket;
      liveSocket = null;
      try { socket.close(); } catch (_) {}
    }
  }

  function setLiveDanmakuBadge(text, mode) {
    const badge = $('#liveDmBadge');
    if (!badge) return;
    if (!text) { badge.hidden = true; return; }
    badge.hidden = false;
    badge.textContent = text;
    badge.classList.toggle('on', mode === 'on');
    badge.classList.toggle('off', mode === 'off');
  }

  function connectLiveDanmaku(roomId) {
    closeLiveDanmaku();
    if (!roomId || !window.WebSocket) return;
    liveRoomId = roomId;
    liveDanmakuCount = 0;
    let info = { ok: false };
    if (typeof bridge.liveDanmuInfo === 'function') {
      info = call('liveDanmuInfo', roomId);
    }
    const host = info.ok && info.host ? info.host : 'broadcastlv.chat.bilibili.com';
    const port = info.ok && info.wssPort ? Number(info.wssPort) : 443;
    const token = info.ok ? String(info.token || '') : '';
    const url = `wss://${host}:${port}/sub`;
    setLiveDanmakuBadge(info.ok ? '弹幕连接中…' : '弹幕受限 · 未取到 token', info.ok ? '' : 'off');
    let socket;
    try {
      socket = new WebSocket(url);
    } catch (error) {
      log('live danmaku socket failed ' + error);
      setLiveDanmakuBadge('直播弹幕连接失败', 'off');
      return;
    }
    socket.binaryType = 'arraybuffer';
    liveSocket = socket;
    const connectTimer = setTimeout(() => {
      if (socket.readyState === 1) return;
      setLiveDanmakuBadge('直播弹幕超时 · 稍后重试', 'off');
    }, 12000);
    socket.addEventListener('open', () => {
      clearTimeout(connectTimer);
      if (liveSocket !== socket) return;
      const auth = JSON.stringify({
        uid: 0, roomid: roomId, protover: 2, platform: 'web', type: 2, key: token,
      });
      try { socket.send(livePacket(7, auth)); } catch (_) {}
      setLiveDanmakuBadge('直播弹幕已连接', 'on');
      clearInterval(liveHeartbeat);
      liveHeartbeat = setInterval(() => {
        if (liveSocket === socket && socket.readyState === 1) {
          try { socket.send(livePacket(2, '[object Object]')); } catch (_) {}
        }
      }, 30000);
    });
    socket.addEventListener('message', (event) => {
      if (event.data instanceof ArrayBuffer) {
        parseLivePackets(event.data).catch((error) => log('live danmaku parse ' + error));
      }
    });
    socket.addEventListener('close', () => {
      clearTimeout(connectTimer);
      clearInterval(liveHeartbeat);
      liveHeartbeat = null;
      if (liveSocket !== socket) return;
      liveSocket = null;
      if (mediaLive && liveRoomId === roomId) {
        setLiveDanmakuBadge('直播弹幕断开 · 重连中', 'off');
        clearTimeout(liveRetryTimer);
        liveRetryTimer = setTimeout(() => connectLiveDanmaku(roomId), 5000);
      }
    });
    socket.addEventListener('error', () => {
      log('live danmaku socket error');
      setLiveDanmakuBadge('直播弹幕连接失败 · 需登录', 'off');
    });
  }

  function destroyHls() {
    if (hls) {
      try { hls.destroy(); } catch (_) {}
      hls = null;
    }
  }

  function clearVideo() {
    mediaLoadToken += 1;
    stopPosterDanmaku();
    removePromotedPreview();
    destroyHls();
    destroyDash();
    closeLiveDanmaku();
    pendingMediaStart = null;
    mediaItem = null;
    mediaBackup = '';
    mediaTriedBackup = false;
    mediaLive = false;
    danmakuItems = [];
    danmakuIndex = 0;
    danmakuLastTime = 0;
    state.availableQualities = [];
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
    const map = { '4K': 120, '1080P60': 116, '1080P+': 112, '1080P': 80, '720P60': 74, '720P': 64, '480P': 32, '360P': 16, '仅音频': 16 };
    return map[value] || 64;
  }

  function qualityLabelFromQn(qn) {
    const map = { 120: '4K', 116: '1080P60', 112: '1080P+', 80: '1080P', 74: '720P60', 64: '720P', 32: '480P', 16: '360P' };
    return map[Number(qn)] || '';
  }

  function showQualityFallback(requested, actual) {
    if (!requested || !actual || requested === actual) return;
    if (host.showPlayerNotice) {
      host.showPlayerNotice('画质', `${requested} 不可用 · 已切到 ${actual}`, 3200);
    }
  }

  const qualityOptionsCache = new Map();
  const qualityOptionsPending = new Set();
  const qualityOptionsTimers = new Map();
  const QUALITY_OPTIONS_TTL = 10 * 60 * 1000;
  const QUALITY_OPTIONS_MAX = 40;
  const QUALITY_RANK = {
    '4K': 120, '1080P60': 116, '1080P+': 112, '1080P': 80,
    '720P60': 74, '720P': 64, '480P': 32, '360P': 16,
  };

  function qualityOptionsKey(item) {
    if (!item || item.live || item.epId || !item.bvid) return '';
    return `${item.bvid}:${item.cid || 0}`;
  }

  function mergeQualityLabels() {
    const seen = new Set();
    const labels = [];
    for (let group = 0; group < arguments.length; group += 1) {
      const list = arguments[group];
      if (!Array.isArray(list)) continue;
      list.forEach((label) => {
        const value = String(label || '');
        if (!value || seen.has(value)) return;
        seen.add(value);
        labels.push(value);
      });
    }
    return labels.sort((a, b) => (QUALITY_RANK[b] || 0) - (QUALITY_RANK[a] || 0));
  }

  function readQualityOptions(item) {
    const key = qualityOptionsKey(item);
    if (!key) return null;
    const cached = qualityOptionsCache.get(key);
    if (!cached) return null;
    if (Date.now() - cached.at >= QUALITY_OPTIONS_TTL) {
      qualityOptionsCache.delete(key);
      return null;
    }
    return cached.labels;
  }

  function cacheQualityOptions(item, labels) {
    const key = qualityOptionsKey(item);
    const merged = mergeQualityLabels(labels);
    if (!key || !merged.length) return;
    qualityOptionsCache.set(key, { labels: merged, at: Date.now() });
    while (qualityOptionsCache.size > QUALITY_OPTIONS_MAX) {
      qualityOptionsCache.delete(qualityOptionsCache.keys().next().value);
    }
  }

  function applyQualityOptions(item, labels) {
    const current = currentItem();
    if (!current || mediaKeyFor(current) !== mediaKeyFor(item)) return;
    state.availableQualities = mergeQualityLabels(labels, state.availableQualities);
    host.updatePlayerLabels();
    if (typeof host.refreshQualityChoices === 'function') host.refreshQualityChoices();
  }

  function requestQualityOptions(item, delay = 0) {
    const key = qualityOptionsKey(item);
    if (!DASH_PLAYBACK || !key || typeof bridge.dash !== 'function') return;
    const cached = readQualityOptions(item);
    if (cached) {
      applyQualityOptions(item, cached);
      return;
    }
    if (qualityOptionsPending.has(key)) {
      if (delay > 0) return;
      const pendingTimer = qualityOptionsTimers.get(key);
      if (!pendingTimer) return;
      clearTimeout(pendingTimer);
      qualityOptionsTimers.delete(key);
      qualityOptionsPending.delete(key);
    }
    qualityOptionsPending.add(key);
    const timer = setTimeout(() => {
      qualityOptionsTimers.delete(key);
      let result = null;
      try {
        result = call('dash', item.bvid, item.cid || 0, 120);
      } catch (_) {
        result = null;
      }
      qualityOptionsPending.delete(key);
      if (!result || !result.ok) return;
      const labels = mergeQualityLabels(
        (Array.isArray(result.video) ? result.video : [])
          .map((track) => qualityLabelFromQn(track && track.qn)),
        Array.isArray(result.available) ? result.available : [],
      );
      if (!labels.length) return;
      const current = currentItem();
      const sameItem = current && mediaKeyFor(current) === mediaKeyFor(item);
      const merged = mergeQualityLabels(labels, sameItem ? state.availableQualities : []);
      cacheQualityOptions(item, merged);
      applyQualityOptions(item, merged);
    }, Math.max(0, Number(delay) || 0));
    qualityOptionsTimers.set(key, timer);
  }

  function setAvailableQualities(tracks) {
    const labels = [];
    (tracks || [])
      .slice()
      .sort((a, b) => Number(b.qn || 0) - Number(a.qn || 0))
      .forEach((track) => {
        const label = qualityLabelFromQn(track && track.qn);
        if (label && !labels.includes(label)) labels.push(label);
      });
    state.availableQualities = mergeQualityLabels(labels, state.availableQualities);
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
    setStatus('连接直播…', 'loading');
    const source = item.liveUrl;
    if (!source) {
      setStatus('直播地址不可用', 'error');
      return;
    }
    connectLiveDanmaku(Number(item.roomId || 0));
    if (NATIVE_MEDIA) {
      video.__nativeLoad({
        videoUrl: source,
        kind: /\.m3u8(\?|$)/i.test(source) ? 'hls' : 'file',
        autoplay: Boolean(autoplay),
      });
      if (autoplay) video.play().catch(() => {});
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

  /* ---------- DASH via MediaSource ---------- */
  function destroyDash() {
    const session = dashState;
    if (!session) return;
    dashState = null;
    session.aborted = true;
    try { if (session.controller) session.controller.abort(); } catch (_) {}
    try {
      if (session.readers) session.readers.forEach((reader) => { try { reader.cancel(); } catch (_) {} });
    } catch (_) {}
    try { URL.revokeObjectURL(session.url); } catch (_) {}
  }

  function dashFallback(item, autoplay, reason) {
    log('dash playback fallback ' + reason);
    destroyDash();
    mediaItem = null;
    setStatus('切换到渐进播放…', 'loading');
    loadVideo(item, autoplay, false);
  }

  function chooseDashTrack(tracks, targetQn) {
    const codecRank = (track) => {
      const id = Number(track && track.codecid) || 0;
      if (id === 7) return 0;
      if (id === 12) return 1;
      if (id === 13) return 2;
      return 3;
    };
    let best = null;
    tracks.forEach((track) => {
      const qn = Number(track.qn || 0);
      if (qn > targetQn) return;
      if (!best) {
        best = track;
        return;
      }
      const bestQn = Number(best.qn || 0);
      if (qn > bestQn || (qn === bestQn && codecRank(track) < codecRank(best))) {
        best = track;
      }
    });
    return best || tracks.slice().sort((a, b) => codecRank(a) - codecRank(b))[0] || null;
  }

  function appendDashBuffer(buffer, data, state) {
    return new Promise((resolve, reject) => {
      let attempts = 0;
      const append = () => {
        if (state.aborted) { resolve(); return; }
        if (buffer.updating) {
          buffer.addEventListener('updateend', append, { once: true });
          return;
        }
        try {
          buffer.appendBuffer(data);
        } catch (error) {
          if (error && error.name === 'QuotaExceededError' && attempts < 3) {
            attempts += 1;
            let removed = false;
            try {
              if (buffer.buffered.length) {
                const start = buffer.buffered.start(0);
                const target = Math.min(
                  buffer.buffered.end(buffer.buffered.length - 1),
                  Math.max(start + 0.5, (Number(video.currentTime) || 0) - 2),
                );
                if (target > start) {
                  buffer.remove(start, target);
                  removed = true;
                }
              }
            } catch (_) {}
            if (removed) buffer.addEventListener('updateend', append, { once: true });
            else setTimeout(append, 220);
            return;
          }
          reject(error);
          return;
        }
        buffer.addEventListener('updateend', () => resolve(), { once: true });
      };
      append();
    });
  }

  async function appendDashChunk(buffer, value, state) {
    const step = 256 * 1024;
    for (let offset = 0; offset < value.length; offset += step) {
      if (state.aborted) return;
      await appendDashBuffer(buffer, value.subarray(offset, Math.min(value.length, offset + step)), state);
    }
  }

  function dashBufferedAhead(buffer) {
    try {
      if (!buffer.buffered.length || !Number.isFinite(video.currentTime)) return 0;
      return buffer.buffered.end(buffer.buffered.length - 1) - video.currentTime;
    } catch (_) {
      return 0;
    }
  }

  function waitDashResume(session) {
    return new Promise((resolve) => {
      if (session.aborted) { resolve(); return; }
      let settled = false;
      const finish = () => {
        if (settled) return;
        settled = true;
        video.removeEventListener('play', finish);
        if (session.controller) {
          try { session.controller.signal.removeEventListener('abort', finish); } catch (_) {}
        }
        resolve();
      };
      video.addEventListener('play', finish, { once: true });
      if (session.controller) {
        session.controller.signal.addEventListener('abort', finish, { once: true });
      }
    });
  }

  async function waitDashRoom(buffer, session) {
    const maxAhead = 12;
    while (!session.aborted) {
      const ahead = dashBufferedAhead(buffer);
      if (ahead < maxAhead) return;
      if (video.paused && !promotedPreview) {
        await waitDashResume(session);
        continue;
      }
      try {
        if (buffer.buffered.length && buffer.buffered.start(0) > 0
          && buffer.buffered.start(0) < video.currentTime - 25 && !buffer.updating) {
          buffer.remove(0, Math.max(0, video.currentTime - 15));
        }
      } catch (_) {}
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
  }

  async function fetchDashBlock(url, offset, size, session) {
    const end = offset + size - 1;
    const response = await fetch(url, {
      cache: 'no-store',
      headers: { Range: 'bytes=' + offset + '-' + end },
      signal: session.controller ? session.controller.signal : undefined
    });
    if (!response.ok) throw new Error('HTTP ' + response.status);
    const contentRange = response.headers.get('Content-Range') || '';
    const totalMatch = contentRange.match(/\/(\d+)$/);
    const total = totalMatch ? Number(totalMatch[1]) : 0;
    const value = new Uint8Array(await response.arrayBuffer());
    return { status: response.status, total, value, size };
  }

  async function pumpDash(urls, buffer, type, item, autoplay, session) {
    const firstSize = 384 * 1024;
    const chunkSize = 1024 * 1024;
    let lastError = 'DASH 地址不可用';
    for (const url of urls.filter(Boolean)) {
      try {
        let offset = 0;
        let total = 0;
        let appended = 0;
        let pending = fetchDashBlock(url, 0, firstSize, session)
          .then((value) => ({ value }), (error) => ({ error }));
        while (!session.aborted) {
          if (!promotedPreview && video.paused && dashBufferedAhead(buffer) >= 6) {
            await waitDashResume(session);
            continue;
          }
          const current = await pending;
          pending = null;
          if (current.error) throw current.error;
          const block = current.value;
          const value = block.value;
          if (!value.length) break;
          if (block.total) total = block.total;
          addNetBytes(value.length);
          const nextOffset = offset + value.length;
          if (block.status === 200 && !total) {
            offset = nextOffset;
            await appendDashChunk(buffer, value, session);
            appended += value.length;
            if (!session.started && type === 'video' && appended > 350 * 1024) {
              session.started = true;
              startDashPlayback(autoplay);
            }
            break;
          }
          const canContinue = total === 0 || nextOffset < total;
          const canPrefetch = canContinue
            && value.length >= Math.min(block.size, 64 * 1024)
            && !(video.paused && dashBufferedAhead(buffer) >= 10);
          const lookahead = canPrefetch
            ? fetchDashBlock(url, nextOffset, chunkSize, session)
              .then((next) => ({ value: next }), (error) => ({ error }))
            : null;
          await appendDashChunk(buffer, value, session);
          appended += value.length;
          offset = nextOffset;
          if (!session.started && type === 'video' && appended > 350 * 1024) {
            session.started = true;
            startDashPlayback(autoplay);
          }
          await waitDashRoom(buffer, session);
          if (total > 0 && offset >= total) break;
          if (value.length < Math.min(block.size, 64 * 1024)) break;
          if (!lookahead) break;
          pending = lookahead;
        }
        if (!session.aborted && type === 'video') startDashPlayback(autoplay);
        if (!session.aborted) log('dash ' + type + ' ended bytes=' + appended);
        return;
      } catch (error) {
        if (session.aborted) return;
        lastError = String(error);
        log('dash ' + type + ' source failed ' + lastError);
      }
    }
    if (!session.aborted) dashFallback(item, autoplay, lastError);
  }

  function startDashPlayback(autoplay) {
    playerVideo.classList.add('has-video');
    playerVideo.classList.remove('video-loading');
    setStatus('', '');
    if (!autoplay) return;
    video.play().then(() => {
      state.playing = true;
      host.setPlayIcon(true);
      host.updatePlaylistDock();
    }).catch(() => {});
  }

  function loadDash(item, dash, autoplay) {
    destroyDash();
    destroyHls();
    const target = qualityQn(state.settings.quality);
    const MediaSourceCtor = window.MediaSource || window.ManagedMediaSource;
    if (!MediaSourceCtor) {
      mediaItem = null;
      loadVideo(item, autoplay, false);
      return;
    }
    const supportsMime = (mime) => {
      try {
        if (typeof MediaSourceCtor.isTypeSupported === 'function') return MediaSourceCtor.isTypeSupported(mime);
        if (window.MediaSource && typeof window.MediaSource.isTypeSupported === 'function') return window.MediaSource.isTypeSupported(mime);
      } catch (_) {}
      return true;
    };
    const trackMime = (track, audio) => `${track.mime || (audio ? 'audio/mp4' : 'video/mp4')}; codecs="${track.codecs || (audio ? 'mp4a.40.2' : 'avc1.640033')}"`;
    const videoCandidates = dash.video.filter((track) => supportsMime(trackMime(track, false)));
    const audioCandidates = dash.audio.filter((track) => supportsMime(trackMime(track, true)));
    const videoTrack = chooseDashTrack(videoCandidates.length ? videoCandidates : dash.video, target);
    const audioTrack = (audioCandidates.length ? audioCandidates : dash.audio)
      .slice()
      .sort((a, b) => Number(b.bandwidth || 0) - Number(a.bandwidth || 0))[0];
    if (!videoTrack || !audioTrack) {
      mediaItem = null;
      loadVideo(item, autoplay, false);
      return;
    }
    setAvailableQualities(videoCandidates.length ? videoCandidates : [videoTrack]);
    cacheQualityOptions(item, state.availableQualities);
    const requestedQuality = state.settings.quality;
    state.streamInfo = {
      videoBitrate: Number(videoTrack.bandwidth) || 0,
      audioBitrate: Number(audioTrack.bandwidth) || 0,
      sourceWidth: Number(videoTrack.width) || 0,
      sourceHeight: Number(videoTrack.height) || 0,
      frameRate: Number(videoTrack.frameRate) || 0,
      netBps: 0,
      netAt: 0,
      direct: true,
    };
    resetNetMeter();
    const videoMime = trackMime(videoTrack, false);
    const audioMime = trackMime(audioTrack, true);
    log(`dash pick v=${videoTrack.qn || 0}/${videoTrack.codecid || 0} ${videoMime}`
      + ` a=${audioTrack.qn || 0}/${audioTrack.codecid || 0} ${audioMime}`);
    if (!supportsMime(videoMime) || !supportsMime(audioMime)) {
      mediaItem = null;
      loadVideo(item, autoplay, false);
      return;
    }
    mediaItem = item;
    mediaLive = false;
    mediaBackup = '';
    loadDanmaku(item.cid);
    if (NATIVE_MEDIA && typeof video.__nativeLoad === 'function') {
      playerVideo.classList.remove('video-error');
      playerVideo.classList.add('has-video');
      playerVideo.classList.remove('video-loading');
      setStatus('', '');
      const actualTrackQuality = qualityLabelFromQn(videoTrack.qn) || dash.qualityLabel;
      if (actualTrackQuality) {
        window.O11A1Host.state.settings.quality = actualTrackQuality;
        host.updatePlayerLabels();
        showQualityFallback(requestedQuality, actualTrackQuality);
      }
      const keep = Number(video.currentTime) || 0;
      video.__nativeLoad({
        videoUrl: videoTrack.remote || videoTrack.url,
        audioUrl: audioTrack.remote || audioTrack.url,
        backupUrl: videoTrack.backupRemote || '',
        backupAudioUrl: audioTrack.backupRemote || '',
        kind: 'dash',
        promoted: Boolean(promotedPreview),
        durationMs: Number(dash.durationMs) || 0,
        startMs: keep * 1000,
        autoplay: Boolean(autoplay),
        muted: Boolean(promotedPreview),
      });
      if (autoplay) {
        video.play().then(() => {
          state.playing = true;
          host.setPlayIcon(true);
          host.updatePlaylistDock();
        }).catch(() => {});
      }
      return;
    }
    const mediaSource = new MediaSourceCtor();
    const url = URL.createObjectURL(mediaSource);
    const managed = !window.MediaSource && Boolean(window.ManagedMediaSource);
    if (managed) {
      try { video.disableRemotePlayback = true; } catch (_) {}
    }
    const session = {
      aborted: false,
      started: false,
      readers: [],
      controller: typeof AbortController === 'function' ? new AbortController() : null,
      url,
      mediaSource,
      videoBuffer: null,
      audioBuffer: null,
    };
    dashState = session;
    playerVideo.classList.remove('video-error');
    playerVideo.classList.add('has-video', 'video-loading');
    setStatus('DASH 缓冲中…', 'loading');
    const actualTrackQuality = qualityLabelFromQn(videoTrack.qn) || dash.qualityLabel;
    if (actualTrackQuality) {
      window.O11A1Host.state.settings.quality = actualTrackQuality;
      host.updatePlayerLabels();
      showQualityFallback(requestedQuality, actualTrackQuality);
    }
    mediaSource.addEventListener('sourceopen', () => {
      if (session.aborted) return;
      try {
        const videoBuffer = mediaSource.addSourceBuffer(videoMime);
        const audioBuffer = mediaSource.addSourceBuffer(audioMime);
        videoBuffer.mode = 'segments';
        audioBuffer.mode = 'segments';
        session.videoBuffer = videoBuffer;
        session.audioBuffer = audioBuffer;
        pumpDash([videoTrack.url, videoTrack.backup], videoBuffer, 'video', item, autoplay, session);
        pumpDash([audioTrack.url, audioTrack.backup], audioBuffer, 'audio', item, autoplay, session);
      } catch (error) {
        dashFallback(item, autoplay, String(error));
      }
    }, { once: true });
    video.addEventListener('loadedmetadata', () => {
      if (autoplay && video.paused) {
        video.play().then(() => {
          state.playing = true;
          host.setPlayIcon(true);
          host.updatePlaylistDock();
        }).catch(() => {});
      }
    }, { once: true });
    try { video.pause(); } catch (_) {}
    video.src = url;
    video.load();
  }

  const playInfoCache = new Map();
  const PLAY_INFO_TTL = 4 * 60 * 1000;

  function playInfoKey(item, qn) {
    return `${item.bvid || item.epId || ''}:${qn}`;
  }

  function playQualityCached(item, qn) {
    const key = playInfoKey(item, qn);
    const hit = playInfoCache.get(key);
    if (hit && Date.now() - hit.at < PLAY_INFO_TTL) return hit.value;
    const value = call('playQuality', item.bvid, item.cid || 0, qn);
    if (value && value.ok) {
      if (value.cid) item.cid = value.cid;
      playInfoCache.set(key, { at: Date.now(), value });
    }
    return value;
  }

  function bridgeAsync(name, ...args) {
    const fn = bridge && bridge[name];
    if (typeof fn !== 'function') return Promise.resolve(null);
    return fn.apply(bridge, args).then((raw) => {
      try { return JSON.parse(raw); } catch (_) { return null; }
    }).catch(() => null);
  }

  function bridgeCallMaybe(name, asyncName, ...args) {
    if (bridge && typeof bridge[asyncName] === 'function') {
      return bridgeAsync(asyncName, ...args);
    }
    const fn = bridge && bridge[name];
    if (typeof fn !== 'function') return Promise.resolve(null);
    try {
      const raw = fn.apply(bridge, args);
      return Promise.resolve(typeof raw === 'string' ? JSON.parse(raw) : raw);
    } catch (_) {
      return Promise.resolve(null);
    }
  }

  async function playQualityCachedAsync(item, qn) {
    const key = playInfoKey(item, qn);
    const hit = playInfoCache.get(key);
    if (hit && Date.now() - hit.at < PLAY_INFO_TTL) return hit.value;
    const value = await bridgeCallMaybe('playQuality', 'playQualityAsync', item.bvid, item.cid || 0, qn)
      || { ok: false, error: 'network' };
    if (value && value.ok) {
      if (value.cid) item.cid = value.cid;
      playInfoCache.set(key, { at: Date.now(), value });
    }
    return value;
  }

  const danmakuCidPending = new Set();

  function prefetchPlayerDanmaku(item) {
    if (!item || item.live) return;
    const key = mediaKeyFor(item);
    if (item.cid) {
      prefetchDanmaku(item.cid);
      return;
    }
    if (!item.bvid || danmakuCidPending.has(key)) return;
    danmakuCidPending.add(key);
    bridgeCallMaybe('videoInfo', 'videoInfoAsync', item.bvid).then((info) => {
      danmakuCidPending.delete(key);
      if (!info || !info.ok || !info.cid) return;
      item.cid = info.cid;
      const entry = currentItem();
      if (entry && mediaKeyFor(entry) === key) entry.cid = info.cid;
      prefetchDanmaku(info.cid);
      if (state.playerOpen && currentItem() && mediaKeyFor(currentItem()) === key) {
        loadDanmaku(info.cid);
        if (!promotedPreview) startPosterDanmaku();
      }
    }).catch(() => {
      danmakuCidPending.delete(key);
    });
  }

  function prefetchPlayInfo(item) {
    if (!item || item.live || !item.bvid || item.epId) return;
    const qn = qualityQn(state.settings.quality);
    const key = playInfoKey(item, qn);
    if (playInfoCache.has(key)) return;
    const value = call('playQuality', item.bvid, item.cid || 0, qn);
    if (value && value.ok) {
      if (value.cid) item.cid = value.cid;
      playInfoCache.set(key, { at: Date.now(), value });
    }
  }

  function applyPendingMediaStart() {
    const pending = pendingMediaStart;
    if (!pending) return;
    if (!mediaItem || mediaKeyFor(mediaItem) !== pending.key) {
      pendingMediaStart = null;
      return;
    }
    if (!video.readyState) return;
    const duration = Number(video.duration);
    const target = Number.isFinite(duration) && duration > 0
      ? Math.min(pending.time, Math.max(0, duration - 0.5))
      : pending.time;
    if (!(target > 0.25)) {
      pendingMediaStart = null;
      return;
    }
    try {
      if (Math.abs(video.currentTime - target) > 0.3) video.currentTime = target;
      if (Number.isFinite(duration) && duration > 0) {
        state.progress = target / duration * 100;
        host.setProgress(state.progress);
      }
      pendingMediaStart = null;
    } catch (_) {}
  }

  async function loadVideo(item, autoplay, allowDash = true) {
    state.streamInfo = { videoBitrate: 0, audioBitrate: 0, sourceWidth: 0, sourceHeight: 0, frameRate: 0, netBps: 0, netAt: 0, direct: false };
    state.availableQualities = [];
    resetNetMeter();
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
    const loadToken = ++mediaLoadToken;
    if (item.cid) loadDanmaku(item.cid);
    prefetchPlayerDanmaku(item);
    if (!promotedPreview) startPosterDanmaku();
    const key = item.epId ? `ep:${item.epId}` : `bvid:${item.bvid}`;
    if (mediaItem && mediaKeyFor(mediaItem) === key && video.src) {
      applyPendingMediaStart();
      if (autoplay) video.play().catch(() => {});
      return;
    }
    const cachedQualityOptions = readQualityOptions(item);
    if (cachedQualityOptions) state.availableQualities = cachedQualityOptions;
    destroyDash();
    destroyHls();
    try { video.pause(); } catch (_) {}
    mediaLive = false;
    if (player) player.classList.remove('live-player');
    mediaItem = item;
    video.muted = Boolean(promotedPreview);
    mediaTriedBackup = false;
    mediaBackup = '';
    state.duration = 0;
    playerVideo.classList.remove('has-video', 'video-error');
    playerVideo.classList.add('video-loading');
    setStatus('加载中…', 'loading');
    let dashTried = false;
    if (DASH_PLAYBACK && allowDash && qualityQn(state.settings.quality) > 64
      && item.bvid && !item.epId
      && (typeof bridge.dash === 'function' || typeof bridge.dashAsync === 'function')) {
      dashTried = true;
      const dash = await bridgeCallMaybe('dash', 'dashAsync', item.bvid, item.cid || 0, 120) || {};
      if (loadToken !== mediaLoadToken) return;
      const dashMax = dash.ok && Array.isArray(dash.video)
        ? dash.video.reduce((max, track) => Math.max(max, Number(track.qn) || 0), 0)
        : 0;
      if (dash.ok && dashMax > 64 && Array.isArray(dash.video) && Array.isArray(dash.audio) && dash.video.length && dash.audio.length) {
        if (dash.cid) {
          item.cid = dash.cid;
          const entry = currentItem();
          if (entry) entry.cid = dash.cid;
        }
        loadDash(item, dash, autoplay);
        return;
      }
      log('dash unavailable ' + (dash.error || ''));
    }
    const requestedQuality = state.settings.quality;
    const qn = qualityQn(state.settings.quality);
    const result = item.epId
      ? await bridgeCallMaybe('playPgc', 'playPgcAsync', item.epId, item.bvid || '', item.cid || 0, qn)
      : await playQualityCachedAsync(item, qn);
    if (loadToken !== mediaLoadToken) return;
    if (!result || !result.ok) {
      if (!dashTried && DASH_PLAYBACK && allowDash && item.bvid && !item.epId
        && (typeof bridge.dash === 'function' || typeof bridge.dashAsync === 'function')) {
        const dash = await bridgeCallMaybe('dash', 'dashAsync', item.bvid, item.cid || 0, 120) || {};
        if (loadToken !== mediaLoadToken) return;
        if (dash.ok && Array.isArray(dash.video) && Array.isArray(dash.audio) && dash.video.length && dash.audio.length) {
          if (dash.cid) {
            item.cid = dash.cid;
            const entry = currentItem();
            if (entry) entry.cid = dash.cid;
          }
          loadDash(item, dash, autoplay);
          return;
        }
      }
      setStatus('加载失败 · 点击重试', 'error');
      log('play error ' + (item.bvid || item.epId || '') + ' ' + ((result && result.error) || ''));
      if (host.showPlayerNotice) host.showPlayerNotice('画质', `${requestedQuality} 加载失败`, 3200);
      return;
    }
    if (result.cid) {
      item.cid = result.cid;
      const entry = currentItem();
      if (entry) entry.cid = result.cid;
    }
    const availableLabels = Array.isArray(result.available)
      ? result.available.filter(Boolean)
      : [];
    state.availableQualities = mergeQualityLabels(
      availableLabels,
      result.qualityLabel ? [result.qualityLabel] : [],
      state.availableQualities,
    );
    if (result.qualityLabel) {
      state.settings.quality = result.qualityLabel;
      host.updatePlayerLabels();
      showQualityFallback(requestedQuality, result.qualityLabel);
    }
    loadDanmaku(result.cid || item.cid);
    mediaBackup = NATIVE_MEDIA
      ? String(result.backupRemote || '')
      : String(result.backup || '');
    const progressiveUrl = NATIVE_MEDIA
      ? (String(result.remote || '') || result.url)
      : result.url;
    log('progressive ' + (item.bvid || item.epId || '') + ' q=' + (result.qualityLabel || '')
      + ' ' + String(progressiveUrl).split('?')[0]);
    video.src = progressiveUrl;
    video.load();
    playerVideo.classList.add('has-video');
    if (autoplay) {
      video.play().then(() => {
        state.playing = true;
        host.setPlayIcon(true);
        host.updatePlaylistDock();
      }).catch(() => {
        if (promotedPreview) return;
        state.playing = false;
        host.setPlayIcon(false);
        setStatus('点击播放', 'error');
      });
    }
  }

  video.addEventListener('loadedmetadata', () => {
    state.duration = Number.isFinite(video.duration) ? video.duration : 0;
    applyPendingMediaStart();
    if (state.duration > 0 && !mediaLive) host.setProgress(video.currentTime / state.duration * 100);
    playerVideo.classList.remove('video-loading');
  });
  video.addEventListener('canplay', () => {
    applyPendingMediaStart();
    maybeFinishPromotedPreview();
  });
  video.addEventListener('playing', () => {
    applyPendingMediaStart();
    stopPosterDanmaku();
    maybeFinishPromotedPreview();
  });
  video.addEventListener('seeked', maybeFinishPromotedPreview);
  video.addEventListener('timeupdate', () => {
    if (promotedPreview) {
      maybeFinishPromotedPreview();
      return;
    }
    stopPosterDanmaku();
    if (mediaLive) return;
    if (!video.duration || !Number.isFinite(video.duration)) return;
    host.setProgress(video.currentTime / video.duration * 100);
    tickDanmaku(video.currentTime);
  });
  video.addEventListener('play', () => {
    if (playerVideo) playerVideo.style.backgroundImage = '';
    state.playing = true;
    host.setPlayIcon(true);
    host.updatePlaylistDock();
    playerVideo.classList.remove('video-loading');
    if (danmakuLayer) danmakuLayer.classList.remove('paused');
    if (status) status.textContent = '';
  });
  video.addEventListener('pause', () => {
    if (promotedPreview) return;
    state.playing = false;
    host.setPlayIcon(false);
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
    if (NATIVE_MEDIA && mediaItem && mediaItem.bvid && !mediaItem.live) {
      const fallbackKey = mediaKeyFor(mediaItem);
      if (!nativeFallbackKeys.has(fallbackKey)) {
        nativeFallbackKeys.add(fallbackKey);
        const item = mediaItem;
        mediaItem = null;
        mediaTriedBackup = true;
        try { video.removeAttribute('src'); } catch (_) {}
        log('native media failed, retry progressive ' + item.bvid);
        loadVideo(item, true, false);
        return;
      }
    }
    if (promotedPreview) {
      playerVideo.classList.remove('video-loading', 'video-error');
      if (status) status.textContent = '';
      log('promoted preview kept after player media error ' + (mediaItem ? mediaItem.bvid || mediaItem.roomId : ''));
      return;
    }
    setStatus(mediaLive ? '直播加载失败 · 点击重试' : '播放失败 · 点击重试', 'error');
    log('video element error ' + (mediaItem ? mediaItem.bvid || mediaItem.roomId : ''));
  });
  video.addEventListener('ended', () => {
    if (mediaLive || promotedPreview) return;
    if (state.settings.loop === '循环') {
      video.currentTime = 0;
      video.play().catch(() => {});
    } else if (state.settings.loop === '下一分P' || state.settings.loop === '继续') {
      host.stepTrack(1);
    } else {
      state.playing = false;
      host.setPlayIcon(false);
    }
  });
  if (status) status.addEventListener('click', () => {
    if (!playerVideo.classList.contains('video-error') || !mediaItem) return;
    const item = mediaItem;
    clearVideo();
    loadVideo(item, true);
  });

  window.O11A1Media = {
    isCurrentReady() {
      const item = currentItem();
      if (!item || !mediaItem || !video.src || video.readyState < 2) return false;
      const key = item.epId ? `ep:${item.epId}` : item.roomId ? `live:${item.roomId}` : `bvid:${item.bvid}`;
      return mediaItem.key === key;
    },
    onOpen() {
      applyDanmakuStyle();
      loadVideo(currentItem(), Boolean(state.playing));
    },
    onMinimize() {
    },
    onStop() {
      clearVideo();
    },
    togglePlay() {
      if (promotedPreview) {
        const promoted = promotedPreview.video;
        if (promoted.paused) promoted.play().catch(() => {});
        else promoted.pause();
        return true;
      }
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
      if (promotedPreview) {
        const promoted = promotedPreview.video;
        if (!promoted.duration || !Number.isFinite(promoted.duration)) return;
        promoted.currentTime = promoted.duration * Math.max(0, Math.min(100, percent)) / 100;
        return;
      }
      if (mediaLive || !video.duration || !Number.isFinite(video.duration)) return;
      video.currentTime = video.duration * Math.max(0, Math.min(100, percent)) / 100;
    },
    onSettings() {
      applyDanmakuStyle();
      const rate = parseFloat(state.settings.speed || '1');
      if (promotedPreview) {
        promotedPreview.video.playbackRate = Number.isFinite(rate) && rate > 0 ? rate : 1;
        promotedPreview.video.loop = state.settings.loop === '循环';
      }
      if (!video.src) return;
      video.playbackRate = Number.isFinite(rate) && rate > 0 ? rate : 1;
      video.loop = state.settings.loop === '循环';
    },
    onTrackChange() {
      removePromotedPreview();
      loadVideo(currentItem(), true);
    },
    onRateHold(rate) {
      if (promotedPreview) promotedPreview.video.playbackRate = rate;
      if (!video.src || mediaLive) return;
      video.playbackRate = rate;
    },
    onRateHoldEnd() {
      const rate = parseFloat(state.settings.speed || '1');
      const restored = Number.isFinite(rate) && rate > 0 ? rate : 1;
      if (promotedPreview) promotedPreview.video.playbackRate = restored;
      if (!video.src || mediaLive) return;
      video.playbackRate = restored;
    },
    onQualityChange(value) {
      if (!mediaItem || mediaItem.live) return;
      if (!promotedPreview && !video.src) return;
      state.settings.quality = value;
      host.updatePlayerLabels();
      const keepTime = promotedPreview ? promotedPreview.video.currentTime : (video.currentTime || 0);
      const keepDuration = promotedPreview ? promotedPreview.video.duration : video.duration;
      if (DASH_PLAYBACK && qualityQn(value) > 64 && typeof bridge.dash === 'function' && !mediaItem.epId) {
        const item = mediaItem;
        if (keepTime > 0.5) {
          pendingMediaStart = { key: mediaKeyFor(item), time: keepTime };
          if (Number.isFinite(keepDuration) && keepDuration > 0) {
            state.progress = keepTime / keepDuration * 100;
            host.setProgress(state.progress);
          }
        }
        mediaItem = null;
        loadVideo(item, true);
        return;
      }
      if (typeof bridge.playQuality !== 'function') return;
      const qn = qualityQn(value);
      const wasPlaying = promotedPreview ? !promotedPreview.video.paused : !video.paused;
      const result = mediaItem.epId
        ? call('playPgc', mediaItem.epId, mediaItem.bvid || '', mediaItem.cid || 0, qn)
        : call('playQuality', mediaItem.bvid, mediaItem.cid || 0, qn);
      if (!result.ok || !result.url) {
        if (host.showPlayerNotice) host.showPlayerNotice('画质', `${value} 切换失败`, 2600);
        return;
      }
      mediaBackup = NATIVE_MEDIA
        ? String(result.backupRemote || '')
        : String(result.backup || '');
      mediaTriedBackup = false;
      if (result.qualityLabel) {
        state.settings.quality = result.qualityLabel;
        state.availableQualities = mergeQualityLabels(
          state.availableQualities,
          Array.isArray(result.available) ? result.available : [],
          [result.qualityLabel],
        );
        host.updatePlayerLabels();
        if (typeof host.refreshQualityChoices === 'function') host.refreshQualityChoices();
        showQualityFallback(value, result.qualityLabel);
      }
      playerVideo.classList.add('video-loading');
      setStatus('切换画质…', 'loading');
      destroyDash();
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
      video.src = NATIVE_MEDIA
        ? (String(result.remote || '') || result.url)
        : result.url;
      video.load();
    },
  };

  /* ---------- video detail cache ---------- */
  const VIDEO_INFO_CACHE_MAX = 24;
  const VIDEO_INFO_TTL = 10 * 60 * 1000;
  const videoInfoCache = new Map();
  let detailRenderedKey = '';
  let videoPrefetchToken = 0;
  let videoPrefetchTimers = [];

  function videoCacheKey(item) {
    if (!item) return '';
    return String(item.bvid || item.aid || item.id || '');
  }

  function cacheVideoInfo(item, info) {
    const key = videoCacheKey(item);
    if (!key || !info || !info.ok) return;
    videoInfoCache.delete(key);
    videoInfoCache.set(key, { info, at: Date.now() });
    while (videoInfoCache.size > VIDEO_INFO_CACHE_MAX) {
      videoInfoCache.delete(videoInfoCache.keys().next().value);
    }
  }

  function readVideoInfo(item, options = {}) {
    const key = videoCacheKey(item);
    if (!key) return null;
    const cached = videoInfoCache.get(key);
    if (cached) {
      if (Date.now() - cached.at >= VIDEO_INFO_TTL) {
        videoInfoCache.delete(key);
      } else {
        videoInfoCache.delete(key);
        videoInfoCache.set(key, cached);
        return cached.info;
      }
    }
    if (options.cachedOnly) return null;
    if (!item.bvid || typeof bridge.videoInfo !== 'function') return null;
    let info = null;
    try {
      info = call('videoInfo', item.bvid);
    } catch (error) {
      info = { ok: false, error: String(error) };
    }
    cacheVideoInfo(item, info);
    return info;
  }

  function patchVideoInfoCache(item, patch) {
    const key = videoCacheKey(item);
    if (!key) return;
    const entry = videoInfoCache.get(key);
    if (!entry || !entry.info) return;
    patch(entry.info);
    if (detailRenderedKey === key) detailRenderedKey = '';
  }

  function hasVideoDetail() {
    const item = currentItem();
    const key = videoCacheKey(item);
    if (!key) return false;
    if (videoInfoCache.has(key)) return true;
    return detailRenderedKey === key
      && Boolean(document.querySelector('#videoDetailBody .vd-title'));
  }

  /* ---------- comments ---------- */
  const COMMENT_PREFETCH = 360;
  const COMMENT_LOAD_DELAY = 40;
  const COMMENT_COOLDOWN = 450;
  let commentSort = 2;
  let commentAid = 0;
  let commentRequestAid = 0;
  let commentRequestSort = 2;
  let commentLoadedAid = 0;
  let commentLoadedSort = 0;
  let commentLoaded = false;
  let commentPage = 0;
  let commentHasMore = false;
  let commentLoading = false;
  let commentMoreError = false;
  let commentToken = 0;
  let commentLastLoadAt = 0;
  let commentItems = [];
  let commentScrollRaf = 0;
  let commentNote = '';
  const COMMENT_CACHE_MAX = 200;
  const COMMENT_CACHE_TTL = 10 * 60 * 1000;
  const commentCache = new Map();
  let commentPrefetchKey = '';

  function commentCacheKey(aid, sort) {
    return `${Number(aid) || 0}:${Number(sort) || 0}`;
  }

  function trimCommentCache() {
    while (commentCache.size > COMMENT_CACHE_MAX) {
      commentCache.delete(commentCache.keys().next().value);
    }
  }

  function cacheComments(aid, sort, items, page, hasMore, note) {
    if (!aid) return;
    const key = commentCacheKey(aid, sort);
    commentCache.delete(key);
    commentCache.set(key, {
      aid: Number(aid),
      sort: Number(sort) || 0,
      items: Array.isArray(items) ? items.slice() : [],
      page: Number(page) || 1,
      hasMore: Boolean(hasMore),
      note: note || '',
      at: Date.now(),
    });
    trimCommentCache();
  }

  function readCachedComments(aid, sort) {
    const key = commentCacheKey(aid, sort);
    const entry = commentCache.get(key);
    if (!entry) return null;
    if (Date.now() - entry.at >= COMMENT_CACHE_TTL) {
      commentCache.delete(key);
      return null;
    }
    commentCache.delete(key);
    commentCache.set(key, entry);
    return entry;
  }

  function prefetchComments(item) {
    const aid = Number(item && item.aid ? item.aid : 0);
    if (!aid || typeof bridge.comments !== 'function') return;
    const sort = commentSort;
    if (commentLoading && commentAid === aid && commentRequestSort === sort) return;
    const key = commentCacheKey(aid, sort);
    if (commentCache.has(key) || commentPrefetchKey === key) return;
    commentPrefetchKey = key;
    let result = null;
    try {
      result = call('comments', aid, 1, sort);
    } catch (_) {
      result = null;
    }
    if (commentPrefetchKey !== key) return;
    commentPrefetchKey = '';
    if (!result || !result.ok || !Array.isArray(result.items)) return;
    let items = result.items;
    let actualSort = sort;
    let note = '';
    if (sort === 0 && items.length === 0 && !result.count) {
      let fallback = null;
      try {
        fallback = call('comments', aid, 1, 2);
      } catch (_) {
        fallback = null;
      }
      if (fallback && fallback.ok && Array.isArray(fallback.items) && fallback.items.length) {
        items = fallback.items;
        actualSort = 2;
        result = fallback;
        note = '最新评论需要登录后查看，当前显示最热评论';
      }
    }
    const entry = {
      aid,
      sort: actualSort,
      items: items.slice(),
      page: 1,
      hasMore: result.hasMore === true,
      note,
      at: Date.now(),
    };
    commentCache.set(commentCacheKey(aid, actualSort), entry);
    if (actualSort !== sort) commentCache.set(commentCacheKey(aid, sort), entry);
    trimCommentCache();
  }

  function prefetchCurrentVideo() {
    const item = currentItem();
    const token = (videoPrefetchToken += 1);
    videoPrefetchTimers.forEach((timer) => clearTimeout(timer));
    videoPrefetchTimers = [];
    if (!item) return;
    const key = videoCacheKey(item);
    const alive = () => token === videoPrefetchToken
      && (state.playerOpen || state.miniVisible)
      && videoCacheKey(currentItem()) === key;
    videoPrefetchTimers.push(setTimeout(() => {
      if (alive()) readVideoInfo(item);
    }, 120));
    videoPrefetchTimers.push(setTimeout(() => {
      if (alive()) prefetchComments(item);
    }, 400));
  }

  /* ---------- background preload / page cache ---------- */
  const PRELOAD_PAGE_TTL = 5 * 60 * 1000;
  const PRELOAD_PAGE_MAX = 32;
  const PRELOAD_IDLE_GAP = 10 * 1000;
  const PRELOAD_PLAYBACK_GAP = 20 * 1000;
  const PRELOAD_BACKOFF_CAP = 30 * 1000;
  const PRELOAD_PARK_MS = 5 * 60 * 1000;
  const preloadPages = new Map();
  const preloadState = {
    timer: null,
    round: 0,
    failures: {},
    parked: {},
  };

  function preloadPageKey(kind, args) {
    return `${kind}:${args.map((value) => String(value)).join(':')}`;
  }

  function readPreloadPage(kind, args) {
    const key = preloadPageKey(kind, args);
    const entry = preloadPages.get(key);
    if (!entry) return null;
    if (Date.now() - entry.at >= PRELOAD_PAGE_TTL) {
      preloadPages.delete(key);
      return null;
    }
    preloadPages.delete(key);
    preloadPages.set(key, entry);
    return entry.data;
  }

  function writePreloadPage(kind, args, data) {
    if (!data || data.ok === false) return;
    const key = preloadPageKey(kind, args);
    preloadPages.delete(key);
    preloadPages.set(key, { at: Date.now(), data });
    while (preloadPages.size > PRELOAD_PAGE_MAX) {
      preloadPages.delete(preloadPages.keys().next().value);
    }
  }

  function preloadGate() {
    if (!state.playerOpen) return { allowed: true, gap: PRELOAD_IDLE_GAP };
    const el = $('#realVideo');
    if (!el || el.readyState < 3 || playerVideo.classList.contains('video-loading')) {
      return { allowed: false, gap: 2000 };
    }
    let ahead = 0;
    try {
      if (el.buffered.length) {
        ahead = el.buffered.end(el.buffered.length - 1) - el.currentTime;
      }
    } catch (_) {}
    if (ahead < 2) return { allowed: false, gap: 2000 };
    return { allowed: true, gap: PRELOAD_PLAYBACK_GAP };
  }

  function preloadRoundWork(kind) {
    if (kind === 'comments') {
      const item = currentItem();
      if (item && item.aid) prefetchComments(item);
      return true;
    }
    if (kind === 'live') {
      const result = feedResult('live', [1]);
      if (!result.ok) return false;
      writePreloadPage('feed-live', [1], result);
      return true;
    }
    if (kind === 'pgc') {
      const type = moduleSeasonTypes['番剧'] ? moduleSeasonTypes['番剧'][0] : 1;
      const result = feedResult('bangumi', [1, type]);
      if (!result.ok) return false;
      writePreloadPage('feed-bangumi', [1, type], result);
      return true;
    }
    if (kind === 'dynamic') {
      if (!state.loggedIn) return true;
      const result = call('dynamicFeed', 1, 'all');
      if (!result.ok) return false;
      writePreloadPage('dynamic', ['all', 1], result);
      return true;
    }
    if (kind === 'messages') {
      if (!state.loggedIn) return true;
      const result = call('messages', 1, 'reply');
      if (!result.ok) return false;
      writePreloadPage('messages', ['reply', 1], result);
      return true;
    }
    return true;
  }

  function schedulePreload(delay) {
    clearTimeout(preloadState.timer);
    preloadState.timer = setTimeout(runPreloadRound, Math.max(600, Number(delay) || 0));
  }

  function preloadBusy() {
    if (document.hidden || previewRow) return true;
    if (Date.now() - lastFeedScrollAt < 600) return true;
    return [feeds.home, feeds.module, feeds.search, feeds.up].some((feed) => (
      feed && feed.__feedWindow && (feed.__feedWindow.touchActive || feedIsBusy(feed))
    ));
  }

  function runPreloadRound() {
    preloadState.timer = null;
    if (preloadBusy()) {
      schedulePreload(2000);
      return;
    }
    const gate = preloadGate();
    if (!gate.allowed) {
      schedulePreload(gate.gap);
      return;
    }
    const kinds = ['comments', 'live', 'pgc', 'dynamic', 'messages'];
    const kind = kinds[preloadState.round % kinds.length];
    preloadState.round += 1;
    if ((preloadState.parked[kind] || 0) > Date.now()) {
      schedulePreload(gate.gap);
      return;
    }
    let ok = true;
    try {
      ok = preloadRoundWork(kind);
    } catch (_) {
      ok = false;
    }
    if (ok) {
      preloadState.failures[kind] = 0;
    } else {
      const failures = (preloadState.failures[kind] || 0) + 1;
      preloadState.failures[kind] = failures;
      if (failures >= 5) {
        preloadState.failures[kind] = 0;
        preloadState.parked[kind] = Date.now() + PRELOAD_PARK_MS;
      }
    }
    const wait = ok ? gate.gap : Math.min(PRELOAD_BACKOFF_CAP, 1000 * (2 ** (preloadState.failures[kind] || 0)));
    schedulePreload(wait);
  }

  if (host) {
    host.clearPreloadCaches = () => {
      preloadPages.clear();
      commentCache.clear();
      videoInfoCache.clear();
      playInfoCache.clear();
      previewUrlCache.clear();
      qualityOptionsCache.clear();
      qualityOptionsPending.clear();
      qualityOptionsTimers.forEach((timer) => clearTimeout(timer));
      qualityOptionsTimers.clear();
    };
    host.ensureQualityOptions = () => requestQualityOptions(currentItem(), 0);
  }

  schedulePreload(1800);

  const COMMENT_HEART = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 20.3 4.6 13a4.7 4.7 0 0 1 6.6-6.6l.8.8.8-.8A4.7 4.7 0 0 1 19.4 13z"/></svg>';
  const COMMENT_EMPTY_ICON = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20 12a8 8 0 0 1-8 8H5l2.2-2.2A8 8 0 1 1 20 12Z"/><path d="M8.5 11.5h7M8.5 14.5h4.5"/></svg>';

  function commentCountLabel(value) {
    const n = Number(value || 0);
    if (n >= 100000000) return `${(n / 100000000).toFixed(1)}亿`;
    if (n >= 10000) return `${(n / 10000).toFixed(1)}万`;
    return String(n);
  }

  function syncCommentSortUI() {
    $$('#commentsSort [data-comment-sort]').forEach((button) => {
      const on = Number(button.dataset.commentSort) === commentSort;
      button.classList.toggle('on', on);
      button.setAttribute('aria-selected', on ? 'true' : 'false');
    });
  }

  function commentAvatarMarkup(row) {
    return row.avatar
      ? `<img class="comment-avatar" src="${attr(row.avatar)}" alt="" referrerpolicy="no-referrer">`
      : '<span class="avatar-ph sm comment-avatar"></span>';
  }

  function commentRow(row, depth = 0, replyCount = 0) {
    const rpid = Number(row.rpid || 0);
    const replies = Array.isArray(row.replies) ? row.replies : [];
    const like = Number(row.like || 0);
    const time = row.time ? timeAgo(row.time) : '';
    return `
      <div class="comment-row${depth ? ' comment-reply' : ''}" data-rpid="${rpid}">
        ${commentAvatarMarkup(row)}
        <div class="comment-text">
          <div class="comment-meta">
            <b>${esc(row.user || '用户')}</b>
            ${time ? `<span>${esc(time)}</span>` : ''}
          </div>
          <p>${esc(row.message || '')}</p>
          <div class="comment-actions">
            <span class="comment-stat">${COMMENT_HEART}<span>${esc(like > 0 ? commentCountLabel(like) : '赞')}</span></span>
            ${replyCount > 0 ? `<button class="comment-reply-toggle" type="button" data-reply-root="${rpid}" data-reply-count="${replyCount}">${esc(commentCountLabel(replyCount))} 条回复</button>` : ''}
          </div>
          ${replies.length ? `<div class="comment-replies">${replies.map((reply) => commentRow(reply, depth + 1)).join('')}</div>` : ''}
        </div>
      </div>`;
  }

  function commentThread(row) {
    const rpid = Number(row.rpid || 0);
    const count = Number(row.rcount || 0);
    return `
      <div class="comment-thread" data-thread="${rpid}">
        ${commentRow(row, 0, count)}
        <div class="comment-replies" data-reply-box="${rpid}" hidden></div>
      </div>`;
  }

  function commentListMarkup(items, note) {
    return `${note ? `<div class="comment-inline-note">${esc(note)}</div>` : ''}${items.map(commentThread).join('')}`;
  }

  function commentSkeletonRows(count) {
    let out = '';
    for (let i = 0; i < count; i += 1) {
      out += `<div class="comment-skeleton-row">
        <span class="comment-skeleton-avatar"></span>
        <span class="comment-skeleton-copy">
          <i style="width:${26 + (i % 3) * 9}%"></i>
          <i style="width:${88 - (i % 4) * 11}%"></i>
          <i style="width:${64 - (i % 3) * 13}%"></i>
        </span>
      </div>`;
    }
    return out;
  }

  function commentSkeletonMarkup(count) {
    return `<div class="comment-skeleton">${commentSkeletonRows(count)}</div>`;
  }

  function commentEmptyMarkup(title, sub, retry) {
    return `<div class="comments-empty">
      ${COMMENT_EMPTY_ICON}
      <b>${esc(title)}</b>
      ${sub ? `<span>${esc(sub)}</span>` : ''}
      ${retry ? '<button class="comments-retry" type="button" data-comments-retry="all">重新加载</button>' : ''}
    </div>`;
  }

  function commentMoreErrorMarkup() {
    return '<div class="comment-load-more"><button type="button" data-comments-retry="more">加载失败，点击重试</button></div>';
  }

  function loadComments(sort, options = {}) {
    const nextSort = typeof sort === 'number' ? sort : commentSort;
    if (nextSort !== commentSort) {
      commentSort = nextSort;
      commentLoaded = false;
    }
    syncCommentSortUI();
    const item = currentItem();
    const aid = item && item.aid ? Number(item.aid) : 0;
    if (!aid) {
      commentToken += 1;
      commentAid = 0;
      commentRequestAid = 0;
      commentLoadedAid = 0;
      commentLoaded = false;
      commentLoadedSort = 0;
      commentPage = 0;
      commentHasMore = false;
      commentLoading = false;
      commentMoreError = false;
      commentItems = [];
      commentNote = '';
      host.commentsBody.innerHTML = commentEmptyMarkup('暂无评论', '当前视频还没有可用的评论数据');
      return false;
    }
    if (!options.force && commentLoaded && aid === commentLoadedAid && commentSort === commentLoadedSort) {
      return false;
    }
    if (!options.force && commentLoading && aid === commentRequestAid && commentSort === commentRequestSort) {
      return false;
    }
    const cached = options.force ? null : readCachedComments(aid, commentSort);
    if (cached) {
      commentToken += 1;
      commentSort = cached.sort;
      commentAid = aid;
      commentRequestAid = aid;
      commentRequestSort = cached.sort;
      commentLoaded = true;
      commentLoadedAid = aid;
      commentLoadedSort = cached.sort;
      commentPage = cached.page;
      commentHasMore = cached.hasMore;
      commentLoading = false;
      commentMoreError = false;
      commentItems = cached.items.slice();
      commentNote = cached.note || '';
      commentLastLoadAt = 0;
      syncCommentSortUI();
      if (!commentItems.length) {
        host.commentsBody.innerHTML = commentEmptyMarkup('还没有评论', '换个排序看看，或者来抢个沙发');
      } else {
        host.commentsBody.innerHTML = commentListMarkup(commentItems, commentNote);
      }
      host.commentsBody.scrollTop = 0;
      requestAnimationFrame(() => {
        if (commentLoadedAid !== aid || commentLoadedSort !== commentSort || !commentHasMore) return;
        if (host.commentsBody.scrollHeight <= host.commentsBody.clientHeight + 120) {
          requestCommentPage(true);
        }
      });
      return false;
    }
    commentToken += 1;
    const token = commentToken;
    commentAid = aid;
    commentRequestAid = aid;
    commentRequestSort = commentSort;
    commentLoaded = false;
    commentLoadedAid = 0;
    commentLoadedSort = 0;
    commentPage = 0;
    commentHasMore = true;
    commentMoreError = false;
    commentItems = [];
    commentNote = '';
    commentLoading = true;
    commentLastLoadAt = Date.now();
    host.commentsBody.innerHTML = commentSkeletonMarkup(7);
    host.commentsBody.scrollTop = 0;
    setTimeout(() => {
      if (token !== commentToken) return;
      let result;
      try {
        result = typeof bridge.comments === 'function'
          ? call('comments', aid, 1, commentSort)
          : { ok: false, error: '不支持评论' };
      } catch (error) {
        result = { ok: false, error: String(error) };
      }
      if (token !== commentToken) return;
      if (!result || !result.ok || !Array.isArray(result.items)) {
        commentLoading = false;
        commentLoaded = false;
        host.commentsBody.innerHTML = commentEmptyMarkup(
          '评论加载失败',
          result && result.error ? String(result.error) : '请检查网络后重试',
          true,
        );
        return;
      }
      let items = result.items;
      let note = '';
      if (commentSort === 0 && items.length === 0 && !result.count) {
        const fallback = typeof bridge.comments === 'function'
          ? call('comments', aid, 1, 2)
          : null;
        if (token !== commentToken) return;
        if (fallback && fallback.ok && Array.isArray(fallback.items) && fallback.items.length) {
          commentSort = 2;
          commentRequestSort = 2;
          syncCommentSortUI();
          items = fallback.items;
          result = fallback;
          note = '最新评论需要登录后查看，当前显示最热评论';
        }
      }
      commentLoading = false;
      commentLoaded = true;
      commentLoadedAid = aid;
      commentLoadedSort = commentSort;
      commentPage = 1;
      commentItems = items.slice();
      commentHasMore = items.length > 0 && result.hasMore === true;
      commentMoreError = false;
      commentLastLoadAt = 0;
      commentNote = note;
      cacheComments(commentLoadedAid, commentLoadedSort, commentItems, commentPage, commentHasMore, commentNote);
      if (!items.length) {
        host.commentsBody.innerHTML = commentEmptyMarkup('还没有评论', '换个排序看看，或者来抢个沙发');
        return;
      }
      host.commentsBody.innerHTML = commentListMarkup(items, note);
      host.commentsBody.scrollTop = 0;
      requestAnimationFrame(() => {
        if (token !== commentToken) return;
        if (commentHasMore && host.commentsBody.scrollHeight <= host.commentsBody.clientHeight + 120) {
          requestCommentPage(true);
        }
      });
    }, options.opening ? 360 : COMMENT_LOAD_DELAY);
    return true;
  }

  function requestCommentPage(force) {
    if (commentLoading || !commentLoaded || !commentHasMore || !commentAid || commentPage < 1) return false;
    if (commentMoreError && !force) return false;
    if (!force && Date.now() - commentLastLoadAt < COMMENT_COOLDOWN) return false;
    const token = commentToken;
    const page = commentPage + 1;
    $$('.comment-load-more', host.commentsBody).forEach((el) => el.remove());
    commentMoreError = false;
    const skeleton = document.createElement('div');
    skeleton.className = 'comment-skeleton comment-skeleton-more';
    skeleton.innerHTML = commentSkeletonRows(3);
    host.commentsBody.appendChild(skeleton);
    commentLoading = true;
    commentRequestAid = commentAid;
    commentRequestSort = commentSort;
    commentLastLoadAt = Date.now();
    setTimeout(() => {
      if (token !== commentToken) {
        skeleton.remove();
        return;
      }
      let result;
      try {
        result = typeof bridge.comments === 'function'
          ? call('comments', commentAid, page, commentSort)
          : { ok: false, error: '不支持评论' };
      } catch (error) {
        result = { ok: false, error: String(error) };
      }
      if (token !== commentToken) {
        skeleton.remove();
        return;
      }
      commentLoading = false;
      if (!result || !result.ok || !Array.isArray(result.items)) {
        skeleton.remove();
        commentMoreError = true;
        host.commentsBody.insertAdjacentHTML('beforeend', commentMoreErrorMarkup());
        return;
      }
      const items = result.items;
      if (!items.length) {
        skeleton.remove();
        commentHasMore = false;
        return;
      }
      const chunk = document.createElement('div');
      chunk.className = 'comment-chunk';
      chunk.innerHTML = items.map(commentThread).join('');
      skeleton.replaceWith(chunk);
      commentItems.push(...items);
      commentPage = page;
      commentHasMore = result.hasMore === true;
      commentMoreError = false;
      commentLastLoadAt = Date.now();
      cacheComments(commentLoadedAid, commentLoadedSort, commentItems, commentPage, commentHasMore, commentNote);
    }, COMMENT_LOAD_DELAY);
    return true;
  }

  function maybeLoadComments() {
    if (commentLoading || commentMoreError || !commentLoaded || !commentHasMore) return;
    const body = host.commentsBody;
    if (body.scrollTop + body.clientHeight < body.scrollHeight - COMMENT_PREFETCH) return;
    requestCommentPage();
  }

  host.commentsBody.addEventListener('scroll', () => {
    if (commentScrollRaf) return;
    commentScrollRaf = requestAnimationFrame(() => {
      commentScrollRaf = 0;
      maybeLoadComments();
    });
  }, { passive: true });

  function toggleReplies(button) {
    const root = Number(button.dataset.replyRoot || 0);
    const box = host.commentsBody.querySelector(`[data-reply-box="${root}"]`);
    if (!box || !root) return;
    const count = Number(button.dataset.replyCount || 0);
    if (!box.hidden) {
      box.hidden = true;
      button.textContent = `${commentCountLabel(count)} 条回复`;
      return;
    }
    box.hidden = false;
    button.textContent = '收起回复';
    if (box.dataset.loaded === '1' || box.dataset.loading === '1') return;
    box.dataset.loading = '1';
    box.innerHTML = commentSkeletonMarkup(2);
    const token = commentToken;
    const aid = commentAid;
    setTimeout(() => {
      if (token !== commentToken || box.dataset.loading !== '1') return;
      const result = typeof bridge.commentsReplies === 'function'
        ? call('commentsReplies', aid, root, 1)
        : { ok: false, error: '当前版本不支持楼中楼' };
      box.dataset.loading = '';
      if (!result.ok || !Array.isArray(result.items)) {
        box.innerHTML = `<div class="comment-inline-note">${esc(result.error || '回复加载失败')}</div>`;
        return;
      }
      box.dataset.loaded = '1';
      box.innerHTML = result.items.map((reply) => commentRow(reply, 1)).join('')
        || '<div class="comment-inline-note">暂无回复</div>';
    }, COMMENT_LOAD_DELAY);
  }

  const commentsSortBar = $('#commentsSort');
  if (commentsSortBar) {
    commentsSortBar.addEventListener('click', (event) => {
      const button = event.target.closest('[data-comment-sort]');
      if (!button) return;
      const sort = Number(button.dataset.commentSort);
      if (sort === commentSort) return;
      commentSort = sort;
      syncCommentSortUI();
      loadComments(sort);
    });
  }

  host.commentsBody.addEventListener('click', (event) => {
    const retry = event.target.closest('[data-comments-retry]');
    if (retry) {
      event.preventDefault();
      if (retry.dataset.commentsRetry === 'more') requestCommentPage(true);
      else loadComments(commentSort, { force: true });
      return;
    }
    const button = event.target.closest('[data-reply-root]');
    if (!button) return;
    event.preventDefault();
    toggleReplies(button);
  });

  /* ---------- video detail ---------- */
  function detailDate(seconds) {
    const value = Number(seconds || 0);
    if (!value) return '';
    const date = new Date(value * 1000);
    const pad = (n) => String(n).padStart(2, '0');
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
  }

  function renderVideoDetail() {
    const body = document.getElementById('videoDetailBody');
    if (!body) return false;
    const item = currentItem();
    if (!item) {
      body.innerHTML = '<div class="comments-empty"><b>没有可显示的视频</b><span>先从视频流打开一个视频。</span></div>';
      detailRenderedKey = '';
      return false;
    }
    const key = videoCacheKey(item);
    if (key && detailRenderedKey === key && body.querySelector('.vd-title')) return true;
    const detail = readVideoInfo(item);
    const info = detail && detail.ok ? detail : {};
    const title = info.title || item.title || '视频';
    const pic = info.pic || item.pic || '';
    const duration = info.duration || item.duration || '';
    const desc = info.desc || item.desc || '暂无简介';
    const owner = info.owner || item.owner || 'UP 主';
    const ownerFace = info.ownerFace || item.ownerFace || '';
    const mid = Number(info.mid || item.mid || 0);
    const bvid = info.bvid || item.bvid || '';
    const aid = Number(info.aid || item.aid || 0);
    const stat = info.stat || {};
    const view = Number(stat.view || item.view || 0);
    const danmaku = Number(stat.danmaku || 0);
    const like = Number(stat.like || 0);
    const favorite = Number(stat.favorite || 0);
    const date = detailDate(info.pubdate || item.pubdate || 0);
    const authorItem = Object.assign({}, item, {
      owner,
      ownerFace,
      mid,
      bvid,
      aid,
      title,
      pic,
      duration,
      desc,
    });
    const longDesc = desc.length > 90;
    body.innerHTML = `
      <div class="vd-hero">
        ${pic ? `<img src="${attr(pic)}" alt="" referrerpolicy="no-referrer">` : ''}
        ${duration ? `<span class="vd-duration">${esc(duration)}</span>` : ''}
      </div>
      <h2 class="vd-title">${esc(title)}</h2>
      <div class="vd-meta">
        ${date ? `<span>${esc(date)}</span>` : ''}
        ${bvid ? `<span>${esc(bvid)}</span>` : ''}
        ${duration ? `<span>${esc(duration)}</span>` : ''}
      </div>
      <button class="vd-author" type="button" data-detail-author>
        ${ownerFace ? `<img class="vd-avatar" src="${attr(ownerFace)}" alt="" referrerpolicy="no-referrer">` : '<span class="avatar-ph sm vd-avatar"></span>'}
        <span class="vd-author-copy">
          <b>${esc(owner)}</b>
          <small>${mid ? `UID ${mid}` : 'UP 主'} · 点击进入主页</small>
        </span>
        <span class="vd-author-go">主页 <svg viewBox="0 0 24 24" aria-hidden="true"><path d="m9 6 6 6-6 6"/></svg></span>
      </button>
      <div class="vd-stat-row">
        <span class="vd-stat"><b>${esc(countText(view))}</b><small>播放</small></span>
        <span class="vd-stat"><b>${esc(countText(danmaku))}</b><small>弹幕</small></span>
        <span class="vd-stat"><b>${esc(countText(like))}</b><small>点赞</small></span>
        <span class="vd-stat"><b>${esc(countText(favorite))}</b><small>收藏</small></span>
      </div>
      <p class="vd-desc${longDesc ? '' : ' expanded'}" id="vdDesc">${esc(desc)}</p>
      ${longDesc ? '<button class="vd-desc-toggle" type="button" data-vd-desc-toggle>展开简介</button>' : ''}`;
    const author = body.querySelector('[data-detail-author]');
    if (author) {
      author.addEventListener('click', (event) => {
        event.preventDefault();
        event.stopPropagation();
        if (host.openUpFromDetail) host.openUpFromDetail(authorItem);
      });
    }
    const descEl = body.querySelector('#vdDesc');
    const descToggle = body.querySelector('[data-vd-desc-toggle]');
    if (descEl && descToggle) {
      descToggle.addEventListener('click', () => {
        const expanded = descEl.classList.toggle('expanded');
        descToggle.textContent = expanded ? '收起简介' : '展开简介';
      });
    }
    detailRenderedKey = key;
    return true;
  }

  /* ---------- account ---------- */
  function renderAccount() {
    const card = $('.my-account-card');
    if (card) card.classList.remove('is-loading');
    const avatar = $('#myAvatar');
    const name = $('#myName');
    const meta = $('#myMeta');
    const action = $('#myAccountAction');
    const loggedIn = Boolean(accountInfo && accountInfo.loggedIn);
    if (avatar) {
      avatar.innerHTML = '';
      avatar.style.backgroundImage = loggedIn && accountInfo.face ? `url("${accountInfo.face}")` : '';
      avatar.textContent = loggedIn && !accountInfo.face ? (accountInfo.name || 'B').slice(0, 1) : (loggedIn ? '' : 'B');
    }
    if (loggedIn) {
      if (name) name.textContent = accountInfo.name || 'B 站用户';
      if (meta) {
        const bits = [`UID ${accountInfo.mid || ''}`, `Lv${accountInfo.level || 0}`];
        if (accountInfo.follower) bits.push(`${countText(accountInfo.follower)} 粉丝`);
        if (accountInfo.following) bits.push(`${countText(accountInfo.following)} 关注`);
        if (accountInfo.coins != null) bits.push(`${accountInfo.coins} 硬币`);
        meta.textContent = bits.join(' · ');
      }
      if (action) {
        action.hidden = false;
        action.textContent = accountInfo.vip ? (accountInfo.vipLabel || '大会员') : '账户';
        action.classList.toggle('on', Boolean(accountInfo.vip));
      }
    } else {
      if (name) name.textContent = '未登录';
      if (meta) meta.textContent = '登录 B 站账号，同步收藏 / 历史 / 动态';
      if (action) {
        action.hidden = false;
        action.textContent = '登录';
        action.classList.remove('on');
      }
    }
    if (host && typeof host.setUserIdentity === 'function') {
      host.setUserIdentity(
        loggedIn ? (accountInfo.face || '') : '',
        loggedIn ? (accountInfo.name || '') : ''
      );
    }
  }

  function loadAccount(immediate) {
    if (typeof bridge.account !== 'function') {
      renderAccount();
      return;
    }
    if (!immediate) {
      if (accountInfo && accountInfo.loggedIn && Date.now() - accountFetchedAt < 30000) {
        renderAccount();
        return;
      }
      deferLoading('account', showAccountSkeleton, () => loadAccount(true));
      return;
    }
    const result = call('account');
    accountFetchedAt = Date.now();
    accountInfo = result && result.ok ? result : {
      loggedIn: false,
      name: '',
      face: '',
      mid: 0,
      level: 0,
      vip: false,
    };
    renderAccount();
    if (accountInfo.loggedIn && !state.loggedIn) {
      state.loggedIn = true;
      host.save();
      host.app.classList.remove('auth-gate');
      if (state.page === 'login') {
        host.showPage('home');
        loadHome(1);
      }
    }
  }

  function openAccountSheet() {
    const info = accountInfo || {};
    host.openSheet('账户', info.loggedIn ? 'B 站账号 · 实时信息' : '未登录 · B 站登录后同步', (body) => {
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
      host.actionRow(body, 'B 站登录', info.loggedIn ? '已登录' : '去登录', () => {
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

  function loadDynamic(page, append, immediate) {
    if (!state.loggedIn) {
      renderEmpty($('#dynamicFeed'), '登录后查看动态', '登录后同步关注动态。', '去登录', () => host.showPage('login'));
      return true;
    }
    if (typeof bridge.dynamicFeed !== 'function') {
      renderEmpty($('#dynamicFeed'), '当前版本不支持动态', '');
      return true;
    }
    if (!append && !immediate) {
      deferLoading('dynamic', () => showDynamicSkeleton(4), () => loadDynamic(1, false, true));
      return true;
    }
    if (append && !immediate) {
      deferLoading('dynamic-more', appendDynamicSkeleton, () => loadDynamic(page || 1, true, true));
      return true;
    }
    const filter = ['all', 'video', 'image'][Math.max(0, Number(state.dynamicFilterIndex) || 0) % 3];
    const pageNo = page || 1;
    let result = !append ? readPreloadPage('dynamic', [filter, pageNo]) : null;
    if (!result) {
      result = call('dynamicFeed', pageNo, filter);
      if (result.ok) writePreloadPage('dynamic', [filter, pageNo], result);
    }
    clearMoreSkeletons($('#dynamicFeed'));
    if (!result.ok) {
      renderEmpty($('#dynamicFeed'), result.needLogin ? '登录后查看动态' : '动态加载失败', result.needLogin ? '登录后同步关注动态。' : (result.error || ''), result.needLogin ? '去登录' : '重试', result.needLogin ? () => host.showPage('login') : () => loadDynamic(1, false));
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

  function loadMessages(page, append, immediate) {
    if (!state.loggedIn) {
      renderEmpty($('#messageFeed'), '登录后查看消息', '登录后同步回复、@ 和点赞。', '去登录', () => host.showPage('login'));
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
    if (!append && !immediate) {
      deferLoading('messages', () => showMessageSkeleton(5), () => loadMessages(1, false, true));
      return true;
    }
    if (append && !immediate) {
      deferLoading('messages-more', appendMessageSkeleton, () => loadMessages(page || 1, true, true));
      return true;
    }
    const filter = ['reply', 'at', 'like'][index];
    const pageNo = page || 1;
    let result = !append ? readPreloadPage('messages', [filter, pageNo]) : null;
    if (!result) {
      result = call('messages', pageNo, filter);
      if (result.ok) writePreloadPage('messages', [filter, pageNo], result);
    }
    clearMoreSkeletons($('#messageFeed'));
    if (!result.ok) {
      renderEmpty($('#messageFeed'), result.needLogin ? '登录后查看消息' : '消息加载失败', result.needLogin ? '登录后同步回复、@ 和点赞。' : (result.error || ''), result.needLogin ? '去登录' : '重试', result.needLogin ? () => host.showPage('login') : () => loadMessages(1, false));
      return true;
    }
    renderMessages(result.items || [], Boolean(append));
    more.messages = result.hasMore !== false;
    const label = $('#messageFilter');
    if (label) label.textContent = `${messageFilterNames[index]} ⌄`;
    return true;
  }

  /* ---------- player info / actions ---------- */
  function renderPlayerInfoSheet(item, detail) {
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
      if (typeof detail.liked === 'boolean') state.liked = detail.liked;
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

  function playerInfo() {
    const item = currentItem();
    if (!item) {
      host.openSheet('信息', '当前没有播放项', (body) => {
        host.actionRow(body, '返回', '', () => host.closeSheet());
      });
      return;
    }
    const cached = readVideoInfo(item, { cachedOnly: true });
    if (cached) {
      renderPlayerInfoSheet(item, cached);
      return;
    }
    host.openSheet('信息', '正在加载视频信息…', (body) => {
      body.innerHTML = sheetSkeletonMarkup(6);
    });
    requestAnimationFrame(() => {
      setTimeout(() => {
        const sheet = document.getElementById('psheet');
        if (!sheet || !sheet.classList.contains('open')) return;
        const detail = readVideoInfo(item) || { ok: false };
        renderPlayerInfoSheet(item, detail);
      }, 36);
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
    patchVideoInfoCache(item, (info) => {
      info.faved = next;
      if (info.stat) info.stat.favorite = Math.max(0, Number(info.stat.favorite || 0) + (next ? 1 : -1));
    });
    host.save();
    return next ? '已收藏' : '已取消';
  }

  function likeCurrent() {
    const item = currentItem();
    if (!item || !item.aid || typeof bridge.like !== 'function') return '无视频';
    const next = !state.liked;
    const result = call('like', item.aid, next);
    if (!result.ok) return result.needLogin ? '请先登录' : (result.error || '点赞失败');
    state.liked = next;
    patchVideoInfoCache(item, (info) => {
      info.liked = next;
      if (info.stat) info.stat.like = Math.max(0, Number(info.stat.like || 0) + (next ? 1 : -1));
    });
    host.save();
    return next ? '已点赞' : '已取消';
  }

  function coinCurrent() {
    const item = currentItem();
    if (!item || !item.aid || typeof bridge.coin !== 'function') return '无视频';
    if (state.coin) return '已投币';
    const result = call('coin', item.aid, 2, false);
    if (!result.ok) return result.needLogin ? '请先登录' : (result.error || '投币失败');
    state.coin = true;
    patchVideoInfoCache(item, (info) => { info.coined = true; });
    host.save();
    return '已投币';
  }

  function followCurrent() {
    const item = currentItem();
    if (!item || !item.mid || typeof bridge.follow !== 'function') {
      const detail = item ? readVideoInfo(item) : null;
      if (detail && detail.ok && detail.mid) item.mid = detail.mid;
    }
    if (!item || !item.mid) return '没有 UP 信息';
    const next = !state.followed;
    const result = call('follow', item.mid, next);
    if (!result.ok) return result.needLogin ? '请先登录' : (result.error || '关注失败');
    state.followed = next;
    patchVideoInfoCache(item, (info) => { info.followed = next; });
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

  const loginNote = $('.login-note');
  if (loginNote) loginNote.innerHTML = '登录后同步收藏 / 历史 / 大会员画质<br>使用 B 站官方短信验证码登录 · v0.4.46';

  const accountAction = $('#myAccountAction');
  if (accountAction) accountAction.addEventListener('click', () => {
    if (!state.loggedIn && !(accountInfo && accountInfo.loggedIn)) {
      host.showPage('login');
      return;
    }
    openAccountSheet();
  });
  const accountCard = $('.my-account-card');
  if (accountCard) accountCard.addEventListener('click', (event) => {
    if (event.target.closest('#myAccountAction')) return;
    if (!state.loggedIn && !(accountInfo && accountInfo.loggedIn)) {
      host.showPage('login');
      return;
    }
    openAccountSheet();
  });

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
      loadModule(1);
    }, 0);
  });

  const appScroll = $('#appScroll');
  if (appScroll) appScroll.addEventListener('scroll', () => {
    if (Date.now() - (window.__o11a1ScrollAdjust || 0) < 160) return;
    if (state.page === 'home') scheduleWindowUpdate(feeds.home);
    else if (state.page === 'module') scheduleWindowUpdate(feeds.module);
    if (appScroll.scrollTop + appScroll.clientHeight < appScroll.scrollHeight - FEED_PREFETCH) return;
    if (state.page === 'dynamic' && more.dynamic && $('#dynamicFeed .dynamic-card:not(.skeleton-card)')) {
      more.dynamic = false;
      pages.dynamic += 1;
      if (loadDynamic(pages.dynamic, true) && $('#dynamicFeed').querySelector('.native-empty')) more.dynamic = false;
    }
    if (state.page === 'messages' && more.messages && $('#messageFeed .message-row:not(.skeleton-message)')) {
      more.messages = false;
      pages.messages += 1;
      if (loadMessages(pages.messages, true) && $('#messageFeed').querySelector('.native-empty')) more.messages = false;
    }
  });

  const upScroller = upScroll;
  if (upScroller) upScroller.addEventListener('scroll', () => {
    if (Date.now() - (window.__o11a1ScrollAdjust || 0) < 160) return;
    if (state.page !== 'up') return;
    scheduleWindowUpdate(feeds.up);
  });

  const searchScroller = $('#searchPanelBody');
  if (searchScroller) searchScroller.addEventListener('scroll', () => {
    if (Date.now() - (window.__o11a1ScrollAdjust || 0) < 160) return;
    if (!state.searchOpen) return;
    scheduleWindowUpdate(feeds.search);
  });

  function trackFeedTouch(scroll, feedFor) {
    if (!scroll) return;
    let touchedFeed = null;
    const down = () => {
      touchedFeed = feedFor();
      setFeedTouch(touchedFeed, true);
    };
    const up = () => {
      if (touchedFeed) setFeedTouch(touchedFeed, false);
      touchedFeed = null;
    };
    scroll.addEventListener('pointerdown', down, { passive: true });
    window.addEventListener('pointerup', up);
    window.addEventListener('pointercancel', up);
  }

  trackFeedTouch(appScroll, () => {
    if (state.page === 'home') return feeds.home;
    if (state.page === 'module') return feeds.module;
    return null;
  });
  trackFeedTouch(upScroller, () => feeds.up);
  trackFeedTouch(searchScroller, () => feeds.search);

  const pageObserver = new MutationObserver(() => {
    if (state.page === 'home') {
      if (!feeds.home.querySelector('.real-row')) loadHome(1);
      else scheduleWindowSettle(feeds.home, 220);
    }
    if (state.page === 'search') {
      if (!feeds.search.querySelector('.real-row')) loadSearch(host.searchInput.value.trim(), 1);
      else scheduleWindowSettle(feeds.search, 220);
    }
    if (state.page === 'module') {
      loadModule(1);
      scheduleWindowSettle(feeds.module, 220);
    }
    if (state.page === 'up') scheduleWindowSettle(feeds.up, 220);
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

  const upFollow = $('#upFollow');
  if (upFollow) upFollow.addEventListener('click', () => {
    const mid = Number(state.upItem && state.upItem.mid ? state.upItem.mid : 0);
    if (!mid) return;
    const result = call('follow', mid, true);
    if (result.ok) {
      upFollow.textContent = '已关注';
      upFollow.classList.add('on');
    } else {
      upFollow.textContent = result.needLogin ? '需登录' : '失败';
    }
  });

  const upSortBar = $('#upSort');
  if (upSortBar) upSortBar.addEventListener('click', (event) => {
    const button = event.target.closest('[data-up-sort]');
    if (!button) return;
    changeUpSort(button.dataset.upSort);
  });

  window.O11A1NativeData = {
    search: (query) => loadSearch(query, 1),
    searchAsync,
    openUpPage,
    renderVideoDetail,
    hasVideoDetail,
    prefetchCurrent: prefetchCurrentVideo,
    onComments: (sort, options) => loadComments(sort, options),
    favorite: favoriteCurrent,
    like: likeCurrent,
    coin: coinCurrent,
    follow: followCurrent,
    copyLink: copyCurrentLink,
    screenshot: screenshotCurrent,
    applyDanmakuStyle,
    ensureQualityOptions: () => requestQualityOptions(currentItem(), 0),
    playerInfo,
    playerPerf,
    openAccount: openAccountSheet,
    get accountInfo() { return accountInfo; },
  };

  /* ---------- search ---------- */
  host.searchInput.addEventListener('input', () => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      loadSearch(host.searchInput.value.trim(), 1);
    }, 320);
  });

  /* ---------- first data load ---------- */
  setTimeout(() => {
    loadAccount();
    if (state.page === 'search') loadSearch(host.searchInput.value.trim(), 1);
    if (state.page === 'module') loadModule(1);
    if (state.page === 'dynamic') loadDynamic(1, false);
    if (state.page === 'messages') loadMessages(1, false);
    if (state.page === 'my') loadAccount();
    if (state.loggedIn) loadHome(1);
  }, 120);
})();

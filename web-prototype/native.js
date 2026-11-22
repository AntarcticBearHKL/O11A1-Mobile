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
  const pages = { dynamic: 1, messages: 1 };
  const windows = {
    home: { page: 0, cursor: '', hasMore: true, loading: false, lastLoadAt: 0, token: 0, query: '' },
    search: { page: 0, cursor: '', hasMore: true, loading: false, lastLoadAt: 0, token: 0, query: '' },
    module: { page: 0, cursor: '', hasMore: true, loading: false, lastLoadAt: 0, token: 0, name: '' },
    up: { page: 0, cursor: '', hasMore: true, loading: false, lastLoadAt: 0, token: 0, name: '' },
  };
  const FEED_PREFETCH = 900;
  const more = { dynamic: true, messages: true };
  let upSort = 'pubdate';
  let upTotal = 0;
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
            <span class="ph-line w80"></span>
            <span class="ph-line w55"></span>
            <span class="ph-line w30"></span>
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
    feed.__nativeItems = [];
    feed.__chunkPages = [];
    feed.__chunkItems = {};
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
    const card = $('#accountCard');
    if (!card) return;
    card.classList.add('is-loading');
    card.innerHTML = `
      <span class="skeleton-avatar lg"></span>
      <span class="account-copy"><span class="skeleton-line w40"></span><span class="skeleton-line w65"></span></span>
      <span class="skeleton-chip"></span>`;
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
    feed.__nativeItems = [];
    feed.__chunkPages = [];
    feed.__chunkItems = {};
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
    const owner = item.owner || '';
    const fresh = item.live ? '直播中' : feedFreshness(item.pubdate);
    const color = item.live ? '#d97862' : feedFreshnessColor(item.pubdate);
    const ownerMarkup = owner
      ? `<span class="meta-owner"><span class="meta-owner-name">${esc(owner)}</span></span>`
      : '';
    const freshMarkup = fresh
      ? `<span class="meta-fresh" style="color:${color}">${esc(fresh)}</span>`
      : '';
    return (ownerMarkup || freshMarkup)
      ? `<span class="real-meta">${ownerMarkup}${freshMarkup}</span>`
      : '';
  }

  function buildRow(item, label, page, index) {
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
        ${pic ? `<img src="${attr(pic)}" alt="" loading="lazy" decoding="async" referrerpolicy="no-referrer">` : ''}
        ${item.live ? '<span class="live-badge">LIVE</span>' : ''}
        ${item.live ? '' : `<span class="dur-ph">${esc(item.duration || (item.seasonId ? '番剧' : '00:00'))}</span>`}
        ${progress ? `<span class="row-progress"><span style="width:${progress}%"></span></span>` : ''}
      </span>
      <span class="row-copy">
        <span class="real-title">${esc(item.title || '视频')}</span>
        ${metaMarkup(item, label)}
      </span>
      <span class="row-swipe-mask" aria-hidden="true" data-action="queue">
        <b class="rsm-label">加入播放列表</b>
        <small class="rsm-hint">左滑加入</small>
      </span>`;
    const image = $('img', row);
    if (image) {
      const reveal = () => image.classList.add('loaded');
      if (image.complete && image.naturalWidth) reveal();
      else image.addEventListener('load', reveal, { once: true });
      image.addEventListener('error', () => image.remove());
    }
    row.addEventListener('click', (event) => {
      if (host.isFeedClickSuppressed && host.isFeedClickSuppressed()) return;
      event.preventDefault();
      event.stopPropagation();
      if (item.live) playLive(item);
      else if (item.seasonId && !item.epId) playSeason(item);
      else playItem(item);
    });
    const wrapper = document.createElement('div');
    wrapper.className = 'feed-item';
    wrapper.dataset.chunk = String(page);
    wrapper.__nativeItem = item;
    wrapper.appendChild(row);
    return wrapper;
  }

  function renderRows(feed, items, label, page) {
    const chunk = page || 1;
    feed.__nativeItems = items.slice();
    feed.__chunkPages = [chunk];
    feed.__chunkItems = { [chunk]: items.slice() };
    const realRows = items.map((item, index) => buildRow(item, label, chunk, index));
    const skeletons = $$(`.feed-skeleton[data-skeleton-page="${chunk}"]`, feed);
    if (skeletons.length) {
      realRows.forEach((row, index) => {
        const skeleton = skeletons[index];
        row.classList.add('feed-reveal');
        setTimeout(() => row.classList.remove('feed-reveal'), 240);
        if (skeleton && skeleton.isConnected) skeleton.replaceWith(row);
        else feed.appendChild(row);
      });
      skeletons.slice(realRows.length).forEach((skeleton) => skeleton.remove());
      return;
    }
    feed.innerHTML = '';
    const fragment = document.createDocumentFragment();
    realRows.forEach((row) => fragment.appendChild(row));
    feed.appendChild(fragment);
  }

  function feedViewport(feed) {
    const scroll = feed === feeds.up
      ? $('.page[data-page="up"]')
      : feed === feeds.search
        ? $('.page[data-page="search"]')
        : $('#appScroll');
    const isActive = (feed === feeds.home && state.page === 'home')
      || (feed === feeds.search && state.page === 'search')
      || (feed === feeds.module && state.page === 'module')
      || (feed === feeds.up && state.page === 'up');
    return { scroll, isActive: Boolean(scroll && isActive) };
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

  function trimChunk(feed, page) {
    const rows = $$(`[data-chunk="${page}"]`, feed);
    if (!rows.length) {
      delete feed.__chunkItems[page];
      return true;
    }
    const { scroll, isActive } = feedViewport(feed);
    if (isActive && scroll) {
      const first = rows[0];
      const last = rows[rows.length - 1];
      const viewportTop = scroll.getBoundingClientRect().top;
      // Never unload a chunk that still overlaps the visible feed area:
      // removing it mid-read is what made the feed jump forward a whole page.
      if (last.getBoundingClientRect().bottom > viewportTop + 4) return false;
      const anchor = topVisibleRow(feed, scroll, rows);
      const anchorTop = anchor ? anchor.getBoundingClientRect().top : 0;
      const oldHeight = last.getBoundingClientRect().bottom - first.getBoundingClientRect().top;
      rows.forEach((row) => row.remove());
      if (anchor) {
        const afterTop = anchor.getBoundingClientRect().top;
        if (afterTop !== anchorTop) {
          window.__o11a1ScrollAdjust = Date.now();
          scroll.scrollTop = Math.max(0, scroll.scrollTop + (afterTop - anchorTop));
        }
      } else if (oldHeight > 0) {
        window.__o11a1ScrollAdjust = Date.now();
        scroll.scrollTop = Math.max(0, scroll.scrollTop - oldHeight);
      }
    } else {
      rows.forEach((row) => row.remove());
    }
    delete feed.__chunkItems[page];
    return true;
  }

  function trimFeed(feed) {
    const pages = Array.isArray(feed.__chunkPages) ? feed.__chunkPages : [];
    while (pages.length > 2) {
      const oldPage = pages[0];
      if (!trimChunk(feed, oldPage)) break;
      pages.shift();
      feed.__nativeItems = pages.flatMap((pageNo) => feed.__chunkItems[pageNo] || []);
    }
  }

  function appendRows(feed, items, label, page) {
    const chunk = page || 1;
    feed.__chunkPages = feed.__chunkPages || [];
    feed.__chunkItems = feed.__chunkItems || {};
    if (!feed.__chunkPages.includes(chunk)) feed.__chunkPages.push(chunk);
    feed.__chunkItems[chunk] = items.slice();
    const realRows = items.map((item, index) => buildRow(item, label, chunk, index));
    const skeletons = $$(`.feed-skeleton[data-skeleton-page="${chunk}"]`, feed);
    if (skeletons.length) {
      realRows.forEach((row, index) => {
        const skeleton = skeletons[index];
        if (skeleton && skeleton.isConnected) skeleton.replaceWith(row);
        else feed.appendChild(row);
      });
      skeletons.slice(realRows.length).forEach((skeleton) => skeleton.remove());
    } else {
      const fragment = document.createDocumentFragment();
      realRows.forEach((row) => fragment.appendChild(row));
      feed.appendChild(fragment);
    }
    trimFeed(feed);
    feed.__nativeItems = feed.__chunkPages.flatMap((pageNo) => feed.__chunkItems[pageNo] || []);
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
    if (moduleName === '下载') return { api: null, special: 'downloads', label: '离线缓存' };
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
      if (!append) renderEmpty(feed, '登录后查看收藏', '短信登录后同步收藏夹。', '去登录', () => host.showPage('login'));
      return { ok: true, items: [], title: kind.label, needLogin: true, hasMore: false };
    }
    if ((kind.api === 'history' || kind.api === 'following') && !state.loggedIn) {
      if (!append) renderEmpty(feed, `登录后查看${kind.label}`, '短信登录后同步 B 站账号。', '去登录', () => host.showPage('login'));
      return { ok: true, items: [], title: kind.label, needLogin: true, hasMore: false };
    }
    const args = kind.api === 'popular' ? [pageNo, 20]
      : kind.api === 'history' ? [pageNo, cursor || '']
        : kind.api === 'favorites' || kind.api === 'ranking' || kind.api === 'live' || kind.api === 'following'
          ? [pageNo]
          : kind.api === 'bangumi' ? [pageNo, kind.args[0]]
            : kind.api === 'zone' ? [kind.args[0], pageNo]
              : kind.api === 'search'
                ? [name, pageNo]
                : [pageNo];
    const result = feedResult(kind.api, args);
    if (!result.ok) {
      if (!append) {
        if (result.needLogin) {
          renderEmpty(feed, `登录后查看${kind.label}`, '短信登录后同步 B 站账号。', '去登录', () => host.showPage('login'));
        } else {
          renderEmpty(feed, `${kind.label}加载失败`, result.error || '网络错误', '重试', () => loadFeed(name, feed, 1, ''));
        }
      } else {
        setTail(feed, 'error', result.needLogin ? '登录后继续加载' : '加载失败 · 点击重试',
          () => requestFeedPage(feedKey(feed), true));
      }
      return { ok: false, items: [], title: kind.label, needLogin: Boolean(result.needLogin), hasMore: true };
    }
    const items = Array.isArray(result.items) ? result.items : [];
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
      setNote(`${result.title || kind.label} · 触底加载 · 保留最近两段`);
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
    if (!append && !immediate && kind.special !== 'downloads' && kind.special !== 'fish') {
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
    if (kind.special === 'downloads') {
      win.hasMore = false;
      win.page = 1;
      win.loading = false;
      if (!appendPage) renderDownloads();
      setTail(feeds.module, 'idle');
      return true;
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
    upTotal = 0;
    const count = $('#upSortCount');
    if (count) count.textContent = '';
    const page = $('.page[data-page="up"]');
    if (page) page.scrollTop = 0;
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
    upTotal = Number(result.total) || 0;
    const countEl = $('#upSortCount');
    if (countEl) countEl.textContent = upTotal > 0 ? `共 ${countText(upTotal)} 个投稿` : '';
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
    if (note) note.textContent = `${state.upName || 'UP 主'} · ${upSort === 'click' ? '播放量' : '最新发布'} · 触底加载`;
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
    const count = $('#upSortCount');
    if (count) count.textContent = '';
    syncUpSortUI();
    host.showPage('up');
    windows.up.token += 1;
    windows.up.page = 0;
    windows.up.cursor = '';
    windows.up.hasMore = true;
    windows.up.loading = false;
    windows.up.name = name;
    loadUp(1, false);
  }

  /* ---------- offline downloads ---------- */
  let downloadItems = [];
  let downloadTimer = null;
  let downloadNote = '';

  function stopDownloadPolling() {
    clearInterval(downloadTimer);
    downloadTimer = null;
  }

  function downloadRow(item) {
    const progress = Number(item.progress || 0);
    const status = String(item.status || '');
    const statusText = status === 'completed' ? '已完成'
      : status === 'downloading' ? `下载中 ${progress}%`
        : status === 'merging' ? '正在合流音视频…'
        : status === 'paused' ? `已暂停 ${progress}%`
          : status === 'missing' ? '文件已丢失'
            : status === 'error' ? `失败 · ${item.error || '未知错误'}`
              : status;
    const action = status === 'completed' ? 'play'
      : status === 'downloading' ? 'pause'
        : status === 'paused' || status === 'error' ? 'resume'
          : status === 'merging' ? ''
            : 'play';
    const actionLabel = action === 'play' ? '播放' : action === 'pause' ? '暂停' : '继续';
    return `
      <article class="download-row" data-download="${attr(item.id)}">
        <span class="download-thumb">${item.pic ? `<img src="${attr(item.pic)}" alt="" referrerpolicy="no-referrer">` : ''}</span>
        <div class="download-copy">
          <b>${esc(item.title || item.id)}</b>
          <span>${esc(item.quality || '')}${item.mode === 'dash' ? ' · DASH 合流' : ''} · ${esc(item.downloadedText || '0 B')} / ${esc(item.totalText || '未知')}</span>
          <div class="download-track"><i style="width:${progress}%"></i></div>
          <small class="${status === 'error' || status === 'missing' ? 'bad' : status === 'completed' ? 'ok' : ''}">${esc(statusText)}</small>
        </div>
        <div class="download-actions">
          ${action ? `<button type="button" data-dl-action="${action}" data-dl-id="${attr(item.id)}">${actionLabel}</button>` : ''}
          <button type="button" class="ghost" data-dl-action="remove" data-dl-id="${attr(item.id)}">删除</button>
        </div>
      </article>`;
  }

  function paintDownloads(list) {
    const box = $('#downloadList');
    if (!box) return;
    if (!list.length) {
      box.innerHTML = '<div class="native-empty"><b>还没有离线任务</b><span>在播放器或这里缓存当前视频，完成后可离线播放。</span></div>';
      return;
    }
    box.innerHTML = list.map(downloadRow).join('');
  }

  function refreshDownloads(showNote) {
    if (typeof bridge.downloadList !== 'function') return;
    const result = call('downloadList');
    if (!result.ok) {
      const box = $('#downloadList');
      if (box) box.innerHTML = `<div class="native-empty">下载列表加载失败<br>${esc(result.error || '')}</div>`;
      return;
    }
    downloadItems = Array.isArray(result.items) ? result.items : [];
    paintDownloads(downloadItems);
    const storage = $('#downloadStorage');
    if (storage) storage.textContent = `已用 ${result.storage ? sizeText(result.storage) : '0 B'} · ${downloadItems.length} 个任务`;
    if (showNote) {
      const note = $('#downloadNote');
      if (note) note.textContent = showNote;
    }
  }

  function sizeText(bytes) {
    const value = Number(bytes || 0);
    if (value >= 1073741824) return `${(value / 1073741824).toFixed(2)} GB`;
    if (value >= 1048576) return `${(value / 1048576).toFixed(1)} MB`;
    if (value >= 1024) return `${Math.round(value / 1024)} KB`;
    return `${value} B`;
  }

  function renderDownloads() {
    stopDownloadPolling();
    const feed = feeds.module;
    const current = currentItem();
    const supported = typeof bridge.downloadStart === 'function';
    feed.innerHTML = `
      <div class="special-page">
        <div class="special-head">
          <div><b>离线缓存</b><span>渐进 MP4 · 应用私有目录 · 支持断点续传</span></div>
          <button type="button" class="filter-btn" id="downloadRefresh">刷新</button>
        </div>
        <div class="download-add">
          <div>
            <b>${current ? esc(current.title || '当前视频') : '当前没有打开视频'}</b>
            <span id="downloadStorage">已用 0 B · 0 个任务</span>
          </div>
          <button type="button" class="pill-btn primary" id="downloadCurrent" ${supported && current && current.bvid ? '' : 'disabled'}>缓存当前视频</button>
        </div>
        ${typeof bridge.downloadDash === 'function' ? `<div class="download-add dash-add"><div><b>DASH 音视频合流</b><span>分轨下载后用 MediaMuxer 合成 MP4</span></div><button type="button" class="pill-btn" id="downloadDash" ${current && current.bvid ? '' : 'disabled'}>DASH 合流缓存</button></div>` : ''}
        <div class="special-note" id="downloadNote">${supported ? '下载完成后在这里直接播放；删除会同时移除本地文件。' : '当前版本没有可用的下载桥。'}</div>
        <div class="download-list" id="downloadList"></div>
      </div>`;
    const button = $('#downloadCurrent');
    if (button) button.addEventListener('click', () => {
      const item = currentItem();
      if (!item || !item.bvid) {
        const note = $('#downloadNote');
        if (note) note.textContent = '当前视频没有可缓存的 BV 号。';
        return;
      }
      const note = $('#downloadNote');
      if (note) note.textContent = '已加入下载队列…';
      const result = call('downloadStart', item.bvid, Number(item.cid || 0), item.title || '', item.pic || '', state.settings.quality);
      if (!result.ok) {
        if (note) note.textContent = `加入失败 · ${result.error || '未知错误'}`;
        return;
      }
      refreshDownloads('已开始下载。');
    });
    const refresh = $('#downloadRefresh');
    if (refresh) refresh.addEventListener('click', () => refreshDownloads('已刷新。'));
    const dashButton = $('#downloadDash');
    if (dashButton) dashButton.addEventListener('click', () => {
      const item = currentItem();
      if (!item || !item.bvid) {
        const note = $('#downloadNote');
        if (note) note.textContent = '当前视频没有可缓存的 BV 号。';
        return;
      }
      const note = $('#downloadNote');
      if (note) note.textContent = '已加入 DASH 合流队列…';
      const result = call('downloadDash', item.bvid, Number(item.cid || 0), item.title || '', item.pic || '', state.settings.quality);
      if (!result.ok) {
        if (note) note.textContent = `加入失败 · ${result.error || '未知错误'}`;
        return;
      }
      refreshDownloads('DASH 音视频分轨下载中，完成后自动合流。');
    });
    refreshDownloads();
    if (supported) downloadTimer = setInterval(() => {
      if (state.page !== 'module' || state.moduleName !== '下载') {
        stopDownloadPolling();
        return;
      }
      refreshDownloads();
    }, 1200);
  }

  function downloadAction(action, id) {
    const item = downloadItems.find((row) => row.id === id);
    if (!item) return;
    if (action === 'remove') {
      const result = call('downloadRemove', id);
      refreshDownloads(result.ok ? '已删除本地文件。' : `删除失败 · ${result.error || ''}`);
      return;
    }
    if (action === 'pause') {
      call('downloadPause', id);
      refreshDownloads('已暂停，可继续。');
      return;
    }
    if (action === 'resume') {
      const result = call('downloadResume', id);
      refreshDownloads(result.ok ? '继续下载。' : `继续失败 · ${result.error || ''}`);
      return;
    }
    if (action === 'play') {
      if (!item.url) {
        refreshDownloads('文件不在本地，请重新缓存。');
        return;
      }
      playItem({
        id: item.id,
        key: `offline:${item.id}`,
        title: item.title,
        meta: `离线 · ${item.quality || ''}`,
        pic: item.pic,
        bvid: item.bvid,
        cid: item.cid,
        offlineUrl: item.url,
      });
    }
  }

  feeds.module.addEventListener('click', (event) => {
    const button = event.target.closest('[data-dl-action]');
    if (!button) return;
    event.preventDefault();
    downloadAction(button.dataset.dlAction, button.dataset.dlId);
  });

  /* ---------- member center ---------- */
  function renderMember(immediate) {
    const feed = feeds.module;
    if (!state.loggedIn) {
      renderEmpty(feed, '登录后查看会员任务', '短信登录后同步大会员状态与每日经验。', '去登录', () => host.showPage('login'));
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

  function loadSearch(query, page, append, immediate) {
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
    const result = query ? feedResult('search', [query, pageNo]) : feedResult('popular', [pageNo, 20]);
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
    const now = Date.now();
    if (!force && now - (win.lastLoadAt || 0) < 800) return;
    if (!feed.querySelector('.real-row')) return;
    if (win.page < 1) return;
    const next = win.page + 1;
    const token = win.token;
    win.lastLoadAt = now;
    win.loading = true;
    setTail(feed, 'idle');
    showFeedSkeleton(feed, next, 20);
    win.loadTimer = setTimeout(() => {
      win.loadTimer = null;
      if (win.token !== token) {
        win.loading = false;
        clearFeedSkeletons(feed, next);
        return;
      }
      if (state.page !== key) {
        win.loading = false;
        clearFeedSkeletons(feed, next);
        setTail(feed, 'idle');
        return;
      }
      const pages = Array.isArray(feed.__chunkPages) ? feed.__chunkPages : [];
      const oldest = pages.length ? Math.min(...pages) : 0;
      if (win.page >= next || (oldest && next < oldest)) {
        win.loading = false;
        clearFeedSkeletons(feed, next);
        setTail(feed, 'idle');
        return;
      }
      if (key === 'home') loadHome(next, true);
      else if (key === 'search') loadSearch(host.searchInput.value.trim(), next, true);
      else if (key === 'up') loadUp(next, true);
      else loadModule(next, true);
      clearFeedSkeletons(feed, next);
    }, 220);
  }

  function playItem(item) {
    if (!item) return;
    if (item.live) { playLive(item); return; }
    if (item.seasonId && !item.epId) { playSeason(item); return; }
    const key = item.offlineUrl ? `offline:${item.id || item.bvid}`
      : item.epId ? `ep:${item.epId}` : item.roomId ? `live:${item.roomId}` : `bvid:${item.bvid}`;
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
    host.openPlayer({ resume: true });
  }

  function playLive(item) {
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
  const postCanvas = $('#postCanvas');
  const playerStage = $('#playerStage');
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
    destroyHls();
    destroyDash();
    closeLiveDanmaku();
    stopPostProcess();
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
    const map = { '4K': 120, '1080P60': 116, '1080P+': 112, '1080P': 80, '720P': 64, '480P': 32, '360P': 16, '仅音频': 16 };
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

  function setAvailableQualities(tracks) {
    const labels = [];
    (tracks || [])
      .slice()
      .sort((a, b) => Number(b.qn || 0) - Number(a.qn || 0))
      .forEach((track) => {
        const label = qualityLabelFromQn(track && track.qn);
        if (label && !labels.includes(label)) labels.push(label);
      });
    state.availableQualities = labels;
  }

  function loadLive(item, autoplay) {
    destroyHls();
    stopPostProcess();
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
    connectLiveDanmaku(Number(item.roomId || 0));
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
    if (!dashState) return;
    dashState.aborted = true;
    try {
      if (dashState.readers) {
        dashState.readers.forEach((reader) => { try { reader.cancel(); } catch (_) {} });
      }
    } catch (_) {}
    try { URL.revokeObjectURL(dashState.url); } catch (_) {}
    dashState = null;
  }

  function dashFallback(item, autoplay, reason) {
    log('dash playback fallback ' + reason);
    destroyDash();
    mediaItem = null;
    setStatus('切换到渐进播放…', 'loading');
    loadVideo(item, autoplay, false);
  }

  function chooseDashTrack(tracks, targetQn) {
    const sorted = tracks.slice().sort((a, b) => Number(a.qn || 0) - Number(b.qn || 0));
    let best = sorted[0];
    sorted.forEach((track) => {
      if (Number(track.qn || 0) <= targetQn) best = track;
    });
    return best || sorted[sorted.length - 1];
  }

  function appendDashBuffer(buffer, data, state) {
    return new Promise((resolve, reject) => {
      const append = () => {
        if (state.aborted) { resolve(); return; }
        if (buffer.updating) {
          buffer.addEventListener('updateend', append, { once: true });
          return;
        }
        try {
          buffer.appendBuffer(data);
        } catch (error) {
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

  async function waitDashRoom(buffer, state) {
    let guard = 0;
    while (!state.aborted && guard < 120) {
      guard += 1;
      let bufferedEnd = 0;
      let bufferedStart = 0;
      try {
        if (buffer.buffered.length) {
          bufferedEnd = buffer.buffered.end(buffer.buffered.length - 1);
          bufferedStart = buffer.buffered.start(0);
        }
      } catch (_) {}
      if (!bufferedEnd || video.currentTime <= 0) return;
      if (bufferedEnd - video.currentTime < 45) return;
      if (bufferedStart > 0 && bufferedStart < video.currentTime - 30 && !buffer.updating) {
        try { buffer.remove(0, Math.max(0, video.currentTime - 20)); } catch (_) {}
      }
      await new Promise((resolve) => setTimeout(resolve, 350));
    }
  }

  async function pumpDash(urls, buffer, type, item, autoplay, state) {
    let lastError = 'DASH 地址不可用';
    for (const url of urls.filter(Boolean)) {
      try {
        let offset = 0;
        let total = 0;
        let appended = 0;
        while (!state.aborted) {
          const response = await fetch(url, {
            cache: 'no-store',
            headers: { Range: `bytes=${offset}-` }
          });
          if (!response.ok) throw new Error('HTTP ' + response.status);
          const contentRange = response.headers.get('Content-Range') || '';
          const totalMatch = contentRange.match(/\/(\d+)$/);
          if (totalMatch) total = Number(totalMatch[1]);
          const value = new Uint8Array(await response.arrayBuffer());
          if (!value.length) break;
          addNetBytes(value.length);
          await appendDashChunk(buffer, value, state);
          appended += value.length;
          offset += value.length;
          if (!state.started && type === 'video' && appended > 350 * 1024) {
            state.started = true;
            startDashPlayback(autoplay);
          }
          await waitDashRoom(buffer, state);
          if (response.status === 200 && !total) break;
          if (total > 0 && offset >= total) break;
          if (value.length < 64 * 1024) break;
        }
        if (!state.aborted && type === 'video') startDashPlayback(autoplay);
        if (!state.aborted) log('dash ' + type + ' stream ended bytes=' + appended);
        return;
      } catch (error) {
        lastError = String(error);
        log('dash ' + type + ' source failed ' + lastError);
        if (state.aborted) return;
      }
    }
    if (!state.aborted) dashFallback(item, autoplay, lastError);
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
    if (!supportsMime(videoMime) || !supportsMime(audioMime)) {
      mediaItem = null;
      loadVideo(item, autoplay, false);
      return;
    }
    mediaItem = item;
    mediaLive = false;
    mediaBackup = '';
    loadDanmaku(item.cid);
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
    video.src = url;
    video.load();
  }

  function loadVideo(item, autoplay, allowDash = true) {
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
    if (!item.bvid && !item.epId && !item.offlineUrl) {
      clearVideo();
      return;
    }
    const key = item.offlineUrl ? `offline:${item.id || item.bvid}`
      : item.epId ? `ep:${item.epId}` : `bvid:${item.bvid}`;
    if (mediaItem && mediaItem.key === key && video.src) {
      if (autoplay) video.play().catch(() => {});
      return;
    }
    destroyHls();
    stopPostProcess();
    mediaLive = false;
    if (player) player.classList.remove('live-player');
    mediaItem = item;
    mediaTriedBackup = false;
    mediaBackup = '';
    state.duration = 0;
    playerVideo.classList.remove('has-video', 'video-error');
    playerVideo.classList.add('video-loading');
    setStatus('加载中…', 'loading');
    if (item.offlineUrl) {
      loadDanmaku(item.cid);
      mediaBackup = '';
      video.src = item.offlineUrl;
      video.load();
      playerVideo.classList.add('has-video');
      if (autoplay) {
        video.play().then(() => {
          state.playing = true;
          host.setPlayIcon(true);
          host.updatePlaylistDock();
        }).catch(() => {
          state.playing = false;
          host.setPlayIcon(false);
          setStatus('点击播放', 'error');
        });
      }
      return;
    }
    const highQuality = ['4K', '1080P60', '1080P', '1080P+'].includes(state.settings.quality);
    if (allowDash && highQuality && item.bvid && typeof bridge.dash === 'function') {
      const dash = call('dash', item.bvid, item.cid || 0, qualityQn(state.settings.quality));
      if (dash.ok && Array.isArray(dash.video) && Array.isArray(dash.audio) && dash.video.length && dash.audio.length) {
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
    const result = item.epId
      ? call('playPgc', item.epId, item.bvid || '', item.cid || 0, qualityQn(state.settings.quality))
      : call('playQuality', item.bvid, item.cid || 0, qualityQn(state.settings.quality));
    if (!result.ok) {
      setStatus('加载失败 · 点击重试', 'error');
      log('play error ' + (item.bvid || item.epId || '') + ' ' + (result.error || ''));
      if (host.showPlayerNotice) host.showPlayerNotice('画质', `${requestedQuality} 加载失败`, 3200);
      return;
    }
    if (result.cid) {
      item.cid = result.cid;
      const entry = currentItem();
      if (entry) entry.cid = result.cid;
    }
    if (result.qualityLabel) {
      state.settings.quality = result.qualityLabel;
      state.availableQualities = [result.qualityLabel];
      host.updatePlayerLabels();
      showQualityFallback(requestedQuality, result.qualityLabel);
    }
    loadDanmaku(result.cid || item.cid);
    mediaBackup = result.backup || '';
    video.src = result.url;
    video.load();
    playerVideo.classList.add('has-video');
    if (autoplay) {
      video.play().then(() => {
        state.playing = true;
        host.setPlayIcon(true);
        host.updatePlaylistDock();
      }).catch(() => {
        state.playing = false;
        host.setPlayIcon(false);
        setStatus('点击播放', 'error');
      });
    }
  }

  video.addEventListener('loadedmetadata', () => {
    state.duration = Number.isFinite(video.duration) ? video.duration : 0;
    if (state.duration > 0 && !mediaLive) host.setProgress(video.currentTime / state.duration * 100);
    if (mediaLive && host.pcTime) host.pcTime.textContent = 'LIVE';
    playerVideo.classList.remove('video-loading');
    post.newFrame = true;
    syncPostProcess();
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
    host.setPlayIcon(true);
    host.updatePlaylistDock();
    playerVideo.classList.remove('video-loading');
    if (danmakuLayer) danmakuLayer.classList.remove('paused');
    if (status) status.textContent = '';
    syncPostProcess();
  });
  video.addEventListener('pause', () => {
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
      host.setPlayIcon(false);
    }
  });
  if (status) status.addEventListener('click', () => {
    if (!playerVideo.classList.contains('video-error') || !mediaItem) return;
    const item = mediaItem;
    clearVideo();
    loadVideo(item, true);
  });

  /* ---------- WebGL post-process: interpolation / CAS / Anime4K ---------- */
  const post = {
    gl: null,
    canvas: null,
    program: null,
    copyProgram: null,
    curTex: null,
    prevTex: null,
    prevFbo: null,
    width: 0,
    height: 0,
    raf: 0,
    running: false,
    newFrame: true,
    lastFrameAt: 0,
    initialized: false,
  };
  let lastInterpNoticeKey = '';
  let postFallbackNotified = false;

  function displayRefreshRate() {
    try {
      if (window.O11A1Native && typeof window.O11A1Native.displayHz === 'function') {
        return Number(window.O11A1Native.displayHz()) || 0;
      }
    } catch (_) {}
    return 0;
  }

  function measureRenderFps(callback) {
    let start = 0;
    let frames = 0;
    const tick = (now) => {
      if (!state.playerOpen) {
        callback(0);
        return;
      }
      if (!start) {
        start = now;
        frames = 0;
        requestAnimationFrame(tick);
        return;
      }
      frames += 1;
      if (now - start >= 800) {
        callback(frames * 1000 / Math.max(1, now - start));
        return;
      }
      requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
  }

  function syncHighRefresh() {
    if (!window.O11A1Native || typeof window.O11A1Native.setHighRefresh !== 'function') return;
    const interp = state.settings.interp;
    const target = interp === '自动' ? 120 : Number(interp) || 0;
    const want = Boolean(state.playerOpen) && target >= 90;
    try {
      window.O11A1Native.setHighRefresh(want);
    } catch (_) {}
    if (!want) {
      lastInterpNoticeKey = '';
      return;
    }
    setTimeout(() => {
      if (!state.playerOpen || state.settings.interp !== interp) return;
      const hz = displayRefreshRate();
      if (hz && hz < target) {
        const key = `${target}:${hz}`;
        if (key === lastInterpNoticeKey) return;
        lastInterpNoticeKey = key;
        if (host.showPlayerNotice) {
          host.showPlayerNotice('插帧', `屏幕 ${hz}Hz · ${target} 帧插帧不可用`, 3400);
        }
        return;
      }
      measureRenderFps((fps) => {
        if (!state.playerOpen || state.settings.interp !== interp) return;
        const rendered = Math.round(fps);
        if (!rendered || rendered >= target * 0.85) return;
        const key = `${target}:render:${rendered}`;
        if (key === lastInterpNoticeKey) return;
        lastInterpNoticeKey = key;
        if (host.showPlayerNotice) {
          host.showPlayerNotice('插帧', `实际渲染约 ${rendered}fps · ${target} 帧插帧不可用`, 3400);
        }
      });
    }, 750);
  }

  const POST_VERTEX = `
    attribute vec2 aPos;
    varying vec2 vUv;
    void main(){ vUv = aPos * 0.5 + 0.5; gl_Position = vec4(aPos, 0.0, 1.0); }
  `;
  const POST_FRAGMENT = `
    precision mediump float;
    varying vec2 vUv;
    uniform sampler2D uCur;
    uniform sampler2D uPrev;
    uniform vec2 uTexel;
    uniform float uAlpha;
    uniform float uSharp;
    uniform float uSat;
    void main(){
      vec2 uv = vec2(vUv.x, 1.0 - vUv.y);
      vec3 c = texture2D(uCur, uv).rgb;
      vec3 p = texture2D(uPrev, uv).rgb;
      vec3 n = texture2D(uCur, uv + vec2(0.0, uTexel.y)).rgb;
      vec3 s = texture2D(uCur, uv - vec2(0.0, uTexel.y)).rgb;
      vec3 e = texture2D(uCur, uv + vec2(uTexel.x, 0.0)).rgb;
      vec3 w = texture2D(uCur, uv - vec2(uTexel.x, 0.0)).rgb;
      vec3 blur = (n + s + e + w) * 0.25;
      vec3 sharp = clamp(c + (c - blur) * uSharp, 0.0, 1.0);
      vec3 col = mix(p, sharp, uAlpha);
      float l = dot(col, vec3(0.299, 0.587, 0.114));
      col = mix(vec3(l), col, uSat);
      gl_FragColor = vec4(col, 1.0);
    }
  `;
  const COPY_FRAGMENT = `
    precision mediump float;
    varying vec2 vUv;
    uniform sampler2D uCur;
    void main(){ gl_FragColor = texture2D(uCur, vUv); }
  `;

  function compileShader(gl, type, source) {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      log('post shader failed ' + gl.getShaderInfoLog(shader));
      gl.deleteShader(shader);
      return null;
    }
    return shader;
  }

  function makeProgram(gl, fragment) {
    const vertex = compileShader(gl, gl.VERTEX_SHADER, POST_VERTEX);
    const pixel = compileShader(gl, gl.FRAGMENT_SHADER, fragment);
    if (!vertex || !pixel) return null;
    const program = gl.createProgram();
    gl.attachShader(program, vertex);
    gl.attachShader(program, pixel);
    gl.bindAttribLocation(program, 0, 'aPos');
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      log('post link failed ' + gl.getProgramInfoLog(program));
      return null;
    }
    return program;
  }

  function newTexture(gl) {
    const texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    return texture;
  }

  function initPostProcess() {
    if (post.initialized) return Boolean(post.gl);
    post.initialized = true;
    const canvas = postCanvas;
    if (!canvas) return false;
    const gl = canvas.getContext('webgl', { alpha: false, antialias: false, preserveDrawingBuffer: false })
      || canvas.getContext('experimental-webgl', { alpha: false, antialias: false });
    if (!gl) {
      log('post process unavailable: no webgl');
      return false;
    }
    post.canvas = canvas;
    post.gl = gl;
    post.program = makeProgram(gl, POST_FRAGMENT);
    post.copyProgram = makeProgram(gl, COPY_FRAGMENT);
    if (!post.program || !post.copyProgram) return false;
    const buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);
    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);
    return true;
  }

  function postSettings() {
    const interp = state.settings.interp;
    const enhance = state.settings.enhance;
    const enabled = mediaLive === false && !video.paused && video.readyState >= 2
      && (interp !== '关' || enhance !== '关');
    return {
      enabled,
      interp: interp === '自动' ? Math.min(120, Math.max(60, displayRefreshRate() || 60)) : Number(interp) || 0,
      sharp: enhance === 'Anime4K' ? 1.78 : enhance === 'CAS' ? 1.16 : 0.15,
      sat: enhance === 'Anime4K' ? 1.12 : enhance === 'CAS' ? 1.045 : 1,
    };
  }

  function syncPostProcess() {
    const settings = postSettings();
    if (!settings.enabled) {
      stopPostProcess();
      return;
    }
    if (!initPostProcess()) {
      log('post process fallback to css filter');
      playerStage.classList.remove('post-active');
      postCanvas.hidden = true;
      const enhance = state.settings.enhance;
      video.style.filter = enhance === 'Anime4K'
        ? 'contrast(1.1) saturate(1.14)'
        : enhance === 'CAS'
          ? 'contrast(1.06) saturate(1.05)'
          : '';
      if (enhance !== '关' && !postFallbackNotified) {
        postFallbackNotified = true;
        if (host.showPlayerNotice) host.showPlayerNotice('增强', 'WebGL 不可用 · 已用滤镜降级', 3000);
      }
      return;
    }
    postFallbackNotified = false;
    postCanvas.hidden = false;
    video.style.filter = '';
    playerStage.classList.add('post-active');
    if (!post.running) startPostProcess();
  }

  function stopPostProcess() {
    post.running = false;
    cancelAnimationFrame(post.raf);
    post.raf = 0;
    playerStage.classList.remove('post-active');
    if (postCanvas) postCanvas.hidden = true;
    video.style.filter = '';
  }

  function ensurePostSize() {
    const gl = post.gl;
    if (!gl || !video.videoWidth) return false;
    const width = Math.min(1280, video.videoWidth);
    const height = Math.max(1, Math.round(width * video.videoHeight / video.videoWidth));
    if (post.width === width && post.height === height) return true;
    post.width = width;
    post.height = height;
    postCanvas.width = width;
    postCanvas.height = height;
    if (post.curTex) gl.deleteTexture(post.curTex);
    if (post.prevTex) gl.deleteTexture(post.prevTex);
    if (post.prevFbo) gl.deleteFramebuffer(post.prevFbo);
    post.curTex = newTexture(gl);
    post.prevTex = newTexture(gl);
    gl.bindTexture(gl.TEXTURE_2D, post.curTex);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
    gl.bindTexture(gl.TEXTURE_2D, post.prevTex);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
    post.prevFbo = gl.createFramebuffer();
    gl.bindFramebuffer(gl.FRAMEBUFFER, post.prevFbo);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, post.prevTex, 0);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    post.newFrame = true;
    return true;
  }

  function uploadPostFrame() {
    const gl = post.gl;
    if (!gl || !ensurePostSize()) return;
    if (!post.newFrame) return;
    gl.bindFramebuffer(gl.FRAMEBUFFER, post.prevFbo);
    gl.viewport(0, 0, post.width, post.height);
    gl.useProgram(post.copyProgram);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, post.curTex);
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.bindTexture(gl.TEXTURE_2D, post.curTex);
    try {
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, video);
    } catch (error) {
      log('post upload failed ' + error);
    }
    post.newFrame = false;
    post.lastFrameAt = performance.now();
  }

  function drawPostFrame(now) {
    const gl = post.gl;
    if (!gl || !post.running) return;
    const settings = postSettings();
    if (!settings.enabled) { stopPostProcess(); return; }
    uploadPostFrame();
    gl.viewport(0, 0, post.width, post.height);
    gl.useProgram(post.program);
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, post.curTex);
    gl.uniform1i(gl.getUniformLocation(post.program, 'uCur'), 0);
    gl.activeTexture(gl.TEXTURE1);
    gl.bindTexture(gl.TEXTURE_2D, post.prevTex);
    gl.uniform1i(gl.getUniformLocation(post.program, 'uPrev'), 1);
    gl.uniform2f(gl.getUniformLocation(post.program, 'uTexel'), 1 / post.width, 1 / post.height);
    let alpha = 1;
    if (settings.interp) {
      const interval = 1000 / settings.interp;
      alpha = Math.min(1, Math.max(0.05, (now - post.lastFrameAt) / interval));
    }
    gl.uniform1f(gl.getUniformLocation(post.program, 'uAlpha'), alpha);
    gl.uniform1f(gl.getUniformLocation(post.program, 'uSharp'), settings.sharp);
    gl.uniform1f(gl.getUniformLocation(post.program, 'uSat'), settings.sat);
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
    post.raf = requestAnimationFrame(drawPostFrame);
  }

  function startPostProcess() {
    if (post.running) return;
    post.running = true;
    post.newFrame = true;
    post.raf = requestAnimationFrame(drawPostFrame);
  }

  if (typeof video.requestVideoFrameCallback === 'function') {
    const onVideoFrame = () => {
      post.newFrame = true;
      video.requestVideoFrameCallback(onVideoFrame);
    };
    video.requestVideoFrameCallback(onVideoFrame);
  }
  video.addEventListener('seeked', () => { post.newFrame = true; });
  video.addEventListener('loadeddata', () => { post.newFrame = true; });

  window.O11A1Media = {
    onOpen() {
      syncHighRefresh();
      loadVideo(currentItem(), Boolean(state.playing));
    },
    onMinimize() {
      syncHighRefresh();
    },
    onStop() {
      syncHighRefresh();
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
    onSettings() {
      if (danmakuLayer) danmakuLayer.style.display = state.settings.danmaku ? 'block' : 'none';
      syncHighRefresh();
      if (!video.src) return;
      const rate = parseFloat(state.settings.speed || '1');
      video.playbackRate = Number.isFinite(rate) && rate > 0 ? rate : 1;
      video.loop = state.settings.loop === '循环';
      syncPostProcess();
    },
    onTrackChange() {
      loadVideo(currentItem(), true);
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
      if (!mediaItem || !video.src || mediaItem.live) return;
      if (['4K', '1080P60', '1080P', '1080P+'].includes(value) && typeof bridge.dash === 'function') {
        const item = mediaItem;
        mediaItem = null;
        loadVideo(item, true);
        return;
      }
      if (typeof bridge.playQuality !== 'function') return;
      const qn = qualityQn(value);
      const keepTime = video.currentTime || 0;
      const wasPlaying = !video.paused;
      const result = mediaItem.epId
        ? call('playPgc', mediaItem.epId, mediaItem.bvid || '', mediaItem.cid || 0, qn)
        : call('playQuality', mediaItem.bvid, mediaItem.cid || 0, qn);
      if (!result.ok || !result.url) {
        if (host.showPlayerNotice) host.showPlayerNotice('画质', `${value} 切换失败`, 2600);
        return;
      }
      mediaBackup = result.backup || '';
      mediaTriedBackup = false;
      if (result.qualityLabel) {
        state.settings.quality = result.qualityLabel;
        state.availableQualities = [result.qualityLabel];
        host.updatePlayerLabels();
        showQualityFallback(value, result.qualityLabel);
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

  /* ---------- video detail cache ---------- */
  const VIDEO_INFO_CACHE_MAX = 24;
  const RELATED_CACHE_TTL = 10 * 60 * 1000;
  const videoInfoCache = new Map();
  let relatedVideoCache = null;
  let relatedVideoCacheAt = 0;
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
      videoInfoCache.delete(key);
      videoInfoCache.set(key, cached);
      return cached.info;
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
    const relatedReady = relatedVideoCache !== null || typeof bridge.popular !== 'function';
    if (videoInfoCache.has(key) && relatedReady) return true;
    return detailRenderedKey === key
      && Boolean(document.querySelector('#videoDetailBody .vd-title'));
  }

  function ensureRelatedVideos() {
    if (relatedVideoCache !== null && Date.now() - relatedVideoCacheAt < RELATED_CACHE_TTL) {
      return relatedVideoCache;
    }
    if (typeof bridge.popular !== 'function') return relatedVideoCache || [];
    let result = null;
    try {
      result = call('popular', 1, 50);
    } catch (_) {
      result = null;
    }
    if (result && result.ok && Array.isArray(result.items)) {
      relatedVideoCache = result.items.slice();
      relatedVideoCacheAt = Date.now();
    }
    return relatedVideoCache || [];
  }

  function relatedVideos(bvid) {
    return ensureRelatedVideos().filter((row) => !bvid || row.bvid !== bvid);
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
  const COMMENT_CACHE_MAX = 16;
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
    }, 420));
    videoPrefetchTimers.push(setTimeout(() => {
      if (alive()) ensureRelatedVideos();
    }, 900));
    videoPrefetchTimers.push(setTimeout(() => {
      if (alive()) prefetchComments(item);
    }, 1350));
  }

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
    const related = relatedVideos(bvid);
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
      ${longDesc ? '<button class="vd-desc-toggle" type="button" data-vd-desc-toggle>展开简介</button>' : ''}
      <div class="vd-section"><b>相关推荐</b><span>${related.length} 个视频 · 点击加入</span></div>
      <div class="feed detail-related" id="detailRelatedFeed"></div>`;
    const relatedFeed = document.getElementById('detailRelatedFeed');
    if (related.length) {
      renderRows(relatedFeed, related, '相关推荐', 1);
    } else if (relatedFeed) {
      relatedFeed.innerHTML = '<div class="comment-inline-note">暂无相关推荐</div>';
    }
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
    const card = $('#accountCard');
    if (!card) return;
    card.classList.remove('is-loading');
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
          <span class="account-meta">短信登录 B 站账号，同步收藏 / 历史 / 动态</span>
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
    host.openSheet('账户', info.loggedIn ? 'B 站账号 · 实时信息' : '未登录 · 短信登录后同步', (body) => {
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
      host.actionRow(body, '短信登录', info.loggedIn ? '已登录' : '去登录', () => {
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
      renderEmpty($('#dynamicFeed'), '登录后查看动态', '短信登录后同步关注动态。', '去登录', () => host.showPage('login'));
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
    const result = call('dynamicFeed', page || 1, filter);
    clearMoreSkeletons($('#dynamicFeed'));
    if (!result.ok) {
      renderEmpty($('#dynamicFeed'), result.needLogin ? '登录后查看动态' : '动态加载失败', result.needLogin ? '短信登录后同步关注动态。' : (result.error || ''), result.needLogin ? '去登录' : '重试', result.needLogin ? () => host.showPage('login') : () => loadDynamic(1, false));
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
      renderEmpty($('#messageFeed'), '登录后查看消息', '短信登录后同步回复、@ 和点赞。', '去登录', () => host.showPage('login'));
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
    const result = call('messages', page || 1, filter);
    clearMoreSkeletons($('#messageFeed'));
    if (!result.ok) {
      renderEmpty($('#messageFeed'), result.needLogin ? '登录后查看消息' : '消息加载失败', result.needLogin ? '短信登录后同步回复、@ 和点赞。' : (result.error || ''), result.needLogin ? '去登录' : '重试', result.needLogin ? () => host.showPage('login') : () => loadMessages(1, false));
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
  if (loginNote) loginNote.innerHTML = '登录后同步收藏 / 历史 / 大会员画质<br>使用 B 站官方短信验证码登录，不再使用二维码';

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
      loadModule(1);
    }, 0);
  });

  const appScroll = $('#appScroll');
  if (appScroll) appScroll.addEventListener('scroll', () => {
    if (Date.now() - (window.__o11a1ScrollAdjust || 0) < 160) return;
    if (appScroll.scrollTop + appScroll.clientHeight < appScroll.scrollHeight - FEED_PREFETCH) return;
    if (state.page === 'home' || state.page === 'module') {
      requestFeedPage(state.page);
    }
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
    if (state.page === 'home') trimFeed(feeds.home);
    else if (state.page === 'module') trimFeed(feeds.module);
  });

  const upScroller = $('.page[data-page="up"]');
  if (upScroller) upScroller.addEventListener('scroll', () => {
    if (Date.now() - (window.__o11a1ScrollAdjust || 0) < 160) return;
    if (state.page !== 'up') return;
    if (upScroller.scrollTop + upScroller.clientHeight < upScroller.scrollHeight - FEED_PREFETCH) return;
    requestFeedPage('up');
    trimFeed(feeds.up);
  });

  const searchScroller = $('.page[data-page="search"]');
  if (searchScroller) searchScroller.addEventListener('scroll', () => {
    if (Date.now() - (window.__o11a1ScrollAdjust || 0) < 160) return;
    if (state.page !== 'search') return;
    if (searchScroller.scrollTop + searchScroller.clientHeight < searchScroller.scrollHeight - FEED_PREFETCH) return;
    requestFeedPage('search');
    trimFeed(feeds.search);
  });

  const pageObserver = new MutationObserver(() => {
    if (state.page === 'home') {
      if (!feeds.home.querySelector('.real-row')) loadHome(1);
    }
    if (state.page === 'search') {
      if (!feeds.search.querySelector('.real-row')) loadSearch(host.searchInput.value.trim(), 1);
    }
    if (state.page === 'module') {
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
      if (state.page === 'home') loadHome(1);
    }).observe(moduleLabel, { childList: true, characterData: true, subtree: true });
  }

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

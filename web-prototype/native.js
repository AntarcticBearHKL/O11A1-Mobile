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
    if (moduleName === '下载') return { api: null, special: 'downloads', label: '离线缓存' };
    if (moduleName === '会员') return { api: null, special: 'member', label: '会员任务' };
    if (moduleName === '养鱼') return { api: null, special: 'fish', label: 'AI 养鱼' };
    return { api: 'search', args: [moduleName], label: moduleName };
  }

  function loadFeed(name, feed, page, cursor) {
    const kind = moduleKind(name);
    if (kind.special) {
      return { ok: true, items: [], title: kind.label, needLogin: false };
    }
    if (!kind.api) {
      renderEmpty(feed, kind.label, kind.note);
      return { ok: true, items: [], title: kind.label, needLogin: false };
    }
    if (kind.api === 'favorites' && !state.loggedIn) {
      renderEmpty(feed, '登录后查看收藏', '短信登录后同步收藏夹。', '去登录', () => host.showPage('login'));
      return { ok: true, items: [], title: kind.label, needLogin: true };
    }
    if ((kind.api === 'history' || kind.api === 'following') && !state.loggedIn) {
      renderEmpty(feed, `登录后查看${kind.label}`, '短信登录后同步 B 站账号。', '去登录', () => host.showPage('login'));
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
        renderEmpty(feed, `登录后查看${kind.label}`, '短信登录后同步 B 站账号。', '去登录', () => host.showPage('login'));
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
    const filter = $('#moduleFilter');
    if (filter) filter.textContent = kind.label || name;
    if (kind.special === 'downloads') {
      renderDownloads();
      return true;
    }
    if (kind.special === 'member') {
      renderMember();
      return true;
    }
    if (kind.special === 'fish') {
      renderFish();
      return true;
    }
    const result = loadFeed(name, feeds.module, page || 1, cursors.module);
    if (result.ok) cursors.module = result.next || '';
    return true;
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
  function renderMember() {
    const feed = feeds.module;
    if (!state.loggedIn) {
      renderEmpty(feed, '登录后查看会员任务', '短信登录后同步大会员状态与每日经验。', '去登录', () => host.showPage('login'));
      return;
    }
    if (typeof bridge.memberCenter !== 'function') {
      renderEmpty(feed, '当前版本不支持会员中心', '');
      return;
    }
    feed.innerHTML = '<div class="native-empty">正在读取会员中心…</div>';
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
        const response = await fetch(url, { cache: 'no-store' });
        if (!response.ok || !response.body) throw new Error('HTTP ' + response.status);
        const reader = response.body.getReader();
        state.readers.push(reader);
        let appended = 0;
        while (true) {
          const { done, value } = await reader.read();
          if (done || state.aborted) break;
          if (!value || !value.length) continue;
          await appendDashChunk(buffer, value, state);
          appended += value.length;
          if (!state.started && type === 'video' && appended > 350 * 1024) {
            state.started = true;
            startDashPlayback(autoplay);
          }
          await waitDashRoom(buffer, state);
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
      host.pcPlay.textContent = 'Ⅱ';
      host.updatePlaylistDock();
    }).catch(() => {});
  }

  function loadDash(item, dash, autoplay) {
    destroyDash();
    destroyHls();
    const target = qualityQn(state.settings.quality);
    const videoTrack = chooseDashTrack(dash.video, target);
    const audioTrack = dash.audio.slice().sort((a, b) => Number(b.bandwidth || 0) - Number(a.bandwidth || 0))[0];
    if (!window.MediaSource || !videoTrack || !audioTrack) {
      mediaItem = null;
      loadVideo(item, autoplay, false);
      return;
    }
    const videoMime = `${videoTrack.mime || 'video/mp4'}; codecs="${videoTrack.codecs || 'avc1.640033'}"`;
    const audioMime = `${audioTrack.mime || 'audio/mp4'}; codecs="${audioTrack.codecs || 'mp4a.40.2'}"`;
    if (!MediaSource.isTypeSupported(videoMime) || !MediaSource.isTypeSupported(audioMime)) {
      mediaItem = null;
      loadVideo(item, autoplay, false);
      return;
    }
    mediaItem = item;
    mediaLive = false;
    mediaBackup = '';
    loadDanmaku(item.cid);
    const mediaSource = new MediaSource();
    const url = URL.createObjectURL(mediaSource);
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
    if (dash.qualityLabel) {
      window.O11A1Host.state.settings.quality = dash.qualityLabel;
      host.updatePlayerLabels();
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
          host.pcPlay.textContent = 'Ⅱ';
          host.updatePlaylistDock();
        }).catch(() => {});
      }
    }, { once: true });
    video.src = url;
    video.load();
  }

  function loadVideo(item, autoplay, allowDash = true) {
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
          host.pcPlay.textContent = 'Ⅱ';
          host.updatePlaylistDock();
        }).catch(() => {
          state.playing = false;
          host.pcPlay.textContent = '▶';
          setStatus('点击播放', 'error');
        });
      }
      return;
    }
    const highQuality = ['4K', '1080P60', '1080P', '1080P+'].includes(state.settings.quality);
    if (allowDash && highQuality && item.bvid && item.cid && typeof bridge.dash === 'function') {
      const dash = call('dash', item.bvid, item.cid, qualityQn(state.settings.quality));
      if (dash.ok && Array.isArray(dash.video) && Array.isArray(dash.audio) && dash.video.length && dash.audio.length) {
        loadDash(item, dash, autoplay);
        return;
      }
      log('dash unavailable ' + (dash.error || ''));
    }
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
    host.pcPlay.textContent = 'Ⅱ';
    host.updatePlaylistDock();
    playerVideo.classList.remove('video-loading');
    if (danmakuLayer) danmakuLayer.classList.remove('paused');
    if (status) status.textContent = '';
    syncPostProcess();
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
      interp: interp === '自动' ? (window.devicePixelRatio > 1.5 ? 120 : 60) : Number(interp) || 0,
      sharp: enhance === 'Anime4K' ? 1.65 : enhance === 'CAS' ? 1.05 : 0.15,
      sat: enhance === 'Anime4K' ? 1.12 : enhance === 'CAS' ? 1.03 : 1,
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
      video.style.filter = settings.sharp > 0.2 ? 'contrast(1.06) saturate(1.05)' : '';
      return;
    }
    postCanvas.hidden = false;
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
      syncPostProcess();
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
  let commentPage = 1;
  let commentHasMore = false;
  let commentLoading = false;
  let commentItems = [];

  function commentRow(row, depth = 0) {
    const rpid = Number(row.rpid || 0);
    const replies = Array.isArray(row.replies) ? row.replies : [];
    return `
      <div class="comment-row${depth ? ' comment-reply' : ''}" data-rpid="${rpid}">
        ${row.avatar ? `<img class="comment-avatar" src="${attr(row.avatar)}" alt="" referrerpolicy="no-referrer">` : '<span class="avatar-ph sm"></span>'}
        <div class="comment-text">
          <b>${esc(row.user || '用户')}${depth ? ' <span class="reply-tag">回复</span>' : ''}</b>
          <p>${esc(row.message || '')}</p>
          <small>赞 ${Number(row.like || 0)}${row.time ? ` · ${esc(timeAgo(row.time))}` : ''}</small>
          ${replies.length ? `<div class="comment-replies">${replies.map((reply) => commentRow(reply, depth + 1)).join('')}</div>` : ''}
        </div>
      </div>`;
  }

  function commentThread(row) {
    const rpid = Number(row.rpid || 0);
    const count = Number(row.rcount || 0);
    return `
      <div class="comment-thread" data-thread="${rpid}">
        ${commentRow(row)}
        ${count > 0 ? `<button class="comment-reply-toggle" type="button" data-reply-root="${rpid}" data-reply-count="${count}">共 ${count} 条回复 ⌄</button>` : ''}
        <div class="comment-replies" data-reply-box="${rpid}" hidden></div>
      </div>`;
  }

  function renderComments(items, append, total) {
    if (!append) {
      host.commentsBody.innerHTML = '';
      commentItems = [];
    }
    const html = items.map(commentThread).join('');
    host.commentsBody.insertAdjacentHTML('beforeend', html);
    commentItems = commentItems.concat(items);
    let footer = $('#commentFooter');
    if (!footer) {
      host.commentsBody.insertAdjacentHTML('beforeend', '<div class="comment-footer" id="commentFooter"></div>');
      footer = $('#commentFooter');
    }
    const shown = commentItems.length;
    const count = Number(total || shown || 0);
    if (commentHasMore || shown < count) {
      footer.innerHTML = `<button class="comment-more" type="button" id="commentMore">加载更多评论 · 已显示 ${shown} / ${count || '—'}</button>`;
    } else {
      footer.innerHTML = `<span>已显示全部 ${shown} 条评论</span>`;
    }
    if (total) host.commentsCount.textContent = `${total} 条`;
  }

  function loadComments(sort) {
    if (typeof sort === 'number') commentSort = sort;
    commentPage = 1;
    commentHasMore = false;
    commentLoading = false;
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
        commentHasMore = fallback.hasMore === true;
        renderComments(fallback.items, false, fallback.count);
        host.commentsBody.insertAdjacentHTML('afterbegin', '<div class="comment-inline-note">最新评论需要登录后查看，当前显示最热评论</div>');
        return;
      }
    }
    commentHasMore = result.hasMore === true;
    renderComments(result.items, false, result.count);
  }

  function loadMoreComments() {
    if (commentLoading) return;
    const item = currentItem();
    const aid = item && item.aid ? Number(item.aid) : 0;
    if (!aid) return;
    commentLoading = true;
    const footer = $('#commentFooter');
    if (footer) footer.innerHTML = '<span>正在加载…</span>';
    const nextPage = commentPage + 1;
    const result = typeof bridge.comments === 'function'
      ? call('comments', aid, nextPage, commentSort)
      : { ok: false, error: '不支持评论' };
    commentLoading = false;
    if (!result.ok || !Array.isArray(result.items) || result.items.length === 0) {
      commentHasMore = false;
      if (footer) footer.innerHTML = `<span>${result.needLogin ? '更多评论需要登录后查看' : '没有更多评论了'}</span>`;
      return;
    }
    commentPage = nextPage;
    commentHasMore = result.hasMore === true;
    renderComments(result.items, true, result.count);
  }

  function toggleReplies(button) {
    const root = Number(button.dataset.replyRoot || 0);
    const box = document.querySelector(`[data-reply-box="${root}"]`);
    if (!box || !root) return;
    if (!box.hidden) {
      box.hidden = true;
      button.textContent = `共 ${button.dataset.replyCount} 条回复 ⌄`;
      return;
    }
    box.hidden = false;
    button.textContent = `收起回复 ⌃`;
    if (box.dataset.loaded === '1') return;
    const item = currentItem();
    const aid = item && item.aid ? Number(item.aid) : 0;
    const result = typeof bridge.commentsReplies === 'function'
      ? call('commentsReplies', aid, root, 1)
      : { ok: false, error: '当前版本不支持楼中楼' };
    if (!result.ok || !Array.isArray(result.items)) {
      box.innerHTML = `<div class="comment-inline-note">${esc(result.error || '回复加载失败')}</div>`;
      return;
    }
    box.dataset.loaded = '1';
    box.innerHTML = result.items.map((reply) => commentRow(reply, 1)).join('')
      || '<div class="comment-inline-note">暂无回复</div>';
  }

  host.commentsBody.addEventListener('click', (event) => {
    const button = event.target.closest('[data-reply-root]');
    if (button) {
      event.preventDefault();
      toggleReplies(button);
      return;
    }
    if (event.target.closest('#commentMore')) {
      event.preventDefault();
      loadMoreComments();
    }
  });

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
      time: Math.floor(Date.now() / 1000),
    };
    const firstThread = host.commentsBody.querySelector('.comment-thread');
    if (firstThread) firstThread.insertAdjacentHTML('beforebegin', commentThread(row));
    else host.commentsBody.insertAdjacentHTML('afterbegin', commentThread(row));
    commentItems.unshift(row);
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

  function loadDynamic(page, append) {
    if (!state.loggedIn) {
      renderEmpty($('#dynamicFeed'), '登录后查看动态', '短信登录后同步关注动态。', '去登录', () => host.showPage('login'));
      return true;
    }
    if (typeof bridge.dynamicFeed !== 'function') {
      renderEmpty($('#dynamicFeed'), '当前版本不支持动态', '');
      return true;
    }
    const filter = ['all', 'video', 'image'][Math.max(0, Number(state.dynamicFilterIndex) || 0) % 3];
    const result = call('dynamicFeed', page || 1, filter);
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

  function loadMessages(page, append) {
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
    const filter = ['reply', 'at', 'like'][index];
    const result = call('messages', page || 1, filter);
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

  function likeCurrent() {
    const item = currentItem();
    if (!item || !item.aid || typeof bridge.like !== 'function') return '无视频';
    const next = !state.liked;
    const result = call('like', item.aid, next);
    if (!result.ok) return result.needLogin ? '请先登录' : (result.error || '点赞失败');
    state.liked = next;
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
      pages.search = 1;
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

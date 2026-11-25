(function () {
  var PORT = __PORT__;
  var TEST_FLOW = __TEST_FLOW__;
  function request(path) {
    try {
      var xhr = new XMLHttpRequest();
      xhr.open('GET', 'http://127.0.0.1:' + PORT + path, false);
      xhr.send(null);
      return xhr.responseText || '{}';
    } catch (error) {
      return JSON.stringify({ ok: false, error: String(error) });
    }
  }
  function call(name, params) {
    var parts = [];
    var data = params || {};
    for (var key in data) {
      if (Object.prototype.hasOwnProperty.call(data, key)) {
        parts.push(encodeURIComponent(key) + '=' + encodeURIComponent(String(data[key])));
      }
    }
    return request('/api/' + name + (parts.length ? '?' + parts.join('&') : ''));
  }
  function callAsync(name, params) {
    return new Promise(function (resolve, reject) {
      try {
        var parts = [];
        var data = params || {};
        for (var key in data) {
          if (Object.prototype.hasOwnProperty.call(data, key)) {
            parts.push(encodeURIComponent(key) + '=' + encodeURIComponent(String(data[key])));
          }
        }
        var xhr = new XMLHttpRequest();
        xhr.open('GET', 'http://127.0.0.1:' + PORT + '/api/' + name
          + (parts.length ? '?' + parts.join('&') : ''), true);
        xhr.onload = function () {
          if (xhr.status >= 200 && xhr.status < 400) resolve(xhr.responseText || '{}');
          else reject(new Error('HTTP ' + xhr.status));
        };
        xhr.onerror = function () { reject(new Error('network')); };
        xhr.send(null);
      } catch (error) {
        reject(error);
      }
    });
  }
  var rateCache = null;
  function displayRates() {
    var now = Date.now();
    if (rateCache && now - rateCache.at < 1000) return rateCache;
    var info = {};
    try { info = JSON.parse(call('displayHz', {})); } catch (error) { info = {}; }
    rateCache = {
      at: now,
      hz: Number(info.hz || 0),
      fps: Number(info.fps || 0)
    };
    return rateCache;
  }
  window.O11A1Native = {
    available: function () { return true; },
    version: function () { return '0.4.48-ios'; },
    popular: function (page, ps) { return call('popular', { page: page, ps: ps }); },
    recommend: function (page, ps, fresh) { return call('recommend', { page: page, ps: ps, fresh: fresh }); },
    search: function (keyword, page) { return call('search', { keyword: keyword, page: page }); },
    searchAsync: function (keyword, page) { return callAsync('search', { keyword: keyword, page: page }); },
    suggestAsync: function (term) { return callAsync('suggest', { term: term }); },
    play: function (bvid, cid) { return call('play', { bvid: bvid, cid: cid }); },
    playLow: function (bvid, cid) { return call('playLow', { bvid: bvid, cid: cid }); },
    previewUrlCached: function (bvid, cid) { return call('previewCached', { bvid: bvid, cid: cid }); },
    previewCached: function (bvid, cid) { return call('previewCached', { bvid: bvid, cid: cid }); },
    previewWarm: function () {},
    playQuality: function (bvid, cid, qn) { return call('playQuality', { bvid: bvid, cid: cid, qn: qn }); },
    playQualityAsync: function (bvid, cid, qn) { return callAsync('playQuality', { bvid: bvid, cid: cid, qn: qn }); },
    playPgc: function (epId, bvid, cid, qn) { return call('playPgc', { epId: epId, bvid: bvid, cid: cid, qn: qn }); },
    playPgcAsync: function (epId, bvid, cid, qn) { return callAsync('playPgc', { epId: epId, bvid: bvid, cid: cid, qn: qn }); },
    dashAsync: function (bvid, cid, qn) { return callAsync('dash', { bvid: bvid, cid: cid, qn: qn }); },
    videoInfoAsync: function (bvid) { return callAsync('videoInfo', { bvid: bvid }); },
    account: function () { return call('account', {}); },
    favorites: function (page) { return call('favorites', { page: page }); },
    history: function (page, cursor) { return call('history', { page: page, cursor: cursor }); },
    following: function (page) { return call('following', { page: page }); },
    space: function (mid, page, order) { return call('space', { mid: mid, page: page, order: order }); },
    dynamicFeed: function (page, filter) { return call('dynamicFeed', { page: page, filter: filter }); },
    messages: function (page, filter) { return call('messages', { page: page, filter: filter }); },
    ranking: function (page) { return call('ranking', { page: page }); },
    bangumi: function (page, type) { return call('bangumi', { page: page, type: type }); },
    season: function (seasonId) { return call('season', { seasonId: seasonId }); },
    live: function (page) { return call('live', { page: page }); },
    liveRoom: function (roomId) { return call('liveRoom', { roomId: roomId }); },
    liveDanmuInfo: function (roomId) { return call('liveDanmuInfo', { roomId: roomId }); },
    zone: function (rid, page) { return call('zone', { rid: rid, page: page }); },
    videoInfo: function (bvid) { return call('videoInfo', { bvid: bvid }); },
    related: function (bvid) { return call('related', { bvid: bvid }); },
    like: function (aid, on) { return call('like', { aid: aid, on: on ? 1 : 0 }); },
    coin: function (aid, count, likeAlso) { return call('coin', { aid: aid, count: count, likeAlso: likeAlso ? 1 : 0 }); },
    favorite: function (aid, on) { return call('favorite', { aid: aid, on: on ? 1 : 0 }); },
    follow: function (mid, on) { return call('follow', { mid: mid, on: on ? 1 : 0 }); },
    sendComment: function (aid, message) { return call('sendComment', { aid: aid, message: message }); },
    sendDanmaku: function (cid, message, progress) { return call('sendDanmaku', { cid: cid, message: message, progress: progress }); },
    comments: function (aid, page, sort) { return call('comments', { aid: aid, page: page, sort: sort }); },
    commentsReplies: function (aid, root, page) { return call('commentsReplies', { aid: aid, root: root, page: page }); },
    memberCenter: function () { return call('memberCenter', {}); },
    aiChat: function (endpoint, apiKey, model, prompt) { return call('aiChat', { endpoint: endpoint, apiKey: apiKey, model: model, prompt: prompt }); },
    dash: function (bvid, cid, qn) { return call('dash', { bvid: bvid, cid: cid, qn: qn }); },
    mediaStats: function () { return call('mediaStats', {}); },
    prewarmPreviews: function (json) {
      try {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', 'http://127.0.0.1:' + PORT + '/api/prewarm?items=' + encodeURIComponent(String(json || '[]')), true);
        xhr.send(null);
      } catch (error) {}
    },
    displayHz: function () { return displayRates().hz; },
    compositorFps: function () { return displayRates().fps; },
    copy: function (text) { return call('copy', { text: text }); },
    screenshot: function () { return call('screenshot', {}); },
    danmaku: function (cid) { return call('danmaku', { cid: cid }); },
    danmakuAsync: function (cid) { return callAsync('danmaku', { cid: cid }); },
    session: function () { return call('session', {}); },
    logout: function () { return call('logout', {}); },
    openWebLogin: function () { return call('webLogin', {}); },
    sendSmsCode: function (tel, cid) { return call('smsSendCode', { tel: tel, cid: cid }); },
    smsLogin: function (tel, cid, code, captchaKey) { return call('smsLogin', { tel: tel, cid: cid, code: code, captchaKey: captchaKey }); },
    nativePlayerLoad: function (slot, json) { return call('nativePlayerLoad', { slot: slot, json: json }); },
    nativePlayerControl: function (slot, action, value) { return call('nativePlayerControl', { slot: slot, action: action, value: value }); },
    nativePlayerRect: function (slot, x, y, w, h, visible, rotation) { return call('nativePlayerRect', { slot: slot, x: x, y: y, w: w, h: h, visible: visible ? 1 : 0, rotation: rotation || 0 }); },
    nativePlayerRelease: function (slot) { return call('nativePlayerRelease', { slot: slot }); },
    nativePlayerLayer: function (slot, background) { return call('nativePlayerLayer', { slot: slot, background: background ? 1 : 0 }); },
    nativePlayerState: function (slot) { return call('nativePlayerState', { slot: slot }); },
    playerSnapshot: function (slot) { return call('playerSnapshot', { slot: slot }); },
    brightness: function () { try { return Number(JSON.parse(call('brightness', {})).v || 0); } catch (error) { return 0; } },
    setBrightness: function (value) { return call('setBrightness', { v: value }); },
    restoreBrightness: function () { return call('restoreBrightness', {}); },
    volume: function () { try { return Number(JSON.parse(call('volume', {})).v || 0); } catch (error) { return 0; } },
    setVolume: function (value) { return call('setVolume', { v: value }); },
    setOrientation: function (mode) { return call('setOrientation', { mode: mode }); },
    proxyInfo: function () { return call('proxyInfo', {}); },
    log: function (message) { return call('log', { message: message }); }
  };
  if (TEST_FLOW) {
    setTimeout(function () {
      try {
        var host = window.O11A1Host;
        if (!host) return;
        host.state.loggedIn = true;
        host.save();
        host.showPage('home');
        if (TEST_FLOW === 'player' || TEST_FLOW === 'playerseek') {
          setTimeout(function () {
            try {
              var row = document.querySelector('#homeFeed .real-row');
              if (row) row.click();
            } catch (error) {}
          }, 3500);
          if (TEST_FLOW === 'playerseek') {
            setTimeout(function () {
              try { if (window.O11A1Media) window.O11A1Media.seek(25); } catch (error) {}
            }, 16000);
            setTimeout(function () {
              try { if (window.O11A1Media) window.O11A1Media.seek(60); } catch (error) {}
            }, 22000);
          }
        }
        if (TEST_FLOW === 'landscape') {
          setTimeout(function () {
            try {
              var row = document.querySelector('#homeFeed .real-row');
              if (row) row.click();
            } catch (error) {}
          }, 3500);
          setTimeout(function () {
            try { window.O11A1Host.setPlayerOrientation(1); } catch (error) {}
          }, 9000);
        }
        if (TEST_FLOW === 'theme') {
          setTimeout(function () {
            try {
              window.O11A1Host.state.settings.theme = '浅色';
              window.O11A1Host.save();
            } catch (error) {}
          }, 1800);
        }
        if (TEST_FLOW === 'dragsnapshot') {
          setTimeout(function () {
            try {
              var row = document.querySelector('#homeFeed .real-row');
              if (row) row.click();
            } catch (error) {}
          }, 3500);
          setTimeout(function () {
            try {
              window.O11A1Host.beginPlayerDragSnapshot();
              var player = document.querySelector('#player');
              if (player) {
                player.style.transition = 'none';
                player.style.transform = 'translateY(30%) scale(.84)';
                player.style.borderRadius = '44px';
              }
            } catch (error) {}
          }, 14000);
        }
        if (TEST_FLOW === 'dock') {
          setTimeout(function () {
            try {
              var row = document.querySelector('#homeFeed .real-row');
              if (row) row.click();
            } catch (error) {}
          }, 3500);
          setTimeout(function () {
            try { window.O11A1Host.addToPlaylist(); } catch (error) {}
          }, 12000);
          setTimeout(function () {
            try { window.O11A1Host.minimizePlayer(); } catch (error) {}
          }, 14000);
          setTimeout(function () {
            try { window.O11A1Host.setDockExpanded(true); } catch (error) {}
          }, 16000);
        }
        if (TEST_FLOW === 'minimize') {
          setTimeout(function () {
            try {
              var row = document.querySelector('#homeFeed .real-row');
              if (row) row.click();
            } catch (error) {}
          }, 3500);
          setTimeout(function () {
            try { window.O11A1Host.minimizePlayer(); } catch (error) {}
          }, 15000);
          setTimeout(function () {
            try {
              var dock = document.querySelector('#playlistDock');
              if (dock) dock.click();
            } catch (error) {}
          }, 17500);
        }
        if (TEST_FLOW === 'feedscroll') {
          var last = 0;
          var pump = function (ts) {
            if (ts - last > 15) {
              last = ts;
              var scroller = document.querySelector('#appScroll');
              if (scroller) {
                var max = Math.max(1, scroller.scrollHeight - scroller.clientHeight);
                var next = scroller.scrollTop + 4;
                scroller.scrollTop = next > max - 1200 ? Math.max(0, next - max) : next;
              }
            }
            requestAnimationFrame(pump);
          };
          requestAnimationFrame(pump);
        }
      } catch (error) {}
    }, 1500);
  }
})();

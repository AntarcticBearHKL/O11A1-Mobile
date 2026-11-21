import React, { useEffect, useState } from 'react';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { requireOptionalNativeModule } from 'expo-modules-core';
import { WebView } from 'react-native-webview';
import { WEBAPP_FILES } from './src/webapp.generated';

type BridgeModule = {
  start(files: Record<string, string>): Promise<number>;
  port(): number;
  testFlow(): string;
};

const NativeBridge = requireOptionalNativeModule('O11A1Bridge') as BridgeModule | null;

function bridgeShim(port: number, testFlow: string): string {
  return `
(function () {
  var PORT = ${JSON.stringify(port)};
  var TEST_FLOW = ${JSON.stringify(testFlow)};
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
  window.O11A1Native = {
    available: function () { return true; },
    version: function () { return '0.2.0-ios'; },
    popular: function (page, ps) { return call('popular', { page: page, ps: ps }); },
    search: function (keyword, page) { return call('search', { keyword: keyword, page: page }); },
    play: function (bvid, cid) { return call('play', { bvid: bvid, cid: cid }); },
    playLow: function (bvid, cid) { return call('playLow', { bvid: bvid, cid: cid }); },
    playQuality: function (bvid, cid, qn) { return call('playQuality', { bvid: bvid, cid: cid, qn: qn }); },
    playPgc: function (epId, bvid, cid, qn) { return call('playPgc', { epId: epId, bvid: bvid, cid: cid, qn: qn }); },
    account: function () { return call('account', {}); },
    favorites: function (page) { return call('favorites', { page: page }); },
    history: function (page, cursor) { return call('history', { page: page, cursor: cursor }); },
    following: function (page) { return call('following', { page: page }); },
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
    downloadStart: function (bvid, cid, title, pic, quality) { return call('downloadStart', { bvid: bvid, cid: cid, title: title, pic: pic, quality: quality }); },
    downloadList: function () { return call('downloadList', {}); },
    downloadRemove: function (id) { return call('downloadRemove', { id: id }); },
    downloadPause: function (id) { return call('downloadPause', { id: id }); },
    downloadResume: function (id) { return call('downloadResume', { id: id }); },
    copy: function (text) { return call('copy', { text: text }); },
    screenshot: function () { return call('screenshot', {}); },
    danmaku: function (cid) { return call('danmaku', { cid: cid }); },
    session: function () { return call('session', {}); },
    logout: function () { return call('logout', {}); },
    qrGenerate: function () { return call('qrGenerate', {}); },
    qrPoll: function (key) { return call('qrPoll', { key: key }); },
    openWebLogin: function () { return call('webLogin', {}); },
    setBrightness: function (value) { return call('setBrightness', { v: value }); },
    restoreBrightness: function () { return call('restoreBrightness', {}); },
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
        if (TEST_FLOW === 'player') {
          setTimeout(function () {
            try {
              var row = document.querySelector('#homeFeed .real-row');
              if (row) row.click();
            } catch (error) {}
          }, 3500);
        }
      } catch (error) {}
    }, 1500);
  }
})();
`;
}

const MOCK_BRIDGE = `
(function () {
  function cover(seed) {
    var colors = ['#2F7CF6', '#37B58B', '#F2665E', '#D99A3D', '#8B5CF6', '#0EA5E9'];
    var color = colors[String(seed).length % colors.length];
    var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="170">'
      + '<rect width="300" height="170" fill="' + color + '"/>'
      + '<rect x="10" y="10" width="280" height="150" rx="12" fill="rgba(255,255,255,.14)"/>'
      + '<text x="24" y="94" font-family="sans-serif" font-size="24" fill="#ffffff">UI ' + seed + '</text>'
      + '</svg>';
    return 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg);
  }
  function items(prefix, count) {
    var out = [];
    for (var i = 0; i < count; i += 1) {
      out.push({
        bvid: 'BVmock' + prefix + i,
        aid: 9000 + i,
        cid: 8000 + i,
        mid: 10001,
        title: prefix + ' · UI 调试视频 ' + (i + 1),
        pic: cover(prefix + (i + 1)),
        owner: 'O11A1 UI',
        duration: '12:34',
        durationSec: 754,
        pubdate: 1760000000 + i,
        play: 12000 + i * 317,
        playText: '1.2 万',
        desc: '这是 UI 调试模式的占位简介。',
        meta: 'O11A1 UI · 1.2 万 播放'
      });
    }
    return out;
  }
  var popular = items('推荐', 20);
  var ranking = items('排行', 20);
  var bangumi = [];
  for (var b = 0; b < 20; b += 1) {
    bangumi.push({
      kind: 'season', seasonId: 7001 + b, title: 'UI 番剧 ' + (b + 1),
      pic: cover('番剧' + (b + 1)), owner: '番剧', duration: '', bvid: '', aid: 0, cid: 0,
      meta: '全 12 话 · 9.5 分', badge: '番剧'
    });
  }
  var live = [];
  for (var l = 0; l < 20; l += 1) {
    live.push({
      kind: 'live', live: true, roomId: 5000 + l, title: 'UI 直播房间 ' + (l + 1),
      pic: cover('直播' + (l + 1)), owner: '主播 ' + (l + 1), mid: 10001,
      duration: 'LIVE', online: 12000 + l * 100, meta: '主播 ' + (l + 1) + ' · 1.2 万人气'
    });
  }
  function episodes(seasonId) {
    var out = [];
    for (var i = 0; i < 11; i += 1) {
      out.push({
        epId: 15000 + seasonId + i, bvid: 'BVmockEp' + seasonId + i,
        cid: 21000 + i, aid: 13000 + i, title: '第 ' + (i + 1) + ' 话',
        duration: '24:00', pic: cover('选集' + (i + 1))
      });
    }
    return out;
  }
  function dynamicFeed(filter) {
    var rows = [];
    for (var i = 0; i < 10; i += 1) {
      var kind = i % 3 === 0 ? 'video' : (i % 3 === 1 ? 'image' : 'text');
      if (filter === 'video' && kind !== 'video') continue;
      if (filter === 'image' && kind === 'video') continue;
      var row = {
        id: 'dyn' + i, type: 'DYNAMIC_TYPE', author: '动态用户 ' + (i + 1),
        avatar: cover('头像' + i), mid: 10001, time: 1760000000 - i * 3600,
        text: '这是 UI 调试模式下的动态正文 ' + (i + 1) + '。',
        images: kind === 'image' ? [cover('图' + i), cover('图' + (i + 1))] : [],
        likes: 12 + i, comments: 3 + i, kind: kind
      };
      if (kind === 'video') row.video = popular[i % popular.length];
      rows.push(row);
    }
    return rows;
  }
  function comments() {
    var out = [];
    for (var i = 0; i < 6; i += 1) {
      out.push({
        rpid: 32000 + i, root: 0, rcount: i === 0 ? 5 : 0,
        user: '评论用户 ' + (i + 1), avatar: cover('评论' + i),
        message: '这是 UI 调试评论 ' + (i + 1) + '，用来检查最热/最新、楼中楼和分页布局。',
        like: 20 - i, time: 1760000000 - i * 600
      });
    }
    return out;
  }
  function replies() {
    var out = [];
    for (var i = 0; i < 5; i += 1) {
      out.push({
        rpid: 33000 + i, root: 32000, parent: 32000,
        user: '回复用户 ' + (i + 1), avatar: cover('回复' + i),
        message: '楼中楼回复 ' + (i + 1) + '，检查缩进与展开收起。',
        like: i, time: 1760000000 - i * 300
      });
    }
    return out;
  }
  var danmaku = [];
  for (var d = 1; d <= 40; d += 1) {
    danmaku.push({ t: d * 2, mode: 1, color: 16777215, text: 'UI 弹幕 ' + d });
  }
  window.O11A1Native = {
    available: function () { return true; },
    version: function () { return '0.3.0-ui-mock'; },
    log: function () {},
    popular: function (page, ps) { return JSON.stringify({ ok: true, items: popular.slice(0, ps || 20), page: page || 1 }); },
    search: function (keyword, page) { return JSON.stringify({ ok: true, items: items('搜索', 20), page: page || 1 }); },
    ranking: function (page) { return JSON.stringify({ ok: true, items: ranking, page: page || 1, total: 100 }); },
    bangumi: function (page, type) { return JSON.stringify({ ok: true, items: bangumi, page: page || 1 }); },
    season: function (seasonId) { return JSON.stringify({ ok: true, seasonId: seasonId, title: 'UI 番剧 ' + seasonId, cover: cover('番剧'), episodes: episodes(seasonId) }); },
    live: function (page) { return JSON.stringify({ ok: true, items: live, page: page || 1 }); },
    liveRoom: function () { return JSON.stringify({ ok: false, error: 'UI 调试模式不加载直播' }); },
    zone: function (rid, page) { return JSON.stringify({ ok: true, items: items('分区', 20), page: page || 1, title: 'UI 分区' }); },
    favorites: function (page) { return JSON.stringify({ ok: true, items: items('收藏', 20), page: page || 1, count: 20, title: '收藏夹' }); },
    history: function (page) { return JSON.stringify({ ok: true, items: items('历史', 20), page: page || 1, next: '', title: '历史' }); },
    following: function (page) { return JSON.stringify({ ok: true, items: items('关注', 20), page: page || 1 }); },
    dynamicFeed: function (page, filter) { return JSON.stringify({ ok: true, items: dynamicFeed(filter), page: page || 1 }); },
    messages: function (page, filter) { return JSON.stringify({ ok: true, items: [0,1,2,3,4,5].map(function (i) { return { user: '消息用户 ' + (i + 1), avatar: cover('消息' + i), text: '这是一条 UI 调试消息 ' + (i + 1), kind: filter || 'reply', unread: i % 2 === 0, time: 1760000000 - i * 600 }; }), page: page || 1 }); },
    account: function () { return JSON.stringify({ ok: true, loggedIn: false, hasSession: false, name: '', face: '', mid: 0, level: 0, vip: false, vipLabel: '', coins: 0, sign: '' }); },
    session: function () { return JSON.stringify({ ok: true, loggedIn: false }); },
    logout: function () { return JSON.stringify({ ok: true }); },
    qrGenerate: function () { return JSON.stringify({ ok: false, error: 'UI 调试模式不使用二维码' }); },
    qrPoll: function () { return JSON.stringify({ ok: false, error: 'UI 调试模式不使用二维码' }); },
    openWebLogin: function () { return JSON.stringify({ ok: false, error: 'UI 调试模式：请点「本地测试进入」' }); },
    play: function () { return JSON.stringify({ ok: false, error: 'UI 调试模式不加载视频' }); },
    playLow: function () { return JSON.stringify({ ok: false, error: 'UI 调试模式不加载视频' }); },
    playQuality: function () { return JSON.stringify({ ok: false, error: 'UI 调试模式不加载视频' }); },
    playPgc: function () { return JSON.stringify({ ok: false, error: 'UI 调试模式不加载视频' }); },
    dash: function () { return JSON.stringify({ ok: false, error: 'UI 调试模式不加载 DASH' }); },
    danmaku: function () { return JSON.stringify({ ok: true, items: danmaku }); },
    comments: function (aid, page, sort) { return JSON.stringify({ ok: true, items: comments(), count: 128, page: page || 1, hasMore: true }); },
    commentsReplies: function () { return JSON.stringify({ ok: true, items: replies(), count: 5, page: 1 }); },
    videoInfo: function (bvid) { return JSON.stringify({ ok: true, bvid: bvid || 'BVmock', aid: 9000, cid: 8000, mid: 10001, owner: 'O11A1 UI', ownerFace: cover('UP'), title: 'UI 调试视频信息', desc: '这是 UI 调试模式的视频简介。', pic: cover('信息'), duration: '12:34', durationSec: 754, stat: { view: 12000, danmaku: 123, reply: 45, favorite: 67, coin: 89, share: 10, like: 100 }, pages: [{ cid: 8000, page: 1, title: 'P1', duration: 754 }] }); },
    like: function () { return JSON.stringify({ ok: false, needLogin: true, error: 'UI 调试模式不写入账号' }); },
    favorite: function () { return JSON.stringify({ ok: false, needLogin: true, error: 'UI 调试模式不写入账号' }); },
    coin: function () { return JSON.stringify({ ok: false, needLogin: true, error: 'UI 调试模式不写入账号' }); },
    follow: function () { return JSON.stringify({ ok: false, needLogin: true, error: 'UI 调试模式不写入账号' }); },
    sendComment: function () { return JSON.stringify({ ok: false, needLogin: true, error: 'UI 调试模式不写入账号' }); },
    sendDanmaku: function () { return JSON.stringify({ ok: false, needLogin: true, error: 'UI 调试模式不写入账号' }); },
    memberCenter: function () { return JSON.stringify({ ok: true, vip: false, tasks: [{ key: 'login', label: '每日登录', done: true, reward: 5 }, { key: 'watch', label: '每日观看', done: false, reward: 5 }, { key: 'share', label: '每日分享', done: false, reward: 5 }, { key: 'coins', label: '每日投币', done: false, reward: 50, detail: '已获得 0 / 50 经验' }], log: [{ delta: 5, reason: '登录奖励', time: '2026-11-22 08:00:00' }] }); },
    aiChat: function () { return JSON.stringify({ ok: false, needKey: true, error: 'UI 调试模式不请求 AI' }); },
    downloadList: function () { return JSON.stringify({ ok: true, items: [], storage: 0, count: 0 }); },
    downloadStart: function () { return JSON.stringify({ ok: false, error: 'UI 调试模式不下载' }); },
    downloadDash: function () { return JSON.stringify({ ok: false, error: 'UI 调试模式不下载' }); },
    downloadRemove: function () { return JSON.stringify({ ok: true }); },
    downloadPause: function () { return JSON.stringify({ ok: true }); },
    downloadResume: function () { return JSON.stringify({ ok: false, error: 'UI 调试模式不下载' }); },
    mediaStats: function () { return JSON.stringify({ ok: true, bytes: 0, requests: 0 }); },
    copy: function () { return JSON.stringify({ ok: false, error: 'UI 调试模式不复制' }); },
    screenshot: function () { return JSON.stringify({ ok: false, error: 'UI 调试模式不截图' }); },
    setBrightness: function () {},
    restoreBrightness: function () {},
    setOrientation: function () {},
    liveDanmuInfo: function () { return JSON.stringify({ ok: false, error: 'UI 调试模式不加载直播弹幕' }); }
  };
})();
`;

function buildMockHtml(files: Record<string, string>): string {
  let html = files['index.html'] || '';
  html = html.replace(/<link[^>]*styles\.css[^>]*>/, () => `<style>${files['styles.css'] || ''}</style>`);
  html = html.replace(/<script[^>]*vendor\/hls[^>]*><\/script>/, () => '');
  html = html.replace(/<script[^>]*app\.js[^>]*><\/script>/, () => `<script>${files['app.js'] || ''}</script>`);
  html = html.replace(/<script[^>]*native\.js[^>]*><\/script>/, () => `<script>${files['native.js'] || ''}</script>`);
  html = html.replace('</head>', () => `<script>${MOCK_BRIDGE}</script></head>`);
  return html;
}

const MOCK_HTML = NativeBridge ? null : buildMockHtml(WEBAPP_FILES);

export default function App() {

  const [config, setConfig] = useState<{ port: number; testFlow: string } | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    if (!NativeBridge) return () => { active = false; };
    (async () => {
      try {
        const port = await NativeBridge.start(WEBAPP_FILES);
        let testFlow = '';
        try {
          testFlow = NativeBridge.testFlow();
        } catch {
          testFlow = '';
        }
        if (active) setConfig({ port, testFlow });
      } catch (cause) {
        if (active) setError(cause instanceof Error ? cause.message : String(cause));
      }
    })();
    return () => {
      active = false;
    };
  }, []);

  if (!NativeBridge && MOCK_HTML) {
    return (
      <View style={styles.root}>
        <StatusBar hidden />
        <WebView
          source={{ html: MOCK_HTML, baseUrl: 'https://o11a1.local/' }}
          style={styles.web}
          containerStyle={styles.web}
          originWhitelist={['*']}
          javaScriptEnabled
          domStorageEnabled
          allowsInlineMediaPlayback
          mediaPlaybackRequiresUserAction={false}
          mixedContentMode="always"
          allowFileAccess
          bounces={false}
          scrollEnabled={false}
          setSupportMultipleWindows={false}
        />
        <View style={styles.mockBadge} pointerEvents="none">
          <Text style={styles.mockBadgeText}>UI MOCK · 无视频 / 无账号</Text>
        </View>
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.center}>
        <StatusBar hidden />
        <Text style={styles.title}>O11A1</Text>
        <Text style={styles.error}>{error}</Text>
      </View>
    );
  }

  if (!config) {
    return (
      <View style={styles.center}>
        <StatusBar hidden />
        <Text style={styles.title}>O11A1</Text>
        <ActivityIndicator color="#B4453A" />
      </View>
    );
  }

  const { port, testFlow } = config;

  return (
    <View style={styles.root}>
      <StatusBar hidden />
      <WebView
        source={{ uri: `http://127.0.0.1:${port}/index.html` }}
        style={styles.web}
        containerStyle={styles.web}
        originWhitelist={['*']}
        javaScriptEnabled
        domStorageEnabled
        allowsInlineMediaPlayback
        allowsPictureInPictureMediaPlayback={false}
        mediaPlaybackRequiresUserAction={false}
        injectedJavaScriptBeforeContentLoaded={bridgeShim(port, testFlow)}
        onShouldStartLoadWithRequest={(request) =>
          request.url.startsWith(`http://127.0.0.1:${port}`) || request.url.startsWith('about:')
        }
        bounces={false}
        scrollEnabled={false}
        contentInsetAdjustmentBehavior="never"
        automaticallyAdjustContentInsets={false}
        setSupportMultipleWindows={false}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#F4EFE5',
  },
  web: {
    flex: 1,
    backgroundColor: '#F4EFE5',
  },
  mockBadge: {
    position: 'absolute',
    top: 46,
    left: 12,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 7,
    backgroundColor: 'rgba(12,14,19,.72)',
    zIndex: 20,
  },
  mockBadgeText: {
    color: '#9FB3CC',
    fontSize: 9,
    fontWeight: '700',
    letterSpacing: 0.4,
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#F4EFE5',
    gap: 18,
    padding: 32,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    letterSpacing: 3,
    color: '#171410',
  },
  error: {
    fontSize: 13,
    lineHeight: 20,
    color: '#8A3A31',
    textAlign: 'center',
  },
});

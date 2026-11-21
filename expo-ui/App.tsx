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
    zone: function (rid, page) { return call('zone', { rid: rid, page: page }); },
    videoInfo: function (bvid) { return call('videoInfo', { bvid: bvid }); },
    like: function (aid, on) { return call('like', { aid: aid, on: on ? 1 : 0 }); },
    coin: function (aid, count, likeAlso) { return call('coin', { aid: aid, count: count, likeAlso: likeAlso ? 1 : 0 }); },
    favorite: function (aid, on) { return call('favorite', { aid: aid, on: on ? 1 : 0 }); },
    follow: function (mid, on) { return call('follow', { mid: mid, on: on ? 1 : 0 }); },
    sendComment: function (aid, message) { return call('sendComment', { aid: aid, message: message }); },
    sendDanmaku: function (cid, message, progress) { return call('sendDanmaku', { cid: cid, message: message, progress: progress }); },
    comments: function (aid, page, sort) { return call('comments', { aid: aid, page: page, sort: sort }); },
    copy: function (text) { return call('copy', { text: text }); },
    screenshot: function () { return call('screenshot', {}); },
    danmaku: function (cid) { return call('danmaku', { cid: cid }); },
    session: function () { return call('session', {}); },
    logout: function () { return call('logout', {}); },
    qrGenerate: function () { return call('qrGenerate', {}); },
    qrPoll: function (key) { return call('qrPoll', { key: key }); },
    setBrightness: function (value) { return call('setBrightness', { v: value }); },
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

export default function App() {
  const [config, setConfig] = useState<{ port: number; testFlow: string } | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    (async () => {
      try {
        if (!NativeBridge) {
          throw new Error('O11A1Bridge 原生模块未加载，请使用原生 iOS 构建。');
        }
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

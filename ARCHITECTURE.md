# O11A1 architecture

Last updated: 2026-11-26

## 1. Runtime topology

```
                    ┌─────────────────────────────────────────┐
                    │ web-prototype (the only UI)             │
                    │ index.html + styles.css + fonts.css     │
                    │ app.js        shell, pages, gestures    │
                    │ native.js     feed/media/bridge logic   │
                    │ native-player.js  <video> ⇄ native player│
                    └───────────────┬─────────────────────────┘
                                    │ window.O11A1Native
              ┌─────────────────────┴──────────────────────┐
              │ iOS WKWebView                              │ Android WebView
              │ ios-native/O11A1App.swift                  │ app/.../MainActivity.java
              │   · launch overlay / login hand-off        │   · WebView settings
              │   · haptic, brightness, orientation        │   · JS bridge registration
              │   · WKURLSchemeHandler-free local server   │
              │ bridge.js → 127.0.0.1 HTTP                 │ WebAppBridge (@JavascriptInterface)
              │ O11A1LocalServer                           │ BiliApi / BiliExtras
              │ O11A1BiliClient (URLSession)               │ CookieStore (HttpURLConnection)
              │ O11A1Player (AVPlayer + DASH audio)        │ NativePlayerHost (ExoPlayer)
              │ O11A1MediaLoader (byte-range DASH)         │
              └────────────────────────────────────────────┘
```

Both platforms render the same HTML/CSS/JS. Platform differences are confined to
the native shell, the bridge transport, and the native player. The Web layer
must never branch on platform for layout; it may branch only for capabilities
(`NATIVE_MEDIA`, async bridge availability).

## 2. Shared UI layer

| File | Size | Responsibility |
| --- | --- | --- |
| `index.html` | 30 KB | Static shell: app pages, player chrome, search panel, sheets, sidebar, launch overlay. |
| `styles.css` | 153 KB | Design system, glass, feed card, toolbar, player controls and wheel, transitions. |
| `fonts.css` | 5.2 MB | Embedded icon/emoji font subset. Loaded locally, not network. |
| `app.js` | 286 KB | App shell: persistence, theme, navigation, feed window, login, player chrome, gestures, comments panel, search, sheets, keyboard, event wiring. |
| `native.js` | 210 KB | Native-only behaviour: real feed, previews, media/DASH, comments, detail cache, background preload, search, account, dynamic/messages, quality. Bails out immediately when no native bridge exists. |
| `native-player.js` | 21 KB | Adapter between `<video>` elements and `O11A1NativeMedia`; rect sync, visibility, lifecycle. |

### app.js sections

| Lines | Section |
| --- | --- |
| 1–654 | element lookup, state, helpers |
| 655–715 | persistence (localStorage + native prefs) |
| 716–831 | appearance / theme |
| 832–945 | navigation pages |
| 946–1254 | toolbar follow-scroll hide/show |
| 1255–1757 | login (SMS, native hand-off) |
| 1758–1971 | feed window / mock feed (web prototype only) |
| 1972–2125 | home modules, hidden entries, bottom-nav editor |
| 2126–3134 | playlist dock/page/reorder — **retired UI, still in code** |
| 3135–3253 | live sidebar drag |
| 3254–4070 | player chrome, wheel, quality, orientation, debug HUD |
| 4071–4760 | player orientation / landscape |
| 4761–5018 | video detail overlay, comments panel |
| 5019–5542 | player gesture state machine, sheets |
| 5543–6021 | external keyboard |
| 6022–6186 | search panel |
| 6187–6261 | prototype drawer (web review only) |
| 6262–7556 | event wiring |
| 7557–end | native host bridge contract |

### native.js sections

| Lines | Section |
| --- | --- |
| 1–124 | bridge, helpers, text formatting |
| 125–725 | feed rows, skeletons, window state, deferLoading |
| 726–2174 | focused-card preview, preview preload, player prewarm, page preload |
| 2175–2574 | member center, fish config |
| 2575–3169 | media, danmaku, live danmaku |
| 3170–4087 | DASH via MediaSource / native DASH hand-off |
| 4088–4283 | video-info cache, comments cache/prefetch |
| 4284–4916 | background preload, page cache, video detail |
| 4917–5176 | account, dynamic, messages |
| 5177–5514 | player info, like/fav/coin/follow, search |
| 5515–end | search toggle, first data load |

## 3. Loading flows

### Launch

1. Native shell creates the WebView and injects `bridge.js` (iOS) or registers
   `O11A1Native` (Android).
2. `app.js` restores persisted prefs and paints the launch overlay. On iOS the
   native launch overlay is used instead, with cached avatar and progress.
3. `native.js` boots, marks `body.native-app`, loads the account (30 s cache),
   then `loadHome(1)` after 120 ms.
4. `primeNavSkeleton` paints navigation skeletons synchronously before a tab
   page switch so the first frame is never blank.

### Feed page

1. `loadHome(page)` picks the module API and calls `feedResult` → bridge.
2. Rows are rendered in blocks of `FEED_BLOCK_SIZE`; only three blocks are kept
   in the DOM (`FEED_WINDOW_BLOCKS`). Scrolling advances the window without
   re-fetching already loaded pages.
3. Next page is requested when the scroll is within `FEED_PREFETCH` (900 px) of
   the end, or when the queue is empty. Requests are skipped while the player is
   open and while a finger/fling is active.
4. Dynamic/messages pages load once and are reused on later tab switches.

### Focused-card preview

1. On scroll settle, the row nearest the viewport centre becomes the preview
   row; only one video is mounted.
2. `previewCached` checks the native preview cache (10 min TTL). A miss queues a
   bounded prewarm (max 3 rows per block) and returns empty; the preview is
   attached when the cache fills.
3. Preload is paused while scrolling, while the player is open, and when any
   overlay (comments, detail, sheets) covers the feed.

### Player open

1. Tap passes the item to `openPlayer`; the poster/preview stays visible while
   metadata loads.
2. `dashAsync` (iOS) / `dash` (Android) returns quality tracks; `playQuality`
   returns the play URL. Both are cached in the Web layer and in the native
   server, and in-flight requests are coalesced.
3. Native player starts video immediately; for DASH, audio is mounted muted in
   parallel and handed off when ready.
4. Background preloads (comments, video info, next preview) are scheduled only
   after the player is open and are cancelled when the item changes.

## 4. Network budget

| Priority | Traffic | Rule |
| --- | --- | --- |
| P0 | Player manifest / play URL / DASH segments | Never blocked; prefetch pauses while the player is open. |
| P1 | First feed page, focused preview | Immediate, deduplicated. |
| P2 | Next feed page, neighbour preview | Only when scroll is idle and within 900 px of the end; max 3 preview warms per block. |
| P3 | Comments, video info, detail page | Deferred 120–400 ms after the player opens; 5 min page cache. |
| P4 | Account, suggestions, static metadata | Cached with TTL; suggestions debounced 320 ms. |

### Caches (Web layer)

| Cache | TTL | Bound |
| --- | --- | --- |
| `previewUrlCache` | 10 min | 120 |
| `playInfoCache` (play URL) | 4 min | 80 |
| `dashInfoCache` (tracks) | 4 min | 60 |
| `videoInfoCache` | 5 min | bounded |
| `commentCache` | 5 min | bounded |
| `preloadPages` | 5 min | 32 |
| `qualityOptionsCache` | 4 min | per item |
| `searchCache` | in-memory | bounded |

### Caches (native)

iOS `O11A1LocalServer`: preview 10 min/80, quality 4 min, dash 4 min, suggest
80 entries, danmaku 10 min/80.
Android `WebAppBridge`: preview 10 min, quality 4 min, dash 4 min, with
`*Loading` sets that coalesce concurrent requests.

## 5. Bridge contract

`window.O11A1Native` is the single JS surface.

- Synchronous methods return a JSON string. Used for cached/local reads and
  one-off actions (like, follow, coin, copy, screenshot).
- `*Async` methods return a Promise and are used for player metadata and any
  path that must not block the WebView thread. iOS exposes them through
  `bridge.js` (`callAsync` → async XHR to the loopback server). Android
  currently exposes only the synchronous form; `bridgeCallMaybe` falls back
  automatically.

### Capability flags

- `window.O11A1NativeMedia` — native player available.
- `window.O11A1Media` — adapter API for play/pause/seek/rate.
- `window.ReactNativeWebView` — iOS shell message channel (haptics, prefs,
  brightness, orientation).
- `window.O11A1Native.haptic` — Android haptic (added in this pass).

## 6. Cross-platform parity

| Area | iOS | Android | Status |
| --- | --- | --- | --- |
| UI / layout | shared web | shared web | identical |
| Bottom toolbar inset | 6 px | 6 px | fixed |
| Haptics (2× hold) | UIImpactFeedbackGenerator | Vibrator one-shot | matched this pass |
| Launch overlay | native avatar/progress | HTML launch overlay | differs (by design, iOS needs credentials first) |
| Player | AVPlayer + DASH audio | ExoPlayer | different engine, same contract |
| Metadata transport | loopback HTTP + async | direct JNI, sync | async parity pending |
| Preview cache | server-side | bridge-side | same TTL/behaviour |
| Quality labels | same merge logic | same merge logic | identical |
| Version string | `0.4.85-ios` | `0.4.85-android` | matched this pass |
| Asset cache | `Cache-Control: no-store` | query stamp per build | matched this pass |

## 7. Changes in this pass

### Network

- Web `dashInfoCache` + `dashInfoPending`: deduplicates quality discovery and
  player-open dash requests; 4 min TTL, 60 entries.
- `playInfoCache`: async play-URL requests are now coalesced per item/quality
  and the cache is bounded to 80.
- `previewUrlCache` is bounded to 120 in both write paths.
- Preview prewarm is limited to 3 rows per appended block and skipped while the
  player is open.
- Feed next-page prefetch and buffer fill are skipped while the player is open.
- Entering the module, dynamic and messages tabs no longer refetches data that
  is already on screen; the observer checks for rendered rows first.
- Cache clear on logout clears every new map/set.
- iOS API session: 8 connections per host, `waitsForConnectivity`,
  `.responsiveData` service type.
- Android API transport: gzip is accepted again and connections are no longer
  disconnected after each request, restoring keep-alive reuse.

### Cleanup

- Removed unused `nativeUrl`, `nativeBackup`, `playerDragSnapshot`,
  `playQualityCached`, `previewWarm` (no-op on both platforms),
  `previewUrlCached`, `warmPreviewPrefix`, `warmFocusPreview`,
  `prewarmPreviewItems` burst behaviour, `feedTime`, `previewPlaybackRate`,
  `prefetchPlayInfo`.
- Removed the retired sidebar drag-to-select path (never enabled), its `.picked`
  CSS, and the 5 related helpers.
- Removed the 673-line gesture self-test and `?demo=` review modes from
  `app.js`; they referenced the retired playlist dock and could not run on
  device.
- Removed the dead rate HUD (markup, JS, CSS) left over from the old left/right
  hold gesture; 2× hold is now the only rate gesture and has no HUD.
- Removed other single-use leftovers: `playlistOwnerName`, `setPlaylistDisc`,
  `pulsePlaylistDock`, `showMiniPlayer`, `setPlayerDropZone`, `showPlayerDrop`,
  `firePlayerDropZone`, `openPlayerSideSheet`, `enterDockSearch`.

### Parity

- Android `haptic(style)` bridge + `VIBRATE` permission; `triggerHaptic` prefers
  it, then the iOS message channel, then `navigator.vibrate`.
- Android `version()` and the WebView User-Agent now read the installed
  `versionName` instead of a hard-coded `0.2.0`; both platforms report the real
  build.
- Android `syncWebAssets` stamps every `?v=` asset URL with the current
  `versionName`, so a new build never runs JavaScript or CSS from the WebView's
  previous cache. iOS already serves static files with `Cache-Control:
  no-store`.

### Verified on the Android emulator (0.4.85 / 103)

- Home feed loads 20 real rows; card is edge-to-edge (411 px on a 411 px
  viewport), bottom radius 14 px, glass footer 80 px, avatar 50 px.
- Toolbar is 383 × 72 px with a 6 px bottom inset.
- Avatar tap opens the UP page with 20 rows.
- Player autoplays; long-press 2× measured 1.96× for 2 s and restored to 1.05×.
- Wheel: controls 92 px, wheel 48 px, long tick 29 px, needle 48 px, tick-label
  gap 14 px.
- Pull-down drag keeps playback running, reveals 260–380 px of feed, clips a
  matching hole in `.app-main`, and closes on release.
- Left swipe on the feed opens search with the input focused; a query returns
  20 rows.
- `O11A1Native.haptic('light')` returns `{ok:true}`.
- No JS exceptions or fatal native errors in logcat.

## 8. Remaining work

1. **Async bridge on Android.** Add a generic `request(id, name, args)` that
   runs on an executor and answers through `evaluateJavascript`. Then make
   `bridgeCallMaybe` use it for feed/comments/detail. This removes the last
   blocking JNI calls from the UI thread.
2. **Retire playlist state.** Replace `state.playlist[currentIndex]` with
   `currentItem()` / `setCurrentItem()`, delete the dock/page/reorder markup,
   CSS and handlers (about 1,000 lines in `app.js`). High touch count; needs
   device verification.
3. **Native transport parity.** Move iOS-only haptics/launch messages into a
   documented capability contract; add matching Android handlers.
4. **Server-side concurrency limit.** The iOS local server currently dispatches
   each API request to the global queue; a semaphore (6–8) would cap bursts
   without touching the player path.
5. **Release verification.** Wheel height, card footer, avatar → UP, pull-down
   reveal, autoplay and 1080P/4K DASH still need an iPhone run.

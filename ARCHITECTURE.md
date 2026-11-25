# Native architecture

## Layers

```
iOS                                  Android
┌──────────────────────────┐         ┌──────────────────────────┐
│ UIKit view controllers   │         │ Activity + native Views  │
│ Feed / Player / Search   │         │ FeedView / PlayerOverlay │
├──────────────────────────┤         ├──────────────────────────┤
│ BiliAPI (async wrapper)  │         │ BiliApi / BiliExtras      │
│ O11A1BiliClient          │         │ CookieStore               │
├──────────────────────────┤         ├──────────────────────────┤
│ VideoEngine (AVPlayer)   │         │ VideoEngine (ExoPlayer)   │
│ AVKit PiP                │         │ System PiP               │
└──────────────────────────┘         └──────────────────────────┘
```

There is no local HTTP server and no WebView in either platform. UI code calls
the Bilibili clients and native players directly.

## iOS

- `O11A1App.swift` — `AppDelegate`, window, audio session.
- `RootViewController.swift` — tab container and player presentation.
- `FeedViewController.swift` — vertical paging feed, preview autoplay, toolbar
  hide/show, left-swipe search gesture.
- `VideoCardCell.swift` — edge-to-edge card, dark glass panel, avatar, footer.
- `PlayerViewController.swift` — full-screen player, pull-down window, scrub
  wheel, long-press 2x, comments.
- `VideoEngine.swift` — `AVPlayer`, progressive media, KVO progress, looping,
  AVKit PiP.
- `BiliAPI.swift` — async facade over `O11A1BiliClient`.
- `LoginViewController.swift` — native QR login using CoreImage.
- `SearchViewController.swift`, `VideoListViewController.swift`,
  `SettingsViewController.swift`, `CommentsViewController.swift`.
- `Theme.swift` / `ThemeManager.swift` — pure white/black palette and dynamic
  colours.

Media URLs are requested through `O11A1BiliClient.playLow` (360P preview) and
`playQuality` (720P/1080P progressive). `AVURLAssetHTTPHeaderFieldsKey` carries
the Bilibili Referer/Origin/User-Agent/Cookie headers. No proxy is used.

## Android

- `MainActivity.java` — native root, tab switching, player overlay, PiP.
- `FeedView.java` — `ViewPager2` feed, shared preview engine, horizontal search
  drag, pagination.
- `VideoPageView.java` — card layout, cover, dark glass panel, footer.
- `PlayerOverlay.java` — full-screen player, pull-down window, long-press 2x,
  48dp progress wheel, PiP mode.
- `VideoEngine.java` — ExoPlayer + Media3; direct CDN requests with headers.
- `BiliApi.java` / `BiliExtras.java` / `CookieStore.java` — API and session.
- `LoginDialog.java` — native QR login using ZXing.
- `SearchView.java`, `VideoListView.java`, `VideoRowAdapter.java`,
  `GlassTabBarView.java`, `NativeTheme.java`.

## Playback flow

1. Feed loads recommendation JSON from the native API client.
2. The focused card resolves a 360P progressive URL (`qn=16`) and attaches a
   native player view inside the card. Preview is muted and loops.
3. Tapping the card resolves 720P/1080P progressive media and opens the native
   player overlay/controller. The preview player stops.
4. Pulling down shrinks the native video view into a window over the still
   visible feed. Closing the window stops and releases playback; it never starts
   PiP.
5. Backgrounding while playing:
   - iOS AVKit starts PiP automatically from the inline layer.
   - Android `onUserLeaveHint` calls `enterPictureInPictureMode` only when the
     main player is playing.
6. Restoring from PiP returns to the player. Closing PiP stops playback.

## Theming

`NativeTheme` / `Theme` expose pure white (`#FFFFFF`) and pure black (`#000000`)
backgrounds, neutral glass panels and dynamic foreground colours. Media overlays
use a dark material so white text stays readable over bright video. The theme
choice is stored in native preferences.

## Data and auth

Cookies are stored in the native cookie stores (`UserDefaults` on iOS,
`SharedPreferences` on Android). QR login polls the Bilibili passport endpoint,
imports the returned `SESSDATA`/`bili_jct`/`DedeUserID` cookies, and never opens
a web login page.

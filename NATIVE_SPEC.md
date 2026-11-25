# O11A1 Native App Specification

This document is the single source of truth for the iOS and Android native
rewrite. The app must not contain a WebView, HTML, CSS, JavaScript, or any web
runtime. Both platforms implement the same screens, labels, spacing and
behaviour with native UI toolkits.

## Hard rules

- iOS: Swift + UIKit + AVFoundation only. No `WKWebView`, no bundled web assets.
- Android: Java + Android Views + Media3/ExoPlayer only. No `WebView`, no
  `assets/web`, no JavaScript bridge.
- Data comes from the existing native Bilibili clients:
  - iOS: `O11A1BiliClient`
  - Android: `BiliApi` / `BiliExtras`
- Cookies and session stay in the native cookie stores.
- Playback is native on both platforms. No website or local HTTP server is in
  the media path.

## Shared information architecture

Bottom bar, left to right:

1. 推荐 (`Recommend`)
2. 关注 (`Following`)
3. 动态 (`Dynamic`)
4. 养鱼 (`Fish`)

The bar is glass, nearly full width, sits 12 dp/pt above the safe-area bottom,
and hides/shows with a 0.75 s animation while scrolling.

### Feed

- One video per screen, edge-to-edge.
- Muted, looping preview of the focused card. Preview uses 360P progressive
  MP4 (`qn=16`). It starts only when the card is centred and the feed is idle.
- Glass information panel over the bottom of the video, 14 dp/pt bottom radius.
- Three-column footer inside the panel:
  - left: UP name
  - centre: play count, coloured by magnitude
  - right: duration
- 50 dp/pt avatar; tapping it opens the UP page.
- Play-count colours:
  - `< 10,000`: secondary text
  - `10,000 ..< 100,000`: `#4C9AFF`
  - `100,000 ..< 1,000,000`: `#FF9F43`
  - `>= 1,000,000`: `#FF5C8A`
- Left-edge horizontal drag opens search and tracks the finger 1:1. Commit at
  26% width or a fast left flick.

### Player

- Opens from the focused card; native AVPlayer / ExoPlayer.
- Full-screen video; web-style black backdrop is forbidden.
- Pull down shrinks the player into a window over the still-visible feed.
  Dragging up restores it. Closing stops playback. Closing must never enter PiP.
- Long-press anywhere on the video: 2x speed + light haptic. Release restores
  1x. No HUD.
- Progress wheel: 48 dp/pt tall, proportional ticks, labels and needle.
- Paused letterbox edges use pale rose (`#FFD9DE`), not black.
- PiP starts only when the app is backgrounded while the video is playing.
  Restoring from PiP reopens the player; closing PiP stops playback.
- Android: `onUserLeaveHint` enters PiP only if the main player is playing.
- iOS: `canStartPictureInPictureAutomaticallyFromInline = true` plus an
  explicit background fallback.

### Themes

- Light: pure `#FFFFFF` background, black text.
- Dark: pure `#000000` background, white text.
- Glass panels are neutral; no yellow/cream tint.
- No background-transparency or blur sliders.

## Native screen map

| Screen | iOS | Android |
| --- | --- | --- |
| Root + tabs | `RootViewController` | `MainActivity` |
| Feed | `FeedViewController` | `FeedView` |
| Player | `PlayerViewController` | `PlayerView` overlay |
| Search | `SearchViewController` | `SearchView` |
| UP page | `ProfileViewController` | `ProfileView` |
| Comments | `CommentsViewController` | `CommentsView` |
| Settings | `SettingsViewController` | `SettingsView` |
| Login | `LoginViewController` (native QR) | `LoginActivity` (native QR) |

## Shared data contract

Feed item fields: `bvid`, `aid`, `cid`, `mid`, `title`, `pic`, `owner`,
`ownerFace`, `duration`, `durationSec`, `play`, `playText`, `desc`.

Playback:
- Preview: `playLow(bvid, cid)` -> `url`, `backup`, `quality`.
- Full: `playQuality(bvid, cid, qn)` -> `url`, `backup`, `quality`,
  `qualityLabel`. Start at 720P (`qn=64`) and fall back automatically.
- Media requests must send Bilibili `Referer`, `Origin`, `User-Agent` and the
  session cookie.

## Migration phases

1. Native shell, tabs, feed, preview and full player on both platforms.
2. Search with 1:1 drag, UP page, comments.
3. Login (native QR), settings, history/favourites.
4. Secondary tabs: following, dynamic, fish; live/bangumi/ranking lists.
5. Remove all remaining legacy native player/bridge code and update docs.

No phase may reintroduce a WebView or web asset.

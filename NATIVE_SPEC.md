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

The bar is glass, nearly full width, 72 dp/pt tall with an 18 dp/pt corner
radius. It sits 4 dp/pt above the safe-area bottom and gives its buttons 8 dp/pt
of horizontal breathing room. The selected tab sits on a 14 dp/pt-radius pill
that springs between tabs, bounces its icon and crossfades the label; only one
tab is selected at a time and the initial highlight is visible on first layout.
The bar hides/shows with a 0.75 s animation while scrolling.

### Sidebar

- A rightward horizontal drag on the feed opens the left drawer and tracks the
  finger 1:1; the feed recedes to 10% scale behind it.
- A leftward drag anywhere over the open drawer closes it with the finger.
- Rows: 直播, 番剧, 消息, 历史 and 用户 in the footer.
- Tapping a row closes the drawer before switching content.


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
- Leftward horizontal drag anywhere on the feed opens search and tracks the
  finger 1:1. Commit at 26% width or a fast left flick. A rightward drag on the
  search screen closes it with the same 1:1 tracking.

### Search

- Left-edge drag opens the search screen and tracks the finger 1:1.
- Empty query shows the live hot-search list (`search/square`).
- Typing shows debounced suggestions (`s/main/suggest`); pressing the keyboard
  search action or tapping a suggestion/hot item runs the video search.
- Results use a native list with cover, title, UP name, play count and duration.

### Member centre

- Opened from 我的 → 会员中心.
- Shows VIP state and expiry, daily experience tasks and the recent exp log,
  read from the native member endpoints. Not logged in shows the QR login path.

### Player

- Opens in portrait and plays immediately. The progress panel is hidden on
  entry; tap the video to show it.
- Portrait centre stage: the 16:9 video is centred on a full-screen, blurred,
  enlarged copy of the same video, with the status bar visible over the blur.
- Swipe up on the video (or its blurred stage) to push the video to the top.
  The video then starts below the visible status bar and the comment stream
  fills the space below it.
- Swipe down on the top video to return to the centre stage. Scrolling the
  comments back to the top and pulling down continues into the same spring
  transition back to the centre stage.
- Swipe down on the centre video to shrink and close the player. Closing
  restores portrait.
- The phone only enters landscape when it is physically rotated; the layout
  animates between portrait and landscape.
- Landscape is the full-screen player: video edge-to-edge, precision wheel
  docked at the bottom.
- Tap the video to toggle the floating control panel; it auto-hides after
  3.2 s of playback.
- Left swipe on the video (or portrait comments) slides in a related-video feed
  using the home card style. Opening a related video replaces the current item
  in place; closing the player returns to the feed.
- Right swipe on the video (or portrait comments) slides in the video details
  panel. The panel bottom holds 画质 (inline quality chips), 弹幕设置 (on/off)
  and 循环模式 (loop/single). There is no separate upward settings menu.
- Long-press anywhere on the video: 2x speed + light haptic. Release restores
  1x. No HUD.
- Progress wheel: 48 dp/pt tall, proportional ticks, labels and needle. The
  ruler moves under a centred red needle; dragging the ruler left advances and
  dragging it right rewinds.
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
| Player | `PlayerViewController` | `PlayerOverlay` |
| Related feed | `RelatedViewController` | `PlayerOverlay` |
| Video details | `VideoDetailViewController` | `PlayerOverlay` |
| Sidebar | `SidebarView` | `SidebarView` |
| Search | `SearchViewController` | `SearchView` |
| UP page | `ProfileViewController` | `ProfileView` |
| Comments | `CommentsPanelViewController` | `CommentsView` |
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

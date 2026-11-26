# O11A1 Mobile (native)

O11A1 is a native iOS + Android Bilibili video client. The app contains **no
WebView, HTML, CSS, JavaScript, local web server, or bundled web UI**.

- iOS: Swift, UIKit, AVFoundation, AVKit.
- Android: Java, Android Views, Media3/ExoPlayer.
- Both platforms use the same screen structure, labels, spacing, colours and
  interaction rules, documented in [NATIVE_SPEC.md](NATIVE_SPEC.md).

## Repository layout

| Path | Role |
| --- | --- |
| `ios-native/` | iOS app, XcodeGen project, Swift sources |
| `app/` | Android app, Gradle project, Java sources |
| `NATIVE_SPEC.md` | Shared product/design/behaviour contract |
| `ARCHITECTURE.md` | Native architecture and data flow |

## Implemented features

- Native vertical video feed with muted 360P previews, home card layout,
  magnitude-coloured play counts and 50pt avatar.
- Interactive toolbar: 66pt glass bar with an 18pt radius, a single 14pt-radius
  selection pill that springs between tabs with an icon bounce and haptic.
- Interactive navigation: finger-following left drawer (right drag opens,
  left drag closes, feed recedes live) and finger-following search open/close.
- Portrait player: 16:9 video pinned at the top with the native comment stream
  below; rotates to the full-screen landscape player only when the phone is
  physically rotated and returns to portrait on close.
- Related-video panel on left swipe, using the home card feed; selecting a card
  replaces the current playback with no navigation stack.
- Video-details panel on right swipe, with 画质, 弹幕设置 and 循环模式 at the
  bottom; the old upward settings menu is gone.
- Native player: UGC progressive/DASH-capable source, PGC episodes, live HLS,
  quality/speed cycling, follow, 2x long-press, precision progress wheel,
  pull-down-to-window in landscape, comments, danmaku overlay and danmaku
  input.
- System PiP:
  - iOS AVKit inline PiP.
  - Android `onUserLeaveHint`.
  - Pulling the player closed never enters PiP.
- Native QR login (Bilibili passport), no web login page.
- Native search with drag tracking, hot-search list, live suggestions and
  result list.
- 推荐 / 关注 / 动态 / 养鱼 tabs.
- 我的 hub with account and modules: 热门, 排行, 番剧, 影视, 直播, 分区,
  收藏, 历史, 关注, 动态, 消息, 会员中心, 养鱼, 设置, 我的主页.
- Native module lists and pagination; UP space; season episode lists.
- Member centre with VIP status, daily experience tasks and recent exp log.
- Live player with a native WBI-signed WebSocket danmaku column.
- Comments with native input and one-tap nested reply lists; danmaku
  load/send/toggle.
- AI 养鱼 screen using an OpenAI-compatible endpoint, native fields and output.
- Settings: theme system/light/dark, default quality, account, about.
- Light theme pure `#FFFFFF`; dark theme pure `#000000`.

The iPhone build is the current reference for the toolbar, drawer, search,
portrait player, related feed and details panel. Android keeps the same screen
model; the newest interactive/player changes are being ported to
`PlayerOverlay` and `GlassTabBarView`.

## Build

### Android

```powershell
.\gradlew.bat :app:assembleDebug
adb install -r app\build\outputs\apk\debug\app-debug.apk
```

### iOS

The unsigned IPA is built by `.github/workflows/ios-native.yml` on GitHub
Actions. Locally (macOS):

```bash
cd ios-native
xcodegen generate
xcodebuild -project O11A1.xcodeproj -scheme O11A1 \
  -configuration Release -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

For device installation, sign the app with your own team or use Sideloadly.
See [SIGNING.md](SIGNING.md).

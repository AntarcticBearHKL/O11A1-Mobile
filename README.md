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

## What is implemented

- Native vertical video feed with muted 360P previews, glass information panel,
  three-column footer, magnitude-coloured play counts, and a 50pt avatar.
- Native full-screen player: progressive Bilibili MP4, speed control, 2x
  long-press with light haptic, 48pt progress wheel, pull-down-to-window, and
  pause/play state.
- System PiP:
  - iOS: AVKit inline PiP; starts when the app is backgrounded while playing.
  - Android: `onUserLeaveHint` enters PiP only while the main player is playing.
  - Pulling the player closed never enters PiP.
- Native QR login (Bilibili passport), no web login page.
- Native search with left-swipe-to-open drag tracking, suggestions/results.
- 推荐 / 关注 / 动态 / 养鱼 tabs.
- Native comments list, settings, theme (system/light/dark), quality selection.
- Light theme is pure `#FFFFFF`; dark theme is pure `#000000`.

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

## Current scope

The first native pass covers feed, playback, PiP, search, QR login, following
and dynamic lists, comments and settings. Live, bangumi, ranking, favourites,
history, danmaku and the 养鱼 mini-feature are on the phase-2 list in
[NATIVE_SPEC.md](NATIVE_SPEC.md). No phase may reintroduce a WebView.

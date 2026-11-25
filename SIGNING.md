# Signing

## Android

Debug builds use the local debug keystore:

```powershell
.\gradlew.bat :app:assembleDebug
adb install -r app\build\outputs\apk\debug\app-debug.apk
```

CI publishes `o11a1-video-test-debug` / `android-debug` APK artifacts.

## iOS

The `ios-native` GitHub Actions workflow builds an unsigned device IPA and a
simulator `.app`. The IPA is published to the `ios-unsigned` release.

Local unsigned build (macOS):

```bash
cd ios-native
xcodegen generate
xcodebuild -project O11A1.xcodeproj -scheme O11A1 \
  -configuration Release -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

For a physical iPhone, open the generated project in Xcode, select the `O11A1`
target, set your Personal Team and a unique bundle identifier, then Run. The
default bundle identifier is `com.o11a1.videotest`.

The app uses the audio background mode for PiP/background playback. It does not
need a local network server or any web entitlements.

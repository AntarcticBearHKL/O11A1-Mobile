# O11A1 移动端视频测试

![android-debug](https://github.com/AntarcticBearHKL/O11A1-Mobile/actions/workflows/android-debug.yml/badge.svg)
![ios-unsigned](https://github.com/AntarcticBearHKL/O11A1-Mobile/actions/workflows/ios-unsigned.yml/badge.svg)

仓库里有两套东西：

- `expo-ui/`：Expo 应用。iOS 原生构建已包含 VideoToolbox + Metal 播放器（本地 Expo 模块 `modules/o11a1-video`）；Expo Go 里仍只能预览 UI。
- 根目录：Android Studio 原生测试工程（MediaCodec → SurfaceTexture → GLES3）。

## 0. 测试视频

两个平台统一使用 B 站 **BV1NS4t6oEXQ**（影视飓风 MacBook Pro PROLED XDR）的 30 秒测试片段：

- 1920×1080、H.264、29.97 fps、无音轨、约 6 MB
- Android：`app/src/main/assets/BV1NS4t6oEXQ.mp4`
- iOS：`expo-ui/modules/o11a1-video/ios/Resources/BV1NS4t6oEXQ.mp4`
- 未登录的 B 站接口最高只能取到 1080p；4K / 60fps 需要登录和大会员，等接 DASH 播放时再做。

## 1. Expo 应用 / iOS 原生播放器

```bash
cd expo-ui
npm install
npx expo start
```

Expo Go 扫码只能看 UI。真正的播放器在 iOS 原生构建里：

- `VTDecompressionSession` 硬解优先（H.264 / HEVC，失败才回退软解）
- `AVAssetReader` 提供压缩样本，VideoToolbox 输出 BGRA
- Metal 采样上一帧/当前帧做 blend 插帧（60 / 120 目标）
- 同一个 fragment shader 里做 CAS-like 自适应锐化
- HUD 和解码统计：`H.264 HW`、分辨率、显示 Hz、render/decode fps、队列深度

原生视图由 `expo-ui/modules/o11a1-video` 提供，JS 只负责挂载和切换开关。

## 1.1 iOS 自动构建（unsigned）

`.github/workflows/ios-unsigned.yml` 在每次 push 时自动跑：

- `expo prebuild --platform ios`
- `pod install`（自动链接 `modules/o11a1-video`）
- 构建 **unsigned** `iphoneos` app，打成 `o11a1-ios-unsigned.ipa`
- 同时构建 `iphonesimulator` app，打成 `o11a1-ios-simulator.zip`

说明：

- unsigned IPA 不能直接安装到未越狱 iPhone；下载后自己用证书 / Sideloadly / AltStore 等方式签名安装。
- simulator zip 只能在 Mac 的 Simulator 里运行；Windows 不能跑 iOS Simulator。
- 当前还没有音频、Anime4K 和 B 站 DASH 登录。

## 2. Android 原生测试

要求：

- Android Studio / Android SDK 35
- JDK 17
- 一台 Android 8.0+ 真机（必须；模拟器只能看管线通不通）

用 Android Studio 打开 `D:\Dev\o11a1-mobile-test`，等 Gradle 同步后运行 `app`。

或者在装有 SDK 的机器上：

```bash
./gradlew :app:assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

也可以直接跑仓库里的 `android-debug` workflow（每次 push 自动构建），从 Actions artifact 下载 `app-debug.apk`；debug APK 已自动签名，直接安装。

启动后：

- 视频自动循环播放内置的 `BV1NS4t6oEXQ.mp4`（1920×1080、29.97fps、H.264、30 秒）。
- 左上角显示实际使用的解码器、`HW`/`SW`、分辨率、显示刷新率、渲染 fps、已解码帧数、插帧和 CAS 状态。
- 底部两个开关：
  - `插帧 blend`：用上一帧和当前帧做混合，验证双帧纹理 + 显示循环；这不是 MEMC，快速运动会有重影。
  - `CAS 锐化`：一个单 pass 的自适应锐化 shader（CAS-like，不是 AMD CAS 的逐像素完整实现），用来验证 GPU 后处理链路。
- `解码器探测`：列出 `MediaCodecList` 中 H.264 / HEVC / AV1 / VP9 解码器、HW/SW、支持分辨率和帧率。

日志与错误：

```bash
adb logcat -s O11A1VideoTest
```

### 怎么判断结果

- 左上角 `HW` 且解码器名是 `c2.qti.*` / `c2.mtk.*` / `OMX.qcom.*` / `OMX.Exynos.*` 一类，才说明走的是厂商硬解。
- `SW` 或 `c2.android.*` / `OMX.google.*` 说明是软件解码，不能用来评估手机硬解性能。
- 模拟器通常显示软件 codec；它只能验证 shader 编译、画面方向、回调和 UI，不代表真机帧率。
- 真机测试时重点看：1080p 是否能稳定、开插帧后 fps、开 CAS 后 fps、连续 5–10 分钟是否降频。

## 3. 现在测到什么、没测到什么

已覆盖：

- Android：MediaCodec 硬解、SurfaceTexture 零拷贝、GLES3 双帧 blend、CAS-like。
- iOS：VideoToolbox 硬解、Metal 双帧 blend、CAS-like、60/120 目标、运行统计。
- 两端统一使用 BV1NS4t6oEXQ 测试片段。
- GitHub Actions 每次 push 自动构建 Android APK 和 unsigned iOS 包。

还没覆盖：

- 音频与 A/V 同步（测试片无音轨）。
- Anime4K Restore-CNN-S（多 pass，下一步单独压测）。
- B 站 DASH / 登录 / 弹幕 / 播放器 UI。
- 4K / 60fps 源（需要 B 站登录）。
- Android 端的 Expo 本地模块（当前仍是独立原生工程）。
- iOS 签名 / TestFlight。

## 4. 推荐下一步

1. 用自己签名的 IPA 在 iPhone 上跑，重点看 `HW`、render/decode fps、发热降频。
2. 接 B 站 DASH，把 BV1NS4t6oEXQ 的 4K/60 视频轨直接拉进播放器。
3. 加 Anime4K 单 pass/多 pass 对比，确定机型白名单。
4. 把 Android 播放器也包成 Expo 本地模块，统一成一个 App。

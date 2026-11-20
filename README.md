# O11A1 移动端视频测试

![android-debug](https://github.com/AntarcticBearHKL/O11A1-Mobile/actions/workflows/android-debug.yml/badge.svg)
![ios-unsigned](https://github.com/AntarcticBearHKL/O11A1-Mobile/actions/workflows/ios-unsigned.yml/badge.svg)

两件事放在一起：

- `expo-ui/`：Expo Go 里能直接看的测试页 UI（纯 JS，不含原生播放器）。
- 根目录：Android Studio 打开的原生测试工程（MediaCodec → SurfaceTexture → GLES3）。

> Expo Go 不能加载自定义原生模块。真正的硬解、插帧、CAS 必须用 Android Studio 构建这个原生工程，后面再接 Expo Development Build。
>
> 说明：本机没有安装 Android SDK，原生 APK 已由 GitHub Actions 构建成功（`android-debug` workflow，artifact 约 7.9 MB）；本地真机运行还需要你安装到手机上验证。Expo UI 已通过 TypeScript、Metro 导出和 Web 预览。

## 1. Expo UI 预览

```bash
cd expo-ui
npm install
npx expo start
```

用手机 Expo Go 扫码。页面里的开关、分段控件、统计卡片都可以点；视频区域是占位，点“开始测试”会提示原生能力需要 dev build。

## 1.1 iOS 自动构建（unsigned）

`.github/workflows/ios-unsigned.yml` 在 `expo-ui/**` 变更时自动跑：

- `expo prebuild --platform ios`
- `pod install`
- 构建 **unsigned** `iphoneos` app，打成 `o11a1-ios-unsigned.ipa`
- 同时构建 `iphonesimulator` app，打成 `o11a1-ios-simulator.zip`

说明：

- 当前 iOS 包只有 Expo UI，还没有 VideoToolbox + Metal 原生播放器。
- unsigned IPA 不能安装到未越狱 iPhone；需要后续 Apple 签名 / TestFlight。
- simulator zip 可在 Mac 的 Simulator 里解压安装；Windows 只能下载 artifact，不能跑 iOS Simulator。

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

也可以直接跑仓库里的 `android-debug` workflow（workflow_dispatch / 相关路径 push），从 Actions artifact 下载 `app-debug.apk`；debug APK 已自动签名，直接安装。

启动后：

- 视频会自动循环播放内置的 `test_1080p60.mp4`（1920×1080、60fps、H.264，6 秒）。
- 左上角显示实际使用的解码器、`HW`/`SW`、分辨率、显示刷新率、渲染 fps、已解码帧数、插帧和 CAS 状态。
- 底部两个开关：
  - `插帧 blend`：用上一帧和当前帧做 0.5 混合，验证双帧纹理 + 显示循环；这不是 MEMC，快速运动会有重影。
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
- 真机测试时重点看：1080p60 是否能稳定、开插帧后 fps、开 CAS 后 fps、连续 5–10 分钟是否降频。

## 3. 现在测到什么、没测到什么

已覆盖：

- MediaCodec 硬解探测和实际解码。
- 解码器输出到 SurfaceTexture，GLES 采样外部 OES 纹理（零拷贝路径）。
- 解码帧复制到双 FBO 纹理，上一帧/当前帧混合。
- 单 pass CAS-like 锐化。
- 帧率、解码器、HW/SW、分辨率统计。

还没覆盖：

- 音频与 A/V 同步（测试片无音轨）。
- Anime4K Restore-CNN-S（多 pass，下一步单独压测）。
- B 站 DASH / 登录 / 弹幕 / 播放器 UI。
- RN 原生 View 和 Expo Dev Client 集成。
- iOS VideoToolbox + Metal。

## 4. 推荐下一步

1. 先在真机跑通这个 Android 工程，记录解码器和 fps。
2. 把测试片换成 B 站 1080p60 DASH 视频轨（先只做视频，音频后接）。
3. 加 Anime4K 单 pass/多 pass 对比，确定机型白名单。
4. 再把 `VideoRenderer` 包成 Expo 本地模块 / Fabric View，接进 Expo dev build。
5. 最后做 GitHub Actions APK 和 iOS EAS 签名。

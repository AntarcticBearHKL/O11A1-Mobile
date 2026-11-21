# O11A1 移动端视频测试

![android-debug](https://github.com/AntarcticBearHKL/O11A1-Mobile/actions/workflows/android-debug.yml/badge.svg)
![ios-unsigned](https://github.com/AntarcticBearHKL/O11A1-Mobile/actions/workflows/ios-unsigned.yml/badge.svg)

仓库里有两套 V2 客户端：

- `expo-ui/`：iOS V2 客户端。Expo 壳 + 全屏 WKWebView + 本地回环 Bilibili 桥（`modules/o11a1-bridge`）；UI 仍然是 `web-prototype/`，播放走 HTML5 `<video>` + 本地 Range 代理。
- 根目录：Android V2 应用（`com.o11a1.videotest`）。全屏 WebView 承载 V2 设计 + 原生 Bilibili 桥 + 本地视频代理；旧 MediaCodec / GLES3 测试类保留在工程里。

## 只调 UI：Expo Go 模式

完整的 O11A1 app **不能直接**用 Expo Go 跑，因为 `expo-ui` 依赖自定义原生模块 `O11A1Bridge`（本地 HTTP 服务、Cookie、B 站接口、原生 WebView 宿主）。Expo Go 里没有这个模块，所以原来的行为是直接显示“原生模块未加载”。

现在 `App.tsx` 增加了 UI MOCK 回退：

- 在 Expo Go 中启动时检测不到 `O11A1Bridge`，会自动把 `web-prototype/` 的 `index.html / styles.css / app.js / native.js` 内联进一个 WebView。
- 注入 `window.O11A1Native` 的 mock 实现：热门/搜索/排行/番剧/直播/收藏/历史/关注/动态/消息/评论/楼中楼/会员任务都有假数据。
- 登录 gate、短信登录卡片、侧边栏、播放器工具栏、画质/倍速/插帧/增强/循环/评论/播放列表/设置/主题/外观滑杆/键盘映射等 UI 都可以点。
- 视频播放、真实账号、离线下载、AI、截图、复制链接会显示“UI 调试模式…”的内联提示，不会伪造成功。
- 左上角会显示 `UI MOCK · 无视频 / 无账号` 标识。

启动：

```bash
cd expo-ui
npm run dev
```

`npm run dev` 会同时启动 Expo 和 `web-prototype` 文件监听：改 `web-prototype/app.js / native.js / styles.css / index.html` 后自动重生成 `src/webapp.generated.ts`，Expo Go 会重新加载 WebView；改 `App.tsx` 则由 Metro Fast Refresh 处理。

快速在 Android 模拟器上自动打开 Expo Go：

```bash
npm run dev:android
```

iOS Simulator（macOS）：

```bash
npm run dev:ios
```

也可以分别启动：

```bash
npx expo start --lan
# 另一个终端
npm run watch:web
```

用 Expo Go 扫 Metro 的二维码，或在 Expo Go 里打开同一局域网地址。局域网不通时用：

```bash
npx expo start --tunnel
```

如果只想在电脑上快速看 UI，直接起一个静态服务器打开 `web-prototype/` 也可以；Expo Go 模式的好处是能在手机上测试触摸手势和横屏工具栏。

## iOS V2 实装（当前 IPA）

- **架构**：`expo-ui` 启动 `O11A1Bridge` 原生模块，在 `127.0.0.1` 随机端口起一个本地 HTTP 服务，把打包进 JS 的 `index.html / app.js / native.js / styles.css` 原样提供给 WKWebView。
- **同步桥**：注入 `window.O11A1Native`，通过同步 XHR 调本地 `/api/*`，与 Android 的 `WebAppBridge` API 完全一致；`native.js` 不需要分叉。
- **真实数据**：Swift `O11A1BiliClient` 直接请求 B 站热门、搜索、分页 cid、playurl、评论、弹幕、导航登录态、账户资料、收藏夹、历史、关注动态、动态、消息、排行榜、番剧/影视索引、番剧选集、直播推荐与直播地址、分区、视频详情；Cookie 持久化到 UserDefaults。
- **真实登录**：应用内打开 B 站官方短信验证码登录页；登录成功后读取 WebKit Cookie 并保存 `SESSDATA` 等 Cookie。
- **真实播放**：progressive MP4 优先 720P，失败回退 480P / 360P；本地 `/media` 代理补 Referer/UA、转发 Range，按 8MB 分块返回 206；主 CDN 失败自动试备用 CDN；番剧通过 `pgc/player/web/playurl` 播放并一次加入整季选集；直播使用原生 HLS；1080P / 4K / 1080P+ 会先尝试 DASH，失败自动回退渐进播放。
- **离线缓存**：`O11A1Downloads` 在 Documents/offline 保存 progressive MP4，支持进度、暂停、继续、断点续传、删除，完成后由本地 `/file` 路由播放。
- **播放器**：与 Android 共用同一套 V2 播放器 UI、三区手势、评论、弹幕、播放列表、刷新和登录 gate；视频信息/性能面板、截图、复制链接、收藏/投币/关注/弹幕发送会调用真实接口（未登录时内联提示）；外接键盘映射、深色主题、全屏评论楼中楼/三段窗口无限列表、会员任务、AI 养鱼、WebGL 插帧/CAS 全部共用 web 实现。
- **构建**：GitHub Actions `ios-unsigned`（macOS）每次 push 生成未签名 IPA + 模拟器 zip；成功后发布到 Releases。
- **下载**：
  - IPA：`https://github.com/AntarcticBearHKL/O11A1-Mobile/releases/download/ios-unsigned/o11a1-ios-unsigned.ipa`
  - 模拟器包：`https://github.com/AntarcticBearHKL/O11A1-Mobile/releases/download/ios-unsigned/o11a1-ios-simulator.zip`
  - Android APK：`https://github.com/AntarcticBearHKL/O11A1-Mobile/releases/download/android-debug/app-debug.apk`
- **安装**：未签名 IPA 需要自己签名（Sideloadly / AltStore / eSign / 自有开发者证书）；模拟器 zip 解压后用 `xcrun simctl install booted O11A1.app`，需要 macOS。
- **CI 验证**：`ios-unsigned` 在 macOS runner 上启动 iOS Simulator，已实际跑通登录 gate + 短信登录入口 → 本地测试进入 → 真实热门流 → 首个视频 720P 播放 + 弹幕。Release 里的 `ios-simulator.png` 是登录 gate，`ios-simulator-player.png` 是真实播放画面。真机仍需你自己签名后测试。
- **亮度 / 音量**：播放器左侧竖滑调系统屏幕亮度（`UIScreen.main.brightness`），右侧竖滑调系统输出音量（`MPVolumeView` + `AVAudioSession`）；不再修改 `<video>` 元素音量，也不再叠加软件变暗层。退出播放器、切后台或退出登录时恢复进入播放器前的亮度；App 启动和进入播放器都不会强制调到最高。Expo Go 没有修改系统音量的公开 API，右侧滑杆只更新 HUD；原生 IPA 才有真实系统音量。

## Android V2 实装（当前 APK）

- **架构**：`web-prototype/` 是唯一 UI 源；Gradle 构建时复制到 `assets/web`，`MainActivity` 用全屏 WebView 加载。
- **原生桥**：`WebAppBridge` / `BiliApi` / `BiliExtras` / `DownloadManager` / `CookieStore` / `StreamProxy` 提供热门、搜索、分集 cid、playurl、DASH、评论与楼中楼、弹幕、短信登录、Cookie、账户、收藏、历史、关注、动态、消息、排行榜、番剧/影视、直播、分区、视频详情、互动写入、会员中心、AI 接口、离线下载、亮度、方向、剪贴板和截图。
- **真实数据**：首页热门 / 排行 / 番剧 / 影视 / 直播 / 分区 / 收藏 / 历史 / 关注；搜索；模块页；账户卡；动态 / 消息；视频信息；会员中心每日任务与经验记录。未登录的账户页会显示登录 CTA。
- **真实播放**：Bridge 取 B 站 progressive MP4；1080P / 1080P60 / 1080P+ / 4K 先请求 DASH，用 MediaSource 分流视频/音频，失败自动回退渐进播放。本地代理补齐 Referer/UA 并转发 Range；番剧按集播放并加入播放列表；直播 HLS 使用 hls.js；HTML5 `<video>` 播放。
- **真实登录**：应用内打开 B 站官方手机号 + 短信验证码登录页；登录成功后读取 WebKit Cookies 保存 `SESSDATA` / `bili_jct`，不再提供二维码入口；「本地测试进入」仅用于无账号调试。
- **亮度 / 音量**：播放器左侧竖滑调系统屏幕亮度（当前窗口 `screenBrightness`，直接改变面板亮度，不叠加软件变暗层），右侧竖滑调系统媒体音量（`AudioManager.STREAM_MUSIC`）；不再修改 `<video>` 元素音量。App 启动、进入播放器都不会修改亮度；退出播放器、切后台或退出登录时恢复原亮度。
- **播放器**：播放/暂停、进度、音量、倍速、循环、画质重取、三区手势、收起进浮动播放列表、全屏真实评论（三段窗口无限列表 + 楼中楼）、真实弹幕滚动、信息/性能面板、截图保存到相册、复制 BV 链接、收藏/投币/关注/点赞、弹幕发送、外接键盘映射、深色主题与外观滑杆、会员任务、AI 养鱼、WebGL 插帧 / CAS / Anime4K。评论发送入口暂时隐藏。
- **调试信息**：视频流右上角实时显示 FEED 刷新率与 FPS；播放器右上角五条 HUD：DSP 显示刷新率、TGT/RND 目标/渲染帧率、DEC 解码帧率与分辨率、DRP/AV 丢帧与音画间隔、NET 实时码率。
- **离线缓存**：`DownloadManager` 支持两种任务：渐进 MP4 直接缓存；DASH 音视频分轨下载后用 `MediaMuxer` 交错合流成 MP4（FFmpeg 合流的原生等价实现）。支持队列、进度、暂停、继续、断点续传、删除和本地播放。
- **列表**：视频行左滑展开「播放列表 / UP主」动作，拖到按钮触发；浮动框加高并接近全宽、上滑展开播放器、点击进播放列表页；触底加载下一段真实数据，只保留最近两段并保持滚动位置；历史行显示观看进度。
- **构建**：
  ```bash
  ./gradlew :app:assembleDebug
  adb install -r app/build/outputs/apk/debug/app-debug.apk
  ```
- **模拟器验证**：`Medium_Phone_API_37.0`，480×800 / 160dpi。已验证登录 gate / 短信登录入口、热门 20 条、搜索“原神”20 条、排行/番剧/影视/分区真实列表、番剧第一集 360P 播放（整季 11 集入队）、真实评论（8709 条）、最新评论未登录回退最热、楼中楼展开 12 条、触底无限加载、侧边栏、左滑播放列表、播放列表页/移除、视频信息/性能面板、截图（MediaStore）、复制链接、画质切换、倍速/循环、设置账户卡、视频流刷新率、五条播放 HUD、深色/浅色主题、渐进 MP4 离线下载 141.5MB、DASH 分轨下载 + MediaMuxer 合流 11.6MB（360P，音频解码计数 >0）并从本地播放、DASH 720P 在线播放、WebGL 插帧/CAS。直播列表 20 条和直播地址 HLS 已验证；模拟器长时间 720P/直播软解会让模拟器不稳定，真机为准。
- **未验证 / 需要账号**：真实登录后的收藏/历史/关注/动态/消息/会员任务、4K/1080P+（需要大会员）、点赞/投币/收藏/关注/评论/弹幕发送、直播弹幕（B 站匿名接口 -352，需登录 Cookie）、AI 养鱼（需要用户提供 DeepSeek/OpenAI 兼容 Key）。这些入口在条件不满足时会内联提示，不会伪造成功。

## 移动端 V2 规划（当前）

- **不要底部工具栏**：视频流占满整个窗口；在屏幕上向右滑，从左边展开侧边栏。
- **强制登录**：未登录冷启动直接停在登录 gate，首页、侧边栏、搜索、播放器、播放列表全部不可达；点「打开短信登录」/「本地测试进入」进首页，登录态本地保存；设置 → 账户可退出。
- 侧边栏列出了全部导航入口：首页 / 收藏 / 直播 / 关注 / 动态 / 消息 / 历史 / 我的；不再有搜索按钮。
- 侧边栏使用统一的极简线性 SVG 图标（无 emoji）；「我的」独立放在侧边栏底部，与主入口之间用分隔线隔开。
- 养鱼（AI 看片）入口默认隐藏；设置 → 防干扰 → 隐藏养鱼入口 可恢复。
- 首页/搜索/模块视频流使用触底无限加载：每次追加一段，只保留最近两段（1+2 → 2+3 → 3+4），旧段自动丢弃并保持滚动锚点；不再有下拉刷新。
- 左侧菜单滑出时，主页面以 3D 缩放/侧移向后退出，带阴影与遮罩；关闭时回弹。
- 所有页面都不设顶栏/标题栏：状态栏下只有玻璃渐变，内容直接开始；一行一个视频；整体行高加大。
- 首页浅色背景完全对齐桌面版：`#FAFAFC` 冷白底 + 桌面版五层柔和径向渐变（桃 / 蓝 / 薄荷 / 薰衣草 / 奶油），60px 模糊、无点阵；顶部玻璃、侧边栏、弹层、卡片同步改为冷白中性色，不再使用暖黄纸底。
- 默认锁定竖屏：Expo、Android、iOS 启动和退出播放器都回到 portrait；不监听陀螺仪、加速度计或 `orientationchange`。只有播放器中间上滑会手动切换横屏 / 竖屏，切换后仍然锁定，不会随设备转动。
- 搜索只保留首页视频流上滑出现的浮动搜索框：点击后视频流隐藏，显示热搜/联想；上滑关闭；回车或点选后进入独立搜索结果页。
- 播放列表不在侧边栏：非空时在视频流底部显示加高、接近全宽的浮动框；视频行左滑拖到「播放列表」加入；上滑展开当前播放；点击进入完整播放列表页；播放列表页支持下滑关闭；空列表隐藏。
- 播放器三区手势：中间下滑收起 / 上滑切换横屏与竖屏；左侧竖滑系统亮度、右侧竖滑系统音量（竖向 HUD）；左滑全屏评论；双击中间播放 / 暂停；长按左 0.5× 减速、长按右 2.0× 加速。
- 播放器任意空白处单击显示顶部 / 底部工具栏；1 秒内没有新的点击、滑动或控件操作时自动隐藏。
- 评论页：左滑进入全屏平面评论，无顶部菜单栏 / 排序栏和底部发送框；评论按页分块，最多保留 3 段，下滑加载更旧并丢弃最上一段，上滑加载更新并丢弃最下一段，滚动位置保持锚定。
- 播放器横竖屏共用：顶部极简返回 / 标题 / 队列 / 更多；底部改为全宽扁平控制台：细进度线、白色播放键、线性图标、可横向滚动的画质 / 倍速 / 插帧 / 增强 / 播放模式 / 面板 / 设置 / 截图工具条，以及极简弹幕输入线。无玻璃卡片、无边框、无阴影；显示/隐藏、弹幕栏折叠、按钮按压和播放图标都有动效。
- 无 Toast、无旧版灰色提示条；所有反馈内联。
- 桌面端功能逐项保留；完整对照见 [MOBILE_FEATURES.md](MOBILE_FEATURES.md)。

> Android APK 已接入真实热门/搜索/播放/短信登录/评论/弹幕；Web 原型继续作为布局与手势基准。产品与播放器设计：[MOBILE_DESIGN.md](MOBILE_DESIGN.md)（V2）。
> 产品与播放器设计：[MOBILE_DESIGN.md](MOBILE_DESIGN.md)（V2）。
> 功能与交互规范：[MOBILE_INTERACTION.md](MOBILE_INTERACTION.md)（V2）。
> 桌面功能完整对照：[MOBILE_FEATURES.md](MOBILE_FEATURES.md)。
> Web 布局/手感原型：[web-prototype/](web-prototype/)（V2：全屏视频流、左侧边栏、视频搜索、浮动播放列表框 + 播放列表页、三区手势播放器、全屏评论、横屏主页）。
>
> V2 网页原型直接打开 http://localhost:4173 ；重置状态用 http://localhost:4173/?reset=1 。

## 0. 测试视频

两个平台统一使用 B 站 **BV1NS4t6oEXQ**（影视飓风 MacBook Pro PROLED XDR）的 30 秒测试片段：

- 1920×1080、H.264、29.97 fps、无音轨、约 6 MB
- Android：`app/src/main/assets/BV1NS4t6oEXQ.mp4`
- iOS：`expo-ui/modules/o11a1-video/ios/Resources/BV1NS4t6oEXQ.mp4`
- 未登录的 B 站接口最高只能取到 720P；1080P / 4K / 60fps 需要登录和大会员，客户端已经实现 DASH 请求与 MediaSource 播放，未登录时会自动回退到服务端允许的清晰度。

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

- unsigned IPA 不能直接安装到未越狱 iPhone；下载后自己用证书 / Sideloadly / AltStore 等方式签名安装。签名方案和免费 Apple ID 限制见 [SIGNING.md](SIGNING.md)。
- simulator zip 只能在 Mac 的 Simulator 里运行；Windows 不能跑 iOS Simulator。
- 当前未接音频、Anime4K 和 B 站 DASH 登录；DASH 播放只在 Android WebView 可用，iOS 自动回退渐进播放。

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

- Android V2：WebView UI + 真实热门/搜索/模块数据、B 站短信验证码登录、progressive 720P 播放、评论、弹幕、播放列表、触底无限加载。
- Android 旧测试管线：MediaCodec 硬解、SurfaceTexture 零拷贝、GLES3 双帧 blend、CAS-like。
- iOS V2：Expo + WKWebView + 本地回环桥；CI 的 iOS Simulator 已跑通登录 gate/短信登录入口、真实热门流、首个视频 720P 播放、真实弹幕，截图随 Release 发布。
- iOS 旧测试管线：VideoToolbox 硬解、Metal 双帧 blend、CAS-like、60/120 目标、运行统计。
- 两端统一使用 BV1NS4t6oEXQ 测试片段。
- GitHub Actions 每次 push 自动构建 Android APK 和 unsigned iOS 包，并把 IPA/APK 发布到 Releases。

还没覆盖：

- DASH 分轨 / 4K / 60fps / 1080P+（需要大会员 Cookie 和 DASH 合流）。
- Anime4K Restore-CNN-S（多 pass，下一步单独压测）。
- 动态 / 消息 / 收藏 / 历史等账户页仍是设计壳；直播 / PGC 没有接独立接口。
- 插帧 / CAS / 增强 / 截图目前是 Android V2 播放器的 UI 开关，原生管线仍在 iOS 模块里。
- Android 端的 Expo 本地模块（当前仍是独立原生工程）。
- iOS 签名 / TestFlight。

## 4. 推荐下一步

1. 用自己签名的 IPA 在 iPhone 上跑，重点看 `HW`、render/decode fps、发热降频。
2. 接 B 站 DASH，把播放器接到 1080P/4K 分轨视频 + 音频，补 AV 同步。
3. 给 Android 播放器接入原生插帧 / CAS / 截图，逐步与 iOS 模块对齐。
4. 接动态 / 消息 / 收藏 / 历史接口，或把 Android V2 包成 Expo 本地模块统一工程。

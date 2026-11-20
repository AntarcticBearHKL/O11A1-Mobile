# O11A1 Mobile 设计草案

> 目标：把桌面端 O11A1 的 B 站客户端体验带到手机，保留原生硬解、DASH、弹幕、插帧、增强；去掉桌面窗口交互，按触控、单手和移动网络重新设计。
>
> 基线：桌面 O11A1 0.7.4。推荐 / 搜索 / 收藏 / 历史 / 分区 / 番剧 / 直播 / 动态 / 消息 / 会员 / 设置 / 下载，加上 Rust 原生播放器（DASH、弹幕、画质、音轨、0.1–10x、插帧 0/60/90/120/自动、增强 CAS/Anime4K、精准定位、A/B、播放队列）。

## 1. 桌面端盘点与移动端取舍

### 1.1 直接保留的能力

- 二维码登录、账号校验、-101 失效回到扫码页、大会员/画质状态。
- 推荐流、搜索、视频详情、UP 主空间、收藏、历史、分区、番剧、直播、动态、消息、会员、设置。
- DASH 视频 + 音频、全部画质/编码、弹幕、评论、选集、播放队列、循环/下一 P。
- 插帧（关/60/90/120/自动）、画质增强（关/CAS/Anime4K）、4K 原始分辨率。
- A/V 同步、缓冲/预取、直播 FLV/HLS、番剧按普通视频管线播放。
- 浅色/深色/跟随系统、暖纸视觉、Chill Round Gothic 字体。

### 1.2 必须改造的部分

| 桌面端 | 手机端设计 | 原因 |
|---|---|---|
| 首页固定 7 行、按宽度算列数 | 2 列瀑布流 + 下拉刷新 + 触底加载；保留“刷新换一批”和后台预取 | 手机屏幕窄，固定 7 行不适合无限滚动 |
| 底部工具栏 10 个入口 | 4 个根 tab + “我的”聚合页 + 播放小窗 | 手机底栏最多 4–5 项，单手可达 |
| 右侧播放器侧栏 6 个 tab | 底部 sheet：信息 / 选集 / 评论 / 历史 / 性能 / 设置 | 横屏空间有限，sheet 更符合触控 |
| 窗口拖动、右键刷新、键盘快捷键 | 手势、下拉刷新、长按、播放器手势 | 没有窗口和键盘 |
| 悬停 tooltip / hover | 按压态、长按菜单、首次手势提示 | 触屏没有 hover |
| 精准定位面板 / A-B / 帧步进 | P2 的“精准模式”：长按进度条进入；普通用户先用横滑 seek | 桌面级工具不适合作为首屏 |
| 下载入口隐藏 | 手机端做“离线缓存” P1/P2，后台下载 + 管理 | 移动网络/通勤场景需要 |
| 托盘、开机自启、NSIS 更新 | 应用内更新提示；个人签名/TestFlight 分发 | 手机没有托盘/安装器 |
| 养鱼、AI 切片、测试实验室 | P3 或桌面端专属 | 不是 B 站客户端核心 |
| 6 列封面网格 | 2 列（平板 3 列） | 手机宽度 |

### 1.3 手机端新增

- 播放器手势：双击左右 ±10s、横滑 seek、左半竖滑亮度、右半竖滑音量、长按 2x。
- 画中画 / 后台音频 / 锁屏控制。
- 移动网络画质策略：Wi-Fi 默认最高，蜂窝默认 720P/1080P，可切换。
- 离线缓存管理、存储占用、仅 Wi-Fi 下载。
- 首次播放手势引导、单手模式、触感反馈。
- 分享面板、系统分享、复制 BV/链接。
- 屏幕常亮、睡眠定时、自动连播下一 P。

## 2. 产品原则

1. **播放优先**：首页和详情都为“尽快进入播放”服务；点击卡片直接播，详情页只是补充信息。
2. **单手可达**：主操作放底部；顶部只放返回/标题/更多；重要按钮不小于 44pt。
3. **原生能力**：硬解、插帧、增强、弹幕都在原生层；RN 只做 UI 和状态。
4. **渐进增强**：低端机默认 1080P + 关闭插帧；高端机可 4K/120；能力探测后给选项，不强行全开。
5. **不复制桌面**：桌面是鼠标+键盘+大屏，手机是触控+单手+移动网络；保留功能，不保留窗口交互。
6. **个人使用/合规**：第三方 B 站客户端涉及 ToS 和分发风险；默认按个人 sideload/TestFlight 设计，不默认上架。

## 3. 信息架构

### 3.1 根导航（4 tab）

```
首页        动态        消息        我的
```

- **首页**：顶部品牌/搜索/头像；横向 chips：推荐 / 热门 / 番剧 / 直播 / 分区。
- **动态**：全部 / 视频 / 图文。
- **消息**：回复 / @ / 赞 / 私信。
- **我的**：账号卡、收藏、历史、下载、会员、设置。

搜索是顶部搜索图标打开的全屏 modal，不占根 tab。播放中的 **mini-player** 悬浮在 tab 栏上方，点按回到播放器，横滑关闭。

### 3.2 层级

```
首页
 ├─ 视频详情（push）
 │   └─ 播放器（全屏 modal / 横屏）
 ├─ 番剧详情（push）
 │   └─ 播放器
 ├─ 直播间（push）
 ├─ 分区（push）
 └─ UP 主空间（push）

我的
 ├─ 收藏夹
 ├─ 历史
 ├─ 离线缓存
 ├─ 会员
 └─ 设置

搜索（modal）
动态 / 消息（tab 内 push 私信会话）
登录（全屏 gate）
```

### 3.3 播放器 sheet

播放器底部/右上“更多”打开：

- 画质（全部 DASH 分辨率 + 编码 + 码率 + 大会员锁）
- 音轨
- 倍速（0.1–10，常用 0.5/0.75/1/1.25/1.5/2）
- 插帧（关 / 60 / 90 / 120 / 自动）
- 增强（关 / CAS / Anime4K）
- 弹幕设置（透明度、字号、速度、区域、屏蔽）
- 选集 / 分P
- 评论
- 播放队列
- 循环（暂停 / 单曲 / 下一首 / 下一 P）
- 性能 HUD（默认关闭）
- 精准模式（P2）

## 4. 页面设计

### 4.1 登录

- 全屏暖纸背景 + 居中卡片；只有二维码、6px 进度条、一行状态文字。
- 二维码过期自动换；失败可点二维码重试。
- 记住上次账号头像/昵称；`-101` 时提示“登录已失效，请扫码重新登录”，不进入未登录首页。
- 登录成功：头像 + “登录成功，正在进入主页…”，然后进入首页。
- 不在登录页放品牌大标题、说明、按钮；保持桌面端的极简登录表面。

### 4.2 首页

- 顶栏：O11A1 标识、搜索、头像；滚动时磨砂。
- chips：推荐 / 热门 / 番剧 / 直播 / 分区（横向滚动，选中蓝色药丸）。
- 2 列视频卡：16:10 封面、时长、标题 2 行、UP、时间/播放量；历史卡显示进度条。
- 下拉刷新换一批；触底加载下一页；首屏骨架；空/错误状态。
- 保留“后台预取两批”思路：首屏加载后预取下一批，刷新时直接换入。
- 点击卡片直接播放；长按显示“稍后再看 / 收藏 / UP 主页 / 分享”。
- 直播卡红色“直播中”；番剧卡竖版海报/集数。

### 4.3 搜索

- 顶部搜索框自动聚焦；空输入显示热搜 + 最近搜索。
- 输入 160ms 防抖联想；回车进入结果。
- 结果 tabs：视频 / 番剧 / 影视 / 直播 / 用户；筛选 chip（排序、分区、时长）。
- 结果网格复用首页卡片；分页/触底加载；空结果/错误/未登录提示。

### 4.4 视频详情

- 顶部 16:9 播放器预览；点按进入全屏播放器；支持小窗/画中画。
- 标题、播放/弹幕/点赞/投币/收藏统计、发布时间。
- UP 行：头像、昵称、粉丝数、关注按钮；点进 UP 空间。
- 操作：收藏（选收藏夹）、投币、分享、下载/缓存、稍后再看。
- tabs：简介 / 评论 / 相关推荐；分P 横向列表在简介上方。
- 评论：最热/最新、楼中楼、触底加载；头像圆形。
- 相关推荐 2 列卡片；点按直接播放。
- 底部 mini-player 保持当前播放。

### 4.5 播放器（核心）

**布局**

- 横屏全屏，隐藏状态栏；刘海/挖孔安全区留白。
- 顶部：返回、标题/UP、画质 chip、投屏/PiP、更多。
- 底部：播放/暂停、下一 P、时间、进度条（缓冲/弹幕热力可选）、弹幕开关/输入、画质、倍速、插帧、增强、全屏/锁定。
- 控件 3 秒无操作淡出；点按画面显示/隐藏；锁定后只保留解锁按钮。
- 竖屏详情页的视频预览不显示完整控件，只保留播放按钮和时长。

**手势**

| 手势 | 行为 |
|---|---|
| 单击画面 | 显示/隐藏控件 |
| 双击左/右半屏 | -10s / +10s |
| 双击中间 | 播放/暂停 |
| 左右拖动 | seek 预览，松手跳转 |
| 左半屏上下滑 | 亮度 |
| 右半屏上下滑 | 音量 |
| 长按 | 2x 临时倍速，松手恢复 |
| 双指捏合 | 适应/填充（可选） |
| 下滑 | 退出全屏（可选，需防误触） |

首次进入显示一次手势提示，可在设置关闭。

**画质 / 音轨**

- 画质列表：8K / 4K / 1080P60 / 1080P / 720P60 / 720P / 480P / 360P；每项显示编码（AVC/HEVC/AV1）、分辨率、码率；大会员档加锁标识。
- 默认画质：最高可用 / 2160P / 1440P / 1080P / 720P / 480P / 360P；按登录态和 VIP 过滤。
- 音轨：DASH 音频轨列表，默认最高码率；切换不打断视频画面。
- 画质切换保留当前进度；失败回退上一档并提示。
- 移动网络策略：Wi-Fi 默认最高；蜂窝默认 1080P/720P；可在设置改。

**插帧**

- 档位：关 / 60 / 90 / 120 / 自动。
- 自动 = 跟随屏幕刷新率（ProMotion 120 / 120Hz Android / 60Hz 设备）。
- 固定档位高于屏幕刷新率时灰显；120Hz 屏幕才显示 120。
- 源 24/25/30/60fps 都可；当前是 **blend 过渡**，不是 MEMC；快速运动会有重影，UI 里明确写“blend 插帧”。
- 掉帧/发热保护：连续 10 秒低于目标 85% 时提示降档；设置里可开“自动降档”。
- 播放器 HUD 显示 display Hz / target / render / decode / dropped。

**增强**

- 关 / CAS / Anime4K。
- 默认：1080P 以下 CAS；4K/高码率关；按机型性能给推荐档。
- Anime4K 只在高性能设备开放；低端机灰显或提示。
- 增强只作用于视频层，不处理弹幕/UI；截图/录屏保留增强后画面。

**弹幕**

- 原生层绘制，跟随播放器时钟；120Hz 下不卡 UI。
- 开关、透明度、字号 50–150%、速度 50–200%、显示区域 25/50/75/100%、屏蔽滚动/顶部/底部。
- 发送：输入框 + 发送按钮；未登录提示；发送成功 toast。
- 弹幕历史按日期查看；点赞/举报/屏蔽用户/关键词；智能云屏蔽开关。
- 弹幕设置即时生效，写入本地设置。

**评论 / 选集 / 队列**

- 评论：底部 sheet，60–85% 高度，可拖动；最热/最新；楼中楼展开；触底加载。
- 选集：分P 横向列表/网格；当前 P 高亮；切换保留播放器窗口。
- 队列：当前播放列表；点按切换；清空；播放完自动下一条并移除。
- 循环：暂停 / 单曲 / 下一首 / 下一 P；播放到结尾自动下一 P（可关）。

**精准模式（P2）**

- 长按进度条或“更多 → 精准定位”进入。
- 帧步进、A-B 循环、帧号/时间码、弹幕热力图、滚轮/拖动预览。
- 这是桌面端的强项，但手机首版不做主入口；放到 P2，避免普通用户误触。

**HUD / 统计**

- 默认关闭；设置 → 播放 → 性能 HUD。
- 显示：解码器名、HW/SW、分辨率、display Hz、target/render/decode fps、dropped、A/V gap、缓冲秒数、网络码率。
- 用于真机验收，不面向普通用户。

**A/V 同步**

- 音频设备时钟为主时钟；视频按音频时钟取帧/丢帧。
- 偏差 >250ms 且持续 >900ms 才 seek 对齐；2 秒内不重复 seek。
- 音频欠载 650ms 暂停视频；恢复后追帧。
- 直播低延迟优先，允许更大偏差。

**直播 / 番剧**

- 直播：FLV/HLS、5 档画质、聊天/弹幕；强制关闭插帧/增强；低延迟模式。
- 番剧：季详情、选集、cid 弹幕；和普通视频同一播放器管线；大会员锁提示。

**后台 / PiP / 下载**

- iOS：AVPictureInPictureController；Android：PiP + 前台服务。
- 后台音频、锁屏控制（播放/暂停/下一 P/进度）。
- 离线缓存：DASH 视频+音频、后台队列、仅 Wi-Fi、存储管理、删除；P1/P2。
- 下载完成通知；断点续传；播放本地缓存优先。

### 4.6 番剧 / 直播

- 番剧：每日放送、索引、排行榜、季详情、选集网格、追番；排版沿用桌面端的竖版海报/单行类型 chips。
- 直播：推荐、分区、关注、房间；房间页展示主播、在线人数、画质、聊天；直播设置只有画质/置顶/仅音频。

### 4.7 动态 / 消息

- 动态：全部/视频/图文 chips；正文、图片网格、视频附件；图片全屏查看器；作者/视频跳转。
- 消息：回复/@/赞/私信；扁平列表、未读蓝点；私信会话；触底加载。

### 4.8 我的 / 设置

- 我的：账号卡（头像/昵称/UID/等级/VIP）、收藏/历史/下载/会员入口、设置。
- 设置分类：账户、播放（默认画质/插帧/增强/移动网络）、弹幕、手势、外观（浅色/深色/跟随系统）、存储、关于。
- 手机特有：仅 Wi-Fi 下载、蜂窝画质、手势开关、首次提示、HUD、日志导出。

### 4.9 离线缓存

- 队列、进度、速度、暂停/继续/取消、删除、打开文件位置（系统分享）。
- 同时最多 2 个任务；失败重试；存储不足提示。
- 版权/ToS 提示：仅个人使用。

## 5. 视觉系统

### 5.1 颜色

| Token | 浅色（暖纸） | 深色（墨） |
|---|---|---|
| background | `#F5F0E6` | `#0B0D12` |
| surface | `#FFFDF8` | `#141820` |
| surface-2 | `#F0EADD` | `#1A202A` |
| text | `#202024` | `#F2F5FA` |
| text-muted | `#7A7A80` | `#8D97A8` |
| line | `#E6DFD2` | `#252C38` |
| blue | `#2F7CF6` | `#54A7FF` |
| coral | `#FF6B5E` | `#FF7468` |
| green | `#37B58B` | `#4EC9A5` |
| amber | `#D99A3D` | `#F0B35B` |

播放器始终深色；弹幕白色字 + 细黑描边，保证亮暗画面可读。

### 5.2 字体

- 品牌/标题/按钮：Chill Round Gothic 500/700（与桌面一致）。
- 正文/评论：系统字体（SF / Roboto / 思源黑体）保证小字号可读性。
- 数字：等宽数字（时间、帧率、码率）。
- 正文 15–16pt，辅助 12–13pt，最小 11pt；支持动态字体/缩放。

### 5.3 形状与间距

- 8pt 网格；卡片 18px 圆角；sheet 24px 顶部圆角；按钮 12px / 胶囊 999px。
- 页面左右 16px；卡片间距 10–12px；底部安全区 + tab 高度。
- 触控目标 ≥44×44pt；播放器控件 ≥48pt。
- 底部 tab 4 项，活跃蓝色药丸/圆点；mini-player 悬浮在 tab 上方。

### 5.4 动效

- 页面 push 240ms；sheet 260ms；按钮 spring 180ms；卡片按压 scale 0.98。
- 播放器控件淡入淡出 180ms；手势提示一次性。
- `prefers-reduced-motion` / 系统减少动态效果时关闭非必要动画。
- 120Hz 下动画用原生驱动，不在 JS 每帧 setState。

### 5.5 组件

- `VideoCard`（横版/竖版/直播/历史进度）
- `ChannelChip`、`PillTabs`
- `MiniPlayer`
- `PlayerSheet`、`QualitySheet`、`SpeedSheet`、`DanmakuSheet`
- `CommentRow`、`FloorReplies`
- `AccountCard`
- `Skeleton`、`EmptyState`、`ErrorState`
- `Toast`、`ActionSheet`、`ConfirmDialog`

### 5.6 平台材质：iOS Liquid Glass / Android 磨砂玻璃

结论：**可以做，而且建议这样做**。但不是做两套完全不同的 UI，而是：

> **同一套布局、字体、颜色、间距、图标和交互；只把“玻璃材质”这一层换成平台原生实现。**

这样 iOS 有 iOS 26 的原生 Liquid Glass，Android 有桌面端同款的暖纸磨砂玻璃，同时仍然是同一个 O11A1。

#### 设计规则

1. **玻璃只用在“框架层”**：底部 tab、顶部导航、mini-player、sheet 顶部、播放器控制条。内容卡片、列表、评论、设置行保持扁平暖纸/墨色，不铺玻璃。
2. **一层玻璃**：同一区域不要玻璃叠玻璃；iOS 用 `GlassContainer` 把相邻玻璃合成一层。
3. **不改变布局**：两端 tab 高度、图标、文字、间距一致；iOS 可以浮起成胶囊，Android 可以是通栏，但信息结构一致。
4. **不遮视频**：播放器画面本身不盖玻璃；只有控制条/按钮可以半透明。
5. **可读性优先**：浅色玻璃配深色字，深色玻璃配白字；对比度不足时自动回退到实色。
6. **尊重辅助功能**：开启“降低透明度”时全部回退到实色/半透明纸面，不显示玻璃。

#### 平台实现

| 层级 | iOS 26+ | iOS 16.4–25 | Android 12+ | Android <12 |
|---|---|---|---|---|
| 材质 | `expo-glass-effect` 的 `GlassView` / `GlassContainer`（原生 `UIGlassEffect`） | `expo-blur` 的 `BlurView`（`systemMaterial`），或实色纸面 | `expo-blur` 的 `BlurView` + `BlurTargetView`，`blurMethod="dimezisBlurViewSdk31Plus"` | 半透明暖纸 + 1px 发丝线，无模糊 |
| 底部 tab | 浮起胶囊，圆角 28，距边 10–12 | 同布局，毛玻璃/实色 | 通栏磨砂，顶部发丝线 | 通栏半透明暖纸 |
| 顶部导航 | 滚动时玻璃化 | 毛玻璃/实色 | 滚动时磨砂 | 半透明暖纸 |
| mini-player | 玻璃胶囊 | 毛玻璃胶囊 | 磨砂深色胶囊 | 深色半透明胶囊 |
| sheet | 玻璃背景 + grabber | 毛玻璃 sheet | 磨砂暖纸 sheet | 暖纸实色 sheet |
| 播放器控制 | 深色玻璃按钮/胶囊 | 深色毛玻璃 | 深色磨砂条 + 发丝线 | 深色半透明条 |
| 内容卡片 | 扁平暖纸 | 扁平暖纸 | 扁平暖纸 | 扁平暖纸 |

#### iOS 实现要点

- 包：`expo-glass-effect`（SDK 58 对应 `~58.0.5`）。
- 组件：`GlassView`、`GlassContainer`；`glassEffectStyle` 用 `regular`（bars/sheets）或 `clear`（小按钮）；`isInteractive` 给可点击控件；`tintColor` 用暖纸色，避免重色。
- 守卫：
  - `isLiquidGlassAvailable()`：系统/编译器/Info.plist 是否支持。
  - `isGlassEffectAPIAvailable()`：部分 iOS 26 beta 没有 API，必须先检查。
  - `AccessibilityInfo.isReduceTransparencyEnabled()`：开启时回退实色。
- 回退：iOS <26 用 `BlurView` + `systemMaterial`，或直接暖纸实色；不要假装有 Liquid Glass。
- 不要在 `GlassView` 或父视图上用低 opacity；Apple 明确不推荐，会不渲染玻璃。

#### Android 实现要点

- 包：`expo-blur`（SDK 58 对应 `~58.0.6`）。
- 结构：把需要被模糊的内容包在 `BlurTargetView` 里，把 `BlurView` 作为同层 sibling 放上去，传 `blurTarget` ref。
- 参数：`blurMethod="dimezisBlurViewSdk31Plus"`（Android 12+ 真模糊，旧版自动回退半透明）；`intensity` 70–85；`tint` 用暖纸色；`blurReductionFactor` 先保持默认 4，两端对比后再调。
- **RN Modal 里不能用 Android blur**：Modal 是独立窗口，BlurTargetView 跨不过去。播放器 sheet、评论 sheet 要用同层 absolute overlay，不要用 RN `Modal`。
- 性能：只在静态/低频变化的 bar 上用模糊；不要在滚动卡片、视频画面上实时模糊；120Hz 设备先测；低端机/省电模式关闭模糊。

#### 共享组件：`GlassSurface`

```tsx
function GlassSurface({ children, style, dark = false }) {
  const reduce = useReduceTransparency();

  if (Platform.OS === 'ios') {
    if (!reduce && isLiquidGlassAvailable() && isGlassEffectAPIAvailable()) {
      return (
        <GlassView
          style={style}
          glassEffectStyle="regular"
          colorScheme={dark ? 'dark' : 'light'}
          tintColor={dark ? 'rgba(20,24,32,0.55)' : 'rgba(255,253,248,0.45)'}
        >
          {children}
        </GlassView>
      );
    }
    return <BlurView intensity={70} tint={dark ? 'dark' : 'light'} style={style}>{children}</BlurView>;
  }

  if (Platform.OS === 'android' && blurTarget) {
    return (
      <BlurView
        blurTarget={blurTarget}
        blurMethod="dimezisBlurViewSdk31Plus"
        intensity={78}
        tint={dark ? 'dark' : 'light'}
        style={style}
      >
        {children}
      </BlurView>
    );
  }

  return <View style={[style, dark ? styles.solidDark : styles.solidLight]}>{children}</View>;
}
```

#### 验收

- iOS 26：tab/导航/mini/sheet/播放器控制是原生 Liquid Glass；降低透明度后变实色；iOS <26 不崩、有毛玻璃/实色回退。
- Android 12+：tab/导航/mini/sheet 有真实磨砂；滚动时不掉帧；Android <12 是半透明暖纸。
- 两端：同一页面截图对比，布局、字号、图标、间距一致，只有材质/浮起方式不同；120Hz 下滚动和播放器不掉帧。
- 真机：iPhone 13 Pro（iOS 26）和 Android 12+ 各一台；模拟器只做 UI 检查。

## 6. 技术架构

### 6.1 总览

```text
React Native / Expo UI
  ├─ 页面、导航、状态、设置、评论、搜索
  ├─ Expo Module: O11A1Core      ← Rust core (FFI)
  ├─ Expo View:   O11A1Player    ← Android/iOS native player
  └─ Expo Module: O11A1Storage   ← Keychain/Keystore, MMKV/SQLite, files

Rust core (复用桌面 o11a1-core)
  ├─ Bilibili API / WBI / playurl / nav / feed / search
  ├─ 收藏 / 历史 / 动态 / 消息 / 番剧 / 直播 / 下载
  ├─ 弹幕 XML / protobuf 解析
  └─ 账号 cookie / 刷新 / -101 处理

Native player
  ├─ Android: Media3 ExoPlayer (DASH/Audio) + SurfaceTexture + GLES
  │    ├─ blend 插帧 / CAS / Anime4K
  │    └─ 弹幕 overlay / HUD / A/V sync
  └─ iOS: AVPlayer / VideoToolbox + Metal
       ├─ blend 插帧 / CAS / Anime4K
       └─ 弹幕 overlay / ProMotion / HUD
```

### 6.2 为什么复用 Rust core

桌面端 `o11a1-core` 已经有 WBI、playurl、nav、feed、search、收藏、历史、直播、PGC、下载、弹幕解析和 251 个测试。手机端如果再用 TypeScript 重写一遍，会重复维护最容易被 B 站改坏的接口。建议：

- 用 UniFFI 把 `o11a1-core` 编成 Android/iOS 静态库。
- Expo Module `O11A1Core` 暴露 `loginQr`、`pollLogin`、`nav`、`feed`、`search`、`videoDetail`、`playurl`、`favorites`、`history`、`dynamic`、`messages`、`live`、`pgc`、`danmaku`、`download`。
- Cookie 只在 Rust/原生层和 Keychain/Keystore 之间传递，不进 JS 日志。
- 桌面端 `native_player` 是 Windows D3D11/DComp/WASAPI + FFmpeg，不能直接复用；手机端用平台播放器。

### 6.3 播放器

**Android**

- Media3 ExoPlayer 负责 DASH、音频、缓冲、seek、直播 FLV/HLS。
- 视频输出到 `SurfaceTexture`，GLES 做 blend 插帧 + CAS/Anime4K，再显示到 `SurfaceView`/`TextureView`。
- 音频由 ExoPlayer/AudioTrack 输出，作为主时钟；视频按音频时钟取帧。
- 硬解优先，失败/花屏回退软解；HUD 显示实际解码器。
- 高刷：`SurfaceView` + `Choreographer`/`FrameCallback` 按 display Hz；120Hz 设备目标 120。
- 弹幕用 GL/Canvas 原生层绘制，跟随播放器时钟。

**iOS**

- 当前原型使用 VideoToolbox + Metal；继续保留，用于自定义 DASH/双轨与后处理。
- 或用 AVPlayer + AVPlayerItemVideoOutput，音频/视频双轨由 AVPlayer 管理；Metal 做 blend/CAS。
- ProMotion：`CADisableMinimumFrameDurationOnPhone=true` + `CADisplayLink.preferredFrameRateRange` / `MTKView.preferredFramesPerSecond=120`。
- 弹幕用 Metal/Core Animation 原生层；PiP 用 AVPictureInPictureController。

**统一接口**

```ts
type PlayerSource = {
  videoUrl: string;
  audioUrl: string;
  quality: number;
  codec: 'avc' | 'hevc' | 'av1';
  startMs?: number;
};

type PlayerConfig = {
  interp: 0 | 60 | 90 | 120 | 'auto';
  enhance: 0 | 1 | 2; // off / CAS / Anime4K
  danmaku: DanmakuConfig;
  speed: number;
  loop: 'pause' | 'one' | 'next' | 'nextPart';
};
```

事件：`onProgress`、`onState`、`onStats`、`onError`、`onDanmaku`、`onEnded`。

### 6.4 账号与安全

- 二维码登录：Rust 生成/轮询；cookie 存 Keychain/Keystore；不写明文文件。
- 启动校验 `nav`；-101 清 session、保留上次头像、回扫码页。
- 画质档位随登录态刷新；匿名 480P 缓存不能带到登录后。
- 日志脱敏：SESSDATA/bili_jct/refresh_token 永不打印；分享/导出日志前过滤。
- 下载/缓存仅个人使用；不上传、不二次分发。

### 6.5 网络与缓存

- 图片：480px CDN 缩略图 → 原图 → 占位；内存/磁盘缓存。
- 首页：首屏 + 预取两批；下拉刷新换一批。
- 视频：DASH 预取/缓冲；本地缓存分片；断点续传。
- 弱网：720P/480P 降级；缓冲 spinner；错误重试。
- 直播：低延迟优先，允许更大 A/V 偏差。

### 6.6 构建与测试

- 保留现有 GitHub Actions：Android debug APK + iOS unsigned IPA；后续加 Expo dev client / 真机签名。
- Rust core 单元测试沿用桌面；播放器需要真机测试（模拟器只验证 UI/管线，不代表硬解/120Hz）。
- 验收机型：至少一台 120Hz Android、一台 iPhone 13 Pro/Pro Max、一台 60Hz 设备。
- 关键指标：首帧时间、seek 延迟、丢帧、A/V gap、发热降频、120Hz 稳定性。

## 7. 版本路线

| 阶段 | 内容 | 验收 |
|---|---|---|
| **P0 现在** | 真机播放器稳定：硬解、A/V 同步、120Hz、弹幕、画质/倍速/插帧/增强 | Android/iPhone 真机能播测试片；120Hz 屏幕 target/render 到 120；无花屏/音画不同步 |
| **P1 MVP** | 二维码登录、首页、搜索、详情、B 站 DASH 播放、弹幕、画质/音轨/倍速、插帧/增强、收藏/历史、设置 | 用自己账号完整看一个视频；切画质/倍速/插帧/增强不崩；-101 正确回登录 |
| **P2** | 番剧、直播、评论、动态、消息、PiP/后台、离线缓存、精准模式/A-B | 番剧/直播可播；后台/PiP 正常；缓存可管理 |
| **P3** | 会员、AI 养鱼/切片、测试实验室、投屏、更多桌面级工具 | 按需 |

## 8. 风险

- **B 站接口/WBI 变化**：复用 Rust core，减少重复实现；接口失败要有明确错误和回退。
- **第三方客户端 ToS/分发**：个人 sideload/TestFlight 优先；应用商店上架有政策风险。
- **4K/大会员**：不做绕过；按账号真实权限展示/锁定。
- **Android 解码器碎片化**：硬解失败回退软解；HUD 暴露实际解码器；真机验收。
- **120Hz/发热**：高刷+4K+插帧+增强会热；自动降档/提示；不要默认全开。
- **iOS 后台/PiP**：系统限制多；先做前台播放，再做 PiP/后台音频。
- **弹幕性能**：必须原生层；RN 每帧渲染会掉帧。
- **模拟器不可靠**：Codec2/SurfaceTexture/GPU 与真机差异大；以真机为准。

## 9. 待确认

1. 默认主题：暖纸浅色（桌面同款）还是深色？建议跟随系统，浅色用暖纸。
2. 根 tab 4 个（首页/动态/消息/我的）是否够？建议 4 个 + 搜索图标 + 首页 channels。
3. 是否复用 Rust core（推荐是）？还是先用 TypeScript 快速做 MVP？
4. Android 播放器：Media3 ExoPlayer + GL（推荐）还是自写 MediaCodec + HTTP？
5. 离线缓存优先级：P1 还是 P2？
6. 分发方式：个人签名/TestFlight，还是尝试上架？

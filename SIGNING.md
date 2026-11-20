# iOS 本地签名方案（免费 Apple ID，无付费开发者账号）

本仓库的 iOS 产物是 **unsigned IPA**：`o11a1-ios-unsigned.ipa`。下面只讨论“自己用、自己签名、不买 99 美元/年 Apple Developer Program”的方案。

## 0. 先理解：免费 Apple ID 也能签名

任何 Apple ID 在 Xcode 或签名工具里登录后，都会自动得到一个 **Personal Team（免费开发者账号）**。它不是“没有开发者权限”，而是 Apple 提供的免费开发签名：

| 项目 | 免费 Apple ID（Personal Team） |
|---|---|
| 签名有效期 | 7 天 |
| 同时安装 App | 每台设备最多 3 个 |
| App ID | 每 7 天最多 10 个 |
| 注册设备 | 最多 3 台，7 天有效 |
| 分发 | 只能自己用，不能给别人、TestFlight、App Store |
| 不支持的能力 | 推送、iCloud、Sign in with Apple、IAP、Apple Pay、Associated Domains 等 |

本项目只使用 Metal、VideoToolbox 和本地文件，不需要任何受限能力，所以免费账号可以签。

## 1. 所有方案总表

| 方案 | 运行位置 | 直接登录 Apple ID | 免费账号 | 有效期 / 刷新 | 电脑要求 | 适合 |
|---|---|---|---|---|---|---|
| **Sideloadly** | Windows / macOS | ✅ | ✅ | 7 天；可自动重签 | 需要，刷新时电脑要能连到手机 | **Windows 首选，最简单** |
| **AltStore Classic + AltServer** | Windows / macOS | ✅ | ✅ | 7 天；AltServer 刷新 | 需要，AltServer 常开 | 生态成熟，可装 AltStore 源 |
| **SideStore + iloader** | Windows / macOS / Linux | ✅ | ✅ | 7 天；手机端自动刷新 | 仅首次安装需要 | 不想每周连电脑 |
| **Xcode Personal Team** | macOS | ✅ | ✅ | 7 天；重新 Run | 需要 Mac | 苹果官方路线 |
| **Xcode + iOS App Signer** | macOS | 间接（用 Xcode 免费证书） | ✅ | 7 天；手动 | 需要 Mac | 想签现成 IPA |
| **codesign / ldid + 免费 profile** | macOS | 间接 | ✅ | 7 天；手动 | 需要 Mac | 脚本/进阶 |
| **TrollStore** | iOS 设备 | ❌ 不需要 | 永久 | 无 | 无 | **仅特定 iOS 版本** |
| **Feather / KSign** | iOS 设备 | ❌ 需要证书 | ❌ | 证书有效期 | 无 | 有付费证书/购买证书 |
| **ESign / Scarlet / GBox / 3uTools** | iOS / Windows | ❌ 证书或共享证书 | 视证书 | 证书有效期 | 无 | 不推荐共享证书 |
| **AltStore PAL** | iOS（EU/日本/巴西） | ✅ | 不需要 | 不过期 | 无 | 地区限制，中国大陆不适用 |
| **付费 Developer Program / TestFlight / Ad Hoc** | 任意 | ✅ | ❌ 99 美元/年 | 1 年 | — | 要分发/上架 |
| **Apple Configurator / iMazing / ideviceinstaller / pymobiledevice3 / ios-deploy** | Windows / macOS | ❌ | — | — | — | **只能安装，不能签名** |

## 2. 直接登录 Apple ID 的方案（推荐）

### 2.1 Sideloadly（Windows 首选）

官方：https://sideloadly.io  
官方下载镜像：https://github.com/sideloadlyios/sideloadly-download

支持 Windows 7+、macOS 10.12+、iOS 7–27+，免费 Apple ID 和付费账号都能用。

Windows 前置条件（**不要用 Microsoft Store 版**）：

- iTunes 官网版：https://www.apple.com/itunes/download/win64
- iCloud 官网版：Sideloadly 下载页提供的 iCloud 链接

或者用 winget 装 Apple 官网版本：

```powershell
winget install --id Apple.iTunes -e
winget install --id Apple.iCloud -e
```

步骤：

1. 安装 iTunes + iCloud，重启电脑。
2. 连接 iPhone，解锁，点“信任此电脑”。
3. 打开 Sideloadly，确认设备出现在顶部。
4. 把 `o11a1-ios-unsigned.ipa` 拖进去。
5. 输入 Apple ID 和密码；有 2FA 就输入验证码（或使用 App 专用密码）。
6. 点 Start，等待完成。
7. iPhone：设置 → 通用 → VPN 与设备管理 → 点你的 Apple ID → 信任。
8. iOS 16+：设置 → 隐私与安全性 → 开发者模式 → 打开 → 重启。
9. 打开 App；7 天后重新连接 Sideloadly 重签，或开启自动刷新守护进程。

注意：

- Sideloadly 本身不占手机的 3 个 App 名额；你装的 IPA 才占。
- 免费账号最多 3 个 App；如果同时装了 AltStore/SideStore，它们也占名额。
- 报 `maximum App ID limit`：等 7 天，或换一个 Apple ID。
- 报 `Untrusted Developer`：去 VPN 与设备管理里信任。
- 设备不显示：确认 iTunes/iCloud 是官网版、Apple Mobile Device Service 正在运行、换 USB 口/线、重启电脑。

### 2.2 AltStore Classic + AltServer

官方：https://altstore.io  
Windows 安装说明：https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows  
源码：https://github.com/altstoreio/AltStore

- Windows 10+ / macOS 11+。
- Windows 需要 iTunes + iCloud 官网版（AltServer 用它们登录 Apple ID 和连接设备）。
- 用 AltServer 安装 AltStore；AltStore 本身占一个免费 App 名额。
- 之后在 AltStore 里导入 IPA，7 天内刷新；AltServer 要在同一 Wi-Fi 或 USB 可达。
- 适合想长期用 AltStore 管理多个 App 的人。

### 2.3 SideStore + iloader（不想每周连电脑）

官方：https://sidestore.io  
文档：https://docs.sidestore.io  
源码：https://github.com/SideStore/SideStore  
iloader：https://iloader.app / https://github.com/nab138/iloader

- iOS 15+，需要设置锁屏密码。
- 首次在电脑上用 iloader 登录 Apple ID，安装 SideStore 并写入 pairing file；Windows 需要 iTunes（官网版或 Microsoft Store 版都行，推荐官网版）。
- 手机安装 **LocalDevVPN**（App Store 免费），安装/刷新时保持连接。
- 之后 SideStore 在手机端自动刷新，不再需要电脑；pairing file 在 iOS 升级/恢复后可能需要重新放置。
- 免费账号 3 个 App 限额，SideStore 自己占一个。

### 2.4 Xcode Personal Team（macOS 官方路线）

- 安装 Xcode，登录 Apple ID，Xcode 会自动创建 Personal Team。
- 打开 `expo-ui/ios/O11A1VideoLab.xcworkspace`（先 `npx expo prebuild --platform ios` + `pod install`），在 Signing & Capabilities 选自己的 Personal Team，改一个唯一 Bundle ID，连接 iPhone Run。
- 7 天后重新 Run；免费账号最多 3 个 App。
- 不需要 99 美元账号，但不能导出 Ad Hoc/TestFlight。

### 2.5 Xcode + iOS App Signer / codesign（macOS 进阶）

- 先用 Xcode 免费账号生成开发证书和 provisioning profile。
- 用 **iOS App Signer**（https://github.com/DanTheMan827/ios-app-signer）选择 IPA、证书、profile 重签，再用 Xcode Devices 或 `ios-deploy` 安装。
- 或者手动 `codesign -f -s "Apple Development: ..." --entitlements ...`。
- 适合已经熟悉证书/描述文件的人；对普通用户不如 Sideloadly 直接。

## 3. 不登录 Apple ID 的永久签名（仅特定 iOS）

**TrollStore**：https://github.com/opa334/TrollStore

- 支持：iOS/iPadOS **14.0 beta 2 – 16.6.1**、**16.7 RC (20H18)**、**17.0**。
- **iOS 17.0.1 及以上、iOS 18、iOS 26 永久不支持**（CoreTrust 漏洞已修）。
- 安装后 IPA 永久签名，不过期，不需要 Apple ID。
- 只适合正好在支持版本上的设备；先看 设置 → 通用 → 关于本机 → iOS 版本。

## 4. 证书签名（不是 Apple ID 登录）

代表工具：**Feather、KSign、ESign、Scarlet、GBox、3uTools**。

- 需要 `.p12` 证书 + `.mobileprovision` 描述文件。
- Feather 官方明确说明：它是给 **Apple Developer Program 证书** 用的，**不支持免费 Apple ID**。
- Scarlet/ESign/GBox 很多版本自带或共享证书；Apple 随时可能吊销，届时所有用同一证书的 App 一起打不开。
- 不要向这类工具输入 Apple ID 密码；签名只需要证书和 UDID。
- 只有在你已经有自己的证书，或愿意承担共享证书风险时才用。

## 5. 只能安装、不能签名

这些工具可以装已经签好的 IPA，但不能帮你用 Apple ID 生成签名：

- Apple Configurator（macOS）
- iMazing（Windows/macOS）
- `ideviceinstaller` / `libimobiledevice`（https://github.com/libimobiledevice/libimobiledevice）
- `pymobiledevice3`（https://github.com/doronz88/pymobiledevice3）
- `ios-deploy`（https://github.com/ios-control/ios-deploy）

## 6. 本项目的签名注意点

- Bundle ID：`com.o11a1.videolab`
- 最低系统：iOS 16.4（Expo SDK 58）
- IPA 约 15.5 MB（含 6 MB 测试视频）
- 免费账号 3 个 App 限制；Sideloadly 本身不占，AltStore/SideStore 占一个
- 7 天到期后重签，**不要先删除 App**，覆盖安装可以保留数据
- 如果 App ID 达到 10 个/7 天上限：等 7 天或换 Apple ID
- 首次打开如果提示“未受信任的开发者”：设置 → 通用 → VPN 与设备管理 → 信任
- iOS 16+ 必须打开开发者模式

## 7. 推荐顺序

1. **只想最快装上**：Windows 装 iTunes + iCloud 官网版 → Sideloadly → 登录 Apple ID → 签 IPA。
2. **不想每周连电脑**：SideStore + iloader + LocalDevVPN。
3. **iOS 正好是 14.0–17.0**：可以看 TrollStore，永久免签。
4. **需要长期稳定/多设备/分发**：再考虑 99 美元 Developer Program 或购买个人证书；免费 Apple ID 不适合长期分发。

# O11A1 构建下载器

`O11A1-BuildWatcher.ps1` 是桌面上那个小窗口的源码。

## 用途

- 读取 `AntarcticBearHKL/O11A1-Mobile` 最近成功的 `ios-native` 和 `android-debug` 运行
- 显示运行号、提交、时间，以及 **IPA / APK 安装包的实际大小**
- 点“下载双端”把两个安装包直接下载到**桌面**：
  - `C:\Users\antar\Desktop\o11a1-ios-unsigned.ipa`
  - `C:\Users\antar\Desktop\app-debug.apk`
- 优先下载 GitHub Release 上的 IPA/APK，不再下载几十 MB 的 Actions artifact ZIP
- 如果 Release 资产暂时不可用，才回退到 Actions artifact
- 两张卡片里也有单独的“下载 IPA / 下载 APK”按钮，只下载对应平台
- 每次下载直接覆盖桌面上的这两个文件；下载失败时保留旧文件
- 底部“打开下载位置”会直接打开桌面
- 60 秒自动刷新，也可以手动点“刷新”

## 运行

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\O11A1-BuildWatcher.ps1
```

桌面快捷方式使用同样的命令，但加了 `-WindowStyle Hidden`，所以只显示窗口，不显示控制台。

## 参数

- `-SelfTest`：只在控制台打印两端最新成功构建，不显示 UI
- `-DownloadTest`：直接下载两端到下载目录，不显示 UI
- `-Screenshot <path>`：显示 UI，5 秒后截图并退出（用于检查布局）

## Token

脚本从 `%USERPROFILE%\.git-credentials` 读取第一个 `github.com` 的 token；Release 资产是公开的，但查询 Actions 运行和 fallback artifact 仍需要 token。

## 注意

- iOS 现在使用 `ios-native` 工作流和纯 Swift WKWebView，IPA 约 **5.8 MB**；不再是旧 Expo 包。
- Android 使用 `android-debug` 工作流，APK 约 **9.9 MB**。
- 只显示**最近成功**的构建；如果最新运行还在跑或失败，卡片里会提示并回退到上一次成功。

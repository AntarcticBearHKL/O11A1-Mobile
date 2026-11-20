# O11A1 构建下载器

`O11A1-BuildWatcher.ps1` 是桌面上那个小窗口的源码。

## 用途

- 读取 `AntarcticBearHKL/O11A1-Mobile` 最近成功的 `ios-unsigned` 和 `android-debug` 运行
- 显示运行号、提交、时间、artifact 大小
- 点“下载双端”把两个 artifact 下载并解压到：
  `%USERPROFILE%\Downloads\O11A1-Mobile`
  - `o11a1-ios-unsigned.ipa`
  - `app-debug.apk`
- 两张卡片里也有单独的“下载 IPA / 下载 APK”按钮，只下载对应平台
- 每次下载直接覆盖这两个文件；下载失败时保留旧文件
- 60 秒自动刷新，也可以手动点“刷新”

## 运行

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\O11A1-BuildWatcher.ps1
```

桌面快捷方式使用同样的命令，但加了 `-WindowStyle Hidden`，所以只显示窗口，不显示控制台。

## 参数

- `-SelfTest`：只在控制台打印两端最新成功构建，不显示 UI
- `-DownloadTest`：直接下载并解压两端到下载目录，不显示 UI
- `-Screenshot <path>`：显示 UI，5 秒后截图并退出（用于检查布局）

## Token

下载 Actions artifact 需要 GitHub 认证。脚本从 `%USERPROFILE%\.git-credentials` 读取第一个 `github.com` 的 token；没有 token 时仍能查看状态，但不能下载。

## 注意

- Actions artifact 需要登录，且会包含 iOS 的 simulator 包；iOS 的下载体积约 53 MB，解压后只保留 IPA。
- 只显示**最近成功**的构建；如果最新运行还在跑或失败，卡片里会提示并回退到上一次成功。

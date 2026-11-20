<#
  O11A1 Mobile · GitHub Actions build watcher
  - Reads the latest successful android-debug / ios-unsigned runs.
  - Downloads both artifacts and extracts app-debug.apk / o11a1-ios-unsigned.ipa.
  - Token: %USERPROFILE%\.git-credentials
  - Output: %USERPROFILE%\Downloads\O11A1-Mobile
#>
param(
  [switch]$SelfTest,
  [switch]$DownloadTest,
  [string]$Screenshot = ""
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Net.Http
Add-Type -AssemblyName System.IO.Compression.FileSystem

$Repo = "AntarcticBearHKL/O11A1-Mobile"
$ApiBase = "https://api.github.com"
$DownloadDir = Join-Path $env:USERPROFILE "Downloads\O11A1-Mobile"

$script:Token = $null
$script:Busy = $false
$script:Cancel = $false
$script:IosBuild = $null
$script:AndroidBuild = $null
$script:LastRefresh = $null

function Get-GitHubToken {
  $file = Join-Path $env:USERPROFILE ".git-credentials"
  if (-not (Test-Path -LiteralPath $file)) {
    return $null
  }
  foreach ($line in Get-Content -LiteralPath $file) {
    if ($line -notmatch "github\.com") {
      continue
    }
    try {
      $uri = [Uri]$line.Trim()
      if (-not $uri.UserInfo) {
        continue
      }
      $parts = $uri.UserInfo.Split(":", 2)
      if ($parts.Count -eq 2) {
        return [Uri]::UnescapeDataString($parts[1])
      }
    } catch {
      continue
    }
  }
  return $null
}

function Invoke-GitHubApi {
  param([Parameter(Mandatory = $true)][string]$Path)

  $headers = @{
    "User-Agent" = "O11A1-BuildWatcher"
    "Accept"     = "application/vnd.github+json"
  }
  if ($script:Token) {
    $headers["Authorization"] = "Bearer $($script:Token)"
  }
  Invoke-RestMethod -Uri ($ApiBase + $Path) -Headers $headers -Method Get -TimeoutSec 30
}

function Get-ApiErrorMessage {
  param($ErrorRecord)

  $message = $ErrorRecord.Exception.Message
  if ($ErrorRecord.ErrorDetails -and $ErrorRecord.ErrorDetails.Message) {
    try {
      $json = $ErrorRecord.ErrorDetails.Message | ConvertFrom-Json
      if ($json.message) {
        $message = $json.message
      }
    } catch {
      # Keep the original message.
    }
  }
  if ($ErrorRecord.Exception.Response) {
    try {
      $code = [int]$ErrorRecord.Exception.Response.StatusCode
      $message = "$message (HTTP $code)"
    } catch {
      # Keep the original message.
    }
  }
  return $message
}

function Get-WorkflowBuild {
  param(
    [Parameter(Mandatory = $true)][string]$WorkflowFile,
    [Parameter(Mandatory = $true)][string]$ArtifactName
  )

  $response = Invoke-GitHubApi -Path "/repos/$Repo/actions/workflows/$WorkflowFile/runs?per_page=20"
  $runs = @($response.workflow_runs | Where-Object { $_ })
  if ($runs.Count -eq 0) {
    return $null
  }

  $latest = $runs[0]
  $successes = @($runs | Where-Object {
    $_.status -eq "completed" -and $_.conclusion -eq "success"
  })

  foreach ($run in $successes) {
    $artifactsResponse = Invoke-GitHubApi -Path "/repos/$Repo/actions/runs/$($run.id)/artifacts"
    $matches = @($artifactsResponse.artifacts | Where-Object {
      $_ -and $_.name -eq $ArtifactName
    })
    if ($matches.Count -gt 0) {
      return [pscustomobject]@{
        Latest   = $latest
        Run      = $run
        Artifact = $matches[0]
      }
    }
  }

  return [pscustomobject]@{
    Latest   = $latest
    Run      = $null
    Artifact = $null
  }
}

function Save-GitHubArtifact {
  param(
    [Parameter(Mandatory = $true)][long]$ArtifactId,
    [Parameter(Mandatory = $true)][string]$OutFile,
    [string]$Label = "下载",
    [scriptblock]$OnProgress = $null
  )

  if (-not $script:Token) {
    throw "没有找到 GitHub token（~/.git-credentials），无法下载 Actions 产物"
  }

  $apiUrl = "$ApiBase/repos/$Repo/actions/artifacts/$ArtifactId/zip"
  $handler = New-Object System.Net.Http.HttpClientHandler
  $handler.AllowAutoRedirect = $false
  $handler.SslProtocols = [System.Security.Authentication.SslProtocols]::Tls12
  $client = New-Object -TypeName System.Net.Http.HttpClient -ArgumentList $handler

  $request = New-Object -TypeName System.Net.Http.HttpRequestMessage -ArgumentList ([System.Net.Http.HttpMethod]::Get), $apiUrl
  $request.Headers.Authorization = New-Object -TypeName System.Net.Http.Headers.AuthenticationHeaderValue -ArgumentList "Bearer", $script:Token
  $request.Headers.UserAgent.ParseAdd("O11A1-BuildWatcher")

  try {
    $response = $client.SendAsync($request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
    $statusCode = [int]$response.StatusCode
    if ($statusCode -ge 300 -and $statusCode -lt 400) {
      $location = $response.Headers.Location
      if (-not $location) {
        throw "GitHub 返回了重定向，但没有 Location"
      }
      if (-not $location.IsAbsoluteUri) {
        $location = [Uri]::new([Uri]$apiUrl, $location)
      }
      $response.Dispose()
      $client.Dispose()
      $handler.Dispose()

      $handler = New-Object System.Net.Http.HttpClientHandler
      $handler.AllowAutoRedirect = $true
      $handler.SslProtocols = [System.Security.Authentication.SslProtocols]::Tls12
      $client = New-Object -TypeName System.Net.Http.HttpClient -ArgumentList $handler
      $response = $client.GetAsync($location.AbsoluteUri, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
      $statusCode = [int]$response.StatusCode
    }

    if (-not $response.IsSuccessStatusCode) {
      throw "HTTP $statusCode $($response.ReasonPhrase)"
    }

    $total = $response.Content.Headers.ContentLength
    $stream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
    $file = [System.IO.File]::Create($OutFile)
    $buffer = New-Object byte[] 131072
    $read = 0
    $lastPercent = -1

    try {
      while (($count = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        if ($script:Cancel) {
          throw "已取消"
        }
        $file.Write($buffer, 0, $count)
        $read += $count
        if ($total -and $total -gt 0) {
          $percent = [int](100 * $read / $total)
          if ($percent -ne $lastPercent) {
            $lastPercent = $percent
            if ($OnProgress) {
              & $OnProgress $Label $percent $read $total
            }
          }
        }
      }
    } finally {
      $file.Dispose()
      $stream.Dispose()
      $response.Dispose()
      $client.Dispose()
      $handler.Dispose()
    }
  } catch {
    try { $request.Dispose() } catch { }
    try { $client.Dispose() } catch { }
    try { $handler.Dispose() } catch { }
    throw
  }
}

function Extract-ArtifactFile {
  param(
    [Parameter(Mandatory = $true)][string]$ZipPath,
    [Parameter(Mandatory = $true)][string]$EntryName,
    [Parameter(Mandatory = $true)][string]$Destination
  )

  $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
  try {
    $entry = $zip.Entries | Where-Object {
      $_.FullName -eq $EntryName -or $_.Name -eq $EntryName
    } | Select-Object -First 1

    if (-not $entry) {
      throw "压缩包里没有 $EntryName"
    }

    $directory = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $directory)) {
      New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $Destination, $true)
  } finally {
    $zip.Dispose()
  }
}

function Download-BuildCore {
  param(
    [Parameter(Mandatory = $true)]$Build,
    [Parameter(Mandatory = $true)][string]$Kind,
    [Parameter(Mandatory = $true)][string]$EntryName,
    [Parameter(Mandatory = $true)][string]$OutDir,
    [scriptblock]$OnProgress = $null
  )

  if (-not $Build -or -not $Build.Run -or -not $Build.Artifact) {
    throw "$Kind 没有可下载的成功构建"
  }

  if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
  }

  $runNumber = $Build.Run.run_number
  $zipPath = Join-Path $env:TEMP "o11a1-$Kind-$runNumber.zip"

  if ($Kind -eq "iOS") {
    $targetName = "o11a1-ios-unsigned.ipa"
    $oldPattern = "o11a1-ios-unsigned-r*.ipa"
  } else {
    $targetName = "app-debug.apk"
    $oldPattern = "app-debug-r*.apk"
  }
  $destination = Join-Path $OutDir $targetName
  $partial = "$destination.part"

  try {
    Save-GitHubArtifact -ArtifactId $Build.Artifact.id -OutFile $zipPath -Label $Kind -OnProgress $OnProgress
    Extract-ArtifactFile -ZipPath $zipPath -EntryName $EntryName -Destination $partial
    Move-Item -LiteralPath $partial -Destination $destination -Force
    Get-ChildItem -LiteralPath $OutDir -Filter $oldPattern -ErrorAction SilentlyContinue |
      Remove-Item -Force -ErrorAction SilentlyContinue
  } finally {
    Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue
  }

  return $destination
}

function Write-SelfTest {
  $ios = Get-WorkflowBuild -WorkflowFile "ios-unsigned.yml" -ArtifactName "o11a1-ios-unsigned"
  $android = Get-WorkflowBuild -WorkflowFile "android-debug.yml" -ArtifactName "o11a1-video-test-debug"

  foreach ($item in @(
      @{ Name = "iOS"; Build = $ios },
      @{ Name = "Android"; Build = $android }
    )) {
    $build = $item.Build
    if (-not $build -or -not $build.Run) {
      Write-Output "$($item.Name)|none"
      continue
    }
    $size = if ($build.Artifact) { [math]::Round($build.Artifact.size_in_bytes / 1MB, 2) } else { 0 }
    $artifact = if ($build.Artifact) { $build.Artifact.name } else { "none" }
    Write-Output ("{0}|#{1}|{2}|{3}|{4}|{5}|{6}|{7}" -f `
        $item.Name,
      $build.Run.run_number,
      $build.Run.conclusion,
      $build.Run.head_sha.Substring(0, 7),
      ([datetime]$build.Run.created_at).ToLocalTime().ToString("yyyy-MM-dd HH:mm"),
      $artifact,
      $size,
      $build.Run.html_url)
  }
}

if ($SelfTest) {
  $script:Token = Get-GitHubToken
  Write-SelfTest
  exit 0
}

if ($DownloadTest) {
  $script:Token = Get-GitHubToken
  $ios = Get-WorkflowBuild -WorkflowFile "ios-unsigned.yml" -ArtifactName "o11a1-ios-unsigned"
  $android = Get-WorkflowBuild -WorkflowFile "android-debug.yml" -ArtifactName "o11a1-video-test-debug"
  $onProgress = {
    param($label, $percent, $read, $total)
    Write-Progress -Activity "下载 $label" -Status "$percent%  $([math]::Round($read / 1MB, 1)) / $([math]::Round($total / 1MB, 1)) MB" -PercentComplete $percent
  }
  $iosPath = Download-BuildCore -Build $ios -Kind "iOS" -EntryName "o11a1-ios-unsigned.ipa" -OutDir $DownloadDir -OnProgress $onProgress
  $androidPath = Download-BuildCore -Build $android -Kind "Android" -EntryName "app-debug.apk" -OutDir $DownloadDir -OnProgress $onProgress
  Write-Output "iOS=$iosPath"
  Write-Output "Android=$androidPath"
  exit 0
}

# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------

$script:Token = Get-GitHubToken

[Windows.Forms.Application]::EnableVisualStyles()
[Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

$Bg = [Drawing.ColorTranslator]::FromHtml("#0b0d12")
$PanelBg = [Drawing.ColorTranslator]::FromHtml("#141820")
$Panel2 = [Drawing.ColorTranslator]::FromHtml("#1a202a")
$Line = [Drawing.ColorTranslator]::FromHtml("#252c38")
$Ink = [Drawing.ColorTranslator]::FromHtml("#f2f5fa")
$Muted = [Drawing.ColorTranslator]::FromHtml("#8d97a8")
$Faint = [Drawing.ColorTranslator]::FromHtml("#5d6676")
$Blue = [Drawing.ColorTranslator]::FromHtml("#54a7ff")
$Green = [Drawing.ColorTranslator]::FromHtml("#4ec9a5")
$Amber = [Drawing.ColorTranslator]::FromHtml("#f0b35b")
$Red = [Drawing.ColorTranslator]::FromHtml("#ff7468")
$Coral = [Drawing.ColorTranslator]::FromHtml("#ff7468")

$FontBase = [Drawing.Font]::new("Microsoft YaHei UI", 9)
$FontSmall = [Drawing.Font]::new("Microsoft YaHei UI", 8)
$FontTiny = [Drawing.Font]::new("Microsoft YaHei UI", 7.5)
$FontBold = [Drawing.Font]::new("Microsoft YaHei UI", 9, [Drawing.FontStyle]::Bold)
$FontPlatform = [Drawing.Font]::new("Microsoft YaHei UI", 12, [Drawing.FontStyle]::Bold)
$FontRun = [Drawing.Font]::new("Microsoft YaHei UI", 26, [Drawing.FontStyle]::Bold)
$FontTitle = [Drawing.Font]::new("Microsoft YaHei UI", 18, [Drawing.FontStyle]::Bold)

$form = New-Object System.Windows.Forms.Form
$form.Text = "O11A1 Mobile · 构建下载器"
$form.ClientSize = [Drawing.Size]::new(840, 500)
$form.BackColor = $Bg
$form.ForeColor = $Ink
$form.Font = $FontBase
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [Windows.Forms.FormBorderStyle]::FixedSingle
$form.MaximizeBox = $false
$form.MinimizeBox = $true

$formIcon = Join-Path $PSScriptRoot "O11A1.ico"
if (Test-Path -LiteralPath $formIcon) {
  try { $form.Icon = [Drawing.Icon]::new($formIcon) } catch { }
}

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "O11A1 MOBILE"
$titleLabel.Font = $FontTitle
$titleLabel.ForeColor = $Ink
$titleLabel.AutoSize = $true
$titleLabel.Location = [Drawing.Point]::new(24, 16)
$form.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "GitHub Actions · 最新构建下载器"
$subtitleLabel.Font = $FontSmall
$subtitleLabel.ForeColor = $Muted
$subtitleLabel.AutoSize = $true
$subtitleLabel.Location = [Drawing.Point]::new(26, 54)
$form.Controls.Add($subtitleLabel)

$badgeLabel = New-Object System.Windows.Forms.Label
$badgeLabel.Text = "VIDEO LAB"
$badgeLabel.Font = [Drawing.Font]::new("Microsoft YaHei UI", 8, [Drawing.FontStyle]::Bold)
$badgeLabel.ForeColor = $Blue
$badgeLabel.AutoSize = $true
$badgeLabel.Location = [Drawing.Point]::new(748, 22)
$form.Controls.Add($badgeLabel)

function New-BuildCard {
  param(
    [string]$Platform,
    [string]$Subtitle,
    [Drawing.Color]$Accent,
    [int]$X,
    [int]$Y
  )

  $card = New-Object System.Windows.Forms.Panel
  $card.Location = [Drawing.Point]::new($X, $Y)
  $card.Size = [Drawing.Size]::new(388, 250)
  $card.BackColor = $PanelBg
  $card.Add_Paint({
      param($sender, $eventArgs)
      $pen = New-Object Drawing.Pen($Line)
      $eventArgs.Graphics.DrawRectangle($pen, 0, 0, $sender.Width - 1, $sender.Height - 1)
      $pen.Dispose()
    })
  $form.Controls.Add($card)

  $accentBar = New-Object System.Windows.Forms.Panel
  $accentBar.Location = [Drawing.Point]::new(0, 0)
  $accentBar.Size = [Drawing.Size]::new(388, 3)
  $accentBar.BackColor = $Accent
  $card.Controls.Add($accentBar)

  $platformLabel = New-Object System.Windows.Forms.Label
  $platformLabel.Text = $Platform
  $platformLabel.Font = $FontPlatform
  $platformLabel.ForeColor = $Ink
  $platformLabel.AutoSize = $true
  $platformLabel.BackColor = [Drawing.Color]::Transparent
  $platformLabel.Location = [Drawing.Point]::new(16, 14)
  $card.Controls.Add($platformLabel)

  $subtitleLabel = New-Object System.Windows.Forms.Label
  $subtitleLabel.Text = $Subtitle
  $subtitleLabel.Font = $FontSmall
  $subtitleLabel.ForeColor = $Muted
  $subtitleLabel.AutoSize = $true
  $subtitleLabel.BackColor = [Drawing.Color]::Transparent
  $subtitleLabel.Location = [Drawing.Point]::new(16, 40)
  $card.Controls.Add($subtitleLabel)

  $statusLabel = New-Object System.Windows.Forms.Label
  $statusLabel.Text = "查询中"
  $statusLabel.Font = $FontBold
  $statusLabel.ForeColor = $Faint
  $statusLabel.TextAlign = [Drawing.ContentAlignment]::MiddleRight
  $statusLabel.Size = [Drawing.Size]::new(100, 22)
  $statusLabel.BackColor = [Drawing.Color]::Transparent
  $statusLabel.Location = [Drawing.Point]::new(272, 16)
  $card.Controls.Add($statusLabel)

  $runLabel = New-Object System.Windows.Forms.Label
  $runLabel.Text = "#—"
  $runLabel.Font = $FontRun
  $runLabel.ForeColor = $Ink
  $runLabel.AutoSize = $true
  $runLabel.BackColor = [Drawing.Color]::Transparent
  $runLabel.Location = [Drawing.Point]::new(16, 64)
  $card.Controls.Add($runLabel)

  $metaLabel = New-Object System.Windows.Forms.Label
  $metaLabel.Text = "提交 —`n时间 —"
  $metaLabel.Font = $FontSmall
  $metaLabel.ForeColor = $Muted
  $metaLabel.AutoSize = $false
  $metaLabel.Size = [Drawing.Size]::new(356, 38)
  $metaLabel.BackColor = [Drawing.Color]::Transparent
  $metaLabel.Location = [Drawing.Point]::new(16, 116)
  $card.Controls.Add($metaLabel)

  $artifactLabel = New-Object System.Windows.Forms.Label
  $artifactLabel.Text = "产物 —"
  $artifactLabel.Font = $FontSmall
  $artifactLabel.ForeColor = $Muted
  $artifactLabel.AutoSize = $false
  $artifactLabel.Size = [Drawing.Size]::new(356, 20)
  $artifactLabel.BackColor = [Drawing.Color]::Transparent
  $artifactLabel.Location = [Drawing.Point]::new(16, 162)
  $card.Controls.Add($artifactLabel)

  $noteLabel = New-Object System.Windows.Forms.Label
  $noteLabel.Text = ""
  $noteLabel.Font = $FontTiny
  $noteLabel.ForeColor = $Amber
  $noteLabel.AutoSize = $false
  $noteLabel.Size = [Drawing.Size]::new(356, 24)
  $noteLabel.BackColor = [Drawing.Color]::Transparent
  $noteLabel.Location = [Drawing.Point]::new(16, 184)
  $card.Controls.Add($noteLabel)

  $linkLabel = New-Object System.Windows.Forms.LinkLabel
  $linkLabel.Text = "在 GitHub 查看运行"
  $linkLabel.Font = $FontSmall
  $linkLabel.LinkColor = $Blue
  $linkLabel.ActiveLinkColor = $Ink
  $linkLabel.VisitedLinkColor = $Blue
  $linkLabel.AutoSize = $true
  $linkLabel.BackColor = [Drawing.Color]::Transparent
  $linkLabel.Location = [Drawing.Point]::new(16, 218)
  $linkLabel.LinkArea = [Windows.Forms.LinkArea]::new(0, $linkLabel.Text.Length)
  $linkLabel.Add_LinkClicked({
      param($sender, $eventArgs)
      if ($sender.Tag) {
        Start-Process $sender.Tag
      }
    })
  $card.Controls.Add($linkLabel)

  $hover = [Drawing.Color]::FromArgb(
    [Math]::Min(255, [int]$Accent.R + 28),
    [Math]::Min(255, [int]$Accent.G + 28),
    [Math]::Min(255, [int]$Accent.B + 28)
  )

  $downloadLabel = if ($Platform -eq "iOS") { "下载 IPA" } else { "下载 APK" }
  $downloadButton = New-Object System.Windows.Forms.Button
  $downloadButton.Text = $downloadLabel
  $downloadButton.Font = $FontBold
  $downloadButton.Size = [Drawing.Size]::new(120, 30)
  $downloadButton.Location = [Drawing.Point]::new(252, 210)
  $downloadButton.FlatStyle = [Windows.Forms.FlatStyle]::Flat
  $downloadButton.FlatAppearance.BorderSize = 0
  $downloadButton.FlatAppearance.MouseOverBackColor = $hover
  $downloadButton.BackColor = $Accent
  $downloadButton.ForeColor = [Drawing.ColorTranslator]::FromHtml("#07101c")
  $downloadButton.Cursor = [Windows.Forms.Cursors]::Hand
  $downloadButton.Enabled = $false
  $card.Controls.Add($downloadButton)

  return [pscustomobject]@{
    Panel    = $card
    Status   = $statusLabel
    Run      = $runLabel
    Meta     = $metaLabel
    Artifact = $artifactLabel
    Note     = $noteLabel
    Link     = $linkLabel
    Download = $downloadButton
  }
}

$script:IosCard = New-BuildCard -Platform "iOS" -Subtitle "unsigned IPA · VideoToolbox + Metal" -Accent $Blue -X 24 -Y 88
$script:AndroidCard = New-BuildCard -Platform "Android" -Subtitle "debug APK · MediaCodec + GLES3" -Accent $Coral -X 428 -Y 88

$script:IosCard.Download.Add_Click({ Start-Download -Kind "iOS" })
$script:AndroidCard.Download.Add_Click({ Start-Download -Kind "Android" })

$script:ToolTip = New-Object System.Windows.Forms.ToolTip
$script:ToolTip.SetToolTip($script:IosCard.Download, "下载最新 iOS IPA，覆盖旧文件")
$script:ToolTip.SetToolTip($script:AndroidCard.Download, "下载最新 Android APK，覆盖旧文件")

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = "刷新"
$refreshButton.Font = $FontBold
$refreshButton.Size = [Drawing.Size]::new(110, 42)
$refreshButton.Location = [Drawing.Point]::new(24, 354)
$refreshButton.FlatStyle = [Windows.Forms.FlatStyle]::Flat
$refreshButton.FlatAppearance.BorderSize = 1
$refreshButton.FlatAppearance.BorderColor = $Line
$refreshButton.FlatAppearance.MouseOverBackColor = $Panel2
$refreshButton.BackColor = $Panel2
$refreshButton.ForeColor = $Ink
$refreshButton.Cursor = [Windows.Forms.Cursors]::Hand
$form.Controls.Add($refreshButton)

$downloadButton = New-Object System.Windows.Forms.Button
$downloadButton.Text = "下载双端"
$downloadButton.Font = [Drawing.Font]::new("Microsoft YaHei UI", 10, [Drawing.FontStyle]::Bold)
$downloadButton.Size = [Drawing.Size]::new(220, 42)
$downloadButton.Location = [Drawing.Point]::new(146, 354)
$downloadButton.FlatStyle = [Windows.Forms.FlatStyle]::Flat
$downloadButton.FlatAppearance.BorderSize = 0
$downloadButton.FlatAppearance.MouseOverBackColor = [Drawing.ColorTranslator]::FromHtml("#7bbcff")
$downloadButton.BackColor = $Blue
$downloadButton.ForeColor = [Drawing.ColorTranslator]::FromHtml("#07101c")
$downloadButton.Cursor = [Windows.Forms.Cursors]::Hand
$downloadButton.Enabled = $false
$form.Controls.Add($downloadButton)

$folderButton = New-Object System.Windows.Forms.Button
$folderButton.Text = "打开下载文件夹"
$folderButton.Font = $FontBold
$folderButton.Size = [Drawing.Size]::new(160, 42)
$folderButton.Location = [Drawing.Point]::new(378, 354)
$folderButton.FlatStyle = [Windows.Forms.FlatStyle]::Flat
$folderButton.FlatAppearance.BorderSize = 1
$folderButton.FlatAppearance.BorderColor = $Line
$folderButton.FlatAppearance.MouseOverBackColor = $Panel2
$folderButton.BackColor = $Panel2
$folderButton.ForeColor = $Ink
$folderButton.Cursor = [Windows.Forms.Cursors]::Hand
$form.Controls.Add($folderButton)

$autoLabel = New-Object System.Windows.Forms.Label
$autoLabel.Text = if ($script:Token) { "自动刷新 · 60 秒" } else { "自动刷新 · 5 分钟（无 token）" }
$autoLabel.Font = $FontTiny
$autoLabel.ForeColor = $Faint
$autoLabel.AutoSize = $true
$autoLabel.Location = [Drawing.Point]::new(560, 368)
$form.Controls.Add($autoLabel)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Minimum = 0
$progress.Maximum = 100
$progress.Value = 0
$progress.Size = [Drawing.Size]::new(792, 8)
$progress.Location = [Drawing.Point]::new(24, 410)
$progress.Visible = $false
$form.Controls.Add($progress)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "准备就绪"
$statusLabel.Font = $FontSmall
$statusLabel.ForeColor = $Muted
$statusLabel.AutoSize = $false
$statusLabel.Size = [Drawing.Size]::new(792, 22)
$statusLabel.Location = [Drawing.Point]::new(24, 424)
$form.Controls.Add($statusLabel)

$footerLabel = New-Object System.Windows.Forms.Label
$footerLabel.Text = "下载目录：$DownloadDir"
$footerLabel.Font = $FontTiny
$footerLabel.ForeColor = $Faint
$footerLabel.AutoSize = $false
$footerLabel.AutoEllipsis = $true
$footerLabel.Size = [Drawing.Size]::new(600, 18)
$footerLabel.Location = [Drawing.Point]::new(24, 466)
$form.Controls.Add($footerLabel)

$tokenLabel = New-Object System.Windows.Forms.Label
$tokenLabel.Text = if ($script:Token) { "token 已读取" } else { "未找到 token" }
$tokenLabel.Font = $FontTiny
$tokenLabel.ForeColor = if ($script:Token) { $Green } else { $Amber }
$tokenLabel.AutoSize = $true
$tokenLabel.Location = [Drawing.Point]::new(748, 466)
$form.Controls.Add($tokenLabel)

function Update-Card {
  param($Card, $Build, [string]$Kind)

  if (-not $Build -or -not $Build.Run) {
    $Card.Run.Text = "#—"
    $Card.Status.Text = "无成功构建"
    $Card.Status.ForeColor = $Faint
    $Card.Meta.Text = "提交 —`n时间 —"
    $Card.Artifact.Text = "产物 —"
    $Card.Artifact.ForeColor = $Muted
    $Card.Note.Text = ""
    $Card.Link.Tag = $null
    return
  }

  $run = $Build.Run
  $Card.Run.Text = "#$($run.run_number)"
  $Card.Status.Text = "成功"
  $Card.Status.ForeColor = $Green
  $sha = if ($run.head_sha -and $run.head_sha.Length -ge 7) { $run.head_sha.Substring(0, 7) } else { "—" }
  $when = ([datetime]$run.created_at).ToLocalTime().ToString("MM-dd HH:mm")
  $Card.Meta.Text = "提交 $sha`n$when"

  if ($Build.Artifact) {
    $size = [math]::Round($Build.Artifact.size_in_bytes / 1MB, 1)
    $Card.Artifact.Text = "产物 $($Build.Artifact.name) · $size MB"
    $Card.Artifact.ForeColor = $Muted
  } else {
    $Card.Artifact.Text = "产物已过期"
    $Card.Artifact.ForeColor = $Amber
  }

  $Card.Link.Tag = $run.html_url

  if ($Build.Latest -and $Build.Latest.id -ne $run.id) {
    $state = if ($Build.Latest.status -ne "completed") { "进行中" } else { $Build.Latest.conclusion }
    $Card.Note.Text = "最新 #$($Build.Latest.run_number) $state，已显示最近成功构建"
  } else {
    $Card.Note.Text = ""
  }
}

function Refresh-Builds {
  if ($script:Busy) {
    return
  }

  $script:Busy = $true
  $refreshButton.Enabled = $false
  $downloadButton.Enabled = $false
  $script:IosCard.Download.Enabled = $false
  $script:AndroidCard.Download.Enabled = $false
  $statusLabel.ForeColor = $Muted
  $statusLabel.Text = "正在查询 GitHub Actions…"
  $form.Cursor = [Windows.Forms.Cursors]::WaitCursor
  [Windows.Forms.Application]::DoEvents()

  try {
    $ios = Get-WorkflowBuild -WorkflowFile "ios-unsigned.yml" -ArtifactName "o11a1-ios-unsigned"
    $android = Get-WorkflowBuild -WorkflowFile "android-debug.yml" -ArtifactName "o11a1-video-test-debug"

    $script:IosBuild = $ios
    $script:AndroidBuild = $android

    Update-Card -Card $script:IosCard -Build $ios -Kind "iOS"
    Update-Card -Card $script:AndroidCard -Build $android -Kind "Android"

    $script:LastRefresh = Get-Date
    $statusLabel.Text = "刷新完成 · $($script:LastRefresh.ToString('HH:mm:ss'))"

    $canDownload = $script:Token -and $ios -and $ios.Artifact -and $android -and $android.Artifact

    if (-not $script:Token) {
      $statusLabel.ForeColor = $Amber
      $statusLabel.Text = "已读取构建信息，但未找到 GitHub token，无法下载"
    } elseif (-not $canDownload) {
      $statusLabel.ForeColor = $Amber
      $statusLabel.Text = "至少一端还没有可下载的成功构建"
    } else {
      $statusLabel.ForeColor = $Green
    }
  } catch {
    $statusLabel.ForeColor = $Red
    $statusLabel.Text = "查询失败：$(Get-ApiErrorMessage $_)"
  } finally {
    $form.Cursor = [Windows.Forms.Cursors]::Default
    $refreshButton.Enabled = $true
    $script:IosCard.Download.Enabled = [bool]($script:Token -and $script:IosBuild -and $script:IosBuild.Artifact)
    $script:AndroidCard.Download.Enabled = [bool]($script:Token -and $script:AndroidBuild -and $script:AndroidBuild.Artifact)
    $downloadButton.Enabled = [bool]($script:Token -and $script:IosBuild -and $script:IosBuild.Artifact -and $script:AndroidBuild -and $script:AndroidBuild.Artifact)
    $script:Busy = $false
  }
}

function Start-Download {
  param([string]$Kind = "Both")

  if ($script:Busy) {
    return
  }
  if (-not $script:Token) {
    $statusLabel.ForeColor = $Amber
    $statusLabel.Text = "没有 GitHub token，无法下载"
    return
  }

  $jobs = @()
  if ($Kind -eq "iOS" -or $Kind -eq "Both") {
    if (-not $script:IosBuild -or -not $script:IosBuild.Artifact) {
      $statusLabel.ForeColor = $Amber
      $statusLabel.Text = "iOS 还没有可下载的成功构建"
      return
    }
    $jobs += [pscustomobject]@{
      Kind      = "iOS"
      Build     = $script:IosBuild
      EntryName = "o11a1-ios-unsigned.ipa"
    }
  }
  if ($Kind -eq "Android" -or $Kind -eq "Both") {
    if (-not $script:AndroidBuild -or -not $script:AndroidBuild.Artifact) {
      $statusLabel.ForeColor = $Amber
      $statusLabel.Text = "Android 还没有可下载的成功构建"
      return
    }
    $jobs += [pscustomobject]@{
      Kind      = "Android"
      Build     = $script:AndroidBuild
      EntryName = "app-debug.apk"
    }
  }
  if ($jobs.Count -eq 0) {
    return
  }

  $script:Busy = $true
  $script:Cancel = $false
  $refreshButton.Enabled = $false
  $downloadButton.Enabled = $false
  $folderButton.Enabled = $false
  $script:IosCard.Download.Enabled = $false
  $script:AndroidCard.Download.Enabled = $false
  $progress.Value = 0
  $progress.Visible = $true
  $statusLabel.ForeColor = $Muted
  $statusLabel.Text = if ($Kind -eq "Both") { "准备下载双端…" } else { "准备下载 $Kind…" }
  [Windows.Forms.Application]::DoEvents()

  $onProgress = {
    param($label, $percent, $read, $total)
    if ($form.IsDisposed) {
      throw "已取消"
    }
    $progress.Value = [Math]::Min(100, [Math]::Max(0, [int]$percent))
    $statusLabel.Text = "$label · $percent%  ($([math]::Round($read / 1MB, 1)) / $([math]::Round($total / 1MB, 1)) MB)"
    [Windows.Forms.Application]::DoEvents()
  }

  $errors = @()
  try {
    foreach ($job in $jobs) {
      $progress.Value = 0
      try {
        Download-BuildCore -Build $job.Build -Kind $job.Kind -EntryName $job.EntryName -OutDir $DownloadDir -OnProgress $onProgress | Out-Null
      } catch {
        $errors += "$($job.Kind)：$($_.Exception.Message)"
      }
    }

    if (-not $form.IsDisposed) {
      if ($errors.Count -gt 0) {
        $statusLabel.ForeColor = $Red
        $statusLabel.Text = "下载失败：$($errors -join '；')"
      } else {
        $statusLabel.ForeColor = $Green
        $doneLabel = if ($Kind -eq "Both") { "双端下载完成" } else { "$Kind 下载完成" }
        $statusLabel.Text = "$doneLabel · $(Get-Date -Format 'HH:mm:ss')"
        Start-Process -FilePath explorer.exe -ArgumentList $DownloadDir
      }
    }
  } finally {
    if (-not $form.IsDisposed) {
      $progress.Visible = $false
      $refreshButton.Enabled = $true
      $folderButton.Enabled = $true
      $script:IosCard.Download.Enabled = [bool]($script:Token -and $script:IosBuild -and $script:IosBuild.Artifact)
      $script:AndroidCard.Download.Enabled = [bool]($script:Token -and $script:AndroidBuild -and $script:AndroidBuild.Artifact)
      $downloadButton.Enabled = [bool]($script:Token -and $script:IosBuild -and $script:IosBuild.Artifact -and $script:AndroidBuild -and $script:AndroidBuild.Artifact)
      $form.Cursor = [Windows.Forms.Cursors]::Default
    }
    $script:Busy = $false
  }
}

$refreshButton.Add_Click({ Refresh-Builds })
$downloadButton.Add_Click({ Start-Download -Kind "Both" })
$script:ToolTip.SetToolTip($downloadButton, "同时下载 iOS 和 Android，覆盖旧文件")
$folderButton.Add_Click({
    if (-not (Test-Path -LiteralPath $DownloadDir)) {
      New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
    }
    Start-Process -FilePath explorer.exe -ArgumentList $DownloadDir
  })

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = if ($script:Token) { 60000 } else { 300000 }
$timer.Add_Tick({
    if (-not $script:Busy) {
      Refresh-Builds
    }
  })
$timer.Start()

$form.Add_Shown({
    $form.Activate()
    $form.BringToFront()
    Refresh-Builds
  })

$form.Add_FormClosing({
    $script:Cancel = $true
    $timer.Stop()
  })

if ($Screenshot) {
  $form.TopMost = $true
  $captureTimer = New-Object System.Windows.Forms.Timer
  $captureTimer.Interval = 5000
  $captureTimer.Add_Tick({
      $captureTimer.Stop()
      try {
        $bounds = $form.Bounds
        $bitmap = New-Object Drawing.Bitmap $bounds.Width, $bounds.Height
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        $graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bounds.Size)
        $bitmap.Save($Screenshot, [Drawing.Imaging.ImageFormat]::Png)
        $graphics.Dispose()
        $bitmap.Dispose()
      } catch {
        Write-Output "screenshot failed: $($_.Exception.Message)"
      }
      $form.Close()
    })
  $captureTimer.Start()
}

[void]$form.ShowDialog()

[CmdletBinding()]
param(
    [string]$AdbPath,
    [switch]$NoAutoTap,
    [switch]$KeepPlayProtectScan,
    [string]$Source,
    [string]$Target,
    [switch]$Yes
)

$TapTextRegex   = '^\s*(install|install anyway|continue installation|continue|allow|ok|تثبيت|متابعة|السماح|سماح|موافق)\s*$'
$TapPackageRegex = 'installer|security|permission|safecenter|com\.miui|com\.oplus|com\.coloros|com\.heytap|com\.vivo|com\.bbk|com\.huawei|com\.hihonor|com\.samsung'

$ErrorActionPreference = 'Stop'

$BrandPrefixes = @(
    'com.samsung.', 'com.sec.', 'com.sem.', 'com.knox', 'com.osp.', 'com.skms.',
    'com.miui.', 'com.xiaomi.', 'com.mi.', 'com.mipay.',
    'com.huawei.', 'com.hihonor.', 'com.honor.',
    'com.oppo.', 'com.coloros.', 'com.heytap.', 'com.oplus.', 'com.nearme.',
    'com.oneplus.', 'com.realme.', 'com.vivo.', 'com.bbk.', 'com.iqoo.',
    'com.motorola.', 'com.lenovo.', 'com.lge.', 'com.sonymobile.', 'com.sony.',
    'com.asus.', 'com.nothing.', 'com.transsion.', 'com.tecno.', 'com.infinix.',
    'com.itel.', 'com.zte.', 'com.nubia.', 'com.nokia.', 'com.hmdglobal.'
)

$BrandExceptions = @(
    'com.huawei.smarthome',
    'com.xiaomi.wearable'
)

$ExcludeExact = @(
    'com.facebook.appmanager', 'com.facebook.services', 'com.facebook.system'
)

function Find-Adb {
    if ($AdbPath) {
        if (Test-Path $AdbPath) { return (Resolve-Path $AdbPath).Path }
        throw "adb not found at '$AdbPath'."
    }
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @(
        "$env:LOCALAPPDATA\platform-tools\adb.exe",
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Links\adb.exe",
        'C:\platform-tools\adb.exe',
        "$env:USERPROFILE\platform-tools\adb.exe"
    )
    $found = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($found) { return $found }
    $pkgDir = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Directory -Filter 'Google.PlatformTools*' -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($pkgDir) {
        $exe = Get-ChildItem $pkgDir.FullName -Recurse -Filter adb.exe -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($exe) { return $exe.FullName }
    }
    return $null
}

function Invoke-Adb {

    $Serial = $args[0]
    $all = @()
    if ($Serial) { $all += @('-s', $Serial) }
    if ($args.Count -gt 1) { $all += @($args[1..($args.Count - 1)] | ForEach-Object { $_ }) }
    $out = & $script:Adb @all 2>&1
    return ($out | ForEach-Object { "$_".TrimEnd("`r") })
}

function Invoke-ConfirmTap([string]$Serial, [string]$LocalXml) {

    $null = Invoke-Adb $Serial shell rm -f /sdcard/__apkcopy_ui.xml
    $d = Start-Process -FilePath $script:Adb -ArgumentList "-s $Serial shell uiautomator dump /sdcard/__apkcopy_ui.xml" `
        -NoNewWindow -PassThru -RedirectStandardOutput "$LocalXml.log" -RedirectStandardError "$LocalXml.err"
    if (-not $d.WaitForExit(6000)) { try { $d.Kill() } catch {} ; return $false }
    Remove-Item $LocalXml -Force -ErrorAction SilentlyContinue
    $null = Invoke-Adb $Serial pull /sdcard/__apkcopy_ui.xml $LocalXml
    if (-not (Test-Path $LocalXml)) { return $false }

    Copy-Item $LocalXml (Join-Path ([IO.Path]::GetTempPath()) 'Copy-AndroidApps-last-ui.xml') -Force -ErrorAction SilentlyContinue
    try { [xml]$ui = Get-Content $LocalXml -Raw -Encoding UTF8 } catch { return $false }
    $cands = @($ui.SelectNodes('//node') | Where-Object {
        $_.enabled -eq 'true' -and $_.package -match $script:TapPackageRegex -and
        (($_.text -match $script:TapTextRegex) -or ($_.'content-desc' -match $script:TapTextRegex))
    })

    $node = ($cands | Where-Object { $_.clickable -eq 'true' -or $_.class -match 'Button' } | Select-Object -First 1)
    if (-not $node) { $node = $cands | Select-Object -First 1 }
    if (-not $node) { return $false }
    if ($node.bounds -notmatch '\[(\d+),(\d+)\]\[(\d+),(\d+)\]') { return $false }
    $x = [int](([int]$Matches[1] + [int]$Matches[3]) / 2)
    $y = [int](([int]$Matches[2] + [int]$Matches[4]) / 2)
    $null = Invoke-Adb $Serial shell input tap $x $y
    Write-Host "(tapped '$($node.text)') " -NoNewline -ForegroundColor DarkGray
    return $true
}

function Install-Apk([string]$Serial, [string[]]$Files, [string]$WorkDir) {

    $verb = if ($Files.Count -eq 1) { 'install' } else { 'install-multiple' }
    $argLine = "-s $Serial $verb -r " + (($Files | ForEach-Object { '"' + $_ + '"' }) -join ' ')
    $outF = Join-Path $WorkDir '__out.txt'; $errF = Join-Path $WorkDir '__err.txt'
    $p = Start-Process -FilePath $script:Adb -ArgumentList $argLine -NoNewWindow -PassThru `
        -RedirectStandardOutput $outF -RedirectStandardError $errF
    if (-not $NoAutoTap) {
        $xml = Join-Path $WorkDir '__ui.xml'
        Start-Sleep -Milliseconds 800
        while (-not $p.HasExited) {
            if (Invoke-ConfirmTap $Serial $xml) { Start-Sleep -Milliseconds 1500 } else { Start-Sleep -Milliseconds 600 }
        }
    }
    $p.WaitForExit()
    return @((Get-Content $outF -ErrorAction SilentlyContinue) + (Get-Content $errF -ErrorAction SilentlyContinue)) |
        ForEach-Object { "$_".TrimEnd("`r") }
}

function Get-DeviceLabel([string]$Serial) {
    $brand = (Invoke-Adb $Serial shell getprop ro.product.manufacturer | Select-Object -First 1)
    $model = (Invoke-Adb $Serial shell getprop ro.product.model | Select-Object -First 1)
    $ver   = (Invoke-Adb $Serial shell getprop ro.build.version.release | Select-Object -First 1)
    return "$brand $model (Android $ver)"
}

function Get-Packages([string]$Serial, [switch]$ThirdPartyOnly) {
    $a = @('shell', 'pm', 'list', 'packages')
    if ($ThirdPartyOnly) { $a += '-3' }
    Invoke-Adb $Serial @a |
        Where-Object { $_ -like 'package:*' } |
        ForEach-Object { $_.Substring(8).Trim() } |
        Sort-Object -Unique
}

function Get-PackageVersions([string]$Serial, [switch]$ThirdPartyOnly) {

    $a = @('shell', 'pm', 'list', 'packages', '--show-versioncode')
    if ($ThirdPartyOnly) { $a += '-3' }
    $h = @{}
    foreach ($line in (Invoke-Adb $Serial @a)) {
        if ($line -match '^package:(\S+)(?:\s+versionCode:(\d+))?') {
            $h[$Matches[1]] = if ($Matches[2]) { [int64]$Matches[2] } else { [int64]-1 }
        }
    }
    return $h
}

function Get-BrandRule([string]$Pkg) {

    if ($script:BrandExceptions -contains $Pkg) { return $null }
    if ($script:ExcludeExact -contains $Pkg) { return "exact name '$Pkg'" }
    $pre = $script:BrandPrefixes | Where-Object { $Pkg.StartsWith($_) } | Select-Object -First 1
    if ($pre) { return "prefix '$pre'" }
    return $null
}

function Read-Choice([string]$Prompt, [int]$Max, [int]$Exclude = -1) {
    while ($true) {
        $r = Read-Host $Prompt
        $n = 0
        if ([int]::TryParse($r, [ref]$n) -and $n -ge 1 -and $n -le $Max -and $n -ne $Exclude) { return $n }
        Write-Host "  Invalid choice." -ForegroundColor Yellow
    }
}

$script:Adb = Find-Adb
if (-not $script:Adb) {
    Write-Host 'adb (Android Platform Tools) was not found.' -ForegroundColor Yellow
    $ans = Read-Host "Download it from Google now into $env:LOCALAPPDATA\platform-tools ? [Y/n]"
    if ($ans -match '^(n|no)$') { throw 'adb is required. Install Platform Tools or pass -AdbPath.' }
    $zip = Join-Path ([IO.Path]::GetTempPath()) ("platform-tools_" + [guid]::NewGuid().ToString('N') + '.zip')
    try {
        Write-Host 'Downloading platform-tools from dl.google.com ...'
        Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile $zip -UseBasicParsing

        Expand-Archive -Path $zip -DestinationPath $env:LOCALAPPDATA -Force
    } finally {
        Remove-Item $zip -Force -ErrorAction SilentlyContinue
    }
    $script:Adb = Find-Adb
    if (-not $script:Adb) { throw 'adb still not found after download. Pass -AdbPath.' }
}
Write-Host "Using adb: $script:Adb" -ForegroundColor DarkGray
& $script:Adb start-server *> $null

$lines = Invoke-Adb $null devices | Select-Object -Skip 1 | Where-Object { $_ -match '\S' }
$unauth = $lines | Where-Object { $_ -match '\s(unauthorized|offline)$' }
foreach ($u in $unauth) {
    Write-Host "Device not ready: $u  -> unlock the phone and accept the 'Allow USB debugging' prompt." -ForegroundColor Yellow
}
$serials = @($lines | Where-Object { $_ -match '\sdevice$' } | ForEach-Object { ($_ -split '\s+')[0] })
if ($serials.Count -lt 2) {
    throw "Need 2 authorized phones connected, found $($serials.Count). Check cables, USB debugging, and the authorization prompt."
}

$devices = @()
for ($i = 0; $i -lt $serials.Count; $i++) {
    $devices += [pscustomobject]@{ N = $i + 1; Serial = $serials[$i]; Label = Get-DeviceLabel $serials[$i] }
}
Write-Host "`nConnected phones:" -ForegroundColor Cyan
$devices | ForEach-Object { Write-Host ("  [{0}] {1}  ({2})" -f $_.N, $_.Label, $_.Serial) }

function Resolve-Device([string]$v) {
    $d = $devices | Where-Object { "$($_.N)" -eq $v -or $_.Serial -eq $v } | Select-Object -First 1
    if (-not $d) { throw "No connected phone matches '$v'." }
    return $d.N
}
$srcN = if ($Source) { Resolve-Device $Source } else { Read-Choice "`nPick SOURCE phone (copy FROM)" $devices.Count }
$dstN = if ($Target) { Resolve-Device $Target } else { Read-Choice 'Pick TARGET phone (install TO)' $devices.Count $srcN }
if ($srcN -eq $dstN) { throw 'Source and target must be different phones.' }
$src = $devices[$srcN - 1]
$dst = $devices[$dstN - 1]
Write-Host "`nSource: $($src.Label)`nTarget: $($dst.Label)" -ForegroundColor Cyan

$srcVer  = Get-PackageVersions $src.Serial -ThirdPartyOnly
$dstVer  = Get-PackageVersions $dst.Serial
$srcApps = @($srcVer.Keys | Sort-Object)

$skippedBrand = @(); $upToDate = @(); $apps = @(); $action = @{}
foreach ($p in $srcApps) {
    $rule = Get-BrandRule $p
    if ($rule) { $skippedBrand += [pscustomobject]@{ Package = $p; 'Detected by' = $rule }; continue }
    if (-not $dstVer.ContainsKey($p)) {
        $action[$p] = 'new'
    } elseif ($srcVer[$p] -ge 0 -and $dstVer[$p] -ge 0 -and $srcVer[$p] -gt $dstVer[$p]) {

        $action[$p] = "update v$($dstVer[$p]) -> v$($srcVer[$p])"
    } else {
        $upToDate += $p; continue
    }
    $apps += $p
}

Write-Host ("`nUser apps on source: {0} | brand apps skipped: {1} | already up to date on target: {2}" -f `
    $srcApps.Count, $skippedBrand.Count, $upToDate.Count) -ForegroundColor DarkGray

if ($skippedBrand.Count) {
    Write-Host "`nSkipped brand apps (package name matched the brand list at the top of this script):" -ForegroundColor Cyan
    $skippedBrand | Format-Table -AutoSize | Out-String -Width 200 | Write-Host
}

if ($apps.Count -eq 0) { Write-Host 'Nothing to copy or update.' -ForegroundColor Green; return }

$newCount = @($apps | Where-Object { $action[$_] -eq 'new' }).Count
Write-Host "`nApps to install: $newCount new, $($apps.Count - $newCount) update" -ForegroundColor Cyan
for ($i = 0; $i -lt $apps.Count; $i++) { Write-Host ("  [{0,3}] {1}  ({2})" -f ($i + 1), $apps[$i], $action[$apps[$i]]) }

$skip = if ($Yes) { '' } else { Read-Host "`nNumbers to SKIP (e.g. 2,5,9-12), Enter = copy all, q = quit" }
if ($skip -match '^\s*q') { return }
if ($skip -match '\d') {
    $drop = @()
    foreach ($part in ($skip -split '[,\s]+' | Where-Object { $_ })) {
        if ($part -match '^(\d+)-(\d+)$') { $drop += [int]$Matches[1]..[int]$Matches[2] }
        elseif ($part -match '^\d+$') { $drop += [int]$part }
    }
    $apps = @(for ($i = 0; $i -lt $apps.Count; $i++) { if ($drop -notcontains ($i + 1)) { $apps[$i] } })
}
Write-Host "`nCopying $($apps.Count) app(s)..." -ForegroundColor Cyan

$work = Join-Path ([IO.Path]::GetTempPath()) ("apkcopy_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
$ok = @(); $failed = @()

$ppOrig = $null
if (-not $KeepPlayProtectScan) {
    $ppOrig = (Invoke-Adb $dst.Serial shell settings get global verifier_verify_adb_installs | Select-Object -First 1)
    $null = Invoke-Adb $dst.Serial shell settings put global verifier_verify_adb_installs 0
    $now = (Invoke-Adb $dst.Serial shell settings get global verifier_verify_adb_installs | Select-Object -First 1)
    if ($now -eq '0') {
        Write-Host "Play Protect scan of USB installs paused on target (was '$ppOrig'); will be restored at the end." -ForegroundColor DarkGray
    } else {
        Write-Host 'Could not pause Play Protect scan on target; you may still get Play Protect prompts.' -ForegroundColor Yellow
        $ppOrig = $null
    }
}

try {
    $n = 0
    foreach ($pkg in $apps) {
        $n++
        Write-Host ("[{0}/{1}] {2} [{3}] ... " -f $n, $apps.Count, $pkg, $action[$pkg]) -NoNewline
        $dir = Join-Path $work $pkg
        New-Item -ItemType Directory -Path $dir | Out-Null
        try {
            $paths = @(Invoke-Adb $src.Serial shell pm path $pkg |
                Where-Object { $_ -like 'package:*' } | ForEach-Object { $_.Substring(8).Trim() })
            if ($paths.Count -eq 0) { throw 'could not get APK path' }

            foreach ($p in $paths) {
                $local = Join-Path $dir ([IO.Path]::GetFileName($p))
                $r = Invoke-Adb $src.Serial pull $p $local
                if (-not (Test-Path $local)) { throw "pull failed: $($r -join ' ')" }
            }

            $files = @(Get-ChildItem $dir -Filter *.apk | Select-Object -ExpandProperty FullName)
            while ($true) {
                $res = Install-Apk $dst.Serial $files $dir
                if (($res -join "`n") -notmatch 'INSTALL_FAILED_USER_RESTRICTED') { break }
                Write-Host 'BLOCKED by target phone' -ForegroundColor Yellow
                Write-Host '  The target phone refused the USB install. Fix it on the TARGET phone:' -ForegroundColor Yellow
                Write-Host '   - Xiaomi/Redmi/POCO: Developer options -> "Install via USB" ON (needs Mi account + SIM/data)' -ForegroundColor Yellow
                Write-Host '   - Oppo/Realme/OnePlus(ColorOS): Developer options -> "Disable permission monitoring" ON' -ForegroundColor Yellow
                Write-Host '   - Vivo: Developer options -> "Install via USB" ON' -ForegroundColor Yellow
                Write-Host '   - Any brand: keep the screen unlocked and tap "Install"/"Allow" if a prompt pops up' -ForegroundColor Yellow
                $ans = if ($Yes) { 's' } else { Read-Host '  Enter = retry, s = skip this app, q = stop' }
                if ($ans -match '^\s*q') { throw [System.OperationCanceledException]::new('stopped by user') }
                if ($ans -match '^\s*s') { break }
                Write-Host ("[{0}/{1}] {2} ... " -f $n, $apps.Count, $pkg) -NoNewline
            }
            if (($res -join "`n") -match '(?m)^Success') {
                Write-Host 'OK' -ForegroundColor Green; $ok += $pkg
            } else {
                $msg = ($res | Where-Object { $_ -match 'Failure|Error|error' } | Select-Object -First 1)
                throw ($(if ($msg) { $msg } else { $res -join ' ' }))
            }
        } catch [System.OperationCanceledException] {
            Write-Host 'Stopped.' -ForegroundColor Yellow
            break
        } catch {
            Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
            $failed += [pscustomobject]@{ Package = $pkg; Reason = $_.Exception.Message }
        } finally {
            Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
} finally {
    Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
    if ($null -ne $ppOrig) {
        if ($ppOrig -eq 'null' -or $ppOrig -eq '') {
            $null = Invoke-Adb $dst.Serial shell settings delete global verifier_verify_adb_installs
        } else {
            $null = Invoke-Adb $dst.Serial shell settings put global verifier_verify_adb_installs $ppOrig
        }
        Write-Host 'Play Protect USB-install scan setting restored on target.' -ForegroundColor DarkGray
    }
}

Write-Host "`nDone. Installed: $($ok.Count)  Failed: $($failed.Count)" -ForegroundColor Cyan
if ($failed.Count) {
    $failed | Format-Table -AutoSize -Wrap
    $log = Join-Path $PSScriptRoot ("Copy-AndroidApps-failed-{0:yyyyMMdd-HHmmss}.txt" -f (Get-Date))
    $failed | Format-Table -AutoSize -Wrap | Out-String -Width 300 | Set-Content $log
    Write-Host "Failure list saved to $log" -ForegroundColor DarkGray
    Write-Host 'Common causes: app needs a newer Android than the target, CPU type mismatch, or "Install via USB" is off (Xiaomi/Oppo/Vivo developer options).' -ForegroundColor DarkGray
    Write-Host 'UPDATE_INCOMPATIBLE = the app on the target came from a different source (other signature); update it from its store, or uninstall it first (loses its data).' -ForegroundColor DarkGray
}

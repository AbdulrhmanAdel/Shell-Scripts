[CmdletBinding()]
param(
    [string]$AdbPath,
    [string]$Source,
    [string]$Target,
    [string[]]$Folders,
    [switch]$Overwrite,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion -lt [version]'7.4') {
    throw "PowerShell 7.4+ is required (this is $($PSVersionTable.PSVersion)). Older versions corrupt binary pipes."
}

$ExcludePatterns = @('.thumbnails', '.trash', '.Trash', '.Trash-*', '.trashed-*', 'LOST.DIR')

$NeverCopy = @('Android')

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
        'C:\platform-tools\adb.exe',
        "$env:USERPROFILE\platform-tools\adb.exe"
    )
    return ($candidates | Where-Object { Test-Path $_ } | Select-Object -First 1)
}

function Invoke-Adb {

    $Serial = $args[0]
    $all = @()
    if ($Serial) { $all += @('-s', $Serial) }
    if ($args.Count -gt 1) { $all += @($args[1..($args.Count - 1)] | ForEach-Object { $_ }) }
    $out = & $script:Adb @all 2>&1
    return ($out | ForEach-Object { "$_".TrimEnd("`r") })
}

function ConvertTo-ShQuoted([string]$s) { "'" + ($s -replace "'", "'\''") + "'" }

function Format-Size([double]$kb) {
    if ($kb -ge 1GB / 1KB) { return '{0:N1} GB' -f ($kb / 1MB) }
    if ($kb -ge 1MB / 1KB) { return '{0:N0} MB' -f ($kb / 1KB) }
    return '{0:N0} KB' -f $kb
}

function Get-DeviceLabel([string]$Serial) {
    $brand = (Invoke-Adb $Serial shell getprop ro.product.manufacturer | Select-Object -First 1)
    $model = (Invoke-Adb $Serial shell getprop ro.product.model | Select-Object -First 1)
    return "$brand $model"
}

function Get-StorageKB([string]$Serial) {

    $line = Invoke-Adb $Serial shell df -k /sdcard | Select-Object -Last 1
    $f = $line -split '\s+'
    return @{ Used = [int64]$f[2]; Free = [int64]$f[3] }
}

function Show-Menu {

    param(
        [string]$Title,
        [string[]]$Items,
        [switch]$Multi,
        [bool[]]$Checked,
        [int]$Disabled = -1,
        [scriptblock]$Footer
    )
    if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) { return $null }
    $n = $Items.Count
    $sel = [bool[]]::new($n)
    if ($Checked) { for ($i = 0; $i -lt $n; $i++) { $sel[$i] = $Checked[$i] } }
    $cur = if ($Disabled -eq 0 -and $n -gt 1) { 1 } else { 0 }
    $view = [math]::Min($n, [math]::Max(5, [Console]::WindowHeight - 8))
    $top = 0

    Write-Host "`n$Title" -ForegroundColor Cyan
    $help = if ($Multi) { 'Up/Down move · Space check · A all/none · Enter confirm · Esc quit' } else { 'Up/Down move · Enter select · Esc quit' }
    Write-Host "  $help" -ForegroundColor DarkGray
    for ($i = 0; $i -le $view; $i++) { Write-Host '' }
    $startRow = [Console]::CursorTop - ($view + 1)

    $oldVis = $true; try { $oldVis = [Console]::CursorVisible } catch {}
    [Console]::CursorVisible = $false
    try {
        while ($true) {
            if ($cur -lt $top) { $top = $cur }
            if ($cur -ge $top + $view) { $top = $cur - $view + 1 }
            $w = [Console]::WindowWidth - 1
            for ($r = 0; $r -lt $view; $r++) {
                $idx = $top + $r
                [Console]::SetCursorPosition(0, $startRow + $r)
                $box = if ($Multi) { if ($sel[$idx]) { '[x] ' } else { '[ ] ' } } else { '' }
                $ptr = if ($idx -eq $cur) { '>' } else { ' ' }
                $more = if ($r -eq 0 -and $top -gt 0) { '^' } elseif ($r -eq $view - 1 -and $top + $view -lt $n) { 'v' } else { ' ' }
                $txt = "$more$ptr $box$($Items[$idx])"
                if ($txt.Length -gt $w) { $txt = $txt.Substring(0, $w) }
                $fg = if ($idx -eq $Disabled) { 'DarkGray' } elseif ($idx -eq $cur) { 'Black' } elseif ($Multi -and $sel[$idx]) { 'Green' } else { 'Gray' }
                $bg = if ($idx -eq $cur -and $idx -ne $Disabled) { 'Cyan' } else { [Console]::BackgroundColor }
                Write-Host $txt.PadRight($w) -ForegroundColor $fg -BackgroundColor $bg -NoNewline
            }
            [Console]::SetCursorPosition(0, $startRow + $view)
            $foot = if ($Footer) { & $Footer $sel } elseif ($Multi) { "$(@($sel | Where-Object { $_ }).Count) selected" } else { '' }
            if ($foot.Length -gt $w) { $foot = $foot.Substring(0, $w) }
            Write-Host $foot.PadRight($w) -ForegroundColor Yellow -NoNewline

            $k = [Console]::ReadKey($true)
            switch ($k.Key) {
                'UpArrow'   { $cur = ($cur - 1 + $n) % $n; if ($cur -eq $Disabled) { $cur = ($cur - 1 + $n) % $n } }
                'DownArrow' { $cur = ($cur + 1) % $n;      if ($cur -eq $Disabled) { $cur = ($cur + 1) % $n } }
                'PageUp'    { $cur = [math]::Max(0, $cur - $view) }
                'PageDown'  { $cur = [math]::Min($n - 1, $cur + $view) }
                'Home'      { $cur = 0 }
                'End'       { $cur = $n - 1 }
                'Spacebar'  { if ($Multi) { $sel[$cur] = -not $sel[$cur] } }
                'A'         { if ($Multi) { $allOn = ($sel -notcontains $false); for ($i = 0; $i -lt $n; $i++) { $sel[$i] = -not $allOn } } }
                'Enter' {
                    if ($Multi) { return @{ Quit = $false; Indices = @(for ($i = 0; $i -lt $n; $i++) { if ($sel[$i]) { $i } }) } }
                    if ($cur -ne $Disabled) { return @{ Quit = $false; Index = $cur } }
                }
                'Escape'    { return @{ Quit = $true } }
                'Q'         { return @{ Quit = $true } }
            }
        }
    } finally {
        [Console]::SetCursorPosition(0, $startRow + $view)
        Write-Host ''
        try { [Console]::CursorVisible = $oldVis } catch {}
    }
}

function Read-Choice([string]$Prompt, [int]$Max, [int]$Exclude = -1) {
    while ($true) {
        $r = Read-Host $Prompt
        $n = 0
        if ([int]::TryParse($r, [ref]$n) -and $n -ge 1 -and $n -le $Max -and $n -ne $Exclude) { return $n }
        Write-Host '  Invalid choice.' -ForegroundColor Yellow
    }
}

$script:Adb = Find-Adb
if (-not $script:Adb) { throw 'adb not found. Run Copy-AndroidApps.ps1 once (it downloads it) or pass -AdbPath.' }
& $script:Adb start-server *> $null

$lines = Invoke-Adb $null devices | Select-Object -Skip 1 | Where-Object { $_ -match '\S' }
$lines | Where-Object { $_ -match '\s(unauthorized|offline)$' } | ForEach-Object {
    Write-Host "Device not ready: $_  -> unlock it and accept 'Allow USB debugging'." -ForegroundColor Yellow
}
$serials = @($lines | Where-Object { $_ -match '\sdevice$' } | ForEach-Object { ($_ -split '\s+')[0] })
if ($serials.Count -lt 2) { throw "Need 2 authorized phones connected, found $($serials.Count)." }

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
$labels = @($devices | ForEach-Object { "$($_.Label)  ($($_.Serial))" })
if ($Source) { $srcN = Resolve-Device $Source } else {
    $m = Show-Menu -Title 'Pick SOURCE phone (copy FROM):' -Items $labels
    if ($null -eq $m) { $srcN = Read-Choice "`nPick SOURCE phone (copy FROM)" $devices.Count }
    elseif ($m.Quit) { return } else { $srcN = $m.Index + 1 }
}
if ($Target) { $dstN = Resolve-Device $Target } else {
    $m = Show-Menu -Title 'Pick TARGET phone (copy TO):' -Items $labels -Disabled ($srcN - 1)
    if ($null -eq $m) { $dstN = Read-Choice 'Pick TARGET phone (copy TO)' $devices.Count $srcN }
    elseif ($m.Quit) { return } else { $dstN = $m.Index + 1 }
}
if ($srcN -eq $dstN) { throw 'Source and target must be different phones.' }
$src = $devices[$srcN - 1]; $dst = $devices[$dstN - 1]
Write-Host "`nSource: $($src.Label)`nTarget: $($dst.Label)" -ForegroundColor Cyan

Write-Host "`nMeasuring folders on source (can take a minute)..." -ForegroundColor DarkGray
$raw = Invoke-Adb $src.Serial shell 'cd /sdcard && for d in */; do d=${d%/}; [ -d "$d" ] && echo "$(du -sk "$d" 2>/dev/null | cut -f1)|$d"; done'
$all = @($raw | Where-Object { $_ -match '^\d+\|' } | ForEach-Object {
    $kb, $name = $_ -split '\|', 2
    [pscustomobject]@{ Name = $name; KB = [int64]$kb }
} | Where-Object { $NeverCopy -notcontains $_.Name -and -not $_.Name.StartsWith('.') } | Sort-Object KB -Descending)

if ($Folders) {
    $missing = $Folders | Where-Object { $all.Name -notcontains $_ }
    if ($missing) { throw "Folder(s) not found on source: $($missing -join ', ')" }
    $sel = @($all | Where-Object { $Folders -contains $_.Name })
} elseif ($Yes) {
    $sel = $all
} else {
    Write-Host "  (never copied: $($NeverCopy -join ', '), hidden folders; skipped inside: $($ExcludePatterns -join ' '))" -ForegroundColor DarkGray
    $items = @($all | ForEach-Object { '{0,-30} {1,10}' -f $_.Name, (Format-Size $_.KB) })
    $sizes = @($all | ForEach-Object { $_.KB })
    $footer = { param($s) $t = 0; $c = 0; for ($i = 0; $i -lt $s.Count; $i++) { if ($s[$i]) { $t += $sizes[$i]; $c++ } }; "  Selected: $c folder(s), $(Format-Size $t)" }
    $m = Show-Menu -Title 'Folders to copy (internal storage):' -Items $items -Multi -Checked ([bool[]]::new($all.Count)) -Footer $footer
    if ($null -ne $m) {
        if ($m.Quit) { return }
        $sel = @($m.Indices | ForEach-Object { $all[$_] })
    } else {

    Write-Host "`nFolders on source (internal storage):" -ForegroundColor Cyan
    for ($i = 0; $i -lt $all.Count; $i++) { Write-Host ("  [{0,2}] {1,-28} {2,10}" -f ($i + 1), $all[$i].Name, (Format-Size $all[$i].KB)) }
    $pick = Read-Host "`nNumbers to COPY (e.g. 1,3,5-7), Enter = all, q = quit"
    if ($pick -match '^\s*q') { return }
    if ($pick -match '\d') {
        $want = @()
        foreach ($part in ($pick -split '[,\s]+' | Where-Object { $_ })) {
            if ($part -match '^(\d+)-(\d+)$') { $want += [int]$Matches[1]..[int]$Matches[2] }
            elseif ($part -match '^\d+$') { $want += [int]$part }
        }
        $sel = @(for ($i = 0; $i -lt $all.Count; $i++) { if ($want -contains ($i + 1)) { $all[$i] } })
    } else { $sel = $all }
    }
}
if ($sel.Count -eq 0) { Write-Host 'Nothing selected (check folders with Space before pressing Enter).'; return }

$needKB = ($sel | Measure-Object KB -Sum).Sum
$space = Get-StorageKB $dst.Serial
Write-Host ("`nSelected: {0} folder(s), {1}. Free on target: {2}." -f $sel.Count, (Format-Size $needKB), (Format-Size $space.Free)) -ForegroundColor Cyan
if ($needKB -gt ($space.Free - 1GB / 1KB)) {
    throw 'Not enough free space on the target (keeping 1 GB spare). Pick fewer folders.'
}
Write-Host ($(if ($Overwrite) { 'Mode: OVERWRITE existing files on target.' } else { 'Mode: keep existing files on target (no overwrite).' })) -ForegroundColor DarkGray
if (-not $Yes) {
    $go = Read-Host 'Start copying? [Y/n]'
    if ($go -match '^(n|no)$') { return }
}

$exclude = ($ExcludePatterns | ForEach-Object { '--exclude=' + (ConvertTo-ShQuoted $_) }) -join ' '
$xflags  = if ($Overwrite) { '-xf' } else { '-xkf' }
$errFile = '/data/local/tmp/__copyfiles_err.txt'
$results = @()

foreach ($f in $sel) {
    $q = ConvertTo-ShQuoted $f.Name
    Write-Host ("`n== {0} ({1}) ==" -f $f.Name, (Format-Size $f.KB)) -ForegroundColor Cyan
    $srcCmd = "cd /sdcard && tar -cf - $exclude $q 2>$errFile"
    $dstCmd = "rm -f $errFile; tar $xflags - -C /sdcard 2>$errFile"
    $before = (Get-StorageKB $dst.Serial).Used
    $sw = [Diagnostics.Stopwatch]::StartNew()

    $job = Start-ThreadJob -ScriptBlock {
        param($adb, $s, $t, $sc, $dc)
        & $adb -s $s exec-out $sc | & $adb -s $t exec-in $dc
    } -ArgumentList $script:Adb, $src.Serial, $dst.Serial, $srcCmd, $dstCmd

    while ($job.State -eq 'Running' -or $job.State -eq 'NotStarted') {
        Start-Sleep -Seconds 3
        $done = [math]::Max(0, (Get-StorageKB $dst.Serial).Used - $before)
        $pct  = if ($f.KB -gt 0) { [math]::Min(100, [int](100 * $done / $f.KB)) } else { 100 }
        $mbs  = if ($sw.Elapsed.TotalSeconds -gt 0) { ($done / 1KB) / $sw.Elapsed.TotalSeconds } else { 0 }
        Write-Progress -Activity "Copying $($f.Name)" -Status ("{0} / {1}  ({2:N1} MB/s)" -f (Format-Size $done), (Format-Size $f.KB), $mbs) -PercentComplete $pct
    }
    Write-Progress -Activity "Copying $($f.Name)" -Completed
    $jobOut = Receive-Job $job -ErrorAction SilentlyContinue 2>&1
    Remove-Job $job -Force
    $sw.Stop()

    $srcErr = @(Invoke-Adb $src.Serial shell "cat $errFile 2>/dev/null; rm -f $errFile" | Where-Object { $_ })
    $dstErr = @(Invoke-Adb $dst.Serial shell "cat $errFile 2>/dev/null; rm -f $errFile" | Where-Object { $_ })
    $allMsg = @($srcErr + $dstErr + @($jobOut | Where-Object { "$_" -match '\S' } | ForEach-Object { "$_" }))

    $kept = @($allMsg | Where-Object { $_ -match 'File exists' }).Count
    $errs = @($allMsg | Where-Object { $_ -notmatch 'File exists' -and $_ -notmatch '^tar: had errors' })
    $added = [math]::Max(0, (Get-StorageKB $dst.Serial).Used - $before)

    $status = if ($errs.Count) { 'done with warnings' } else { 'OK' }
    Write-Host ("{0}: {1} added in {2:hh\:mm\:ss}{3}" -f $status, (Format-Size $added), $sw.Elapsed, $(if ($kept) { ", $kept existing file(s) kept" } else { '' })) `
        -ForegroundColor ($(if ($errs.Count) { 'Yellow' } else { 'Green' }))
    if ($errs.Count) { $errs | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow } }
    $results += [pscustomobject]@{ Folder = $f.Name; Size = Format-Size $f.KB; Added = Format-Size $added; Kept = $kept; Time = $sw.Elapsed.ToString('hh\:mm\:ss'); Warnings = $errs.Count }
}

Write-Host "`nRescanning media on target so Gallery / music apps see the new files..." -ForegroundColor DarkGray
$scan = Invoke-Adb $dst.Serial shell content call --uri content://media --method scan_volume --arg external_primary
if (($scan -join ' ') -match 'Error|Exception') {
    foreach ($f in $sel) {
        $null = Invoke-Adb $dst.Serial shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d ("file:///sdcard/" + [uri]::EscapeDataString($f.Name))
    }
}

Write-Host "`nDone." -ForegroundColor Cyan
$results | Format-Table -AutoSize

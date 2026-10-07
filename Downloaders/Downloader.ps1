[CmdletBinding(PositionalBinding = $false)]
param (
    [Parameter(Position = 0, ValueFromRemainingArguments)]
    [string[]]$Links,
    [string]$Destination,
    [string]$Folder,
    [ArgumentCompleter({ Get-ChildItem "$PSScriptRoot\Managers" -Directory | Where-Object { Test-Path "$($_.FullName)\$($_.Name).psm1" } | ForEach-Object Name })]
    [string]$Manager = 'Aria2',
    [int]$MaxActive = 3,
    [int]$MaxRefreshes = 3,
    [int]$ResolveGapSeconds = 20,
    [switch]$Extract
)

Import-Module "$PSScriptRoot\Browser\Chromium.psm1" -Force;

$signatures = @{
    '.rar' = @(, [byte[]](0x52, 0x61, 0x72, 0x21, 0x1A, 0x07))
    '.zip' = @([byte[]](0x50, 0x4B, 0x03, 0x04), [byte[]](0x50, 0x4B, 0x05, 0x06))
    '.7z'  = @(, [byte[]](0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C))
};

function Get-SafeName {
    param ([string]$Name)

    $name = [IO.Path]::GetFileName($Name.Replace('/', '\'));
    foreach ($c in [IO.Path]::GetInvalidFileNameChars()) { $name = $name.Replace([string]$c, '_'); }
    return $name.Trim(' .');
}

$managerContract = 'Start-DownloadManager', 'Add-Download', 'Get-DownloadStatus', 'Update-Download', 'Remove-Download';
$hostContract = 'Resolve-Link';
$script:Hosts = @{};

function Import-Contract {
    param ([string]$Path, [string[]]$Functions)

    $module = Import-Module $Path -PassThru -Force -DisableNameChecking;
    $missing = @($Functions | Where-Object { !$module.ExportedCommands.ContainsKey($_) });
    if ($missing) { throw "$(Split-Path $Path -Leaf) does not implement $($missing -join ', ')."; }
    $commands = @{};
    foreach ($name in $Functions) { $commands[$name] = $module.ExportedCommands[$name]; }
    return $commands;
}

function Get-LinkHost {
    param ([string]$Link)

    $labels = ([uri]$Link).Host.Split('.');
    $key = ($labels.Count -ge 2 ? $labels[-2] : $labels[0]) -replace '-', '';
    $file = Get-ChildItem "$PSScriptRoot\Hosts\*.psm1" | Where-Object { $_.BaseName -eq $key } | Select-Object -First 1;
    if (!$file) { return $null; }
    if (!$script:Hosts.ContainsKey($file.FullName)) { $script:Hosts[$file.FullName] = Import-Contract $file.FullName $hostContract; }
    return $script:Hosts[$file.FullName];
}

function Test-Part {
    param ([string]$Path, [long]$ExpectedSize)

    if (!(Test-Path -LiteralPath $Path)) { return "The file is missing."; }
    $size = (Get-Item -LiteralPath $Path).Length;
    if ($ExpectedSize -gt 0 -and $size -ne $ExpectedSize) { return "Size mismatch: $size bytes on disk, expected $ExpectedSize."; }
    $expected = $signatures[[IO.Path]::GetExtension($Path).ToLower()];
    if ($expected) {
        $stream = [IO.File]::OpenRead($Path);
        $head = [byte[]]::new(8);
        $read = $stream.Read($head, 0, 8);
        $stream.Dispose();
        if (!($expected | Where-Object { $read -ge $_.Length -and [Linq.Enumerable]::SequenceEqual([byte[]]$head[0..($_.Length - 1)], $_) })) {
            return "Not a valid $([IO.Path]::GetExtension($Path).TrimStart('.').ToUpper()) file (wrong signature).";
        }
    }
    return $null;
}

function Format-Size {
    param ([double]$Bytes)
    return $Bytes -ge 1GB ? ('{0:N2} GB' -f ($Bytes / 1GB)) : ('{0:N1} MB' -f ($Bytes / 1MB));
}

if (!$Links) {
    $Links = (Input.ps1 -Title 'Downloader' -Message 'Paste the links (one per line), Ctrl+Enter to start' -MultiLine) -split '\r?\n';
}
$Links = @($Links | ForEach-Object { $_.Trim().TrimStart('-', ' ') } | Where-Object { $_ -match '^https?://' } | Select-Object -Unique);
if (!$Links) {
    Write-Host 'No links given.' -ForegroundColor Yellow;
    return;
}

$items = foreach ($link in $Links) {
    $uri = [uri]$link;
    $rawName = $uri.Fragment ? $uri.Fragment.TrimStart('#') : $uri.AbsolutePath.TrimEnd('/').Split('/')[-1];
    [pscustomobject]@{
        Link      = $link
        Host      = Get-LinkHost $link
        FileName  = Get-SafeName ([uri]::UnescapeDataString($rawName))
        State     = 'Queued'
        Id        = $null
        Total     = 0
        Done      = 0
        Speed     = 0
        Refreshes = 0
        Message   = $null
    };
}

$managerPath = "$PSScriptRoot\Managers\$Manager\$Manager.psm1";
if (!(Test-Path -LiteralPath $managerPath)) { throw "No manager '$Manager' in $PSScriptRoot\Managers."; }
$managerApi = Import-Contract $managerPath $managerContract;
$session = & $managerApi['Start-DownloadManager'];
if (!$Destination) { $Destination = $session.Directory ?? "$HOME\Downloads"; }

if (!$Folder) {
    $Folder = $items[0].FileName -replace '(\.part\d+)?\.(rar|zip|7z|\d{3})$', '' -replace '_--_fitgirl-repacks\.site_--_?', '' -replace '_', ' ';
}
$directory = Join-Path $Destination (Get-SafeName $Folder.Trim());
New-Item -ItemType Directory -Force $directory | Out-Null;

$statePath = Join-Path $directory '.verified.json';
$verifiedSizes = (Test-Path -LiteralPath $statePath) ? (Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json -AsHashtable) : @{};
foreach ($item in $items) {
    $path = Join-Path $directory $item.FileName;
    $size = $verifiedSizes[$item.FileName];
    if ($size -and (Test-Path -LiteralPath $path) -and !(Test-Path -LiteralPath "$path.aria2") -and (Get-Item -LiteralPath $path).Length -eq $size) {
        $item.State = 'Verified';
        $item.Total = $size;
        $item.Done = $size;
    }
}

function Save-Verified {
    $sizes = @{};
    $items | Where-Object State -eq 'Verified' | ForEach-Object { $sizes[$_.FileName] = $_.Total; };
    $sizes | ConvertTo-Json | Set-Content -LiteralPath $statePath;
}

function Format-Eta {
    param ([double]$Seconds)
    if ($Seconds -le 0 -or [double]::IsInfinity($Seconds)) { return '--'; }
    $span = [TimeSpan]::FromSeconds($Seconds);
    return $span.TotalHours -ge 1 ? ('{0}h {1:00}m' -f [int][Math]::Floor($span.TotalHours), $span.Minutes) : ('{0}m {1:00}s' -f $span.Minutes, $span.Seconds);
}

function Show-Progress {
    $total = ($items | Measure-Object Total -Sum).Sum;
    $done = ($items | Measure-Object Done -Sum).Sum;
    $speed = ($items | Where-Object State -eq 'Active' | Measure-Object Speed -Sum).Sum;
    $verified = @($items | Where-Object State -eq 'Verified').Count;
    $queued = @($items | Where-Object State -eq 'Queued').Count;
    $known = @($items | Where-Object Total -gt 0);
    $estimate = $known ? ($total / $known.Count) * $items.Count : 0;
    $percent = $estimate ? [Math]::Min(100, 100 * $done / $estimate) : 0;
    $eta = $speed ? ($estimate - $done) / $speed : 0;
    Write-Progress -Id 0 -Activity $Folder -Status ("{0}/{1} verified, {2} queued  |  {3} of ~{4}  |  {5}/s  |  ETA {6}" -f $verified, $items.Count, $queued, (Format-Size $done), (Format-Size $estimate), (Format-Size $speed), (Format-Eta $eta)) -PercentComplete $percent;
    for ($i = 0; $i -lt $items.Count; $i++) {
        $item = $items[$i];
        if ($item.State -eq 'Active' -and $item.Total -gt 0) {
            Write-Progress -Id ($i + 1) -ParentId 0 -Activity $item.FileName -Status ("{0} of {1}  |  {2}/s  |  ETA {3}" -f (Format-Size $item.Done), (Format-Size $item.Total), (Format-Size $item.Speed), (Format-Eta ($item.Speed ? ($item.Total - $item.Done) / $item.Speed : 0))) -PercentComplete ([Math]::Min(100, 100 * $item.Done / $item.Total));
        }
        else {
            Write-Progress -Id ($i + 1) -ParentId 0 -Activity $item.FileName -Completed;
        }
    }
    try { $Host.UI.RawUI.WindowTitle = "{0:N0}% {1} ({2}/{3})" -f $percent, $Folder, $verified, $items.Count; } catch {}
}

function Wait-Tick {
    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Milliseconds 100;
        if (!$script:CanPrompt -or ![Console]::KeyAvailable) { continue; }
        $key = [Console]::ReadKey($true);
        if ($key.Key -eq 'C' -and $key.Modifiers -band [ConsoleModifiers]::Control) {
            $answer = Read-Host "`nStop the batch? Running downloads keep going in aria2, queued parts won't start (y/N)";
            if ($answer -match '^y') { $script:StopRequested = $true; return; }
        }
    }
}

foreach ($item in $items | Where-Object { !$_.Host }) {
    $item.State = 'Failed';
    $item.Message = "No host script for $(([uri]$item.Link).Host) in $PSScriptRoot\Hosts.";
}

$skipped = @($items | Where-Object State -eq 'Verified').Count;
Write-Host "Downloading $($items.Count) file(s) to $directory with $Manager$($skipped ? " ($skipped already verified)" : '')" -ForegroundColor Cyan;
Write-Host "Keep this window open: links are fetched only when needed. Ctrl+C asks before stopping; if it closes, run the same command again to continue." -ForegroundColor DarkGray;

$script:LastResolve = [datetime]::MinValue;

function Send-Item {
    param ($Item, [switch]$Retry)

    try {
        $wait = $ResolveGapSeconds - ((Get-Date) - $script:LastResolve).TotalSeconds;
        if ($wait -gt 0) { Start-Sleep -Seconds ([Math]::Ceiling($wait)); }
        $script:LastResolve = Get-Date;
        Start-CdpBrowser;
        Write-Host "[RESOLVE] $($Item.FileName)" -ForegroundColor DarkGray;
        $resolved = & $Item.Host['Resolve-Link'] -Link $Item.Link;
        $request = @{ Url = $resolved.Url; Headers = $resolved.Headers; Connections = $resolved.Connections; Directory = $directory; FileName = $Item.FileName };
        $Item.Id = $Retry ? (& $managerApi['Update-Download'] -Id $Item.Id -Item $request) : (& $managerApi['Add-Download'] -Item $request);
        $Item.State = 'Active';
        $Item.Message = $null;
        Write-Host "[ADDED]   $($Item.FileName)" -ForegroundColor Blue;
    }
    catch {
        $Item.Refreshes++;
        $Item.Message = "$_";
        $Item.State = $Item.Refreshes -gt $MaxRefreshes ? 'Failed' : 'Queued';
        Write-Host "[$($Item.State -eq 'Failed' ? 'FAILED' : 'RETRY')]  $($Item.FileName): $_" -ForegroundColor ($Item.State -eq 'Failed' ? 'Red' : 'Yellow');
    }
}

$script:StopRequested = $false;
$script:CanPrompt = try { [Console]::TreatControlCAsInput = $true; $true } catch { $false };
try {
    while (!$script:StopRequested -and ($items | Where-Object { $_.State -in 'Queued', 'Active' })) {
        $active = @($items | Where-Object State -eq 'Active');
        if ($active) {
            $status = & $managerApi['Get-DownloadStatus'] -Ids $active.Id;
            foreach ($item in $active) {
                $s = $status[$item.Id];
                $item.Total = $s.Total;
                $item.Done = $s.Done;
                $item.Speed = $s.Speed;
                if ($s.State -eq 'Complete') {
                    $problem = Test-Part -Path (Join-Path $directory $item.FileName) -ExpectedSize $s.Total;
                    if (!$problem) {
                        $item.State = 'Verified';
                        Save-Verified;
                        Write-Host "[VERIFIED] $($item.FileName) ($(Format-Size $s.Total))" -ForegroundColor Green;
                        continue;
                    }
                    Remove-Item -LiteralPath (Join-Path $directory $item.FileName) -ErrorAction SilentlyContinue;
                    $s.Error = "Integrity check failed: $problem";
                }
                if ($s.State -in 'Error', 'Removed' -or $s.Error) {
                    $item.Refreshes++;
                    $item.Message = $s.Error;
                    if ($item.Refreshes -gt $MaxRefreshes) {
                        $item.State = 'Failed';
                        Write-Host "[FAILED]  $($item.FileName): $($s.Error)" -ForegroundColor Red;
                        continue;
                    }
                    Write-Host "[REFRESH] $($item.FileName): $($s.Error)" -ForegroundColor Yellow;
                    Send-Item $item -Retry;
                }
            }
        }

        $running = @($items | Where-Object State -eq 'Active').Count;
        foreach ($item in @($items | Where-Object State -eq 'Queued')) {
            if ($running -ge $MaxActive -or $script:StopRequested) { break; }
            Send-Item $item;
            if ($item.State -eq 'Active') { $running++; }
        }
        if (!($items | Where-Object State -eq 'Queued')) { Stop-CdpBrowser; }

        Show-Progress;
        Wait-Tick;
    }
}
finally {
    if ($script:CanPrompt) { [Console]::TreatControlCAsInput = $false; }
    0..$items.Count | ForEach-Object { Write-Progress -Id $_ -Activity $Folder -Completed; };
    Stop-CdpBrowser;
}

if ($script:StopRequested) {
    Write-Host "`nStopped. Running downloads continue in aria2 (see AriaNg). Run the same command again to continue the batch." -ForegroundColor Yellow;
    return;
}

$failed = @($items | Where-Object State -eq 'Failed');
Write-Host "`n$(@($items | Where-Object State -eq 'Verified').Count) verified, $($failed.Count) failed" -ForegroundColor ($failed ? 'Yellow' : 'Green');
$failed | ForEach-Object { Write-Host "  $($_.FileName): $($_.Message)" -ForegroundColor Red; }

if ($Extract -and !$failed) {
    $first = Get-ChildItem -LiteralPath $directory -File | Where-Object { $_.Name -match '\.part0*1\.rar$' -or ($_.Name -match '\.(rar|zip|7z)$' -and $_.Name -notmatch '\.part\d+\.rar$') } | Select-Object -First 1;
    if ($first) {
        Write-Host "Testing the archive set..." -ForegroundColor Cyan;
        & 7z t $first.FullName -y | Out-Null;
        if ($LASTEXITCODE -ne 0) { Write-Host "The archive set is damaged, not extracting." -ForegroundColor Red; return; }
        & 7z x $first.FullName "-o$directory" -y | Out-Null;
        Write-Host ($LASTEXITCODE -eq 0 ? "Extracted to $directory" : "Extraction failed (7z exit code $LASTEXITCODE).") -ForegroundColor ($LASTEXITCODE -eq 0 ? 'Green' : 'Red');
    }
}

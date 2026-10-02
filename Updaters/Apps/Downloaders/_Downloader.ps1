[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Url,
    [object]
    $FileName,
    # Cache per version, many apps reuse one file name (e.g. nomacs-portable-win.zip) for every release
    [string]
    $Version,
    # When known (GitHub gives it), a cached file of another size is re-downloaded
    [long]
    $ExpectedSize = 0,
    [string]
    $UserAgent
)

$FileName ??= Random-FileName.ps1;
$parentPath = "$(Get-TempScriptPath.ps1)\App_Updaters"
if ($Version) {
    $parentPath = "$parentPath\$($Version -replace '[\\/:*?"<>|\s]', '_')";
}
$OutPath = "$parentPath\$FileName";

$cached = Test-Path -LiteralPath $OutPath;
if ($cached -and $ExpectedSize -gt 0 -and (Get-Item -LiteralPath $OutPath).Length -ne $ExpectedSize) {
    Write-Host "[INFO] Cached file has the wrong size, downloading again." -ForegroundColor DarkGray
    $cached = $false;
}

if ($cached) {
    Write-Host "[INFO] File already exists at $OutPath. Skipping download." -ForegroundColor DarkGray
    return $OutPath;
}

New-Item -Path $parentPath -ItemType Directory -Force | Out-Null;
# Download to .part first so an interrupted download is never mistaken for a finished one
$partPath = "$OutPath.part";
$requestArgs = @{ Uri = $Url; OutFile = $partPath };
if ($UserAgent) {
    $requestArgs.UserAgent = $UserAgent;
}

# Streams the download and writes "<downloaded bytes> <total bytes>" to the progress file,
# which the software updater shows next to each app in its parallel status board
function Save-WithProgress {
    param ([string]$Uri, [string]$OutFile, [string]$UserAgent, [string]$ProgressFile)

    $client = [Net.Http.HttpClient]::new();
    $client.Timeout = [TimeSpan]::FromMinutes(30);
    [void]$client.DefaultRequestHeaders.UserAgent.TryParseAdd($UserAgent ? $UserAgent : "Mozilla/5.0 (Windows NT 10.0; Win64; x64) PowerShell/$($PSVersionTable.PSVersion)");
    try {
        $response = $client.GetAsync($Uri, [Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult();
        [void]$response.EnsureSuccessStatusCode();
        $total = $response.Content.Headers.ContentLength ?? 0;
        $source = $response.Content.ReadAsStream();
        $target = [IO.File]::Create($OutFile);
        $done = 0;
        try {
            $buffer = [byte[]]::new(81920);
            $clock = [Diagnostics.Stopwatch]::StartNew();
            [IO.File]::WriteAllText($ProgressFile, "0 $total");
            while (($read = $source.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $target.Write($buffer, 0, $read);
                $done += $read;
                if ($clock.ElapsedMilliseconds -ge 250) {
                    try { [IO.File]::WriteAllText($ProgressFile, "$done $total") } catch {}
                    $clock.Restart();
                }
            }
        }
        finally {
            $target.Dispose();
            $source.Dispose();
        }
        if ($total -gt 0 -and $done -ne $total) {
            throw "Incomplete download ($done of $total bytes)";
        }
        [IO.File]::WriteAllText($ProgressFile, "$done $($total -gt 0 ? $total : $done)");
    }
    finally {
        $client.Dispose();
    }
}

try {
    if ($env:APP_UPDATER_PROGRESS_FILE) {
        Save-WithProgress -Uri $Url -OutFile $partPath -UserAgent $UserAgent -ProgressFile $env:APP_UPDATER_PROGRESS_FILE;
    }
    else {
        Invoke-WebRequest @requestArgs -ErrorAction Stop;
    }
    Move-Item -LiteralPath $partPath -Destination $OutPath -Force;
}
catch {
    Remove-Item -LiteralPath $partPath -Force -ErrorAction SilentlyContinue;
    Write-Host "[ERROR] Download failed: $Url ($($_.Exception.Message))" -ForegroundColor Red
    return $null;
}

return $OutPath;

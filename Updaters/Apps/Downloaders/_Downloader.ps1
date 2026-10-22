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
        # Continue a .part left by a dropped connection, when the server supports ranges (206)
        $existing = (Test-Path -LiteralPath $OutFile) ? (Get-Item -LiteralPath $OutFile).Length : 0;
        $request = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Get, $Uri);
        if ($existing -gt 0) {
            $request.Headers.Range = [Net.Http.Headers.RangeHeaderValue]::new($existing, $null);
        }
        $response = $client.SendAsync($request, [Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult();
        if ([int]$response.StatusCode -eq 416) {
            # The .part does not fit the file anymore, start over on the next attempt
            Remove-Item -LiteralPath $OutFile -Force -ErrorAction SilentlyContinue;
        }
        [void]$response.EnsureSuccessStatusCode();
        $resumed = $existing -gt 0 -and [int]$response.StatusCode -eq 206;
        $done = $resumed ? $existing : 0;
        $total = $response.Content.Headers.ContentLength ?? 0;
        if ($total -gt 0) {
            $total += $done;
        }
        if ($resumed) {
            Write-Host "[INFO] Resuming the download at $([Math]::Round($done / 1MB, 1)) MB" -ForegroundColor DarkGray;
        }
        $source = $response.Content.ReadAsStream();
        $target = $resumed ? [IO.File]::Open($OutFile, [IO.FileMode]::Append) : [IO.File]::Create($OutFile);
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

# A dropped connection on a big download (e.g. Brave's 250 MB) is retried, resuming from the .part
$maxAttempts = 5;
for ($attempt = 1; ; $attempt++) {
    try {
        if ($env:APP_UPDATER_PROGRESS_FILE) {
            Save-WithProgress -Uri $Url -OutFile $partPath -UserAgent $UserAgent -ProgressFile $env:APP_UPDATER_PROGRESS_FILE;
        }
        else {
            Invoke-WebRequest @requestArgs -Resume -ErrorAction Stop;
        }
        Move-Item -LiteralPath $partPath -Destination $OutPath -Force;
        break;
    }
    catch {
        if ($attempt -lt $maxAttempts) {
            Write-Host "[WARN] Download interrupted ($($_.Exception.Message)), retrying ($($attempt + 1)/$maxAttempts)..." -ForegroundColor Yellow
            Start-Sleep -Seconds (3 * $attempt);
            continue;
        }
        # The .part is kept, so the next run resumes it
        Write-Host "[ERROR] Download failed: $Url ($($_.Exception.Message))" -ForegroundColor Red
        return $null;
    }
}

return $OutPath;

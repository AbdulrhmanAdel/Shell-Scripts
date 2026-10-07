$script:Cdp = @{
    Process = $null
    Socket  = $null
    Profile = $null
    Id      = 0
    Events  = [System.Collections.Generic.List[object]]::new()
}

function Find-CdpBrowser {
    if ($env:DOWNLOADER_BROWSER -and (Test-Path -LiteralPath $env:DOWNLOADER_BROWSER)) { return $env:DOWNLOADER_BROWSER; }
    foreach ($name in 'msedge.exe', 'brave.exe', 'chrome.exe') {
        foreach ($hive in 'HKCU:', 'HKLM:') {
            $value = (Get-ItemProperty -LiteralPath "$hive\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$name" -ErrorAction SilentlyContinue).'(default)';
            if ($value -and (Test-Path -LiteralPath $value.Trim('"'))) { return $value.Trim('"'); }
        }
        $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1;
        if ($command) { return $command.Source; }
    }
}

function Start-CdpBrowser {
    param (
        [string]$Path = (Find-CdpBrowser),
        [string]$ProfilePath = "$env:LOCALAPPDATA\Downloader\Browser",
        [string[]]$Arguments = @(
            '--no-first-run',
            '--no-default-browser-check',
            '--no-service-autorun',
            '--no-pings',
            '--password-store=basic',
            '--disable-breakpad',
            '--disable-component-update',
            '--disable-background-networking',
            '--disable-search-engine-choice-screen',
            '--disable-session-crashed-bubble',
            '--hide-crash-restore-bubble',
            '--disable-backgrounding-occluded-windows',
            '--disable-renderer-backgrounding',
            '--disable-background-timer-throttling',
            '--window-size=520,600',
            '--window-position=40,40'
        )
    )

    if ($script:Cdp.Socket) { return; }
    if (!$Path) { throw "No supported browser found. Install Microsoft Edge, Brave or Google Chrome, or set DOWNLOADER_BROWSER to a Chromium browser exe."; }

    New-Item -ItemType Directory -Force $ProfilePath | Out-Null;
    $script:Cdp.Profile = $ProfilePath;
    $portFile = Join-Path $ProfilePath 'DevToolsActivePort';
    Remove-Item -LiteralPath $portFile -ErrorAction SilentlyContinue;
    $script:Cdp.Process = Start-Process -FilePath $Path -PassThru -ArgumentList (@('--remote-debugging-port=0', "--user-data-dir=`"$ProfilePath`"") + $Arguments + 'about:blank');

    $port = $null;
    for ($i = 0; $i -lt 80 -and !$port; $i++) {
        Start-Sleep -Milliseconds 250;
        if (Test-Path -LiteralPath $portFile) { $port = (Get-Content -LiteralPath $portFile -TotalCount 1); }
    }
    if (!$port) { throw "The browser did not open its debugging port ($Path)."; }

    $page = (Invoke-RestMethod "http://127.0.0.1:$port/json/list") | Where-Object type -eq 'page' | Select-Object -First 1;
    $socket = [System.Net.WebSockets.ClientWebSocket]::new();
    $socket.Options.KeepAliveInterval = [TimeSpan]::Zero;
    $socket.ConnectAsync([uri]$page.webSocketDebuggerUrl, [Threading.CancellationToken]::None).Wait();
    $script:Cdp.Socket = $socket;

    Invoke-Cdp 'Emulation.setFocusEmulationEnabled' @{ enabled = $true } | Out-Null;
    Write-Host "[INFO] Browser: $(Split-Path $Path -Leaf)" -ForegroundColor DarkGray;
}

function Stop-CdpBrowser {
    if ($script:Cdp.Socket) {
        try { Invoke-Cdp 'Browser.close' -TimeoutSeconds 5 | Out-Null; } catch {}
        $script:Cdp.Socket.Dispose();
        $script:Cdp.Socket = $null;
    }
    if ($script:Cdp.Process -and !$script:Cdp.Process.HasExited) {
        $script:Cdp.Process.WaitForExit(5000) | Out-Null;
        if (!$script:Cdp.Process.HasExited) { Stop-Process -Id $script:Cdp.Process.Id -Force -ErrorAction SilentlyContinue; }
    }
    $script:Cdp.Process = $null;
    $script:Cdp.Profile = $null;
}

function Receive-CdpMessage {
    param ([int]$TimeoutSeconds)

    $source = [Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($TimeoutSeconds));
    $stream = [IO.MemoryStream]::new();
    $buffer = [byte[]]::new(65536);
    try {
        do {
            $result = $script:Cdp.Socket.ReceiveAsync([ArraySegment[byte]]$buffer, $source.Token).GetAwaiter().GetResult();
            $stream.Write($buffer, 0, $result.Count);
        } until ($result.EndOfMessage)
    }
    catch [OperationCanceledException] {
        throw "The browser did not answer within $TimeoutSeconds seconds.";
    }
    finally { $source.Dispose(); }
    return [Text.Encoding]::UTF8.GetString($stream.ToArray()) | ConvertFrom-Json -Depth 50;
}

function Invoke-Cdp {
    param (
        [string]$Method,
        [hashtable]$Params = @{},
        [int]$TimeoutSeconds = 30
    )

    $script:Cdp.Id++;
    $id = $script:Cdp.Id;
    $json = @{ id = $id; method = $Method; params = $Params } | ConvertTo-Json -Depth 20 -Compress;
    $bytes = [Text.Encoding]::UTF8.GetBytes($json);
    $script:Cdp.Socket.SendAsync([ArraySegment[byte]]$bytes, 'Text', $true, [Threading.CancellationToken]::None).GetAwaiter().GetResult();

    while ($true) {
        $message = Receive-CdpMessage -TimeoutSeconds $TimeoutSeconds;
        if ($message.id -eq $id) {
            if ($message.error) { throw "CDP $Method failed: $($message.error.message)"; }
            return $message.result;
        }
        if ($message.method) {
            $script:Cdp.Events.Add($message);
            if ($script:Cdp.Events.Count -gt 2000) { $script:Cdp.Events.RemoveRange(0, 1000); }
        }
    }
}

function Get-CdpEvents {
    param ([string]$Method, [switch]$Clear)

    $events = @($script:Cdp.Events | Where-Object { !$Method -or $_.method -eq $Method });
    if ($Clear) { $script:Cdp.Events.Clear(); }
    return $events;
}

function Invoke-CdpScript {
    param (
        [string]$Expression,
        [int]$TimeoutSeconds = 30
    )

    $result = Invoke-Cdp 'Runtime.evaluate' @{ expression = $Expression; awaitPromise = $true; returnByValue = $true; userGesture = $true; allowUnsafeEvalBlockedByCSP = $true } -TimeoutSeconds $TimeoutSeconds;
    if ($result.exceptionDetails) { throw "Page script failed: $($result.exceptionDetails.exception.description ?? $result.exceptionDetails.text)"; }
    return $result.result.value;
}

function Open-CdpPage {
    param (
        [string]$Url,
        [int]$TimeoutSeconds = 30
    )

    Invoke-Cdp 'Page.navigate' @{ url = $Url } | Out-Null;
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds);
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500;
        try { if ((Invoke-CdpScript 'document.readyState' -TimeoutSeconds 5) -eq 'complete') { return Invoke-CdpScript 'location.href'; } } catch {}
    }
    throw "The page did not finish loading within $TimeoutSeconds seconds: $Url";
}

function Get-CdpRequestHeaders {
    param ([string]$Url)

    $cookies = (Invoke-Cdp 'Network.getCookies' @{ urls = @($Url) }).cookies;
    $headers = @{ 'User-Agent' = (Invoke-CdpScript 'navigator.userAgent') };
    if ($cookies) { $headers.Cookie = ($cookies | ForEach-Object { "$($_.name)=$($_.value)" }) -join '; '; }
    return $headers;
}

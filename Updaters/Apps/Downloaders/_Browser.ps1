[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Url,
    [string]$QueryString,
    [string]$Attribute = 'href',
    [int]$Timeout = 30
)

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) {
    $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
}
if (-not (Test-Path $edgePath)) {
    Write-Error "Edge browser not found"
    return
}

$port = Get-Random -Minimum 10000 -Maximum 60000
$tempDir = Join-Path ([IO.Path]::GetTempPath()) "edge_cdp_$(Get-Random)"

# Non-headless Edge positioned off-screen (Cloudflare detects headless mode)
$proc = Start-Process $edgePath -ArgumentList @(
    "--disable-gpu"
    "--no-first-run"
    "--disable-blink-features=AutomationControlled"
    "--remote-debugging-port=$port"
    "--user-data-dir=$tempDir"
    "--window-position=-32000,-32000"
    "--window-size=1280,720"
    "about:blank"
) -PassThru

try {
    # Wait for Edge CDP to become available
    $targets = $null
    $startTime = Get-Date
    while (((Get-Date) - $startTime).TotalSeconds -lt 15) {
        Start-Sleep -Milliseconds 500
        try { $targets = Invoke-RestMethod "http://localhost:$port/json/list" -ErrorAction Stop; break }
        catch { }
    }
    if (-not $targets) { Write-Error "Failed to connect to Edge DevTools on port $port"; return }

    $wsUrl = ($targets | Where-Object { $_.type -eq 'page' } | Select-Object -First 1).webSocketDebuggerUrl
    if (-not $wsUrl) { Write-Error "No page target found"; return }

    # Connect WebSocket (suppress VoidTaskResult output)
    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts = [System.Threading.CancellationTokenSource]::new()
    $null = $ws.ConnectAsync([Uri]$wsUrl, $cts.Token).GetAwaiter().GetResult()

    $script:msgId = 0

    function Receive-WsMessage {
        $stream = [System.IO.MemoryStream]::new()
        do {
            $buf = [byte[]]::new(131072)
            $seg = [System.ArraySegment[byte]]::new($buf)
            $result = $ws.ReceiveAsync($seg, $cts.Token).GetAwaiter().GetResult()
            $stream.Write($buf, 0, $result.Count)
        } while (-not $result.EndOfMessage)
        return [System.Text.Encoding]::UTF8.GetString($stream.ToArray())
    }

    function Send-CdpCommand {
        param([string]$Method, [hashtable]$Params = @{})
        $script:msgId++
        $id = $script:msgId
        $cmd = @{ id = $id; method = $Method; params = $Params } | ConvertTo-Json -Compress -Depth 10
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($cmd)
        $seg = [System.ArraySegment[byte]]::new($bytes)
        $null = $ws.SendAsync($seg, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).GetAwaiter().GetResult()

        while ($true) {
            $msg = Receive-WsMessage
            $parsed = $msg | ConvertFrom-Json
            if ($parsed.id -eq $id) { return $parsed }
        }
    }

    # Navigate to the target URL
    $null = Send-CdpCommand -Method "Page.navigate" -Params @{ url = $Url }

    # Wait for page to resolve (Cloudflare shows "Just a moment...")
    $deadline = (Get-Date).AddSeconds($Timeout)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 1
        $resp = Send-CdpCommand -Method "Runtime.evaluate" -Params @{ expression = "document.title" }
        $title = $resp.result.result.value
        Write-Verbose "Page title: $title"
        if ($title -and $title -ne "Just a moment..." -and $title -ne "") { break }
    }

    # Wait for page to fully load (readyState === 'complete')
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 1
        $resp = Send-CdpCommand -Method "Runtime.evaluate" -Params @{ expression = "document.readyState" }
        $state = $resp.result.result.value
        Write-Verbose "readyState: $state"
        if ($state -eq 'complete') { break }
    }

    # If a querySelector was provided, evaluate it in the browser (full CSS3 support)
    if ($QueryString) {
        $js = "(() => { const el = document.querySelector(`"$QueryString`"); if (!el) return null; let v = el.getAttribute(`"$Attribute`"); if (!v) { const a = el.querySelector(`"a`"); if (a) v = a.getAttribute(`"$Attribute`"); } return v; })()"
        $resp = Send-CdpCommand -Method "Runtime.evaluate" -Params @{ expression = $js }
        return $resp.result.result.value
    }

    # Otherwise return full rendered HTML
    $resp = Send-CdpCommand -Method "Runtime.evaluate" -Params @{ expression = "document.documentElement.outerHTML" }
    return $resp.result.result.value
}
finally {
    try { $null = $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "", $cts.Token).GetAwaiter().GetResult() } catch { }
    if ($proc -and -not $proc.HasExited) { $proc | Stop-Process -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Milliseconds 500
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

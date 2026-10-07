function Resolve-Link {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Link,
        [int]$TimeoutSeconds = 90
    )

    Invoke-Cdp 'Network.enable' | Out-Null;
    Get-CdpEvents -Clear | Out-Null;
    $location = Open-CdpPage -Url $Link;
    if ($location -notmatch 'datanodes\.to') {
        throw "The page went somewhere else ($location).";
    }

    Invoke-CdpScript @'
    (() => {
        window.__directUrl = null;
        const original = window.fetch;
        window.fetch = async function (...args) {
            const response = await original.apply(this, args);
            try { const data = await response.clone().json(); if (data && data.url) window.__directUrl = decodeURIComponent(data.url); } catch (e) {}
            return response;
        };
    })()
'@ | Out-Null;

    $clickScript = @'
    (() => {
        for (const b of document.querySelectorAll('button, a, input[type="submit"]')) {
            if (/^\s*Free Download/i.test(b.innerText || b.value || '')) { b.scrollIntoView({ block: 'center' }); b.click(); return true; }
        }
        return false;
    })()
'@;
    $findScript = @'
    JSON.stringify(window.__directUrl || [...document.querySelectorAll('a')].map(a => a.href).find(h => h && (h.includes('dlproxy') || /\.(rar|zip|7z)(\?|$)/i.test(h)) && !h.includes('datanodes.to/app')) || null)
'@;

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds);
    $clicked = $false;
    $warned = $false;
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 1;
        if (!$clicked) {
            $clicked = Invoke-CdpScript $clickScript;
            if (!$clicked -and !$warned -and (Get-Date) -gt $deadline.AddSeconds(20 - $TimeoutSeconds)) {
                Write-Host "[WAIT] Cloudflare wants a click: solve the check in the browser window." -ForegroundColor Yellow;
                $warned = $true;
            }
            continue;
        }

        $url = Invoke-CdpScript $findScript | ConvertFrom-Json;
        if (!$url) {
            $url = Get-CdpEvents -Method 'Network.responseReceived' |
                ForEach-Object { $_.params.response.url } |
                Where-Object { $_ -notmatch 'datanodes\.to' -and $_ -match 'dlproxy|/d/|\.(rar|zip|7z)(\?|$)' } |
                Select-Object -Last 1;
        }
        if ($url) {
            Invoke-Cdp 'Network.disable' | Out-Null;
            $headers = Get-CdpRequestHeaders -Url $url;
            $headers.Referer = 'https://datanodes.to/';
            return @{
                Url     = $url
                Headers = $headers
            }
        }
    }

    Invoke-Cdp 'Network.disable' | Out-Null;
    throw ($clicked ? "datanodes did not produce a download link after the countdown." : "Could not find the Free Download button on datanodes (Cloudflare may not have passed).");
}

Export-ModuleMember -Function Resolve-Link;

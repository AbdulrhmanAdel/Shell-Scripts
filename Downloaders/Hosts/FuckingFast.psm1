function Resolve-Link {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Link,
        [int]$TimeoutSeconds = 120
    )

    $fileId = ([uri]$Link).AbsolutePath.Trim('/').Split('/')[-1];
    $values = @{ fileId = $fileId; link = $Link } | ConvertTo-Json -Compress;
    $goScript = @"
    (async () => {
        const v = $values;
        const token = window.turnstileToken || document.querySelector('[name="cf-turnstile-response"]')?.value || '';
        const response = await fetch('/f/' + v.fileId + '/go', {
            method: 'POST',
            headers: { 'HX-Request': 'true', 'HX-Target': '', 'HX-Current-URL': v.link },
            body: new URLSearchParams({ 'cf-turnstile-response': token })
        });
        return JSON.stringify({ status: response.status, url: response.headers.get('HX-Redirect'), challenged: response.headers.get('cf-mitigated') === 'challenge' });
    })()
"@;

    $origin = ([uri]$Link).GetLeftPart([UriPartial]::Authority);
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds);
    $warned = $false;
    while ((Get-Date) -lt $deadline) {
        $location = Open-CdpPage -Url $Link;
        if (!$location.StartsWith("$origin/")) {
            throw "The page went somewhere else ($location).";
        }

        while ((Invoke-CdpScript 'document.title') -eq 'Just a moment...' -and (Get-Date) -lt $deadline) {
            if (!$warned) {
                Write-Host "[WAIT] Cloudflare wants a click: solve the check in the browser window." -ForegroundColor Yellow;
                $warned = $true;
            }
            Start-Sleep -Seconds 1;
        }
        if (Invoke-CdpScript "/file (was )?(not found|deleted|removed)/i.test(document.body?.innerText ?? '')") {
            throw "The file is no longer available on fuckingfast.";
        }

        $cookieDeadline = (Get-Date).AddSeconds(15);
        while ((Get-Date) -lt $cookieDeadline -and @((Invoke-Cdp 'Network.getCookies' @{ urls = @("$origin/") }).cookies.name) -notcontains 'cf_clearance') {
            Start-Sleep -Milliseconds 500;
        }
        Start-Sleep -Seconds 2;

        $result = Invoke-CdpScript $goScript | ConvertFrom-Json;
        if ($result.status -eq 200 -and $result.url) {
            $headers = Get-CdpRequestHeaders -Url $result.url;
            $headers.Referer = $Link;
            return @{
                Url         = $result.url
                Headers     = $headers
                Connections = 1
            }
        }
        if (!$result.challenged) {
            throw "fuckingfast refused the download (HTTP $($result.status)).";
        }
        if (!$warned) {
            Write-Host "[WAIT] Cloudflare challenged the request. If a check appears in the browser window, solve it." -ForegroundColor Yellow;
            $warned = $true;
        }
        Start-Sleep -Seconds 5;
    }
    throw "Cloudflare did not let the download through within $TimeoutSeconds seconds.";
}

Export-ModuleMember -Function Resolve-Link;

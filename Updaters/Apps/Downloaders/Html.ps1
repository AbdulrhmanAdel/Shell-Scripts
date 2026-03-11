[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Url,
    [Parameter(Mandatory)]
    [string]$QueryString,
    [string]$Attribute = 'href',
    $CurrentVersion
)

Write-Host "INFO: " -ForegroundColor Blue -NoNewline; Write-Host "Using Html Downloader";

# Try fetching HTML directly first; fall back to browser for Cloudflare / 403
$htmlContent = $null
$headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
}
try {
    $response = Invoke-WebRequest -Uri $Url -Headers $headers -UseBasicParsing
    $htmlContent = $response.Content
} catch { }

$needsBrowser = -not $htmlContent -or ($htmlContent -match '<title>Just a moment\.\.\.</title>')
if ($needsBrowser) {
    Write-Host "Cloudflare/blocked detected, launching browser..." -ForegroundColor Yellow
    # Use browser with querySelector directly (full CSS3 support, COM HTMLFile has limited selectors)
    $downloadLink = & "$PSScriptRoot\_Browser.ps1" -Url $Url -QueryString $QueryString -Attribute $Attribute
    if (-not $downloadLink) {
        Write-Error "Failed to extract link via browser for querySelector('$QueryString') on $Url"
        return
    }
}
else {
    # Parse HTML with COM HTMLFile (supports basic querySelector on Windows)
    $doc = New-Object -ComObject "HTMLFile"
    try { $doc.IHTMLDocument2_write($htmlContent) }
    catch { $doc.write([ref]$htmlContent) }
    $doc.close()

    $element = $doc.querySelector($QueryString)
    if (-not $element) {
        Write-Error "No element found matching querySelector('$QueryString') on $Url"
        return
    }

    # Extract attribute — try element directly, then fall back to child <a>
    $downloadLink = $element.getAttribute($Attribute)
    if (-not $downloadLink) {
        $childAnchor = $element.querySelector('a')
        if ($childAnchor) { $downloadLink = $childAnchor.getAttribute($Attribute) }
    }
    if (-not $downloadLink) {
        Write-Error "No '$Attribute' found on element matching '$QueryString' on $Url"
        return
    }
}

# Resolve relative URLs
if (-not $downloadLink.StartsWith('http')) {
    $downloadLink = [System.Uri]::new([System.Uri]$Url, $downloadLink).AbsoluteUri
}

# Download
$fileName = ([System.Uri]$downloadLink).Segments[-1]
$downloadPath = & "$PSScriptRoot\_Downloader.ps1" -Url $downloadLink -FileName $fileName

return @{
    HasNewVersion = $true
    DownloadPath  = $downloadPath
}


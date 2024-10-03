# $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
# $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36 Edg/129.0.0.0"
# Invoke-WebRequest -UseBasicParsing -Uri "https://time-test.gologin.com/check_proxy" `
#     -Method "POST" `
#     -WebSession $session `
#     -Headers @{
#     "authority"          = "time-test.gologin.com"
#     "method"             = "POST"
#     "path"               = "/check_proxy"
#     "scheme"             = "https"
#     "accept"             = "application/json"
#     "accept-encoding"    = "gzip, deflate, br, zstd"
#     "accept-language"    = "en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7,ar;q=0.6"
#     "dnt"                = "1"
#     "origin"             = "https://gologin.com"
#     "priority"           = "u=1, i"
#     "referer"            = "https://gologin.com/"
#     "sec-ch-ua"          = "`"Microsoft Edge`";v=`"129`", `"Not=A?Brand`";v=`"8`", `"Chromium`";v=`"129`""
#     "sec-ch-ua-mobile"   = "?0"
#     "sec-ch-ua-platform" = "`"Windows`""
#     "sec-fetch-dest"     = "empty"
#     "sec-fetch-mode"     = "cors"
#     "sec-fetch-site"     = "same-site"
# } `
#     -ContentType "application/json" `
#     -Body "{`"type`":`"socks5`",`"host`":`"8.213.215.187`",`"port`":`"8443`",`"username`":`"`",`"password`":`"`"}"



function Test-Proxy($url, $proxyUrl) {
    try {
        # Setup the proxy
        $proxy = New-Object System.Net.WebProxy($proxyUrl)
    
        # Setup HTTP client
        $httpClientHandler = New-Object System.Net.Http.HttpClientHandler
        $httpClientHandler.Proxy = $proxy
        $httpClientHandler.UseProxy = $true
    
        $httpClient = New-Object System.Net.Http.HttpClient($httpClientHandler)
        $httpClient.Timeout = New-TimeSpan -Seconds 10
    
        # Send HTTP request
        $response = $httpClient.GetAsync($url).Result
    
        if ($response.IsSuccessStatusCode) {
            Write-Output "Proxy $proxyUrl is working."
        }
        else {
            Write-Output "Proxy $proxyUrl failed with status: $($response.StatusCode)."
        }
    }
    catch {
        Write-Output "Proxy $proxyUrl failed with error: $_"
    }
    finally {
        if ($null -ne $httpClient) {
            $httpClient.Dispose()
        }
        if ($null -ne $httpClientHandler) {
            $httpClientHandler.Dispose()
        }
    }
}
    
# List of proxies
$proxies = @("http://45.12.30.195:80")
    
# Target URL to test the proxy
$testUrl = "http://facebook.com"
    
# Test each proxy
foreach ($proxy in $proxies) {
    Test-Proxy -url $testUrl -proxyUrl $proxy
}
    
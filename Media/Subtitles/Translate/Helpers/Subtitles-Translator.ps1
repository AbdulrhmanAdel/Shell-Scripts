# Source https://subtitlestranslator.com/
function Translate {
    param (
        [string[]]$sentences
    )

    $parsedBody = ConvertTo-Json -InputObject @(@($sentences, "auto", "ar"), "te")
    $body = [System.Text.Encoding]::UTF8.GetBytes($parsedBody)
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36 Edg/129.0.0.0"
    $res = Invoke-WebRequest -UseBasicParsing -Uri "https://translate-pa.googleapis.com/v1/translateHtml" `
        -Method "POST" `
        -WebSession $session `
        -Headers @{
        "authority"          = "translate-pa.googleapis.com"
        "method"             = "POST"
        "path"               = "/v1/translateHtml"
        "scheme"             = "https"
        "accept"             = "*/*"
        "accept-encoding"    = "gzip, deflate, br, zstd"
        "accept-language"    = "en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7,ar;q=0.6"
        "dnt"                = "1"
        "origin"             = "https://subtitlestranslator.com"
        "priority"           = "u=1, i"
        "referer"            = "https://subtitlestranslator.com/"
        "sec-ch-ua"          = "`"Microsoft Edge`";v=`"129`", `"Not=A?Brand`";v=`"8`", `"Chromium`";v=`"129`""
        "sec-ch-ua-mobile"   = "?0"
        "sec-ch-ua-platform" = "`"Windows`""
        "sec-fetch-dest"     = "empty"
        "sec-fetch-mode"     = "cors"
        "sec-fetch-site"     = "cross-site"
        "x-goog-api-key"     = "AIzaSyATBXajvzQLTDHEQbcpq0Ihe0vWDHmO520"
    } `
        -ContentType "application/json+protobuf" `
        -Body $body;
        
    return ConvertFrom-Json -InputObject ([System.Text.Encoding]::UTF8.GetString($res.Content));
}

$translated = Translate -sentences $args[0];
return $translated;

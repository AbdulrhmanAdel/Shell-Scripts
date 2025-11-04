$global:Links = @();

if (-not $global:Links -or $global:Links.Length -eq 0) {
    $Text = Input.ps1 -Title "Please Enter Links" -MultiLine;
    $global:Links = $Text -split [Environment]::NewLine;
}


$regex = "window.open\(`"(?<Link>https\:\/\/fuckingfast.co/dl/.*)`"\)"
$global:links = $global:Links | ForEach-Object {
    $response = Invoke-WebRequest -Uri $_;
    $text = $response.Content;
    if ($text -match $regex) {
        return $Matches['Link']
    }
    return null;
} | Where-Object { $null -ne $_ }

Set-Clipboard -Value "$($global:links -join [Environment]::NewLine)"


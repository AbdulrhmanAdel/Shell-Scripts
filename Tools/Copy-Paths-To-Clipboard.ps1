$data = $args | ForEach-Object {
    return """$($_)"""
}

Write-Host $data;
Set-Clipboard -Value "$($data -join " ")"
timeout.exe 10;
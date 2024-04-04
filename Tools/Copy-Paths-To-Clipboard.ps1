Write-Host $args
$data = $args | ForEach-Object {
    $new = $_ -replace "\\", "\\";
    return """\""$new\"""""
}

# Write-Host $data;
Set-Clipboard -Value "$($data -join ", ")"
timeout.exe 10;

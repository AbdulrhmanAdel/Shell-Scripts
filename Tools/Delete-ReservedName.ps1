[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]
    $Files
)

foreach ($file in $Files) {
    $path = "\\?\$file"
    try {
        if ([System.IO.Directory]::Exists($path)) {
            [System.IO.Directory]::Delete($path, $true)
        }
        else {
            [System.IO.File]::Delete($path)
        }
        Write-Host "Deleted $file" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to delete ${file}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

timeout.exe 5;

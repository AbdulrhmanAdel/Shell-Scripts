param(
    [Parameter(Mandatory = $true)]
    [string[]]$FilePaths
)

foreach ($filePath in $FilePaths) {
    Write-Host $filePath;
    # Your script logic here, using $filePath variable
}

Read-Host "Press."

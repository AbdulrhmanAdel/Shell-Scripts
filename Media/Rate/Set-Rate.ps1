$args | ForEach-Object {
    $details = Get-ShowDetails.ps1 -Path $_;
    $rate = & "$($PSScriptRoot)/Websites/Imdb.ps1" -Name ($details.Name) -Type $details.Type;

    Write-Host $rate;
}
$display = Multi-Options-Selector.ps1 -Options @("Streams", "Chapters") -MustSelectOne;
($args | Where-Object { $_ -match ".*(.mkv)$" })  | ForEach-Object {
    Write-Host "===================================" -ForegroundColor Red;
    $fileName = [System.IO.Path]::GetFileName($_);
    Write-Host "Info For $fileName" -ForegroundColor Green;
    $path = $_;
    $display | ForEach-Object {
        if ($_ -eq "Chapters") {
            $chapters = Get-Chapters.ps1 -FilePath $path -Log;
            Write-Host $chapters;
        }
        else {
            & ffprobe.exe -v error -i $path -print_format json -show_streams `
                -show_entries "stream=index,codec_type:disposition=default:tags=language";
        }
    }
    Write-Host "===================================" -ForegroundColor Red;
}
& Force-ManuallyExit.ps1;
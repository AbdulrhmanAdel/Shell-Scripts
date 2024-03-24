function Get-Period() {
    $period = Read-Host "Please type delay period in seconds?";
    $period = $period -as [double]
    if ($period -isnot [System.Double]) {
        return Get-Period;
    }
    

    return $period;
}
$delayMilliseconds = (Get-Period) * 1000;
# Function to adjust time
$handlers = @{
    ".ass" = "$($PSScriptRoot)/handlers/Ass-Subtitle-Shifter.ps1";
    ".srt" = "$($PSScriptRoot)/handlers/Srt-Subtitle-Shifter.ps1";
};

function HandleFiles {
    param (
        $files
    )
 
    foreach ($file in $files) {
        $fileInfo = Get-Item -LiteralPath $file;
        if ($fileInfo -is [System.IO.DirectoryInfo]) {
            $childs = Get-ChildItem -LiteralPath $file -Include "*.ass";
            HandleFiles -files ($childs | Select-Object { $_.FullName });
            continue;
        }

        $extension = $fileInfo.Extension.ToLower();
        $handler = $handlers[$extension];
        if (!$handler) {
            continue;
        }

        Write-Host "USING MODULE $extension => $handler";
        Write-Host "Start Handling $file";
        & $handler ""$file"" $delayMilliseconds;
        Write-Host "Finish Handling $file";
    }
    
}


$files = $args | Where-Object { $_.EndsWith(".ass") }
HandleFiles -files $args;

Write-Host "Subtitles adjusted."
timeout.exe 5;

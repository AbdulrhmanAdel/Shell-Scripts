function Get-Period() {
    $period = Read-Host "Please type delay period in seconds?";
    $period = $period -as [int]
    if ($period -isnot [System.Int32]) {
        return Get-Period;
    }

    return $period;
}
$delayMilliseconds = (Get-Period) * 1000;
$PSScriptRoot
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
        & $handler ""$file"" $delayMilliseconds;
    }
    
}
HandleFiles -files $args;

Write-Host "Subtitles adjusted."
timeout.exe 5;

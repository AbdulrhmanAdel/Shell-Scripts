$handlers = @{
    ".ass" = "$($PSScriptRoot)/handlers/Ass-Subtitle-Shifter.ps1";
    ".srt" = "$($PSScriptRoot)/handlers/Srt-Subtitle-Shifter.ps1";
};

function Get-DelayInMilliseconds() {
    $period = Input.ps1 -Type "Number" -Title "Please type delay period in seconds?" -Required;
    if ($period -eq 0) {
        return Get-DelayInMilliseconds;
    }
    
    return $period;
}

$delayMilliseconds = (Get-DelayInMilliseconds) * 1000;
Write-Host "The Delay Will Be $delayMilliseconds Milliseconds"

# Function to adjust time
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


        Write-Host "=========================" -ForegroundColor Green;
        Write-Host "USING MODULE $extension => $handler";
        Write-Host "Start Handling $file";
        & $handler `
            -file "$file" `
            -delayMilliseconds $delayMilliseconds;

        Write-Host "Finish Handling $file";
        Write-Host "=========================" -ForegroundColor Green;
    }
}

$files = $args | Where-Object { Is-Subtitle.ps1 $_ };
HandleFiles -files $files;
Write-Host "Subtitles adjusted."
timeout.exe  20 /nobreak;

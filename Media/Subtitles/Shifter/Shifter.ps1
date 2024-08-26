$handlers = @{
    ".ass" = "$($PSScriptRoot)/handlers/Ass-Subtitle-Shifter.ps1";
    ".srt" = "$($PSScriptRoot)/handlers/Srt-Subtitle-Shifter.ps1";
};

$global:cutFrom = $null;
$global:cutTo = $null;
$global:startAtWord = $null;

function Get-Period() {
    $period = Read-Host "Please type delay period in seconds?";
    $period = $period -as [double]
    if ($period -isnot [System.Double]) {
        return Get-Period;
    }
    
    return $period;
}

$delayMilliseconds = (Get-Period) * 1000;
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

        Write-Host "USING MODULE $extension => $handler";
        Write-Host "Start Handling $file";
        $encoding = & Get-File-Encoding.ps1 $file;
        Write-Host "USED ENCODING $encoding" -ForegroundColor Green;
        & $handler `
            -file "$file" `
            -delayMilliseconds $delayMilliseconds `
            -encoding $encoding;

        Write-Host "Finish Handling $file";
    }
}


$mode = ($args | Where-Object { $null -ne $_ -and $_.StartsWith("mode=") }) -replace "mode=", ""
switch ($mode) {
    "StartAtWord" {
        $global:startAtWord = "-startAtWord=$(Read-Host 'Please enter startAtWord')";
        break;
    }

    "Range" {  
        $global:cutFrom = "cutFrom=$(Read-Host 'Please enter cutFrom')";
        $global:cutTo = "cutTo=$(Read-Host 'Please enter cutTo')";
        break;
    }
}

$files = $args | Where-Object { $_.EndsWith(".ass") -or $_.EndsWith(".srt") }
HandleFiles -files $files;
Write-Host "Subtitles adjusted."
timeout.exe 15;

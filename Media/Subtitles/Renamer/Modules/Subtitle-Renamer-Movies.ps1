$inputFiles = @($args[0] | ForEach-Object { return Get-Item -LiteralPath $_ } | Where-Object { $_ -is [System.IO.FileInfo] });
if ($inputFiles.Length -le 0) { Exit; };

$replaceRegex = "\.|-|_|\(|\)";
function RemoveSigns {
    param (
        $text
    )

    return $text -replace $replaceRegex, " " -replace "  +", " "
}

function GetMovieName {
    param (
        $fileName
    )

    $match = [regex]::Match($fileName, "720|480|1080")
    if ($match.Success) {
        $Index = $Match.Index;
        $name = RemoveSigns -text $fileName.Substring(0, $Index);
        $name = $name.Trim();
        return $name;

    }

    return $fileName;
}

$subtitles = @($inputFiles | Where-Object {
        return $_.Extension -eq ".ass" -or $_.Extension -eq ".srt";
    } | Foreach-Object {
        return @{
            FileInfo = $_
            Name     = RemoveSigns -text $_.Name
        };
    });

$videos = @($inputFiles | Where-Object {
        return $_.Extension -eq ".mkv" -or $_.Extension -eq ".mp4";
    });


$videos | ForEach-Object {
    $fileInfo = $_;
    $movieName = GetMovieName -fileName ($fileInfo.Name);
    $subFile = $subtitles | Where-Object { 
        return $_.Name -match $movieName
    } | Select-Object -First 1


    if ($subFile) {
        $subFile = $subFile.FileInfo;
        $newSubName = $fileInfo.Name -replace $fileInfo.Extension, $subFile.Extension;
        Write-Host "$($fileInfo.Name) -> $($subFile)" -ForegroundColor Green
        if ($newSubName -eq $subFile.Name) {
            return;
        }

        Rename-Item -LiteralPath $subFile -NewName $newSubName
    }
    else {
        Write-Host "$($fileInfo.Name) -> Not Found" -ForegroundColor Red
    }
}

Write-Host "Done" -ForegroundColor Yellow;
timeout.exe 15;
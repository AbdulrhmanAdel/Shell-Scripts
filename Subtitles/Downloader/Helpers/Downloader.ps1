[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $downloadLink
)

$downloadSubtitleCache ??= @{ };
function DownloadSubtitle {
    param (
        $sub
    )
    Write-Host "Downloading Subtitle From => "  -NoNewLine;
    Write-Host "$subsourceSiteDomain$($sub.link)" -ForegroundColor Blue;
    Write-Host "Release Name " -NoNewLine;
    Write-Host "$($sub.release_info)" -ForegroundColor Blue;
    if ($downloadSubtitleCache[$sub.id]) {
        return $downloadSubtitleCache[$sub.id];
    }
    $downloadSubDetails = Invoke-Request -path "subtitle/$($sub.link)" -property "subtitle";
    $downloadToken = $downloadSubDetails.download_token;
    $downloadLink = "$baseUrl/subtitle/download/$downloadToken";
    $fileName = $sub.release_info -replace '[<>:"/\\|?*]', ' ' -replace '  *', ' ';
    $tempPath = "$downloadPath/$fileName";
    Invoke-WebRequest -Uri $downloadLink -OutFile $tempPath;
    $extractLocation = "$downloadPath\$( Get-Date -Format 'yyyy-MM-dd-HH-mm-ss' )"
    & 7z  x $tempPath -aoa -bb0 -o"$extractLocation" | Out-Null;
    $downloadSubtitleCache[$sub.id] = $extractLocation;
    Start-Sleep -Milliseconds 500;
    return $extractLocation;
}

function CopySubtitle {
    param (
        $subtitlePath,
        $details,
        $savePath,
        $renameTo,
        $episodeRegex,
        $qualityRegex
    )
    
    $files = @(Get-ChildItem -LiteralPath $subtitlePath -Force -Include *.ass, *.srt, *.sub);
    $fileIndex = 0;

    if ($episodeRegex -and $files.Length -gt 1) {
        $files = @($files | Where-Object { $_.Name -match $episodeRegex })
    }

    if ($qualityRegex -and $files.Length -gt 1) {
        $primaryFile = $files | Where-Object { $_.Name -match $qualityRegex } | Select-Object -First 1;
        if ($primaryFile) {
            $files = @($primaryFile);
        }
    }

    $files | ForEach-Object {
        $file = $files[$fileIndex];
        $finalName = $file.Name -replace $file.Extension, "";
        if ($renameTo) {
            $finalName = $renameTo;
        }
        if ($files.Length -gt 1) {
            if ($fileIndex -gt 0) {
                $finalName += ".$fileIndex"
            }
            $fileIndex++;
        }

        if ( $file.Attributes.HasFlag([System.IO.FileAttributes]::Hidden)) {
            $file.Attributes -= "Hidden";
        }

        Copy-Item -LiteralPath $file.FullName `
            -Destination "$savePath/$( $finalName )$( $file.Extension )";
    }
}

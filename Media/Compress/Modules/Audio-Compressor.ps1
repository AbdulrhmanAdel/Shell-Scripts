. Parse-Args.ps1 $args;

$audioConfig = @{
    'mp3'  = @{ Encoder = "libmp3lame"; BitRates = @('128K', '160K', '192K', '256K', '320K') }
    'm4a'  = @{ Encoder = "aac"; BitRates = @('128K', '160K', '192K', '256K') }
    'opus' = @{ Encoder = "libopus"; BitRates = @('64K', '96K', '128K') }
}

$files = @($args)
if ($files.Length -le 0) { Write-Host "No Files Found" -ForegroundColor Red; Start-Sleep -Seconds 10; };
if (!$global:outputPath) {
    $global:outputPath = & Folder-Picker.ps1 -intialDirectory "D:\";
}

#region Functions

function Convert() {
    param (
        [System.IO.FileInfo]$info,
        [string]$finalOutputPath,
        [bool]$addSpecsToFileName
    )

    Write-Host "Converting $($info.Name) to $($targetBitRate)bitrate to $($targetExtension) format" -ForegroundColor Green;
    $name = $info.Name;
    if ($addSpecsToFileName) {
        $name = $name -replace $info.Extension, " $targetBitRate-$($sampleRate)HZ.$($info.Extension)";
    }

    $output = "$finalOutputPath/$($name -replace $info.Extension, ".$targetExtension")";
    $arguments = @(
        "-loglevel", "error",
        "-i", """$($info.FullName)"""
    );

    if (!$keepMetadata) {
        $arguments += @("-map_metadata", "-1");
    }

    $arguments += @(
        "-codec:a" , $config.Encoder,
        "-b:a", $targetBitRate,
        "-ar", $sampleRate,
        "-map", "a",
        """$output"""
    )

    Start-Process ffmpeg -ArgumentList $arguments -NoNewWindow -PassThru -Wait;
    Write-Host "==========================" -ForegroundColor DarkBlue;
}

function Prepeare(
    $inputPath,
    $outputPath
) { 
    $info = Get-Item -LiteralPath $inputPath;
    if ($info -is [System.IO.FileInfo]) {
        $finalOutputPath = $outputPath ?? $info.Directory.FullName;
        $addSpecsToFileName = $addSpecsToOutputFileName -or (!$outputPath);
        Convert -info $info -finalOutputPath $finalOutputPath -addSpecsToFileName $addSpecsToFileName;
        return;
    }

    Get-ChildItem -LiteralPath "$($info.FullName)" | Where-Object {
        return Is-Media.ps1 $_.FullName
    } | ForEach-Object {
        $finalOutputPath = $info.FullName;
        if ($outputPath) {
            $finalOutputPath = "$outputPath/$($info.Name)";
            if (!(Test-Path -LiteralPath $finalOutputPath)) {
                New-Item -Path $finalOutputPath -ItemType Directory -Force;
            }
        }

        if ($_ -is [System.IO.FileInfo]) {
            $addSpecsToFileName = $addSpecsToOutputFileName -or (!$outputPath);
            Convert -info $_ -finalOutputPath $finalOutputPath -addSpecsToFileName $addSpecsToFileName;
            return;
        } 

        Prepeare -inputPath $_.FullName -outputPath $finalOutputPath;
    }
}

#endregion

#region Options

$addSpecsToOutputFileName = & Prompt.ps1 -title "Add Specs to Output File Name?" -defaultValue $false -message "Add Specs to Output File Name?";
$targetExtension = & Single-Options-Selector.ps1 -Options $audioConfig.Keys -defaultValue "m4a";
$config = $audioConfig[$targetExtension];
$targetBitRate = & Single-Options-Selector.ps1 -Options $config.BitRates -defaultValue $config.BitRates[0];
$sampleRate = & Single-Options-Selector.ps1 -Options @("24000", "32000", "48000") -defaultValue "48000";
$keepMetadata = & Prompt.ps1 -title "Keep Metadata?" -defaultValue $false -message "Keep Metadata?";

#endregion

$args | ForEach-Object {
    Prepeare -inputPath $_ -outputPath $global:outputPath;
}

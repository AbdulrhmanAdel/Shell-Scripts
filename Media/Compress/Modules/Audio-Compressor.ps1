$outputPath = & Folder-Picker.ps1 -intialDirectory "D:\";
$audioConfig = @{
    'mp3'  = @{ Encoder = "libmp3lame"; BitRates = @('128K', '160K', '192K', '256K', '320K') }
    'm4a'  = @{ Encoder = "aac"; BitRates = @('128K', '160K', '192K', '256K') }
    'opus' = @{ Encoder = "libopus"; BitRates = @('64K', '96K', '128K') }
}


$addSpecsToOutputFileName = & Prompt.ps1 -title "Add Specs to Output File Name?" -defaultValue $false -message "Add Specs to Output File Name?";
$targetExtension = & Options-Selector.ps1 $audioConfig.Keys -defaultValue "m4a";
$config = $audioConfig[$targetExtension];
$targetBitRate = & Options-Selector.ps1 $config.BitRates -defaultValue $config.BitRates[0];
$sampleRate = & Options-Selector.ps1 @("24000", "32000", "48000") -defaultValue "48000";

$regex = "\.($($audioConfig.Keys -join '|'))$";
$args | Where-Object { $_ -match $regex } | ForEach-Object {
    $info = Get-Item -LiteralPath $_;
    $name = $info.Name;
    $finalOutputPath = $outputPath ?? $info.Directory.FullName;
    if ($addSpecsToOutputFileName -or !$outputPath) {
        $name = $name -replace $info.Extension, " $targetBitRate-$($sampleRate)HZ.$($info.Extension)";
    }

    $output = "$finalOutputPath/$($name -replace $info.Extension, ".$targetExtension")";
    $arguments = @(
        "-i", """$($info.FullName)""",
        "-codec:a" , $config.Encoder,
        "-b:a", $targetBitRate,
        "-ar", $sampleRate,
        "-map", "a",
        """$output"""
    );

    Start-Process ffmpeg -ArgumentList $arguments -NoNewWindow -PassThru -Wait;
}

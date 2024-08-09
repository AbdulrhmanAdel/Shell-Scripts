
$filePath = $args[0];
$fileExtension = [System.IO.Path]::GetExtension($filePath);
$outputPath = $filePath.Replace($fileExtension, ".cropped$fileExtension");

#region Functions
Write-Host "Allowed Sperators => (Space or : or , or |)";
function Prompt {
    param (
        [string]$key
    )
    
    $timeInput = (Read-Host "$key") -split ":| |,|\|";
    if (!$timeInput) {
        return 0;
    }

    $timeSpan = [timespan]::FromSeconds($timeInput[$timeInput.Length - 1]);
    if ($timeInput.Length -eq 3) {
        $timeSpan += [timespan]::FromMinutes($timeInput[1]);
        $timeSpan += [timespan]::FromHours($timeInput[0]);
    }
    elseif ($timeInput.Length -eq 2) {
        $timeSpan += [timespan]::FromMinutes($timeInput[0]);
    }

    return $timeSpan.TotalSeconds;
}
#endregion

$start = Prompt -key "Start?"
$end = Prompt -key "End?"
# if ($end -eq 0) {
#     exit;
# }
$commandArgs = @(
    "-y",
    "-ss", $start
);

if ($end) {
    $commandArgs += @("-to", $end)
}

$commandArgs += @(
    "-i", """$filePath""",
    """$outputPath"""
    );

Start-Process ffmpeg -ArgumentList $commandArgs -NoNewWindow;
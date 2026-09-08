[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string]
    $File
)

$fileExtension = [System.IO.Path]::GetExtension($File);
$outputPath = $File.Replace($fileExtension, ".cropped$fileExtension");

#region Functions
Write-Host "Please enter time in format: HH MM SS or MM SS or SS";
Write-Host "Allowed Separators => Space|:";
function Prompt {
    param (
        [string]$key
    )
    
    $timeInput = (Read-Host "$key") -split ":| ";
    if (!$timeInput) {
        return 0;
    }

    $timeSpan = [TimeSpan]::FromSeconds($timeInput[$timeInput.Length - 1]);
    if ($timeInput.Length -eq 3) {
        $timeSpan += [TimeSpan]::FromMinutes($timeInput[1]);
        $timeSpan += [TimeSpan]::FromHours($timeInput[0]);
    }
    elseif ($timeInput.Length -eq 2) {
        $timeSpan += [TimeSpan]::FromMinutes($timeInput[0]);
    }

    return $timeSpan.TotalSeconds;
}
#endregion

$start = Prompt -key "Start?"
$end = Prompt -key "End?"
$commandArgs = @(
    "-y",
    "-ss", $start
);

if ($end) {
    $commandArgs += @("-to", $end)
}

$commandArgs += @(
    "-i", """$File""",
    """$outputPath"""
);

Start-Process ffmpeg -ArgumentList $commandArgs -NoNewWindow;
Write-Output "$args";

$folderPath = $args[0];
$removeText = Read-Host "Do you want to remove any text from file names?";
$files = Get-ChildItem $folderPath -Force;

class File {
    File($EpisodePath, $EpisodeNumber) {
        $this.EpisodePath = $EpisodePath;
        $this.EpisodeNumber = $EpisodeNumber;
    }
    <# Define the class. Try constructors, properties, or methods. #>
    [System.IO.FileInfo]$EpisodePath;
    [int] $EpisodeNumber;
}

function SortFiles() { 
    param (
        [Parameter(ValueFromPipeline)]
        [System.IO.FileInfo[]]
        $items
    )
    $newItems = [System.IO.FileInfo[]]::new($items.Length);
    $i = 0;
    $items | ForEach-Object {
        $_.Name -match "(?i:(Episode *(\d+))|(E(\d+))|(E *(\d+))|(E *\((\d+)\)))";
        $outNumber = $null;
        foreach ($match in $Matches.Values) {
            if ([Int32]::TryParse($match, [ref] $outNumber)) {
                break;
            }
        }
    
        return [File]::new($_, $outNumber);
    } `
    | Where-Object { $_ -ne $true } `
    | Sort-Object { $_.EpisodeNumber } `
    | ForEach-Object { 
        $newItems[$i] = $_.EpisodePath;
        $i++;
    }

    return $newItems;
}

$videos = SortFiles -items ($files `
    | Where-Object { $_.Name -like "*.mkv" -or $_.Name -like "*.mp4" });

$subtitles = SortFiles -items ($files `
    | Where-Object { $_.Name -like "*.srt" -or $_.Name -like "*.ass" });

if ($videos.Length -ne $subtitles.Length) {
    Write-Output "Videos and subtitles count not equal";
    Read-Host "Press Any key To Exists";
}

for ($i = 0; $i -lt $videos.Length; $i++) {
    $video = $videos[$i];
    $subtitle = $subtitles[$i];

    Write-Output "$($video.Name): $($subtitle.Name)";
}

Read-Host "Continue?"

for ($i = 0; $i -lt $videos.Length; $i++) {
    $video = $videos[$i];
    $subtitle = $subtitles[$i];


    $videoName = $video.Name;
    if ($removeText) {
        $videoName = $videoName -replace $removeText;
        Rename-Item `
            -Path $video.FullName `
            -NewName $videoName;
    }

    $newName = $videoName -replace $video.Extension, $subtitle.Extension;
    Rename-Item `
        -Path $subtitle.FullName `
        -NewName $newName;
}

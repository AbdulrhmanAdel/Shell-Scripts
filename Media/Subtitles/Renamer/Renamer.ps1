# #region Functions
# $replaceRegex = "(?i)-PSA|(\(|\[)(Hi10|AniDL)(\)|\])(_| |-)*";
# $signsRegex = "_"
# function Rename {
#     param (
#         [System.IO.FileInfo]$source,
#         [System.IO.FileInfo]$target
#     )
    
#     $sourceName = $source.Name -replace $replaceRegex, "" -replace $signsRegex, " ";
#     if ($sourceName -ne $sourceName) {
#         Rename-Item -LiteralPath $source.FullName -NewName $sourceName;
#     }

#     $targetName = $sourceName -replace $source.Extension, $target.Extension;
#     if ($targetName -ne $target.Name) {
#         Rename-Item -LiteralPath $target.FullName -NewName $targetName;
#     }
# }


# $episodeNumberRegex = "(?i)(?<Name>.*)((S|Season)\d+)(Episode|Ep|E|[-,|,_,*,#,\.]|\[| |\dx)(?<EpisodeNumber>\d+)([-,|,_,*,#,\.]| |\]|v\d+)";
# function GetEpisodeNumber($fileName) {
#     $episodeNumber = $null;
#     $matched = $fileName -match $episodeNumberRegex;
#     if (!$matched) {
#         $fileNameWithoutExt = $fileName -replace [System.IO.Path]::GetExtension($fileName), "";
#         if ([int]::TryParse($fileNameWithoutExt, [ref]$episodeNumber)) {
#             return $episodeNumber
#         }
#         Write-Host "Can't Extract Episode Number From $fileName";
#         return; 
#     }
#     $episodeNumber = [int]($Matches["EpisodeNumber"]);
#     if (!$episodeNumber) {
#         Write-Host "Can't Get EpisodeNumber for $fileName, GOT $episodeNumber"
#         timeout 15
#         exit;
#     }

#     return $episodeNumber;
# }

# #endregion
# $series = @{};
# $movies = @{};

# $args | ForEach-Object {
#     $info = Get-Item -LiteralPath $_;
#     $episodeNumber = GetEpisodeNumber -fileName $info.Name;

# }

$details = @($args | ForEach-Object {
        return & Get-Show-Details.ps1 -Path $_ --OnlyBasicInfo;
    } | Where-Object {
        $null -ne $_
    })

$global:renameMap = @();

function SetRename {
    param (
        $files
    )

    if ($files.Count -eq 1) {
        $file = $files[0];
        $text = "CAN'T HANDLE $($file.Info.Name)" `
            + ($file.Season ? " Season $($file.Season)" : "") `
            + ($file.Episode ? " Episode $($file.Episode)" : "");
        Write-Host $text -ForegroundColor Red; 
        return;
    }

    $show = $files | Where-Object { $_.Info.Extension -in @(".mkv", ".mp4") } | Select-Object -First 1;
    $subtitle = $files | Where-Object { $_ -ne $show } | Select-Object -First 1;
    $text = "Renaming " `
        + ($show.Season ? " S$($show.Season)E$($show.Episode)-" : "") + $show.Info.Name `
        + " => " `
        + ($subtitle.Season ? " S$($subtitle.Season)E$($subtitle.Episode)-" : "") + $show.Info.Name;
    Write-Host $text -ForegroundColor Green;
    $global:renameMap += @{
        Show     = $show.Info
        Subtitle = $subtitle.Info
    }
}

$replaceRegex = @(
    "-PSA", 
    "(\(|\[)(Hi10|AniDL)(\)|\])(_| |-)*", 
    "-Pahe\.in", 
    "-GalaxyTV"
) -join "|";

function HandleRenameMap {
    $global:renameMap | ForEach-Object {
        $show = [System.IO.FileInfo]$_.Show;
        $subtitle = [System.IO.FileInfo]$_.Subtitle;
        $showNewName = $show.Name -replace $replaceRegex, "";
        if ($showNewName -ne $show.Name) {
            & Force-Rename.ps1 -Path $show.FullName -NewName $showNewName;
        }
    
        $subName = $showNewName -replace $show.Extension, $subtitle.Extension; 
        & Force-Rename.ps1 -Path $subtitle.FullName -NewName $subName;
    }

    $global:renameMap = @();
}

Write-Host "===================== START"
Write-Host "Handling Movies" -ForegroundColor Cyan
@($details | Where-Object { $_.type -eq "M" }) | Group-Object { return $_["Title"] } | ForEach-Object {
    SetRename -files $_.Group;
};

HandleRenameMap
Write-Host "===================== END"
Write-Host ""

Write-Host "===================== START"
Write-Host "Handling Series" -ForegroundColor Blue;
@($details | Where-Object { $_.type -eq "S" }) | Group-Object { return $_["Title"] } | ForEach-Object {
    $seasons = $_.Group | Group-Object { return $_["Season"] };
    $seasons.Group | Group-Object { return $_["Episode"] } | ForEach-Object {
        SetRename -files $_.Group
    };
};

HandleRenameMap
Write-Host "===================== END"

timeout.exe  20 /nobreak;
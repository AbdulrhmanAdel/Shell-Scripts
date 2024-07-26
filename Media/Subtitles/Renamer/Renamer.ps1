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


$method = & Options-Selector.ps1 `
    -options @("Series", "Movies") -defaultValue "Series" `
    -title "Rename Source";

if (!$method) { EXIT; }
& "$($PSScriptRoot)/modules/Subtitle-Renamer-$method" $args;

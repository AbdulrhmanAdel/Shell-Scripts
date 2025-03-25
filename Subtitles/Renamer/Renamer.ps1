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
    $global:renameMap += @{
        Show     = $show
        Subtitle = $subtitle
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
        $show = $_.Show;
        $subtitle = $_.Subtitle;
        Write-Host "Matched Subtitle " -NoNewline -ForegroundColor Yellow;
        Write-Host (($show.Season ? "S$($show.Season)E$($show.Episode)-" : "") + $show.Info.Name)  -ForegroundColor Green -NoNewline;
        Write-Host " => " -ForegroundColor Yellow -NoNewline;
        Write-Host (($subtitle.Season ? " S$($subtitle.Season)E$($subtitle.Episode)-" : "") + $subtitle.Info.Name) -ForegroundColor Green ;
        $showFileInfo = [System.IO.FileInfo]$show.Info;
        $subtitleFileInfo = [System.IO.FileInfo]$subtitle.Info;
        $showFileInfoNewName = $showFileInfo.Name -replace $replaceRegex, "";
        if ($showFileInfoNewName -ne $showFileInfo.Name) {
            & Force-Rename.ps1 -Path $showFileInfo.FullName -NewName $showFileInfoNewName;
        }
    
        $subName = $showFileInfoNewName -replace $showFileInfo.Extension, $subtitleFileInfo.Extension; 
        if ($subName -ne $subtitleFileInfo.Name) {
            & Force-Rename.ps1 -Path $subtitleFileInfo.FullName -NewName $subName;
        }
    }

    $global:renameMap = @();
}

$details = @($args | ForEach-Object {
    return & Get-ShowDetails.ps1 -Path $_ -OnlyBasicInfo;
} | Where-Object {
    $null -ne $_
})

Write-Host "===================== START"
Write-Host "Handling Movies" -ForegroundColor Cyan
@($details | Where-Object { $_.type -eq "Movie" }) | Group-Object { return $_["Title"] } | ForEach-Object {
    SetRename -files $_.Group;
};

HandleRenameMap
Write-Host "===================== END"
Write-Host ""

Write-Host "===================== START"
Write-Host "Handling Series" -ForegroundColor Blue;
@($details | Where-Object { $_.type -eq "Series" }) | Group-Object { return $_["Title"] } | ForEach-Object {
    $seasons = $_.Group | Group-Object { return $_["Season"] };
    $seasons.Group | Group-Object { return $_["Episode"] } | ForEach-Object {
        SetRename -files $_.Group
    };
};

HandleRenameMap
Write-Host "===================== END"

timeout.exe  20 /nobreak;
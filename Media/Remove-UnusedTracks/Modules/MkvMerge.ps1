function GetAudioId {
    param (
        $audioTracks
    )
    $audioTracks = @($audioTracks | ForEach-Object {
            return @{
                Id       = [int]$_.StreamOrder;
                Language = $_.Language
                Title    = $_.Title
            }
        });

    if ($audioTracks.Length -eq 1) {
        return $audioTracks[0].Id;
    }
    
    $preferedTracks = @($audioTracks | Where-Object { $_.Language -notmatch $ignoredAudioLanguages });
    if ($preferedTracks.Length -eq 0) {
        return $audioTracks[0].Id;
    }

    if ($preferedTracks.Length -eq 1) {
        return $preferedTracks[0].Id;
    }

    $nonEnglishTrack = $preferedTracks | Where-Object { $_.Language -notmatch "en|eng|English" } | Select-Object -First 1;
    if ($nonEnglishTrack) {
        return $nonEnglishTrack.Id;
    }

    return $preferedTracks[0].Id;
}

$inputPath = $args[0];
$outputPath = $args[1];
$tracks = (& mediaInfo --Output=JSON "$inputPath" | ConvertFrom-Json).media.track;
$videoTrack = $tracks | Where-Object { $_.'@type' -eq 'Video' }
$tracksOrder = @([int]$videoTrack.StreamOrder);
$arguments = @(
    "-o", """$outputPath""",
    "--video-tracks", [int]$videoTrack.StreamOrder,
    "--no-attachments"
    # "--quiet"
);

#region Audio
$audioTracks = @($tracks | Where-Object { $_.'@type' -eq 'Audio' });
$audioId = GetAudioId -audioTracks $audioTracks;
$arguments += @("--audio-tracks", $audioId);
$tracksOrder += $audioId;
#endregion

#region Subtitles
$global:subAdded = $false;
$subtitleTracks = @($tracks | Where-Object { $_.'@type' -eq 'Text' });
$subtitleTracks | Where-Object { $_.Language -match "ara|ar|Arabic" }  | ForEach-Object {
    $global:subAdded = $true;
    $subIndex = $_.StreamOrder;
    $arguments += @("--default-track-flag", "$($subIndex):0");
    $arguments += @("--forced-display-flag", "$($subIndex):0");
    $tracksOrder += $subIndex;
}

$subtitleTracks | Where-Object { $_.Language -match "en|eng|English" }  | ForEach-Object {
    $global:subAdded = $true;
    $subIndex = $_.StreamOrder;
    $arguments += @("--default-track-flag", $subIndex);
    $arguments += @("--forced-display-flag", $subIndex);
    $tracksOrder += $subIndex;
}

if (!$global:subAdded) {
    $arguments += "--no-subtitles";
}
#endregion

$arguments += """$inputPath""";
$arguments += "--track-order"
$arguments += ($tracksOrder | ForEach-Object { return "0:$_" }) -join ","
return Start-Process mkvmerge -ArgumentList $arguments -NoNewWindow -PassThru -Wait;
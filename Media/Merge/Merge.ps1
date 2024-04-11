#region 

$mkvInfo = "D:\Programs\Media\Tools\mkvtoolnix\mkvinfo.exe";
# $segements = (Read-Host "Enter Segments To Merge") -split "," | ForEach-Object { return "*$($_)*" };
$segements = @("*OP*", "*Prologue*");
$segementsPath = Get-ChildItem -LiteralPath "E:\Watch\Anime\Hunter X Hunter" -Include  $segements;
$segements = @{};
$segementsPath | ForEach-Object {
    $info = (& $mkvInfo $_ | Where-Object { $_ -match "Segment UID" }) -replace "\| \+ Segment UID: ", "";
    $segements[$info] = $_;
}

$order = @();
$path = "E:\Watch\Anime\Hunter X Hunter\Hunter_X_Hunter_-_002_(BD_720p).mkv";
$info = & $mkvInfo $path;
$chaptesIndex = $info.IndexOf("|  + Chapter atom");
do {
    $next = [array]::IndexOf($info, "|  + Chapter atom", $chaptesIndex + 1);
    if ($next -eq -1) { 

        break; 
    }
    $arr = $info[$chaptesIndex..$next];
    $chapterSegmentId = ($arr | Where-Object { $_ -match "Chapter Segment UID" }); 
    if ($chapterSegmentId) {
        $chapterSegmentId -match "\0| +\+ +Chapter segment UID.*data: (?<SegmentId>.*)";
        $m = $Matches["SegmentId"];
        $segement = $segements[$m]
        $order += $segement.FullName;
        Write-Host ""
    }
    $chaptesIndex = $next;
} while ($chaptesIndex);

$total = 0;
$mediaInfo = "D:\Programs\Media\Tools\MediaInfo\MediaInfo.exe";
$order | ForEach-Object { 
    $duration = [double]((&$mediaInfo  --Output=JSON "$($_)" | ConvertFrom-Json).media.track | Where-Object { $_.'@type' -eq 'General' }).Duration;
    $total += $duration;
}
Write-Output $total;
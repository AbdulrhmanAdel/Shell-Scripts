$filePath = "C:\Users\Abdulrahman\Desktop\E (028).mkv"
$mkvinfo = "D:\Programs\Media\Tools\mkvtoolnix\mkvinfo.exe";
$mkvpropedit = "D:\Programs\Media\Tools\mkvtoolnix\mkvpropedit.exe";
$d = &$mkvinfo $filePath;
$chapterIds = &$mkvinfo $filePath | Where-Object {
    return $_.StartsWith("|   + Chapter UID: ");
} | Foreach-Object {
    return $_.Replace("|   + Chapter UID: ", "")
};

$command = "$mkvpropedit ""C:\Users\Abdulrahman\Desktop\E (23).mkv""";
$index = @(0, 1); 

foreach ($i in $index) {
    $command += " --edit chapter:$($i) --set flag-hidden=1"
}


# $processInfo = New-Object System.Diagnostics.ProcessStartInfo;
# $processInfo.FileName = "powershell";
# $processInfo.Arguments = "-Command  $command";
# # $processInfo.Verb = "RunAs";
# [System.Diagnostics.Process]::Start($processInfo)

Write-Host $chapterIds[0];
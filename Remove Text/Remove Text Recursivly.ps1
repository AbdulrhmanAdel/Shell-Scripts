$replaceText = " [FitGirl Repack]";
$replaceWith = "";

$totalRenamed = 0;
function SetName {
    param (
        $fullPath,
        $oldName
    )

    $newName = $oldName.Replace($replaceText, $replaceWith);
    if ($oldName -ne $newName) {
        Write-Output "$oldName => $newName";
        $totalRenamed++;
        Rename-Item  -LiteralPath  $fullPath  -NewName $newName;
    }
}

function Rename {
    param (
        $directory
    )

    $files = Get-ChildItem -LiteralPath $directory;

    foreach ($file in $files) {
        if ($file -is [System.IO.DirectoryInfo]) {
            Rename -directory $file.FullName;
            SetName  -fullPath $file.FullName -oldName $file.Name;
        }
        else {
            SetName  -fullPath $file.FullName -oldName $file.Name;
        }
    }
}


Write-Output "$totalRenamed";


Rename -directory "E:\Games";
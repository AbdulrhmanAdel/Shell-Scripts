enum Operation {
    Remove = 0
    Replace = 1
};

$folderPath = $args[0];
$operation = [Operation]$args[1];

Write-Output "
    Folder Path: $folderPath
    Operation: $operation
";

$removedText = Read-Host "Text To Be Removed?";

$replaceText;
if ($operation -eq "Replace") {
    $replaceText = Read-Host "Text To Be Replaced?"
}

function ReplaceText {
    param (
        $path, $fileName
    )

    $newFileName = $fileName;
    switch ($operation) {
        "Replace" { $newFileName = $fileName -replace $removedText, $replaceText; }
        "Remove" { $newFileName = $fileName -replace $removedText; }
    }
    Rename-Item -LiteralPath $path -NewName $newFileName -Force
}

$pathItem = Get-Item -LiteralPath $folderPath -Force;

if ($pathItem -is [System.IO.DirectoryInfo]) {
    Get-ChildItem -LiteralPath $folderPath -Force | ForEach-Object {
        ReplaceText -path $_.FullName -fileName $_.Name;
    }
}
else {
    ReplaceText -path $pathItem.FullName -fileName $pathItem.Name;
}

Write-Output "Done."




$source = $args[0];
$target = $args[1];

function Verify {
    param (
        $sourcePath,
        $targetPath
    )

    $sourceInfo = Get-Item -LiteralPath $sourcePath;
    if ($sourceInfo -is [System.IO.DirectoryInfo]) {
        $childern = Get-ChildItem -LiteralPath $sourcePath;
    
        $childern | ForEach-Object { 
            $targetFilePath = "$targetPath/" + $_.Name;
            Verify -sourcePath $_.FullName -targetPath $targetFilePath 
        };

        return;
    }

    $sourceHash = (Get-FileHash -LiteralPath $sourcePath).Hash;
    $targetHash = (Get-FileHash -LiteralPath $targetPath).Hash;
    if ($sourceHash.Hash -eq $targetHash.Hash) {
        Write-Host "$sourcePath MATCHES $targetPath" -ForegroundColor Green;
        return;
    }

    Write-Host "$sourcePath DON'T MATCHE $targetPath" -ForegroundColor Green;
}


Verify -sourcePath $source -targetPath $target 
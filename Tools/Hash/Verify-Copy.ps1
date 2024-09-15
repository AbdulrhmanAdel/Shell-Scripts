# $source = "G:\Games\Wo Long - Fallen Dynasty"
# $target = Read-Host "Please Enter Target Path";
$source = "G:\Games\Wo Long - Fallen Dynasty"
$target = "F:\Wo Long - Fallen Dynasty"


function Verify {
    param (
        $source,
        $target
    )

    $sourceInfo = Get-Item -LiteralPath $source;
    if ($sourceInfo -isnot [System.IO.DirectoryInfo]) {
        $sourceHash = Get-FileHash -LiteralPath $source MD5;
        $targetHash = Get-FileHash -LiteralPath $target MD5;
        if ($sourceHash.Hash -eq $targetHash.Hash) {
            Write-Host "$source MATCHES $target" -ForegroundColor Green;
            return;
        }

        Write-Host "$source DON'T MATCHE $target" -ForegroundColor Red;
        return;
    }
    $childern = Get-ChildItem -LiteralPath $source;
    $childern | ForEach-Object { 
        $targetFilePath = "$target/" + $_.Name;
        Verify -source $_.FullName -target $targetFilePath 
    };
}


Verify -source $source -target $target
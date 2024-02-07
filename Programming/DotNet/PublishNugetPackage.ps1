$projectPath = "D:\Education\Projects\Work\Roaa\Freejna\Repos\BackEnd\freejna-common\freejna-common\freejna-common";
$projectPathInfo = Get-Item -LiteralPath $projectPath;

$projectPath = '';
if ($projectPathInfo.Attributes.HasFlag([System.IO.FileAttributes]'Directory')) {
    $projectPath = $projectPathInfo.FullName;
}
else {
    if ($projectPathInfo.Extension -eq '.csproj') {
        $projectPath = $projectPathInfo.Directory;
    }
    else {
        exit 1;
    }
}

dotnet.exe build $projectPath;

$packgeDirectoryPath = "$projectPath/bin/debug";

$packages = Get-ChildItem -LiteralPath $packgeDirectoryPath -Filter "*.nupkg" | Sort-Object $_.Name -Descending;

$packgeFileInfo = $packages[0];

Read-Host "$($packgeFileInfo.Name) will be published, Continue?";

$sourceType = Read-Host "Please enter`n 1- Freejna`n 2- Jeerty`n 3- LetsConnect`n 4- Special Source`n";
$source;
switch ($sourceType) {
    1 { $source = "https://pkgs.dev.azure.com/AbudhabiMin/Freejna/_packaging/FreejnaNuget/nuget/v3/index.json"; break; }
    2 { $source = "https://pkgs.dev.azure.com/roaatech/Jeerty/_packaging/JeertyNuget/nuget/v3/index.json"; break; }
    3 { $source = "https://pkgs.dev.azure.com/AbdulrahmanAdel/LetsConnect/_packaging/LetsConnect/nuget/v3/index.json"; break; }
    4 { $source = Read-Host "Please enter source url"; break; }
};

dotnet nuget push --source $source --api-key az $packgeFileInfo.FullName --interactive;

Read-Host "Press Any Key To Exists";


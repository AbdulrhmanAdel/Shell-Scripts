function Set-Env ($key, $value) {
    [Environment]::SetEnvironmentVariable($key, $value, [EnvironmentVariableTarget]::User);
}

function  Get-Env($key) {
    [Environment]::GetEnvironmentVariable($key, [EnvironmentVariableTarget]::User);
}


$path = Get-Env -key 'Path';

$path += ';D:\Education\Programs\VsCode';
$path += ';D:\Education\Programs\JetBrains\Rider\bin';
$path += ';D:\Education\Programs\Android\Android Studio\bin';
$path += ';D:\Education\Programs\Android\Flutter\SKDs\3.13.7\bin';
$path += ";$($env:userprofile)\AppData\Local\Pub\Cache\bin";
Set-Env -key 'Path' -value $path;



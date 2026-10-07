$script:Aria2 = $null;

function Initialize-Aria2 {
    if ($script:Aria2) { return $script:Aria2; }

    $aria2Root = $env:ARIA2_HOME;
    $exe = $aria2Root ? (Join-Path $aria2Root 'App\aria2c.exe') : $null;
    if (!$aria2Root) {
        $command = Get-Command aria2c -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1;
        if ($command) {
            $exe = $command.Source;
            $shim = [IO.Path]::ChangeExtension($exe, '.shim');
            if (Test-Path -LiteralPath $shim) { $exe = (Get-Content -LiteralPath $shim -TotalCount 1).Trim(); }
            $exeFolder = Split-Path $exe;
            $aria2Root = (Split-Path $exeFolder -Leaf) -eq 'App' ? (Split-Path $exeFolder) : $exeFolder;
        }
    }
    if (!$exe -or !(Test-Path -LiteralPath $exe)) {
        throw "aria2 not found. Put aria2c on PATH, or set ARIA2_HOME to the folder that holds App\aria2c.exe.";
    }

    $conf = Join-Path $aria2Root 'aria2.conf';
    if (!(Test-Path -LiteralPath $conf)) {
        $newSecret = -join ((48..57) + (97..122) | Get-Random -Count 32 | ForEach-Object { [char]$_ });
        Set-Content -LiteralPath $conf -Value @"
dir=$HOME\Downloads\Aria2
enable-rpc=true
rpc-listen-all=false
rpc-listen-port=6800
rpc-allow-origin-all=true
rpc-secret=$newSecret
continue=true
max-concurrent-downloads=5
split=8
max-connection-per-server=8
min-split-size=20M
file-allocation=none
auto-file-renaming=false
allow-overwrite=false
max-tries=5
retry-wait=10
connect-timeout=30
timeout=60
disk-cache=64M
console-log-level=warn
log-level=warn
log=aria2.log
save-session=aria2.session
input-file=aria2.session
save-session-interval=30
"@;
    }
    $session = Join-Path $aria2Root 'aria2.session';
    if (!(Test-Path -LiteralPath $session)) { New-Item -ItemType File -Path $session | Out-Null; }

    $port = (Select-String -LiteralPath $conf -Pattern '^rpc-listen-port=(\d+)$').Matches.Groups[1].Value;
    $script:Aria2 = @{
        Home    = $aria2Root
        Exe     = $exe
        Conf    = $conf
        Options = Join-Path $aria2Root 'aria2.options.json'
        Page    = Join-Path $aria2Root 'UI\index.html'
        Secret  = (Select-String -LiteralPath $conf -Pattern '^rpc-secret=(.+)$').Matches[0].Groups[1].Value
        Port    = $port ? [int]$port : 6800
    };
    return $script:Aria2;
}

function Invoke-Aria2 {
    param ([string]$Method, [array]$Params = @())

    $config = Initialize-Aria2;
    $body = @{ jsonrpc = '2.0'; id = 'downloader'; method = $Method; params = @("token:$($config.Secret)") + $Params } | ConvertTo-Json -Depth 10 -Compress;
    $response = Invoke-RestMethod -Uri "http://127.0.0.1:$($config.Port)/jsonrpc" -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 10;
    return $response.result;
}

function Get-Aria2Options {
    param ([hashtable]$Item)

    $options = @{
        dir      = $Item.Directory
        out      = $Item.FileName
        header   = @($Item.Headers.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" })
        continue = 'true'
    };
    if ($Item.Connections) {
        $options.split = "$($Item.Connections)";
        $options.'max-connection-per-server' = "$($Item.Connections)";
    }
    return $options;
}

function Save-Aria2Settings {
    $config = Initialize-Aria2;
    $current = Invoke-Aria2 'aria2.getGlobalOption';
    if (Test-Path -LiteralPath $config.Options) {
        $started = Get-Content -LiteralPath $config.Options -Raw | ConvertFrom-Json;
        $lines = [Collections.Generic.List[string]](Get-Content -LiteralPath $config.Conf);
        $changed = @();
        foreach ($option in $current.PSObject.Properties) {
            if ($option.Name -in 'rpc-secret', 'conf-path' -or $started.($option.Name) -eq $option.Value) { continue; }
            $index = $lines.FindIndex([Predicate[string]] { param($l) $l -match "^$([regex]::Escape($option.Name))=" });
            $line = "$($option.Name)=$($option.Value)";
            if ($index -ge 0) { $lines[$index] = $line; } else { $lines.Add($line); }
            $changed += $option.Name;
        }
        if ($changed) {
            Set-Content -LiteralPath $config.Conf -Value $lines;
            Write-Host "[INFO] Saved to aria2.conf: $($changed -join ', ')" -ForegroundColor DarkGray;
        }
    }
    $current | ConvertTo-Json | Set-Content -LiteralPath $config.Options;
}

function Open-AriaNg {
    param ([switch]$NoBrowser)

    $config = Initialize-Aria2;
    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($config.Secret)).TrimEnd('=').Replace('+', '-').Replace('/', '_');
    $url = "file:///$($config.Page.Replace('\', '/'))#!/settings/rpc/set/http/127.0.0.1/$($config.Port)/jsonrpc/$encoded";
    Set-Content -LiteralPath (Join-Path $config.Home 'AriaNg.html') -Value "<!doctype html><meta charset=`"utf-8`"><title>AriaNg</title><script>location.replace('$url');</script>";
    if (!$NoBrowser) { Start-Process $url; }
    return $url;
}

function Start-DownloadManager {
    $config = Initialize-Aria2;
    $running = $true;
    try { Invoke-Aria2 'aria2.getVersion' | Out-Null; } catch { $running = $false; }
    if (!$running) {
        Remove-Item -LiteralPath $config.Options -ErrorAction SilentlyContinue;
        Start-Process -FilePath $config.Exe -ArgumentList "--conf-path=`"$($config.Conf)`"" -WorkingDirectory $config.Home -WindowStyle Hidden;
        for ($i = 0; $i -lt 40 -and !$running; $i++) {
            Start-Sleep -Milliseconds 250;
            try { Invoke-Aria2 'aria2.getVersion' | Out-Null; $running = $true; } catch {}
        }
        if (!$running) { throw "aria2 did not start (see $($config.Home)\aria2.log)."; }
    }
    Save-Aria2Settings;
    Open-AriaNg -NoBrowser | Out-Null;
    return @{ Directory = (Invoke-Aria2 'aria2.getGlobalOption').dir };
}

function Add-Download {
    param ([Parameter(Mandatory)][hashtable]$Item)

    return Invoke-Aria2 'aria2.addUri' @(@($Item.Url), (Get-Aria2Options $Item));
}

function Update-Download {
    param ([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][hashtable]$Item)

    try { Invoke-Aria2 'aria2.removeDownloadResult' @($Id) | Out-Null; } catch {}
    return Invoke-Aria2 'aria2.addUri' @(@($Item.Url), (Get-Aria2Options $Item));
}

function Remove-Download {
    param ([Parameter(Mandatory)][string[]]$Ids)

    foreach ($id in $Ids) {
        try { Invoke-Aria2 'aria2.forceRemove' @($id) | Out-Null; } catch {}
        try { Invoke-Aria2 'aria2.removeDownloadResult' @($id) | Out-Null; } catch {}
    }
}

function Get-DownloadStatus {
    param ([Parameter(Mandatory)][string[]]$Ids)

    $states = @{ active = 'Active'; waiting = 'Waiting'; paused = 'Paused'; complete = 'Complete'; error = 'Error'; removed = 'Removed' };
    $result = @{};
    foreach ($id in $Ids) {
        try {
            $s = Invoke-Aria2 'aria2.tellStatus' @($id, @('status', 'totalLength', 'completedLength', 'downloadSpeed', 'errorCode', 'errorMessage'));
            $result[$id] = @{
                State = $states[$s.status]
                Total = [long]$s.totalLength
                Done  = [long]$s.completedLength
                Speed = [long]$s.downloadSpeed
                Error = $s.errorCode -and $s.errorCode -ne '0' ? "aria2 error $($s.errorCode): $($s.errorMessage)" : $null
            };
        }
        catch {
            $result[$id] = @{ State = 'Removed'; Total = 0; Done = 0; Speed = 0; Error = 'The download is no longer in aria2.' };
        }
    }
    return $result;
}

Export-ModuleMember -Function Start-DownloadManager, Add-Download, Get-DownloadStatus, Update-Download, Remove-Download, Open-AriaNg, Save-Aria2Settings;

<#
.SYNOPSIS
    Convert .torrent files to magnet .url shortcuts.
.DESCRIPTION
    Creates a .url internet shortcut with the torrent's magnet link next to each .torrent file, with the same name.
    Problems are reported in a message box, since it runs with a hidden window from the context menu.
.PARAMETER Files
    Paths of the .torrent files.
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Files
)

function Read-Bencode([byte[]]$Bytes, [ref]$Index) {
    $token = [char]$Bytes[$Index.Value];
    if ($token -ceq 'i') {
        $end = [Array]::IndexOf($Bytes, [byte][char]'e', $Index.Value);
        $value = [long][Text.Encoding]::ASCII.GetString($Bytes, $Index.Value + 1, $end - $Index.Value - 1);
        $Index.Value = $end + 1;
        return $value;
    }

    if ($token -ceq 'l') {
        $Index.Value++;
        $list = [System.Collections.Generic.List[object]]::new();
        while ([char]$Bytes[$Index.Value] -cne 'e') {
            $list.Add((Read-Bencode $Bytes $Index));
        }
        $Index.Value++;
        return , $list;
    }

    if ($token -ceq 'd') {
        $Index.Value++;
        $dictionary = @{};
        while ([char]$Bytes[$Index.Value] -cne 'e') {
            $key = Read-Bencode $Bytes $Index;
            $start = $Index.Value;
            $dictionary[$key] = Read-Bencode $Bytes $Index;
            if ($key -eq 'info') {
                $hash = [Security.Cryptography.SHA1]::Create().ComputeHash($Bytes, $start, $Index.Value - $start);
                $dictionary['infoHash'] = [Convert]::ToHexString($hash).ToLower();
            }
        }
        $Index.Value++;
        return $dictionary;
    }

    $colon = [Array]::IndexOf($Bytes, [byte][char]':', $Index.Value);
    $length = [int][Text.Encoding]::ASCII.GetString($Bytes, $Index.Value, $colon - $Index.Value);
    $Index.Value = $colon + 1 + $length;
    return [Text.Encoding]::UTF8.GetString($Bytes, $colon + 1, $length);
}

function Get-MagnetLink([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path);
    $torrent = Read-Bencode $bytes ([ref]0);
    $magnet = "magnet:?xt=urn:btih:$($torrent.infoHash)";
    if ($torrent.info.name) {
        $magnet += "&dn=$([Uri]::EscapeDataString($torrent.info.name))";
    }

    $trackers = @($torrent.announce) + @($torrent.'announce-list' | ForEach-Object { $_ }) | Where-Object { $_ } | Select-Object -Unique;
    foreach ($tracker in $trackers) {
        $magnet += "&tr=$([Uri]::EscapeDataString($tracker))";
    }

    return $magnet;
}

if (!$Files) {
    $Files = & File-Picker.ps1 -Title 'Select Torrent' -Filter 'Torrents|*.torrent' -Multiple -ExitIfNotSelected;
}

$errors = @();
foreach ($file in $Files) {
    try {
        $magnet = Get-MagnetLink $file;
        $urlPath = [IO.Path]::ChangeExtension($file, '.url');
        Set-Content -LiteralPath $urlPath -Value "[InternetShortcut]`nURL=$magnet";
    }
    catch {
        $errors += "Failed to convert:`n$file`n$($_.Exception.Message)";
    }
}

if ($errors) {
    Add-Type -AssemblyName System.Windows.Forms;
    [System.Windows.Forms.MessageBox]::Show(
        ($errors -join "`n`n"),
        'Convert Torrent To Magnet',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null;
}

#region Functions

function AddFlagIfNotExits {
    param (
        $flag
    )
    
    if (!$file.Attributes.HasFlag([System.IO.FileAttributes]$flag)) {
        $file.Attributes += $flag;
    }
}

function RemoveFlagIfExits {
    param (
        $flag
    )
    
    if ($file.Attributes.HasFlag([System.IO.FileAttributes]$flag)) {
        $file.Attributes -= $flag;
    }
}

function ToggleFlag {
    param (
        $flag
    )
    
    if ($file.Attributes.HasFlag([System.IO.FileAttributes]$flag)) {
        $file.Attributes -= $flag;
    }
    else {
        $file.Attributes += $flag;
    }
}

#endregion

$path = $args[0];
Write-Output "Handling File: $path, Operation $operationType";
$file = Get-Item -LiteralPath $path -Force;
$flags = @(
    # 'None',
    'ReadOnly',
    'Hidden',
    'System'
    # 'Directory',
    # 'Archive',
    # 'Device',
    # 'Normal',
    # 'Temporary',
    # 'SparseFile',
    # 'ReparsePoint',
    # 'Compressed',
    # 'Offline',
    # 'NotContentIndexed',
    # 'Encrypted',
    # 'IntegrityStream',
    # 'NoScrubData'
);

$selected = @($flags | Where-Object { return $file.Attributes.HasFlag([System.IO.FileAttributes]$_); });
$newAttributes = & Multi-Options-Selector.ps1 -Options $flags -SelectedOptions $selected ;
$newAttributes | ForEach-Object { AddFlagIfNotExits $_; };

$flags | ForEach-Object {
    if ($newAttributes.Contains($_)) {
        return;
    }

    RemoveFlagIfExits -flag $_;
}

timeout.exe 15;

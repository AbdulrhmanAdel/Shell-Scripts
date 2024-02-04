$path = $args[0];
$operationType = $args[1];

Write-Output "Handling File: $path, Operation $operationType";
$file = Get-Item -LiteralPath $path -Force;


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


switch ($operationType) {
    'System' { 
        ToggleFlag -flag 'System'; 
        AddFlagIfNotExits -flag 'Hidden'; 
        break;
    }
    'Hidden' {
        ToggleFlag -flag 'Hidden';
        break;
    }
}

Write-Output "Done, Closing in 1s.";
Start-Sleep -Seconds 1;

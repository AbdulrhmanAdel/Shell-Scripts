[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments)]
    [string[]]
    $Files
)

function AddRegIfNotExist {
    param (
        [string]$RegPath,
        [string]$RegValue
    )

    if (-not (Test-Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
    }
    New-ItemProperty -Path $RegPath -Name $RegValue -Value "" -PropertyType String -Force | Out-Null
}

function CreateMenu {
    param (
        [string]$base,
        [string]$title,
        [string]$icon
    )
    
    reg add $base  /v "MUIVerb" /d $title /t REG_SZ /f | Out-Null;
    reg add $base  /v "SubCommands" /t REG_SZ /f | Out-Null;
    reg add "$base\shell" /v "Icon" /t REG_SZ /f | Out-Null;
}

function BuildPrefix {
    param (
        $Base
    )
    $Path = Input.ps1 -Title "Please Write Path Saperated By '/'";
    $Paths = $Path -split "/";
    $Base = "$Base/shell";
    AddRegIfNotExist -RegPath "" -RegValue "";
}

$Targets = @(
    @{
        Key   = "Directories"
        Value = @{
            Builder = { 
                return BuildPrefix -Base "HKEY_CURRENT_USER\Software\Classes\Directory\shell";
            }
        }
    }
    @{
        Key   = "Extensions"
        Value = @{
            Builder = {
                $Extensions = Input.ps1 -Title "Please Type extension sepreated by ',' or ' ' without '.'"
                ($Extensions -split ",| ") | ForEach-Object {
                    return BuildPrefix -Base ".$_"
                }
            }
        }
    }
)


$Files | ForEach-Object {
    $File = $_
    $FileTargets = Multi-Options-Selector.ps1 `
        -Options $Targets `
        -Title "Please Select The Target(s)"

    $FinalTargets | ForEach-Object {
        $Prefix = $_.Builder.Invoke();   
    }
}
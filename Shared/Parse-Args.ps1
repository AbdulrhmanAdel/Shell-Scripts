# Accept -arg=value or --arg(True)

$arguments = $args[0];
function SetVariable {
    param (
        $argument
    )

    if ($null -eq $argument -or $argument.GetType().Name -eq "Object[]") {
        return;
    }
    if (!($argument -match "(-(?<Key>.*)=(?<Value>.*)|--(?<Key>.*))")) {
        return;
    }

    $key = $Matches["Key"];
    $value = $Matches["Value"]
    $finalValue = $null;
    if (!$value) {
        $finalValue = $true
    }
    elseif ([int]::TryParse($value, [ref]$finalValue)) {
    }
    elseif ([double]::TryParse($value, [ref]$finalValue)) {
    }
    elseif ([bool]::TryParse($value, [ref]$finalValue)) {
    }
    else {
        $finalValue = $value;
    }

    Set-Variable -Name $key -Value $finalValue -Scope Global -PassThru | Out-Null;
}


$arguments | ForEach-Object {
    SetVariable -argument $_;
}
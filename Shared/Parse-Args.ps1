# Accept -arg=value or --arg(True)
# if (!($argument -match "(-(?<Key>.*)=(?<Value>.*)|--(?<Key>.*))"))
$arguments = $args[0];

function ParseValue {
    param (
        $value
    )
    if ($value.GetType().Name -eq "Object[]") {
        return $value;
    }
    
    $finalValue = $null;
    if ([int]::TryParse($value, [ref]$finalValue)) {
    }
    elseif ([double]::TryParse($value, [ref]$finalValue)) {
    }
    elseif ([bool]::TryParse($value, [ref]$finalValue)) {
    }
    else {
        $finalValue = $value -replace "^""+|""+$", ""
    }

    return $finalValue;
}

for ($i = 0; $i -lt $arguments.Count; $i++) {
    $argument = $arguments[$i];
    if ($null -eq $argument -or $argument.GetType().Name -eq "Object[]") {
        continue;
    }
    if ($argument.ToString().StartsWith("--")) {
        $argument = $argument.ToString().Substring(2);
        Set-Variable -Name $argument -Value $true -Scope Global -PassThru | Out-Null;
        continue;
    }
    elseif ($argument.ToString().StartsWith("-")) {
        $argument = $argument.ToString().Substring(1);
        $value = $arguments[++$i];
        Set-Variable -Name $argument -Value (ParseValue -value $value) -Scope Global -PassThru | Out-Null;
    }
}
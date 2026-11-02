# Docs: https://learn.microsoft.com/en-us/windows-hardware/customize/power-settings/configure-power-button-overrides
# Changes what Windows does when the power button / sleep button is pressed or the lid is closed.
# Equivalent of: Control Panel > Power Options > Choose what the power buttons do.
[CmdletBinding()]
param (
    [ValidateSet("PowerButton", "SleepButton", "LidClose")]
    [string]$Button,
    [ValidateSet("Do nothing", "Sleep", "Hibernate", "Shut down", "Turn off the display")]
    [string]$Action,
    [ValidateSet("PluggedIn", "OnBattery", "Both")]
    [string]$PowerSource,
    # Control Panel applies these to every power plan, so that is the default here too.
    [switch]$ActivePlanOnly
)

# Elevation restarts the script, so the already answered parameters have to travel with it.
$forwardedArguments = $PSBoundParameters.GetEnumerator() | ForEach-Object {
    $_.Value -is [switch] ? "-$($_.Key)" : @("-$($_.Key)", """$($_.Value)""")
};
Run-AsAdmin.ps1 -Arguments $forwardedArguments;

$SubGroup = "4f971e89-eebd-4455-a8de-9e59040e7347"; # Power buttons and lid
$PowerSettingsKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings";

$Buttons = @(
    @{ Key = "When I press the power button"; Name = "PowerButton"; Guid = "7648efa3-dd9c-4e3e-b566-50f929386280" }
    @{ Key = "When I press the sleep button"; Name = "SleepButton"; Guid = "96996bc0-ad50-47ec-923b-6f41874dd9eb" }
    @{ Key = "When I close the lid"; Name = "LidClose"; Guid = "5ca83367-6e45-459f-a27b-476b1d01c936" }
);

#region Helpers
# Reads the actions Windows itself supports for a setting (index + friendly name) from the registry.
function Get-SettingActions($SettingGuid) {
    $settingKey = "$PowerSettingsKey\$SubGroup\$SettingGuid";
    if (!(Test-Path $settingKey)) {
        return @();
    }
    return Get-ChildItem $settingKey |
        Where-Object { $_.PSChildName -match "^\d+$" } |
        Sort-Object { [int]$_.PSChildName } |
        ForEach-Object {
            $friendlyName = (Get-ItemProperty -Path $_.PSPath).FriendlyName;
            if (!$friendlyName) {
                return;
            }
            # FriendlyName is an indirect string: "@powrprof.dll,-51,Do nothing"
            @{ Key = ($friendlyName -split ",")[-1].Trim(); Index = [int]$_.PSChildName }
        };
}

# Current AC/DC indexes of a setting inside a plan, $null when it was never configured.
# powercfg /query stays silent for settings Windows marks as hidden, so the registry is the fallback.
function Get-CurrentIndexes($SchemeGuid, $SettingGuid) {
    $query = (powercfg /query $SchemeGuid $SubGroup $SettingGuid) -join "`n";
    $indexes = @{
        AC = [regex]::Match($query, "Current AC Power Setting Index:\s*(0x[0-9a-fA-F]+)")
        DC = [regex]::Match($query, "Current DC Power Setting Index:\s*(0x[0-9a-fA-F]+)")
    };
    $result = @{};
    foreach ($source in $indexes.Keys) {
        $result[$source] = $indexes[$source].Success ? [Convert]::ToInt32($indexes[$source].Groups[1].Value, 16) : $null;
    }
    if ($null -ne $result.AC -and $null -ne $result.DC) {
        return $result;
    }

    $fallbackKeys = @(
        "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$SchemeGuid\$SubGroup\$SettingGuid" # Plan override
        "$PowerSettingsKey\$SubGroup\$SettingGuid\DefaultPowerSchemeValues\$SchemeGuid" # Windows default
    );
    foreach ($key in $fallbackKeys) {
        $values = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue;
        if (!$values) {
            continue;
        }
        $result.AC ??= $values.ACSettingIndex;
        $result.DC ??= $values.DCSettingIndex;
    }
    return $result;
}

function Get-ActionName($Actions, $Index) {
    if ($null -eq $Index) {
        return "Not available";
    }
    $match = $Actions | Where-Object { $_.Index -eq $Index } | Select-Object -First 1;
    return $match ? $match.Key : "Unknown ($Index)";
}

# Windows ships these settings hidden on some machines, which drops their whole row from
# Control Panel and makes powercfg /query silent about them, so a change looks like it did nothing.
function Show-InControlPanel($SettingGuid) {
    powercfg -attributes $SubGroup $SettingGuid -ATTRIB_HIDE;
}

function Get-PowerPlans {
    return powercfg /list |
        Select-String -Pattern "GUID: ([0-9a-fA-F-]{36})\s+\((.+)\)" |
        ForEach-Object {
            @{ Guid = $_.Matches[0].Groups[1].Value; Name = $_.Matches[0].Groups[2].Value.Trim() }
        };
}
#endregion

$hasBattery = $null -ne (Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue);
$Buttons | ForEach-Object { Show-InControlPanel $_.Guid };
$activeScheme = (powercfg /getactivescheme) -join " ";
$activePlan = Get-PowerPlans | Where-Object { $activeScheme -match $_.Guid } | Select-Object -First 1;
$targetPlans = $ActivePlanOnly ? @($activePlan) : (Get-PowerPlans);

#region Select the button
$selectedButton = $Buttons | Where-Object { $_.Name -eq $Button } | Select-Object -First 1;
if (!$selectedButton) {
    $buttonOptions = $Buttons | ForEach-Object {
        $indexes = Get-CurrentIndexes $activePlan.Guid $_.Guid;
        $actions = Get-SettingActions $_.Guid;
        $current = $hasBattery `
            ? "Battery: $(Get-ActionName $actions $indexes.DC) | Plugged in: $(Get-ActionName $actions $indexes.AC)" `
            : (Get-ActionName $actions $indexes.AC);
        $option = $_.Clone();
        $option.Key = "$($_.Key)`n$current";
        return $option;
    };
    $selectedButton = & Single-Options-Selector.ps1 -Options $buttonOptions -Title "Select The Button To Configure" -Required;
}
if (!$selectedButton) {
    Write-Host "No Button Selected." -ForegroundColor Red;
    Prompt-Exit.ps1;
}

$actions = Get-SettingActions $selectedButton.Guid;
if ($actions.Count -eq 0) {
    Write-Host "This System Does Not Expose '$($selectedButton.Key)'." -ForegroundColor Red;
    Prompt-Exit.ps1;
}
#endregion

#region Select the power source
if ($hasBattery) {
    if (!$PowerSource) {
        $PowerSource = & Single-Options-Selector.ps1 `
            -Options @(
                @{ Key = "Both"; Value = "Both" }
                @{ Key = "Plugged in"; Value = "PluggedIn" }
                @{ Key = "On battery"; Value = "OnBattery" }
            ) `
            -Title "Select When It Applies" `
            -DefaultValue "Both";
    }
}
else {
    if ($PowerSource -eq "OnBattery") {
        Write-Host "No Battery Detected, Nothing To Change." -ForegroundColor Red;
        Prompt-Exit.ps1;
    }
    $PowerSource = "PluggedIn";
}
#endregion

#region Select the action
$selectedAction = $actions | Where-Object { $_.Key -eq $Action } | Select-Object -First 1;
if ($Action -and !$selectedAction) {
    Write-Host "'$Action' Is Not Supported By '$($selectedButton.Key)', Pick Another One." -ForegroundColor Yellow;
}
if (!$selectedAction) {
    $selectedAction = & Single-Options-Selector.ps1 -Options $actions -Title "Select The Action For '$($selectedButton.Key)'" -Required;
}
if ($null -eq $selectedAction -or $null -eq $selectedAction.Index) {
    Write-Host "No Action Selected." -ForegroundColor Red;
    Prompt-Exit.ps1;
}

$hibernateEnabled = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -ErrorAction SilentlyContinue).HibernateEnabled;
if ($selectedAction.Key -eq "Hibernate" -and $hibernateEnabled -ne 1) {
    Write-Host "Hibernate Is Disabled On This System, Enable It With: powercfg /hibernate on" -ForegroundColor Yellow;
}
#endregion

#region Apply
foreach ($plan in $targetPlans) {
    if ($PowerSource -ne "OnBattery") {
        powercfg /setacvalueindex $plan.Guid $SubGroup $selectedButton.Guid $selectedAction.Index;
    }
    if ($PowerSource -ne "PluggedIn") {
        powercfg /setdcvalueindex $plan.Guid $SubGroup $selectedButton.Guid $selectedAction.Index;
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed To Update '$($plan.Name)'." -ForegroundColor Red;
        continue;
    }
    Write-Host "$($selectedButton.Key) => $($selectedAction.Key) [$PowerSource] on '$($plan.Name)'" -ForegroundColor Green;
}

# Re-activating the plan is what makes the new values take effect immediately.
powercfg /setactive $activePlan.Guid;
#endregion

$indexes = Get-CurrentIndexes $activePlan.Guid $selectedButton.Guid;
$summary = "Plugged in: $(Get-ActionName $actions $indexes.AC)";
if ($hasBattery) {
    $summary = "Battery: $(Get-ActionName $actions $indexes.DC) | $summary";
}
Write-Host "$($selectedButton.Key) On '$($activePlan.Name)' => $summary" -ForegroundColor Cyan;

Prompt-Exit.ps1;

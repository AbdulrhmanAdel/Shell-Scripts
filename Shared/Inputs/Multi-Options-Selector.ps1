<#
.SYNOPSIS
    Shows a checkbox picker and returns the selected options.
.DESCRIPTION
    Options are laid out in a scrollable multi column grid (filled top to bottom, column by column)
    with a sticky header holding the select all box and a sticky footer holding the actions.
.PARAMETER Options
    Items to show, either plain values or objects/hashtables with a Key (label) and Value (returned).
.PARAMETER SelectedOptions
    Items of -Options that start out checked.
.PARAMETER Columns
    Force the column count, otherwise it is derived from the item count and the screen size.
#>
[CmdletBinding()]
param (
    $Options,
    [string]$Title,
    [switch]$Multi,
    [switch]
    [Alias("MustSelectOne")]
    $Required,
    $SelectedOptions,
    [int]$Columns = 0
)

. "$PSScriptRoot\Form-Style.ps1";

$Options = @($Options);
$SelectedOptions ??= @();

#region Form

$layout = New-InputForm -Title ($Title ?? "Select Items");
$form = $layout.Form;

$selectAllCheckBox = New-Object System.Windows.Forms.CheckBox;
$selectAllCheckBox.AutoSize = $true;
$selectAllCheckBox.Text = 'Select All';
# ThreeState stays off, the partial state is only ever set from code, never by clicking through it.
$selectAllCheckBox.ThreeState = $false;
$selectAllCheckBox.Font = New-Object System.Drawing.Font($form.Font, [System.Drawing.FontStyle]::Bold);
$selectAllCheckBox.Margin = New-Object System.Windows.Forms.Padding(3, 3, 3, 8);
$layout.Header.Controls.Add($selectAllCheckBox, 0, 0);

$countLabel = New-Object System.Windows.Forms.Label;
$countLabel.AutoSize = $true;
$countLabel.ForeColor = [System.Drawing.SystemColors]::GrayText;
$countLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom;
$countLabel.Margin = New-Object System.Windows.Forms.Padding(3, 3, 3, 8);
$layout.Header.Controls.Add($countLabel, 1, 0);

$optionsGrid = New-Object System.Windows.Forms.TableLayoutPanel;
$optionsGrid.Dock = [System.Windows.Forms.DockStyle]::Top;
$optionsGrid.AutoSize = $true;
$optionsGrid.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink;
$layout.Body.Controls.Add($optionsGrid);

#endregion

#region Options

$checkboxes = @($Options | ForEach-Object {
        $item = $_;
        $checkbox = New-Object System.Windows.Forms.CheckBox
        $checkbox.AutoSize = $true;
        # Fonts are only inherited once parented, set it now so PreferredSize can be measured below.
        $checkbox.Font = $form.Font;
        # Labels are data, '&' in them should not turn into a keyboard accelerator.
        $checkbox.UseMnemonic = $false;
        $checkbox.Margin = New-Object System.Windows.Forms.Padding(3, 3, 16, 3);
        if ($item.Key) {
            $checkbox.Text = $item.Key;
            $checkbox.Tag = $item.Value ?? $item;
        }
        else {
            $checkbox.Tag = $checkbox.Text = $item;
        }

        if ($SelectedOptions -contains $item) {
            $checkbox.Checked = $true
        }

        return $checkbox;
    });

$optionWidth = [Math]::Max(160, ($checkboxes | ForEach-Object { $_.PreferredSize.Width + $_.Margin.Horizontal } | Measure-Object -Maximum).Maximum);
$optionHeight = [Math]::Max(22, ($checkboxes | ForEach-Object { $_.PreferredSize.Height + $_.Margin.Vertical } | Measure-Object -Maximum).Maximum);
$bounds = Get-InputFormBounds;
$columnCount = Get-InputGridColumnCount `
    -ItemCount $checkboxes.Count `
    -ItemWidth $optionWidth `
    -ItemHeight $optionHeight `
    -Bounds $bounds `
    -Requested $Columns;
$rowCount = [int][Math]::Ceiling($checkboxes.Count / $columnCount);

$optionsGrid.ColumnCount = $columnCount;
$optionsGrid.RowCount = $rowCount;
1..$columnCount | ForEach-Object {
    $optionsGrid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, (100 / $columnCount)))) | Out-Null;
}

$optionsGrid.SuspendLayout();
for ($index = 0; $index -lt $checkboxes.Count; $index++) {
    # Column major, so the original order is read down each column instead of across the rows.
    $optionsGrid.Controls.Add($checkboxes[$index], [int][Math]::Floor($index / $rowCount), [int]($index % $rowCount));
}

$optionsGrid.ResumeLayout();

#endregion

#region Actions

Add-InputFormButton -Layout $layout -Text 'Submit' -DialogResult OK -Accept | Out-Null;
Add-InputFormButton -Layout $layout -Text 'Cancel' -DialogResult Cancel -Cancel | Out-Null;

$script:suspendSync = $false;
$script:headerState = [System.Windows.Forms.CheckState]::Unchecked;
function Sync-Header {
    $checkedCount = @($checkboxes | Where-Object { $_.Checked }).Count;
    $countLabel.Text = "$checkedCount of $($checkboxes.Count) selected";
    $script:headerState = $checkedCount -eq 0 `
        ? [System.Windows.Forms.CheckState]::Unchecked `
        : ($checkedCount -eq $checkboxes.Count ? [System.Windows.Forms.CheckState]::Checked : [System.Windows.Forms.CheckState]::Indeterminate);
    $selectAllCheckBox.CheckState = $script:headerState;
}

$selectAllCheckBox.Add_Click({
        # The click already toggled the box, so decide from the state it had before: a click on the
        # partially checked header means "check everything", where WinForms would clear it instead.
        $checked = $script:headerState -eq [System.Windows.Forms.CheckState]::Indeterminate `
            ? $true `
            : $selectAllCheckBox.Checked;
        $script:suspendSync = $true;
        $checkboxes | ForEach-Object { $_.Checked = $checked; };
        $script:suspendSync = $false;
        Sync-Header;
    });

$checkboxes | ForEach-Object {
    $_.Add_CheckedChanged({
            if ($script:suspendSync) {
                return;
            }

            Sync-Header;
        });
}

Sync-Header;

#endregion

Set-InputFormSize -Layout $layout -Content $optionsGrid -Bounds $bounds;
$result = $form.ShowDialog();
if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $selectedItems = $checkboxes | Where-Object { $_.Checked } | Select-Object -ExpandProperty Tag
    return $selectedItems
}

return @();

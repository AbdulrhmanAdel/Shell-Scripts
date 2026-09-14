<#
.SYNOPSIS
    Shows one button per option and returns the one that was clicked.
.DESCRIPTION
    Buttons are laid out in a multi column grid (filled top to bottom, column by column) with a
    sticky footer, matching the other dialogs in this folder.
.PARAMETER Options
    Items to show, either plain values or objects/hashtables with a Key (label) and Value (returned).
.PARAMETER DefaultValue
    Returned when nothing is picked, and its button is the one focused and triggered by Enter.
.PARAMETER Columns
    Force the column count, otherwise it is derived from the item count and the screen size.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [System.Object[]]
    $Options,
    [switch]
    [Alias("MustSelectOne")]
    $Required = $false,
    [string]$Title = "Select an Option",
    [string]$Message,
    [System.Object]$DefaultValue,
    [int]$Columns = 0
)

. "$PSScriptRoot\Form-Style.ps1";

$layout = New-InputForm -Title $Title -Message $Message;
$form = $layout.Form;

$optionsGrid = New-Object System.Windows.Forms.TableLayoutPanel;
$optionsGrid.Dock = [System.Windows.Forms.DockStyle]::Top;
$optionsGrid.AutoSize = $true;
$optionsGrid.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink;
$layout.Body.Controls.Add($optionsGrid);

$buttons = @($Options | ForEach-Object {
        $option = $_;
        $button = New-Object System.Windows.Forms.Button;
        # Fonts are only inherited once parented, set it now so PreferredSize can be measured below.
        $button.Font = $form.Font;
        # Labels are data, '&' in them should not turn into a keyboard accelerator.
        $button.UseMnemonic = $false;
        $button.Text = $option.Key ?? $option;
        $button.Tag = $option.Value ?? $option;
        $button.AutoSize = $true;
        $button.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink;
        $button.Dock = [System.Windows.Forms.DockStyle]::Fill;
        $button.MinimumSize = New-Object System.Drawing.Size(0, 34);
        $button.Margin = New-Object System.Windows.Forms.Padding(3, 3, 3, 3);
        $button.Padding = New-Object System.Windows.Forms.Padding(10, 0, 10, 0);
        $button.Add_Click({
                param ($clicked)
                $form.Tag = $clicked.Tag;
                $form.DialogResult = [System.Windows.Forms.DialogResult]::OK;
            });

        return $button;
    });

$optionWidth = [Math]::Max(160, ($buttons | ForEach-Object { $_.PreferredSize.Width + $_.Margin.Horizontal } | Measure-Object -Maximum).Maximum);
$optionHeight = [Math]::Max(34, ($buttons | ForEach-Object { $_.PreferredSize.Height + $_.Margin.Vertical } | Measure-Object -Maximum).Maximum);
$bounds = Get-InputFormBounds;

function Set-OptionsGridItems {
    param([System.Object[]]$Items)

    $columnCount = Get-InputGridColumnCount `
        -ItemCount $Items.Count `
        -ItemWidth $optionWidth `
        -ItemHeight $optionHeight `
        -Bounds $bounds `
        -Requested $Columns;
    $rowCount = [int][Math]::Max(1, [Math]::Ceiling($Items.Count / $columnCount));

    $optionsGrid.SuspendLayout();
    $optionsGrid.Controls.Clear();
    $optionsGrid.ColumnStyles.Clear();
    $optionsGrid.ColumnCount = $columnCount;
    $optionsGrid.RowCount = $rowCount;
    1..$columnCount | ForEach-Object {
        $optionsGrid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, (100 / $columnCount)))) | Out-Null;
    }

    for ($index = 0; $index -lt $Items.Count; $index++) {
        # Column major, so the original order is read down each column instead of across the rows.
        $optionsGrid.Controls.Add($Items[$index], [int][Math]::Floor($index / $rowCount), [int]($index % $rowCount));
    }

    $optionsGrid.ResumeLayout();
}

Set-OptionsGridItems -Items $buttons;

if ($buttons.Count -gt 1) {
    $layout.Header.RowCount = 2;
    $searchBox = New-Object System.Windows.Forms.TextBox;
    $searchBox.Dock = [System.Windows.Forms.DockStyle]::Top;
    $searchBox.Add_TextChanged({
            $term = $searchBox.Text;
            $filtered = [string]::IsNullOrWhiteSpace($term) `
                ? $buttons `
                : @($buttons | Where-Object { $_.Text.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 });
            Set-OptionsGridItems -Items $filtered;
        }.GetNewClosure());
    $layout.Header.Controls.Add($searchBox, 0, 1);
    $layout.Header.SetColumnSpan($searchBox, 2);
}

Add-InputFormButton -Layout $layout -Text 'Cancel' -DialogResult Cancel -Cancel | Out-Null;

# Enter picks the default, so the common case is one key away.
$defaultButton = $DefaultValue ? ($buttons | Where-Object { $_.Tag -eq $DefaultValue } | Select-Object -First 1) : $null;
if ($defaultButton) {
    $form.AcceptButton = $defaultButton;
    $form.Add_Shown({ $defaultButton.Focus() | Out-Null; }.GetNewClosure());
}

Set-InputFormSize -Layout $layout -Bounds $bounds -Content $optionsGrid;
$result = $form.ShowDialog();
if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $form.Dispose();
    return $form.Tag;
}

if ($DefaultValue) {
    $form.Dispose();
    return $DefaultValue;
}

while ($Required -and $result -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "You Must Select An Option" -ForegroundColor Red;
    $result = $form.ShowDialog();
}

$form.Dispose();
return $form.Tag;

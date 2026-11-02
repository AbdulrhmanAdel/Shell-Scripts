<#
.SYNOPSIS
    Asks for a single text or number value.
.PARAMETER Type
    Text (default) or Number, which swaps the text box for a numeric spinner.
.PARAMETER Required
    Keeps reopening the dialog until it is submitted.
#>
[CmdletBinding()]
param (
    [string]$Title = "Please Enter Value",
    [string]$Message = "Please Enter Value",
    [ArgumentCompletions('Text', 'Number')]
    [string]$Type = "Text",
    [System.Nullable[int]]$DecimalPlaces,
    [switch]$MultiLine,
    [switch]$Required = $false,
    $DefaultValue,
    # Number Specific Args
    [System.Nullable[double]]$Min,
    [System.Nullable[double]]$Max,
    [switch]$NoDecimal
)

. "$PSScriptRoot\Form-Style.ps1";

$layout = New-InputForm -Title $Title -Message $Message;
$form = $layout.Form;

$formInput = $null;
switch ($Type) {
    "Number" {
        $formInput = New-Object System.Windows.Forms.NumericUpDown;
        $formInput.Minimum = $Min ? $Min : [int]::MinValue
        $formInput.Maximum = $Max ? $Max : [int]::MaxValue;
        if ($DecimalPlaces) {
            !$NoDecimal -and ($formInput.DecimalPlaces = $DecimalPlaces) | Out-Null;
        }
        else {
            $formInput.DecimalPlaces = 1;
        }
        $DefaultValue -and ($formInput.Value = [double]$DefaultValue) | Out-Null;
        break;
    }
    Default {
        $formInput = New-Object System.Windows.Forms.TextBox
        $formInput.Multiline = $MultiLine;
        $formInput.Text = $DefaultValue;
        break;
    }
}

$formInput.Font = $form.Font;
$formInput.Width = 460;
$formInput.Margin = New-Object System.Windows.Forms.Padding(3, 3, 3, 3);
$formInput.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right;
if ($MultiLine) {
    $formInput.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical;
    # Enter has to type a newline in a multiline box, so Ctrl+Enter is what submits.
    $formInput.AcceptsReturn = $true;
    $formInput.Height = 180;
    $formInput.Add_KeyDown({
            param ($textBox, $keyEvent)
            if ($keyEvent.Control -and $keyEvent.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                # Swallow the key, otherwise the newline it would have typed ends up in the value.
                $keyEvent.SuppressKeyPress = $true;
                $keyEvent.Handled = $true;
                $form.DialogResult = [System.Windows.Forms.DialogResult]::OK;
            }
        });
}

# An auto sizing host, so the dialog can measure the input whatever type it ended up being.
$inputHost = New-Object System.Windows.Forms.TableLayoutPanel;
$inputHost.Dock = [System.Windows.Forms.DockStyle]::Top;
$inputHost.AutoSize = $true;
$inputHost.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink;
$inputHost.ColumnCount = 1;
$inputHost.RowCount = 1;
$inputHost.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null;
$inputHost.Controls.Add($formInput, 0, 0);
$layout.Body.Controls.Add($inputHost);

$okButton = Add-InputFormButton -Layout $layout -Text 'Ok' -DialogResult OK;
if (!$MultiLine) {
    $form.AcceptButton = $okButton;
}

$form.Add_Shown({ $formInput.Focus() | Out-Null; }.GetNewClosure());

Set-InputFormSize -Layout $layout -Bounds (Get-InputFormBounds) -Content $inputHost -MinWidth 420 -MinHeight 170;
$result = $form.ShowDialog();
while ($Required -and $result -ne [System.Windows.Forms.DialogResult]::OK) {
    $result = $form.ShowDialog();
}

$form.Dispose();
if (!$formInput.Text) {
    return $DefaultValue;
}

return $Type -eq "Number" ? [double]$formInput.Text : $formInput.Text

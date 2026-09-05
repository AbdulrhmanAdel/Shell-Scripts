<#
.SYNOPSIS
    Asks for a number on a slider and returns it.
.PARAMETER DefaultValue
    Where the slider starts, and what is returned when the dialog is closed instead of submitted.
#>
[CmdletBinding()]
param (
    [string]$Title = "Range Selector",
    [string]$Message = 'Select Range',
    [int]$TickFrequency = 10,
    [int]$Minimum = 0,
    [int]$Maximum = 100,
    [int]$DefaultValue = 0
)

. "$PSScriptRoot\Form-Style.ps1";

$layout = New-InputForm -Title $Title -Message $Message;
$form = $layout.Form;

# The live value sits on the right of the header, where the other dialogs show their status.
$valueLabel = New-Object System.Windows.Forms.Label;
$valueLabel.AutoSize = $true;
$valueLabel.Font = New-Object System.Drawing.Font($form.Font, [System.Drawing.FontStyle]::Bold);
$valueLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom;
$valueLabel.Margin = New-Object System.Windows.Forms.Padding(3, 3, 3, 8);
$layout.Header.Controls.Add($valueLabel, 1, 0);

$trackBar = New-Object System.Windows.Forms.TrackBar;
$trackBar.Minimum = $Minimum;
$trackBar.Maximum = $Maximum;
$trackBar.Width = 460;
$trackBar.Anchor = [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right;
$trackBar.Value = if (!$DefaultValue) { $trackBar.Minimum }
elseif ($DefaultValue -le $trackBar.Minimum) { $trackBar.Minimum }
elseif ($DefaultValue -ge $trackBar.Maximum) { $trackBar.Maximum }
else { $DefaultValue };
$trackBar.TickFrequency = $TickFrequency;
$trackBar.SmallChange = $TickFrequency;
$trackBar.LargeChange = $TickFrequency;
$valueLabel.Text = "$($trackBar.Value)";
$trackBar.Add_ValueChanged({ $valueLabel.Text = "$($trackBar.Value)"; });

$minimumLabel = New-Object System.Windows.Forms.Label;
$minimumLabel.AutoSize = $true;
$minimumLabel.ForeColor = [System.Drawing.SystemColors]::GrayText;
$minimumLabel.Text = "$Minimum";
$minimumLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Left;

$maximumLabel = New-Object System.Windows.Forms.Label;
$maximumLabel.AutoSize = $true;
$maximumLabel.ForeColor = [System.Drawing.SystemColors]::GrayText;
$maximumLabel.Text = "$Maximum";
$maximumLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Right;

$sliderHost = New-Object System.Windows.Forms.TableLayoutPanel;
$sliderHost.Dock = [System.Windows.Forms.DockStyle]::Top;
$sliderHost.AutoSize = $true;
$sliderHost.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink;
$sliderHost.ColumnCount = 2;
$sliderHost.RowCount = 2;
$sliderHost.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null;
$sliderHost.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::AutoSize))) | Out-Null;
$sliderHost.Controls.Add($trackBar, 0, 0);
$sliderHost.SetColumnSpan($trackBar, 2);
$sliderHost.Controls.Add($minimumLabel, 0, 1);
$sliderHost.Controls.Add($maximumLabel, 1, 1);
$layout.Body.Controls.Add($sliderHost);

Add-InputFormButton -Layout $layout -Text 'Select' -DialogResult OK -Accept | Out-Null;
Add-InputFormButton -Layout $layout -Text 'Cancel' -DialogResult Cancel -Cancel | Out-Null;

Set-InputFormSize -Layout $layout -Bounds (Get-InputFormBounds) -Content $sliderHost -MinWidth 420 -MinHeight 190;
$result = $form.ShowDialog();
$value = $trackBar.Value;
$form.Dispose();
return $result -eq [System.Windows.Forms.DialogResult]::OK ? $value : $DefaultValue;

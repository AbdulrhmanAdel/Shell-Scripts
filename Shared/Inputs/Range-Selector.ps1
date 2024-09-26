[CmdletBinding()]
param (
    [string]$Title = "Range Selector",
    [string]$Message = 'Select Range',
    [int]$TickFrequency = 10,
    [int]$Minimum = 0,
    [int]$Maximum = 100,
    [int]$DefaultValue = 0
)

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = $Title;
$form.StartPosition = "CenterScreen"
$form.AutoSize = $true;
$form.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowOnly;

$width = 250;
$flowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$flowLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$flowLayoutPanel.AutoScroll = $true
$flowLayoutPanel.Padding = New-Object System.Windows.Forms.Padding(10)  # Add padding
$form.Controls.Add($flowLayoutPanel)

# Create a TrackBar
$trackBar = New-Object System.Windows.Forms.TrackBar
$trackBar.Width = $width
$trackBar.Minimum = $Minimum
$trackBar.Maximum = $Maximum
$value = if (!$defaultValue) { $trackBar.Minimum } 
elseif ($defaultValue -le $trackBar.Minimum) { $trackBar.Minimum }
elseif ($defaultValue -ge $trackBar.Maximum) { $trackBar.Maximum }
else { $defaultValue }
$trackBar.Value = $value;
$trackBar.TickFrequency = $TickFrequency;
$trackBar.SmallChange = $TickFrequency;
$trackBar.LargeChange = $TickFrequency;
$trackBar.Add_ValueChanged(
    {
        $label.Text = "$($Message): $($trackBar.Value)"
    }
);

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "$($Message): $($trackBar.Value)"
$label.Width = $width;
# Create a button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Select Range"
$button.Height = 30;
$button.Width = $width;
$button.Add_Click(
    {
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
    }
)

# Add controls to the form
$flowLayoutPanel.Controls.Add($label)
$flowLayoutPanel.Controls.Add($trackBar)
$flowLayoutPanel.Controls.Add($button)

# Show the form
$result = $form.ShowDialog();
$form.Dispose();
return $result -eq [System.Windows.Forms.DialogResult]::OK ? $trackBar.Value : $DefaultValue;
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

. Parse-Args.ps1 $args;

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = $title ?? "Range Selector"
$form.StartPosition = "CenterScreen"
$form.AutoSize = $true;
$form.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowOnly;

$width = 250;
$flowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$flowLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$flowLayoutPanel.Size = New-Object System.Drawing.Size(300, 150)
$flowLayoutPanel.AutoScroll = $true
$flowLayoutPanel.Padding = New-Object System.Windows.Forms.Padding(10)  # Add padding
$form.Controls.Add($flowLayoutPanel)


# Create a TrackBar

$tickFrequency = $tickFrequency ?? 10
$trackBar = New-Object System.Windows.Forms.TrackBar
$trackBar.Width = $width
$trackBar.Minimum = $minimum ?? 0
$trackBar.Maximum = $maximum ?? 100
$value = if (!$defaultValue) { $trackBar.Minimum } 
elseif ($defaultValue -le $trackBar.Minimum) { $trackBar.Minimum }
elseif ($defaultValue -ge $trackBar.Maximum) { $trackBar.Maximum }
else { $defaultValue }
$trackBar.Value = $value;
$trackBar.TickFrequency = $tickFrequency;
$trackBar.SmallChange = $tickFrequency;
$trackBar.LargeChange = $tickFrequency;
$trackBar.Add_ValueChanged({
        $label.Text = "Selected Range: $($trackBar.Value)"
    })

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Selected Range: $($trackBar.Value)"
$label.Width = $width;
# Create a button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Select Range"
$button.Width = $width;
$button.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
    })

# Add controls to the form
$flowLayoutPanel.Controls.Add($label)
$flowLayoutPanel.Controls.Add($trackBar)
$flowLayoutPanel.Controls.Add($button)

# Show the form
$result = $form.ShowDialog();
$form.Dispose();
return $result -eq [System.Windows.Forms.DialogResult]::OK ? $trackBar.Value : $defaultValue;
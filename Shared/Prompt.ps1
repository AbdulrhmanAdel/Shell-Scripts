$title = $null;
$message = $null;
& Parse-Args.ps1 $args;

# Load necessary assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
# Form Configuration
$form = New-Object System.Windows.Forms.Form
$form.Text = $title;
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$form.MinimizeBox = $false;
$form.MaximizeBox = $false;
$form.AutoSize = $true
$form.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink

# Main FlowLayoutPanel Configuration
$flowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$flowLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$flowLayoutPanel.AutoSize = $true
$flowLayoutPanel.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
$flowLayoutPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
$flowLayoutPanel.Padding = New-Object System.Windows.Forms.Padding(10)
$form.Controls.Add($flowLayoutPanel)

# Label Configuration
$label = New-Object System.Windows.Forms.Label
$label.Text = $message ?? $args[0] ?? 'Are you sure you want to continue?'
$label.AutoSize = $true
$label.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 10)
$flowLayoutPanel.Controls.Add($label)

# Buttons FlowLayoutPanel Configuration
$buttonsFlowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$buttonsFlowLayoutPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight
$buttonsFlowLayoutPanel.AutoSize = $true
$buttonsFlowLayoutPanel.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
$flowLayoutPanel.Controls.Add($buttonsFlowLayoutPanel)

# Create Buttons
$form.AcceptButton = $buttonYes = New-Object System.Windows.Forms.Button
$form.CancelButton = $buttonNo = New-Object System.Windows.Forms.Button
$buttonYes.Text = "Yes"
$buttonNo.Text = "No"
$btnWidth = $form.Width / 2;
$buttonYes.Size = $buttonNo.Size = New-Object System.Drawing.Size($btnWidth, 40)
$buttonYes.DialogResult = $buttonNo.DialogResult = [System.Windows.Forms.DialogResult]::OK
$buttonsFlowLayoutPanel.Controls.Add($buttonYes)
$buttonsFlowLayoutPanel.Controls.Add($buttonNo)
# $padding = $form.Width - $buttonYes.Width - $buttonNo.Width;
# $buttonsFlowLayoutPanel.Padding = New-Object System.Windows.Forms.Padding($padding, 0, 0, 0)

# Show the form
$result = $form.ShowDialog();
$form.Dispose()
return $result -eq [System.Windows.Forms.DialogResult]::OK;

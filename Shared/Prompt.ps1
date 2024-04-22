Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = ($args[0]) ?? 'Select an Option';
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$width = ($form.Text.Length) * $form.Font.Size;
$form.Width = if ($width -gt 350) { $width } else { 350 };
$form.Height = 150;
$form.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink

$flowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$flowLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$flowLayoutPanel.Width = $form.Width
$flowLayoutPanel.AutoScroll = $true
$flowLayoutPanel.Padding = New-Object System.Windows.Forms.Padding(10)  # Add padding
$form.Controls.Add($flowLayoutPanel)

function CreateButton($text) {
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $text
    $width = ($form.Width - 50) / 2;
    $button.Size = New-Object System.Drawing.Size($width, 40)
    $button.DialogResult = [System.Windows.Forms.DialogResult]::$($text);
    $flowLayoutPanel.Controls.Add($button)
}

$form.AcceptButton = CreateButton -text "Yes";
$form.CancelButton = CreateButton -text "No";
return ($form.ShowDialog()) -eq [System.Windows.Forms.DialogResult]::Yes;
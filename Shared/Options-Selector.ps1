Add-Type -AssemblyName System.Windows.Forms

function ParseArgs {
    param ($list, [string]$key)
    $value = $list | Where-Object { $null -ne $_ -and $_.ToString().StartsWith("$key=") };
    if (!$value) { return $null; }
    return $value -replace "$key=", ""
}

$options = $args[0];

$form = New-Object System.Windows.Forms.Form
$form.Text = (ParseArgs -list $args -key "title") ?? 'Select an Option';
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Width = 500;
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

$global:selectedOption = $null

function ButtonClicked {
    param($senderObj, $e)
    $global:selectedOption = $senderObj.Tag;
    $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
}

$flowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$flowLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$flowLayoutPanel.AutoScroll = $true
$flowLayoutPanel.Padding = New-Object System.Windows.Forms.Padding(10)  # Add padding
$form.Controls.Add($flowLayoutPanel)

function CreateButton($text) {
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $text
    $button.Tag = $text
    $button.AutoSize = $true
    $button.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
    $button.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
    $button.ForeColor = [System.Drawing.Color]::FromArgb(0, 0, 0)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $button.Padding = New-Object System.Windows.Forms.Padding(5)  # Add button padding
    $button.Add_Click({ ButtonClicked $args[0] $args[1] })
    $flowLayoutPanel.Controls.Add($button)
}

$options | ForEach-Object {
    CreateButton $_;
}

$result = $form.ShowDialog();
$form.Dispose();
if ($result -eq [System.Windows.Forms.DialogResult]::OK -and $global:selectedOption) {
    return $global:selectedOption;
}
else {
    return $null;
}

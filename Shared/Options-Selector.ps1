Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles();

function ParseArgs {
    param ($list, [string]$key)
    $value = $list | Where-Object { $null -ne $_ -and $_.ToString().StartsWith("$key=") };
    if (!$value) { return $null; }
    return $value -replace "$key=", ""
}

$options = $args[0];
$title = (ParseArgs -list $args -key "title") ?? 'Select an Option';

$form = New-Object System.Windows.Forms.Form
$form.Text = $title;
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Width = 500;
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

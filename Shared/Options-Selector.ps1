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

$global:selectedOption = $null

function ButtonClicked {
    param($senderObj, $e)
    $global:selectedOption = $senderObj.Text
    $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
}

$flowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$flowLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$form.Controls.Add($flowLayoutPanel)

function CreateButton($text) {
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $text
    $button.Add_Click({ ButtonClicked $args[0] $args[1] })
    $flowLayoutPanel.Controls.Add($button)
}

$options | ForEach-Object {
    CreateButton $_;
}

$result = $form.ShowDialog()
if ($result -eq [System.Windows.Forms.DialogResult]::OK -and $global:selectedOption) {
    return $global:selectedOption;
}
else {
    return $null;
}
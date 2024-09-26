[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [System.Object[]]    
    $Options,
    [System.Object]
    $DefaultValue,
    [switch]$MustSelectOne = $false,
    [string]$title = "Select an Option"
)

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles();
$form = New-Object System.Windows.Forms.Form
$form.Text = $title;
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Width = 500;

$flowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$flowLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$flowLayoutPanel.AutoScroll = $true
$flowLayoutPanel.Padding = New-Object System.Windows.Forms.Padding(10)  # Add padding
$form.Controls.Add($flowLayoutPanel)

function CreateButton($option) {
    $button = New-Object System.Windows.Forms.Button
    if ($option.Key) {
        $button.Text = $option.Key
        $button.Tag = $option.Value
    }
    else {
        $button.Text = $option
        $button.Tag = $option
    }
    $button.AutoSize = $true
    $button.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
    $button.Padding = New-Object System.Windows.Forms.Padding(5)  # Add button padding 
    $button.Add_Click(
        {
            param ($button)
            $form.Tag = $button.Tag;
            $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        }
    )
    $flowLayoutPanel.Controls.Add($button)
}

$options | ForEach-Object {
    CreateButton $_;
}

$result = $form.ShowDialog();
if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $form.Dispose();
    return $form.Tag;
}

if ($defaultValue) {
    $form.Dispose();
    return $defaultValue;
}

while ($mustSelectOne -and $result -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "You Must Select An Option" -ForegroundColor Red;
    $result = $form.ShowDialog();
}

$form.Dispose();
return $form.Tag;

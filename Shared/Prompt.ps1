$title = $null;
$message = $null;

$args | Where-Object { $null -ne $_ -and $_.ToString().Split("=").Length -eq 2 } | Foreach-Object {
    $var = $_ -split "=";
    Set-Variable -Name $var[0] -Value $var[1];
};

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$maxWidth = 500;
$width = ($form.Text.Length) * $form.Font.Size;
$form = New-Object System.Windows.Forms.Form
$form.MinimizeBox = $false
$form.MaximizeBox = $false
$form.Text = $title;
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$formWidth = if ($width -gt $maxWidth) { $width } else { $maxWidth };
$form.Size = New-Object System.Drawing.Size($formWidth, 0)
$form.AutoSize = $true;
$form.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowOnly

$flowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$flowLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$flowLayoutPanel.Width = $form.Width
$flowLayoutPanel.AutoSize = $true
$flowLayoutPanel.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowOnly
$buttonsFlowLayoutPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
$flowLayoutPanel.Padding = New-Object System.Windows.Forms.Padding(10)
$form.Controls.Add($flowLayoutPanel);



# Create the Label
$label = New-Object System.Windows.Forms.Label
$label.Text = $message ?? $args[0] ?? 'Are you sure you want continue?'
$label.AutoSize = $true;
$label.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 10);
$label.MaximumSize = New-Object System.Drawing.Size(($form.Width), 0)
$flowLayoutPanel.Controls.Add($label);

$buttonsFlowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$buttonsFlowLayoutPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight
$buttonsFlowLayoutPanel.Width = $form.Width;
$buttonsFlowLayoutPanel.AutoSize = $true
$flowLayoutPanel.Controls.Add($buttonsFlowLayoutPanel);

function CreateButton($text) {
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $text
    $button.Size = New-Object System.Drawing.Size(200, 40)
    $button.DialogResult = [System.Windows.Forms.DialogResult]::$($text);
    $buttonsFlowLayoutPanel.Controls.Add($button)
}

$form.AcceptButton = CreateButton -text "Yes";
$form.CancelButton = CreateButton -text "No";
$result = ($form.ShowDialog()) -eq [System.Windows.Forms.DialogResult]::Yes;
$form.Dispose();
return $result;
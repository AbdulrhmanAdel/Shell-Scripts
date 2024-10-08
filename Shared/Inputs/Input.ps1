[CmdletBinding()]
param (
    [string]$Title = "Please Enter Value",
    [string]$Message = "Please Enter Value",
    [string]$Type = "Text",
    [switch]$Required = $false,
    $DefaultValue
)

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = $Title;
$form.StartPosition = "CenterScreen"
$form.AutoSize = $false; # Changed to false to manually control size
$form.ClientSize = New-Object System.Drawing.Size(300, 120)  # Set fixed size

# Message Label
if ($Message) {
    $messageLabel = New-Object System.Windows.Forms.Label
    $messageLabel.Text = $Message
    $messageLabel.Location = New-Object System.Drawing.Point(10, 10)
    $messageLabel.AutoSize = $true
    $form.Controls.Add($messageLabel)
}

# Text Box
$text = New-Object System.Windows.Forms.TextBox
$text.Location = New-Object System.Drawing.Point(10, 40)  # Adjusted position
$text.Size = New-Object System.Drawing.Size(280, 20)  # Set size
$text.Text = $DefaultValue
if ($Type -eq "Number") {
    $text.Add_KeyPress({
            param($s, $e)
            $e.Handled = ![char]::IsDigit($e.KeyChar) -and ![char]::IsControl($e.KeyChar)
        })
}
$form.Controls.Add($text)

# OK Button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Ok"
$button.Location = New-Object System.Drawing.Point(10, 70)  # Adjusted position
$button.Size = New-Object System.Drawing.Size(280, 30)  # Set size
$button.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
    })
$form.Controls.Add($button)

# Show the form
$result = $form.ShowDialog();
while ($Required -and $result -ne [System.Windows.Forms.DialogResult]::OK) {
    $result = $form.ShowDialog();
}

$form.Dispose();
if (!$text.Text) {
    return $DefaultValue;
}

return $Type -eq "Number" ? [double]$text.Text : $text.Text

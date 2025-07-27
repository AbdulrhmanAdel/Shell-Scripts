[CmdletBinding()]
param (
    [string]$Title = "Please Enter Value",
    [string]$Message = "Please Enter Value",
    [ArgumentCompletions('Text', 'Number')]
    [string]$Type = "Text",
    [System.Nullable[int]]$DecimalPlaces,
    [switch]$MultiLine,
    [switch]$Required = $false,
    $DefaultValue,
    # Number Specific Args
    [System.Nullable[double]]$Min,
    [System.Nullable[double]]$Max,
    [switch]$NoDecimal
)

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
$width = 200 + ($Title.Length -gt 50 ? 50 : $Title.Length) * 5;
$formHeight = 100;
# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = $Title;
$form.StartPosition = "CenterScreen"
$form.AutoSize = $false; # Changed to false to manually control size

# Message Label
if ($Message) {
    $messageLabel = New-Object System.Windows.Forms.Label
    $messageLabel.Text = $Message
    $messageLabel.Location = New-Object System.Drawing.Point(10, 10)
    $messageLabel.AutoSize = $true
    $form.Controls.Add($messageLabel)
}

# Text Box
$formInput = $null;
switch ($Type) {
    "Number" {
        $formInput = New-Object System.Windows.Forms.NumericUpDown;
        $formInput.Minimum = $Min ? $Min : [int]::MinValue
        $formInput.Maximum = $Max ? $Max : [int]::MaxValue;
        if ($DecimalPlaces) {
            !$NoDecimal -and ($formInput.DecimalPlaces = $DecimalPlaces) | Out-Null;
        }
        $DefaultValue -and ($formInput.Value = [double]$DefaultValue) | Out-Null;
        break;
    }
    Default {
        $formInput = New-Object System.Windows.Forms.TextBox
        $formInput.Multiline = $MultiLine;
        $formInput.Text = $DefaultValue;
        break;
    }
}

$formInputHeight = 20;
if ($MultiLine) {
    $formInput.ScrollBars = "Vertical"
    $formInputHeight = 150;
}

$formHeight += $formInputHeight;
$formInput.Location = New-Object System.Drawing.Point(10, 40)  # Adjusted position
$formInput.Size = New-Object System.Drawing.Size(($width - 20), $formInputHeight)  # Set size
$form.Controls.Add($formInput)

# OK Button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Ok"
$button.Location = New-Object System.Drawing.Point(10, (50 + $formInputHeight))  # Adjusted position
$button.Size = New-Object System.Drawing.Size(($width - 20), 30)  # Set size
$button.Add_Click(
    {
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
    }
);
$form.Controls.Add($button)
$form.ClientSize = New-Object System.Drawing.Size($width, $formHeight)  # Set fixed size

# Show the form
$result = $form.ShowDialog();
while ($Required -and $result -ne [System.Windows.Forms.DialogResult]::OK) {
    $result = $form.ShowDialog();
}

$form.Dispose();
if (!$formInput.Text) {
    return $DefaultValue;
}

return $Type -eq "Number" ? [double]$formInput.Text : $formInput.Text

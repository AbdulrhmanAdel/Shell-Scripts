# Load the necessary assembly for creating forms
[CmdletBinding()]
param (
    $options,
    [switch]$Multi,
    [switch]$MustSelectOne,
    $SelectedOptions
)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles();

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = $title ?? "Select Items"
$form.StartPosition = "CenterScreen"

$mainPanel = New-Object System.Windows.Forms.TableLayoutPanel
$mainPanel.ColumnCount = 1
$mainPanel.RowCount = $options.Count + 1
$mainPanel.Dock = [System.Windows.Forms.DockStyle]::Fill;
$mainPanel.AutoScroll = $true;
$mainPanel.Margin = New-Object System.Windows.Forms.Padding(10, 0, 10, 0);
$mainPanel.AutoSize = $true
$mainPanel.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink 
$form.Controls.Add($mainPanel);
$currentRow = 0;
$selectedOptions ??= @();
foreach ($item in $options) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    if ($item.Key) {
        $checkbox.Text = $item.Key;
        $checkbox.Tag = $item.Value;
    }
    else {
        $checkbox.Tag = $checkbox.Text = $item;
    }

    if ($selectedOptions -contains $item) {
        $checkbox.Checked = $true
    }

    $mainPanel.Controls.Add($checkbox, 0, $currentRow);
    $currentRow++;
}

# Add a submit button
$submitButton = New-Object System.Windows.Forms.Button
$submitButton.Text = "Submit"
$submitButton.Width = $mainPanel.Width;
$submitButton.DialogResult = 'OK'
$submitButton.Add_Click(
    {
        $form.Close()
    });
$mainPanel.Controls.Add($submitButton, 0, $currentRow);

$MaxWidth = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width;
$MaxHeight = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height;
$formHeight = $mainPanel.Height;
$formWidth = $mainPanel.Width;
$formWidth = $formWidth -lt $MaxWidth ? $formWidth : $MaxWidth;
$formHeight = $formHeight -lt $MaxHeight ? $formHeight : $MaxHeight;
$form.Size = New-Object System.Drawing.Size($formWidth, $formHeight)

# Show the form
$result = $form.ShowDialog();
if ($result -eq 'OK') {
    $selectedItems = $form.Controls | Where-Object { $_ -is [System.Windows.Forms.CheckBox] -and $_.Checked } | Select-Object -ExpandProperty Tag
    return $selectedItems
}

return @();

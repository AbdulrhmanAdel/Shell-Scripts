# Load the necessary assembly for creating forms
[CmdletBinding()]
param (
    $options,
    [string]$Title,
    [switch]$Multi,
    [switch]$MustSelectOne,
    $SelectedOptions
)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles();

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = $Title ?? "Select Items"
$form.StartPosition = "CenterScreen"

$mainPanel = New-Object System.Windows.Forms.TableLayoutPanel
$mainPanel.ColumnCount = 1
$mainPanel.RowCount = $options.Count + 1
$mainPanel.Dock = [System.Windows.Forms.DockStyle]::Fill;
$mainPanel.AutoScroll = $true;
$mainPanel.Margin = New-Object System.Windows.Forms.Padding(10, 0, 10, 0);
$mainPanel.AutoSize = $true
$mainPanel.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink;
$mainPanel.Dock = [System.Windows.Forms.DockStyle]::Fill;
$form.Controls.Add($mainPanel);
$currentRow = 0;
$selectedOptions ??= @();
$checkboxes = $options | ForEach-Object {
    $item = $_;
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.AutoSize = $true;
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
    return $checkbox;
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
$mainPanel.Controls.Add($submitButton, 0, $options.Count + 1);

$width = ($checkboxes | Select-Object -ExpandProperty Width | Measure-Object -Maximum).Maximum;
$checkboxHeight = ($checkboxes | Select-Object -ExpandProperty Height | Measure-Object -Maximum).Maximum;
$height = $checkboxHeight * $checkboxes.Count + $submitButton.Height;
$width  += 100;
$height += 100;
$form.Size = New-Object System.Drawing.Size($width, $height)

# Show the form
$result = $form.ShowDialog();
if ($result -eq 'OK') {
    $selectedItems = $checkboxes | Where-Object { $_.Checked } | Select-Object -ExpandProperty Tag
    return $selectedItems
}

return @();

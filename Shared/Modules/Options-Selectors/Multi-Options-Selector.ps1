# Load the necessary assembly for creating forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles();
& Parse-Args.ps1 $args[0];

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = $title ?? "Select Items"
$form.Size = New-Object System.Drawing.Size(300, 200)
$form.StartPosition = "CenterScreen"

# The y position for the first checkbox
$y = 10

# Create and add checkboxes to the form
foreach ($item in $options) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    
    $checkbox.Top = $y
    $checkbox.Left = 10
    $checkbox.Width = 260
    if ($item.Key) {
        $checkbox.Text = $item.Key;
        $checkbox.Tag = $item.Value;
    }
    else {
        $checkbox.Tag = $checkbox.Text = $item;
    }
    
    $form.Controls.Add($checkbox)
    $y += 20  # Increase y position for the next checkbox
}

# Add a submit button
$submitButton = New-Object System.Windows.Forms.Button
$submitButton.Text = "Submit"
$submitButton.Top = $y + 10
$submitButton.Left = 10
$submitButton.Width = 260
$submitButton.DialogResult = 'OK'
$submitButton.Add_Click(
    {
        $form.Close()
    });
$form.Controls.Add($submitButton)

# Show the form
$result = $form.ShowDialog();
if ($result -eq 'OK') {
    $selectedItems = $form.Controls | Where-Object { $_ -is [System.Windows.Forms.CheckBox] -and $_.Checked } | Select-Object -ExpandProperty Tag
    return $selectedItems
}

return @();

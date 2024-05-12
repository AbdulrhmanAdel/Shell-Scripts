Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

. Parse-Args.ps1 $args;

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = $title;
$form.StartPosition = "CenterScreen"
$form.AutoSize = $true;
$form.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowOnly;

$width = 250;
$flowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$flowLayoutPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$flowLayoutPanel.AutoScroll = $true
$flowLayoutPanel.Padding = New-Object System.Windows.Forms.Padding(10)  # Add padding
$form.Controls.Add($flowLayoutPanel)

$textFormFlow = New-Object System.Windows.Forms.FlowLayoutPanel
$flowLayoutPanel.Controls.Add($textFormFlow)

if ($message) {
    $messageLabel = New-Object System.Windows.Forms.Label;
    $messageLabel.Text = $message;
    $messageLabel.AutoSize = $true;
    $messageLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $flowLayoutPanel.Controls.Add($messageLabel);
}


function Add {
    
    $text = New-Object System.Windows.Forms.TextBox;
    $text.Width = $width
    $text.Text = $defaultValue;
    $text.AutoSize = $true;
    $text.KeyDown
    $text.Add_KeyDown(
        {
            param ($KeyCode, $key) 
    
            if ($key.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                Add;
            }
        }
    );
    $textFormFlow.Controls.Add($text);
}
Add
# Create a button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Ok"
$button.Width = $width; 
$button.AutoSize = $true;
$button.Padding = New-Object System.Windows.Forms.Padding(3)    
$button.Add_Click(
    {
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
    }
)

# Add controls to the form

$flowLayoutPanel.Controls.Add($button);
$flowLayoutPanel.Height = $text.Height + $button.Height + 20;

# Show the form
$result = $form.ShowDialog();
$form.Dispose();
if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
    return $defaultValuel;
}

return  $null;
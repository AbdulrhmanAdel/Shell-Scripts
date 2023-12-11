# Load Windows Forms
$global:path = $args[0];
$global:directoryName = "";
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select Directory'
$form.Size = New-Object System.Drawing.Size(1080, 1080)
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10, 10)
$listBox.Size = New-Object System.Drawing.Size(1000, 1000)

function CreateDirectoryIfNotExist {
    param (
        $path
    )
    
    if (Test-Path $path) {
        return $path;
    }

    return New-Item -Path $path -Force -ItemType Directory;
}

function RenderOptions {
    $childern = Get-ChildItem -LiteralPath $global:path | Where-Object {
        return $_ -is [System.IO.DirectoryInfo]
    };
    $folderPathes = $childern | Select-Object FullName;
    $listBox.Items.Add("/");
    $listBox.Items.Add("New Folder");
    foreach ($item in $folderPathes) {
        $listBox.Items.Add($item.FullName)
    }
}

RenderOptions -path $global:path;
$form.Controls.Add($listBox)

# Add an event handler for item click
$listBox.Add_Click({
        $selectedItem = $listBox.SelectedItem
        $listBox.Items.Clear();

        if ($selectedItem -eq "/") {
            $form.Hide();
            $form.Close()
            $global:directoryName = $global:path;
            return;
        }
        
        if ($selectedItem -eq "New Folder") {
            $form.Hide();
            $form.Close();
            $folderName = Read-Host "Please enter folder Name";
            if (!$folderName) {
                $folderName = "New Folder";
            }
            $global:directoryName = "$global:path/$folderName";
            CreateDirectoryIfNotExist -path $global:directoryName;
            return;
        }

        $global:path = $selectedItem;
        RenderOptions;
    })

$form.Add_Shown({ 
        $form.Activate();
    })
# $form.Activate();
# Show the form
$form.ShowDialog();
Write-Output $global:directoryName;

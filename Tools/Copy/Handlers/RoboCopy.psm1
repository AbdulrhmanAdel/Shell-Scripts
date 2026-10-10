. "$PSScriptRoot\..\..\..\Shared\Inputs\Form-Style.ps1";

$script:Excludes = @(
    "/XD", '$Recycle.bin', "System Volume Information", "node_modules",
    "/XF", "thumbs.db"
);

function Format-Size {
    param ([double]$Bytes)

    $units = @('B', 'KB', 'MB', 'GB', 'TB');
    $index = 0;
    while ($Bytes -ge 1024 -and $index -lt $units.Count - 1) {
        $Bytes /= 1024;
        $index++;
    }
    return "{0:N1} {1}" -f $Bytes, $units[$index];
}

function Get-MirrorPlan {
    param (
        [string]$Source,
        [string]$Destination
    )

    $log = New-TemporaryFile;
    robocopy $Source $Destination /MIR /L /NJH /NJS /FP /BYTES /NP "/UNILOG:$log" @script:Excludes | Out-Null;
    $lines = Get-Content -LiteralPath $log -Encoding Unicode;
    Remove-Item -LiteralPath $log;

    foreach ($line in $lines) {
        $fields = @($line -split "`t" | ForEach-Object Trim | Where-Object { $_ });
        if ($fields.Count -lt 2) {
            continue;
        }

        $class = $fields[0] -replace '\s+-?\d+$', '';
        $action = switch -Wildcard ($class) {
            'New *' { 'Copy' }
            '*EXTRA*' { 'Delete' }
            { $_ -in 'Newer', 'Older', 'Changed' } { 'Update' }
        }
        if (!$action) {
            continue;
        }

        $path = $fields[-1];
        $root = ($action -eq 'Delete' ? $Destination : $Source) + '\';
        $isDirectory = $path.EndsWith('\');
        [PSCustomObject]@{
            Action      = $action
            Path        = $path.StartsWith($root, 'OrdinalIgnoreCase') ? $path.Substring($root.Length) : $path
            IsDirectory = $isDirectory
            Size        = (!$isDirectory -and $fields.Count -ge 3) ? [long]$fields[-2] : 0
        };
    }
}

function Show-MirrorPreview {
    param (
        [string]$Source,
        [string]$Destination,
        $Plan
    )

    $actions = @(
        @{ Name = 'Copy'; Title = 'Will be copied'; Color = [System.Drawing.Color]::ForestGreen }
        @{ Name = 'Update'; Title = 'Will be overwritten'; Color = [System.Drawing.Color]::DarkOrange }
        @{ Name = 'Delete'; Title = 'Will be deleted from the destination'; Color = [System.Drawing.Color]::Firebrick }
    );

    $summary = foreach ($action in $actions) {
        $items = @($Plan | Where-Object Action -eq $action.Name);
        $action.Items = $items;
        $action.Size = ($items | Measure-Object Size -Sum).Sum;
        "$($action.Name): $($items.Count) ($(Format-Size $action.Size))";
    }

    $layout = New-InputForm -Title "Mirror Preview" -Message "$Source`n→ $Destination`n`n$($summary -join '   •   ')" -MessageWidth 900;
    $form = $layout.Form;
    $form.MaximizeBox = $true;

    $list = New-Object System.Windows.Forms.ListView;
    $list.View = [System.Windows.Forms.View]::Details;
    $list.FullRowSelect = $true;
    $list.Dock = [System.Windows.Forms.DockStyle]::Fill;
    $list.Columns.Add("Path", 680) | Out-Null;
    $list.Columns.Add("Size", 110, [System.Windows.Forms.HorizontalAlignment]::Right) | Out-Null;
    $list.BeginUpdate();
    foreach ($action in $actions) {
        if (!$action.Items.Count) {
            continue;
        }

        $group = New-Object System.Windows.Forms.ListViewGroup("$($action.Title) - $($action.Items.Count) items, $(Format-Size $action.Size)");
        $list.Groups.Add($group) | Out-Null;
        $rows = foreach ($item in $action.Items) {
            $row = New-Object System.Windows.Forms.ListViewItem($item.Path, $group);
            $row.SubItems.Add($item.IsDirectory ? "" : (Format-Size $item.Size)) | Out-Null;
            $row.ForeColor = $action.Color;
            $row;
        }
        $list.Items.AddRange([System.Windows.Forms.ListViewItem[]]$rows);
    }
    $list.EndUpdate();
    $layout.Body.Controls.Add($list);

    $deleteCount = $actions[2].Items.Count;
    Add-InputFormButton -Layout $layout -Text ($deleteCount ? "Mirror (delete $deleteCount)" : "Mirror") -DialogResult OK -Accept | Out-Null;
    Add-InputFormButton -Layout $layout -Text 'Cancel' -DialogResult Cancel -Cancel | Out-Null;

    $bounds = Get-InputFormBounds;
    $form.MinimumSize = New-Object System.Drawing.Size(600, 400);
    $form.Size = New-Object System.Drawing.Size([Math]::Min(950, $bounds.MaxFormWidth), [Math]::Min(700, $bounds.MaxFormHeight));

    $result = $form.ShowDialog();
    $form.Dispose();
    return $result -eq [System.Windows.Forms.DialogResult]::OK;
}

function Confirm-Mirror {
    param (
        [string]$Source,
        [string]$Destination
    )

    Write-Host "Scanning $Source -> $Destination ..." -ForegroundColor Cyan;
    $plan = @(Get-MirrorPlan -Source $Source -Destination $Destination);
    if (!$plan.Count) {
        Write-Host "Already in sync, nothing to do." -ForegroundColor Green;
        return $false;
    }

    if (!(Show-MirrorPreview -Source $Source -Destination $Destination -Plan $plan)) {
        Write-Host "Mirror cancelled." -ForegroundColor Yellow;
        return $false;
    }

    return $true;
}

function Invoke-Copy {
    param (
        [string[]]$Files,
        [string]$Destination,
        [switch]$Move,
        [switch]$Verify,
        [switch]$Mirror
    )

    $checkFolderSync = "$PSScriptRoot\..\..\Check-FolderSync.ps1";
    foreach ($file in $Files) {
        $source = $file.TrimEnd('\');
        $target = $Destination.TrimEnd('\');
        $info = Get-Item -LiteralPath $source;
        $isDirectory = $info -is [System.IO.DirectoryInfo];
        if ($isDirectory) {
            $target += "\$($info.Name)";
        }

        if ($Mirror -and !$isDirectory) {
            Write-Host "Skipping $file, only folders can be mirrored." -ForegroundColor Yellow;
            continue;
        }

        if ($Mirror -and !(Confirm-Mirror -Source $source -Destination $target)) {
            continue;
        }

        robocopy $source $target ($Mirror ? "/MIR" : "/E") /R:0 /MT:16 /V /ETA @script:Excludes;
        $exitCode = $LASTEXITCODE;
        Write-Host ($exitCode -lt 8 ? "RoboCopy completed." : "RoboCopy failed with exit code $exitCode.") -ForegroundColor ($exitCode -lt 8 ? 'Green' : 'Red');

        if ($exitCode -eq 1 -and $Move) {
            if (& $checkFolderSync -Source $source -Target $target -CheckHashes $true) {
                Remove-Item -LiteralPath $source -Recurse -Force;
            }
            continue;
        }

        if ($Verify) {
            $result = & $checkFolderSync -Source $source -Target $target -CheckHashes $true;
            Write-Host "Verification result for $($file): $($result.Success)" -ForegroundColor Yellow;
        }
    }
}

Export-ModuleMember -Function Invoke-Copy;

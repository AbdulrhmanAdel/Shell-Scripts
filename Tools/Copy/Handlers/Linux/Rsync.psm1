$script:Excludes = @('--exclude=$RECYCLE.BIN', '--exclude=System Volume Information', '--exclude=node_modules', '--exclude=thumbs.db');

function Invoke-Copy {
    param (
        [string[]]$Files,
        [string]$Destination,
        [switch]$Move,
        [switch]$Verify,
        [switch]$Mirror
    )

    $arguments = @('--archive', '--human-readable', '--info=progress2') + $script:Excludes;
    if ($Move) { $arguments += '--remove-source-files'; }
    if ($Verify) { $arguments += '--checksum'; }
    if ($Mirror) { $arguments += '--delete'; }

    foreach ($file in $Files) {
        $source = $file.TrimEnd('/');
        $target = $Destination.TrimEnd('/');
        $isDirectory = Test-Path -LiteralPath $source -PathType Container;
        if ($isDirectory) {
            $target = "$target/$(Split-Path $source -Leaf)";
            $source = "$source/";
        }

        if ($Mirror -and !$isDirectory) {
            Write-Host "Skipping $file, only folders can be mirrored." -ForegroundColor Yellow;
            continue;
        }

        if ($Mirror) {
            $changes = @(& rsync @arguments --dry-run --itemize-changes --out-format='%i %n' -- $source "$target/" | Where-Object { $_ -match '^(\*deleting|[<>c])' });
            $changes | ForEach-Object { Write-Host $_; };
            if (!$changes -or !(Prompt.ps1 -Message "Apply these $($changes.Count) changes to $target?")) {
                continue;
            }
        }

        New-Item -ItemType Directory -Force $Destination | Out-Null;
        & rsync @arguments -- $source "$target/";
        if ($LASTEXITCODE -ne 0) {
            Write-Host "rsync failed with exit code $LASTEXITCODE." -ForegroundColor Red;
        }
        elseif ($Move -and $isDirectory) {
            Remove-Item -LiteralPath $file -Recurse -Force;
        }
    }
}

Export-ModuleMember -Function Invoke-Copy;

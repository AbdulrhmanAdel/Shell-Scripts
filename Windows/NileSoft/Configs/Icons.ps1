return @(
    @{
        Title    = "Icons"
        Target   = "dir"
        Children = @(
            @{
                Title          = "Set Or Refresh Icon"
                FilePath       = "Icons\Set-Folder-Icon.ps1"
                MultiExecution = $true
            },
            @{
                Title          = "Remove Icon"
                FilePath       = "Icons\Remove-Icon.ps1"
                MultiExecution = $true
            }
        )
    }
    @{
        Title    = "Icons"
        Filter   = ".png"
        Target   = "file"
        Children = @(
            @{
                Title          = "Convert To Icon"
                FilePath       = "Icons\Utils\Convert-Png-To-Ico.ps1"
                MultiExecution = $true
            }
        )
    }
)
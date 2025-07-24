return @(
    
    @{
        Title    = "Tools"
        Mode     = "multiple"
        Target   = "file|dir"
        Children = @(
            @{
                Target   = "file|dir"
                Title    = "TakeOwn"
                Image    = "\uE194"
                FilePath = "Tools\Take-Ownership.ps1"
            }
            @{
                Target  = "dir"
                Title   = "Add To Path"
                Command = "Add-ToPath.ps1"
            }
            @{
                Target   = "file"
                Title    = "Display Hash"
                FilePath = "$ShellScripsPath\Tools\Hash\Display-Hash.ps1"
            }
            @{
                Target   = "file|dir"
                Title    = "Copy Paths"
                FilePath = "$ShellScripsPath\Tools\Copy-PathsToClipboard.ps1"
            }
            @{
                Target   = "file|dir"
                Title    = "Copy Names"
                FilePath = "$ShellScripsPath\Tools\Copy-FileNames.ps1"
            }
        )
    }
)

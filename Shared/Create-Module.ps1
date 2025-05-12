[CmdletBinding()]
param (
    [Parameter()]
    $Options
)

$FilesExtensions = @($Files | Foreach-Object {
        $ex = [System.IO.Path]::GetExtension($_);
        if (!$ex) {
            return "Directory"
        }
        return $ex -replace "^.", ""
    })

$options = $Options | Where-Object {
    $extensions = $_.Extensions;
    if (!$extensions) {
        return $true
    }

    return [bool]($FilesExtensions | Where-Object { $_ -in $extensions })
}


if ($options.Length -eq 0) {
    $options = @();
}

$options += @{
    Key     = "Choose Another Module";
    Handler = {
        Module-Picker.ps1 -Files $Files;
    };
}

$option = Single-Options-Selector.ps1 -options $Options -Required;
$option.Handler.Invoke();
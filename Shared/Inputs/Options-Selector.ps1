param (
    $options,
    [switch]$Multi
)

if ($args.Contains("--multi") -or $Multi) {
    return & "$($PSScriptRoot)/Modules/Options-Selectors/Multi-Options-Selector.ps1" $args
}

return & "$($PSScriptRoot)/Modules/Options-Selectors/Single-Options-Selector.ps1" $args;
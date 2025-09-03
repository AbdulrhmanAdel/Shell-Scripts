$Colors = @(
    [System.ConsoleColor]::Black
    [System.ConsoleColor]::DarkBlue
    [System.ConsoleColor]::DarkGreen
    [System.ConsoleColor]::DarkCyan
    [System.ConsoleColor]::DarkMagenta
    [System.ConsoleColor]::DarkYellow
    [System.ConsoleColor]::Gray
    [System.ConsoleColor]::DarkGray
    [System.ConsoleColor]::Blue
    [System.ConsoleColor]::Green
    [System.ConsoleColor]::Cyan
    [System.ConsoleColor]::Magenta
)

return Get-Random -InputObject $Colors

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Text
)

if ($env:WAYLAND_DISPLAY -and (Get-Command wl-copy -ErrorAction SilentlyContinue)) {
    & wl-copy -- $Text;
}
elseif (Get-Command xclip -ErrorAction SilentlyContinue) {
    & bash -c 'printf %s "$1" | xclip -selection clipboard' _ $Text;
}
else {
    & qdbus-qt6 org.kde.klipper /klipper setClipboardContents $Text | Out-Null;
}

#!/usr/bin/env bash
# Adds "Run with pwsh" to Dolphin's right-click menu for .ps1 files.
# Safe to run again, including after reinstalling Linux.
#
#   ./Setup-Run-With-Pwsh.sh            install
#   ./Setup-Run-With-Pwsh.sh --remove   remove
set -euo pipefail

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
menus="$data/kio/servicemenus"
menu="$menus/run-with-pwsh.desktop"

refresh() { command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 >/dev/null 2>&1 || true; }

if [ "${1:-}" = '--remove' ]; then
    rm -f -- "$menu"
    refresh
    echo "Removed Run with pwsh from the right-click menu."
    exit 0
fi

mkdir -p "$menus"
chmod 0755 "$here/Run-With-Pwsh.sh"

cat >"$menu" <<DESKTOP
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=application/x-powershell;
Actions=runWithPwsh
X-KDE-Priority=TopLevel

[Desktop Action runWithPwsh]
Name=Run with pwsh
Icon=utilities-terminal
Exec="$here/Run-With-Pwsh.sh" %f
DESKTOP
# Plasma ignores service menus that are not executable.
chmod 0755 "$menu"

refresh
echo "Installed. Right-click a .ps1 file and choose Run with pwsh."

#!/usr/bin/env bash
# raw-open.sh <image.raw>
# Mounts a raw VM disk image with raw-mount.sh (pkexec asks for the password) and opens the mount point.
# Runs when a .raw file is double-clicked, and from the Mount VM Disk And Open menu item.
set -u
here="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
source "$here/../lib/ui.sh"

err="$(mktemp)"
trap 'rm -f "$err"' EXIT

if mp="$(pkexec "$here/raw-mount.sh" mount "$1" 2>"$err")"; then
    xdg-open "$mp"
    # Mounted, but the host disk has less room than the image could take.
    warn="$(grep '^WARNING' "$err" || true)"
    [[ -z "$warn" ]] || ui_error "$warn"
else
    rc=$?
    # 126: the password dialog was cancelled, nothing to report.
    (( rc == 126 )) || ui_error "Could not mount $(basename -- "$1"):"$'\n\n'"$(cat "$err")"
    exit 1
fi

#!/usr/bin/env bash
# Run-With-Pwsh.sh <script.ps1> [args]
# Runs a PowerShell script in a Konsole window that stays open after it finishes, so its output can be read.
set -u

if [ $# -lt 1 ] || [ ! -f "$1" ]; then
    echo "usage: Run-With-Pwsh.sh <script.ps1> [args]" >&2
    exit 2
fi

script="$(readlink -f -- "$1")"
shift
cd -- "$(dirname -- "$script")" || exit 1

exec konsole --hold -e pwsh -NoProfile -File "$script" "$@"

#!/usr/bin/env bash
# open-with-prefix.sh <exe>
# Asks which Faugus prefix to use, then runs the exe in it the same way as run_trainer.sh.
set -u
source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/../lib/ui.sh"

here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exe="$1"
faugus="$HOME/Faugus"

mapfile -t prefixes < <(find -L "$faugus" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
[ ${#prefixes[@]} -gt 0 ] || { ui_error "No prefixes found in $faugus"; exit 1; }

choice="$(ui_choose 'Run in prefix' "Prefix for $(basename -- "$exe"):" "${prefixes[@]}")" || exit 0
exec "$here/prefix-run.sh" -p "$choice" "$exe"

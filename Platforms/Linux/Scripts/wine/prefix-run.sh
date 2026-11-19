#!/usr/bin/env bash
# prefix-run: run any Windows .exe (trainer, mod tool, launcher) inside an existing
# Faugus/umu Wine prefix, using the same Proton and environment the game uses.
#
# Usage:
#   prefix-run [-p PREFIX_NAME] [-P PROTON_DIR] [-d] EXE [ARGS...]
#
#   -p  prefix name under ~/Faugus (default: avatar---frontiers-of-pandora)
#   -P  Proton directory (default: GE-Proton in Steam compatibilitytools.d)
#   -d  dry run: print the command without running it
#
# Examples:
#   prefix-run "/data/Games/Avatar - Frontiers of Pandora/Trainer.exe"
#   prefix-run -p onimusha---way-of-the-sword ~/Downloads/mod-tool.exe

set -euo pipefail

PREFIX_NAME="avatar---frontiers-of-pandora"
PROTON="$HOME/.local/share/Steam/compatibilitytools.d/GE-Proton"
DRY=0
UMU_RUN="$HOME/.local/share/faugus-launcher/umu-run"
FAUGUS_DIR="$HOME/Faugus"
FAUGUS_COMPONENTS="$HOME/.local/share/faugus-launcher/components"

die() { echo "prefix-run: $*" >&2; exit 1; }
usage() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while getopts ":p:P:dh" opt; do
    case $opt in
        p) PREFIX_NAME="$OPTARG" ;;
        P) PROTON="$OPTARG" ;;
        d) DRY=1 ;;
        h) usage 0 ;;
        *) usage 1 ;;
    esac
done
shift $((OPTIND - 1))

[[ $# -ge 1 ]] || usage 1
EXE="$1"; shift

PREFIX="$FAUGUS_DIR/$PREFIX_NAME"
[[ -f "$EXE" ]]     || die "exe not found: $EXE"
[[ -d "$PREFIX" ]]  || die "prefix not found: $PREFIX"
[[ -d "$PROTON" ]]  || die "Proton not found: $PROTON"
[[ -x "$UMU_RUN" ]] || die "umu-run not found: $UMU_RUN"

export WINEPREFIX="$PREFIX"
export PROTONPATH="$PROTON"
export UMU_USE_STEAM=1
export UMU_CONTAINER_NSENTER=1
export UMU_RUNTIME_UPDATE=0
export PROTON_EAC_RUNTIME="$FAUGUS_COMPONENTS/eac"
export PROTON_BATTLEYE_RUNTIME="$FAUGUS_COMPONENTS/be"

if [[ $DRY -eq 1 ]]; then
    echo "WINEPREFIX=$WINEPREFIX PROTONPATH=$PROTONPATH $UMU_RUN \"$EXE\" $*"
    exit 0
fi

# Warn if no Windows program is running in this prefix (the game may be closed).
if ! grep -l "WINEPREFIX=$PREFIX" /proc/[0-9]*/environ 2>/dev/null | grep -q .; then
    echo "prefix-run: warning: no process found in this prefix. Start the game first if the trainer needs it." >&2
fi

cd "$(dirname "$EXE")"
exec "$UMU_RUN" "$EXE" "$@"

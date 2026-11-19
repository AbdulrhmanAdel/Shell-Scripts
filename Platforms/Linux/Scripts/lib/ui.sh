# ui.sh: small dialogs that work on any desktop. Source it, do not run it.
# Uses kdialog on KDE (or when zenity is missing) and zenity everywhere else.
# Each function prints the answer on stdout and fails when the user cancels.
#
#   ui_error   <message>
#   ui_input   <title> <prompt> [default]
#   ui_pick_dir <title> [start folder]
#   ui_choose  <title> <prompt> <option>...

_ui_tool() {
    if command -v kdialog >/dev/null && { [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]] || ! command -v zenity >/dev/null; }; then
        echo kdialog
    elif command -v zenity >/dev/null; then
        echo zenity
    else
        echo none
    fi
}

ui_error() {
    case "$(_ui_tool)" in
        kdialog) kdialog --error "$1" ;;
        zenity) zenity --error --text="$1" ;;
        *) echo "$1" >&2 ;;
    esac
}

ui_input() {
    case "$(_ui_tool)" in
        kdialog) kdialog --title "$1" --inputbox "$2" "${3:-}" ;;
        zenity) zenity --entry --title="$1" --text="$2" --entry-text="${3:-}" ;;
        *) read -r -p "$2 " answer && echo "$answer" ;;
    esac
}

ui_pick_dir() {
    local start="${2:-$HOME}"
    case "$(_ui_tool)" in
        kdialog) kdialog --title "$1" --getexistingdirectory "$start" ;;
        zenity) zenity --file-selection --directory --title="$1" --filename="$start/" ;;
        *) read -r -p "$1: " answer && echo "$answer" ;;
    esac
}

ui_choose() {
    local title="$1" prompt="$2"
    shift 2
    case "$(_ui_tool)" in
        kdialog) kdialog --title "$title" --combobox "$prompt" "$@" ;;
        zenity) zenity --list --title="$title" --text="$prompt" --column=Choice "$@" ;;
        *) select answer in "$@"; do [ -n "$answer" ] && echo "$answer" && break; done ;;
    esac
}

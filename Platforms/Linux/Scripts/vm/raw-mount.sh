#!/usr/bin/env bash
# Mounts or unmounts the NTFS partition inside a raw VM disk image.
#   raw-mount.sh mount   <image.raw>   attach, mount read-write, print the mount point
#   raw-mount.sh unmount <image.raw>   unmount, detach, print nothing
#   raw-mount.sh trim    <image.raw>   give the image's free NTFS space back to the host disk (needs it mounted)
# The image is sparse: space freed inside it (deleted files) stays taken on the host until it is trimmed, so mount and
# unmount trim it too. If the host disk fills up anyway, writes into the image are lost (kernel "critical space
# allocation error"), so mount warns when the image's free space is more than the host disk has left.
# Dolphin names the partitions after the image ("Win-26") instead of their NTFS label ("Local Disk"); the label
# itself is not changed, so Windows still sees its own.
# Run through pkexec (the Dolphin menu does this). Refuses if a running VM uses the image.

set -euo pipefail

action="${1:-}"
img="$(readlink -f "${2:-}")"
[[ "$action" =~ ^(mount|unmount|trim)$ ]] || { echo "usage: $0 mount|unmount|trim <image.raw>" >&2; exit 2; }
[[ -f "$img" && "$img" == *.raw ]] || { echo "Not a .raw image: $img" >&2; exit 2; }

# The user who launched pkexec; files on the mount belong to them.
USER_UID="${PKEXEC_UID:-$(id -u)}"
USER_GID="$(id -g "$USER_UID")"
base="$(basename "$img" .raw)"
mp="/mnt/raw/$base"

# Hands the free NTFS space back to the host (ntfs-3g FITRIM punches holes in the image) and reports the image's size.
trim() {
    local before after
    before=$(du -B1 "$img" | cut -f1)
    fstrim "$mp" >&2 || echo "Trim failed on $mp" >&2
    after=$(du -B1 "$img" | cut -f1)
    echo "Trimmed $(basename "$img"): $(numfmt --to=iec $((before - after))) freed on the host," \
         "it now takes $(numfmt --to=iec "$after")" >&2
}
# Warns when the image could grow past what the host disk has left.
check_room() {
    local inside host
    inside=$(df -B1 --output=avail "$mp" | tail -1)
    host=$(df -B1 --output=avail "$(dirname "$img")" | tail -1)
    if (( inside > host )); then
        echo "WARNING: $mp shows $(numfmt --to=iec "$inside") free, but the disk holding the image has only" \
             "$(numfmt --to=iec "$host"). Writing more than that into $mp loses data." >&2
    fi
}
# Display names come from a udev rule in /run (gone at reboot) that sets UDISKS_NAME, which udisks hands to
# Dolphin as the device name. The main partition gets the image name, the others "<name> (partition N)".
rule_file() { echo "/run/udev/rules.d/90-raw-mount-$(basename "$1").rules"; }
name_parts() {   # <loop device> <main partition>
    local loop="$1" main="$2" label="${base//[\"%]/}"
    mkdir -p /run/udev/rules.d
    cat >"$(rule_file "$loop")" <<EOF
# Written by raw-mount.sh for $img; removed on unmount.
KERNEL=="$(basename "$loop")p*", ENV{UDISKS_NAME}="$label (partition %n)"
KERNEL=="$main", ENV{UDISKS_NAME}="$label"
EOF
    udevadm control --reload
    udevadm trigger --action=change --settle "$loop"p*
}
unname_parts() {   # <loop device>
    rm -f "$(rule_file "$1")"
    udevadm control --reload
}

# Refuse while a running VM uses this image.
while read -r vm; do
    [[ -n "$vm" ]] || continue
    if virsh -c qemu:///system domblklist "$vm" | grep -qF "$img"; then
        echo "VM '$vm' is running and uses $img. Shut it down first." >&2
        exit 1
    fi
done < <(virsh -c qemu:///system list --name)

if [[ "$action" == "mount" ]]; then
    loop="$(losetup -j "$img" | cut -d: -f1 | head -1 || true)"
    if [[ -z "$loop" ]]; then
        loop="$(losetup -Pf --show "$img")"
        udevadm settle
    fi
    # Pick the largest NTFS partition (the Windows or data volume).
    part="$(lsblk -rbno NAME,FSTYPE,SIZE "$loop" | awk '$2=="ntfs"{print $3, $1}' | sort -n | tail -1 | awk '{print $2}')"
    if [[ -z "$part" ]]; then
        losetup -d "$loop"
        echo "No NTFS partition found in $img" >&2
        exit 1
    fi
    name_parts "$loop" "$part"
    mkdir -p "$mp"
    if ! mountpoint -q "$mp"; then
        mount -t ntfs-3g -o "uid=$USER_UID,gid=$USER_GID,umask=022" "/dev/$part" "$mp"
    fi
    trim
    check_room
    echo "$mp"
elif [[ "$action" == "trim" ]]; then
    mountpoint -q "$mp" || { echo "$img is not mounted at $mp" >&2; exit 1; }
    trim
    check_room
else
    loop="$(losetup -j "$img" | cut -d: -f1 | head -1 || true)"
    if mountpoint -q "$mp"; then
        trim
        umount "$mp"
    fi
    rmdir "$mp" 2>/dev/null || true
    if [[ -n "$loop" ]]; then
        losetup -d "$loop"
        unname_parts "$loop"
    fi
fi

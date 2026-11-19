# vm

`raw-mount.sh` attaches a raw VM disk image with `losetup`, mounts its largest NTFS partition
read-write at `/mnt/raw/<image name>`, and detaches it again on unmount. Mount and unmount also trim the image, so space
freed inside it goes back to the host disk (`raw-mount.sh trim` does it by hand), and mount warns when the host disk has
less room left than the image could grow to. Dolphin shows the partitions under the image name instead of their NTFS
label (Windows names them "Local Disk"): a udev rule in `/run/udev/rules.d` sets `UDISKS_NAME`, and unmount removes it.

    sudo Platforms/Linux/Scripts/vm/raw-mount.sh mount   path/to/disk.raw   # prints the mount point
    sudo Platforms/Linux/Scripts/vm/raw-mount.sh unmount path/to/disk.raw
    sudo Platforms/Linux/Scripts/vm/raw-mount.sh trim    path/to/disk.raw   # while mounted

The mount is owned by the user who ran it (through `PKEXEC_UID` or the current user), so files can be moved without sudo.

It refuses to run while a running VM uses the image. Shut the VM down first.

`raw-open.sh <image.raw>` runs `raw-mount.sh mount` through pkexec, opens the mount point, and shows any error in a dialog.
Double-clicking a `.raw` file runs it: `desktop/kde/mime/vm-raw-disk.xml` makes `.raw` its own file type (VM raw disk
image, instead of Panasonic RAW photo) and `desktop/kde/apps/vm-raw-mount.desktop` is the default app for it.

The right-click entries (Tools > Mount VM Disk And Open, Unmount VM Disk) live in `desktop/kde/menus/1-tools/50-vm.desktop`. Install all of it with `desktop/kde/install.sh`.

Requires `ntfs-3g`, `pkexec`, and `virsh`.

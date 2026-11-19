#!/usr/bin/env bash
# extract-exe-icon.sh <exe...>
# Saves the largest icon inside each Windows exe as a PNG next to it: Game.exe -> Game.png.
# Works on its own (python3 and python3-pil or ImageMagick), so it does not need Faugus's icoextract, which only runs
# when Faugus starts it. Use the PNG as a Faugus game icon, a shortcut icon, and so on.
set -u

[ $# -gt 0 ] || exit 0
command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }

output="$(python3 -I - "$@" <<'PY'
import io, os, shutil, struct, subprocess, sys, tempfile

PNG = b"\x89PNG\r\n\x1a\n"
RT_ICON, RT_GROUP_ICON = 3, 14


def largest_exe_icon(path):
    """Return the largest image of the exe's main icon as PNG or DIB bytes, or None."""
    with open(path, "rb") as f:
        def read(offset, size):
            f.seek(offset)
            data = f.read(size)
            if len(data) != size:
                raise ValueError("truncated file")
            return data

        if read(0, 2) != b"MZ":
            return None
        pe = struct.unpack("<I", read(0x3C, 4))[0]
        if read(pe, 4) != b"PE\0\0":
            return None
        section_count, optional_size = struct.unpack("<H12xH", read(pe + 6, 16))
        optional = pe + 24
        directories = optional + {0x10B: 96, 0x20B: 112}[struct.unpack("<H", read(optional, 2))[0]]
        root = struct.unpack("<I", read(directories + 16, 4))[0]
        if not root:
            return None

        sections = []
        for i in range(section_count):
            raw = read(optional + optional_size + i * 40, 40)
            virtual_size, rva, raw_size, raw_offset = struct.unpack("<4I", raw[8:24])
            sections.append((rva, max(virtual_size, raw_size), raw_offset))

        def file_offset(rva):
            for start, size, raw_offset in sections:
                if start <= rva < start + size:
                    return raw_offset + rva - start
            raise ValueError("address outside all sections")

        base = file_offset(root)

        def entries(offset):
            named, numbered = struct.unpack("<2H", read(base + offset + 12, 4))
            for i in range(named + numbered):
                name, target = struct.unpack("<2I", read(base + offset + 16 + i * 8, 8))
                yield name, target

        def first_data(target):
            # Follows the language level, taking the first entry.
            while target & 0x80000000:
                target = next(entries(target & 0x7FFFFFFF))[1]
            rva, size = struct.unpack("<2I", read(base + target, 8))
            return read(file_offset(rva), size)

        types = dict(entries(0))
        if RT_ICON not in types or RT_GROUP_ICON not in types:
            return None
        # Windows shows the first icon group as the exe's icon.
        group = first_data(next(entries(types[RT_GROUP_ICON] & 0x7FFFFFFF))[1])
        images = dict(entries(types[RT_ICON] & 0x7FFFFFFF))
        best_key, best_id = None, None
        for i in range(struct.unpack("<H", group[4:6])[0]):
            width, _, _, _, _, bits, size, icon_id = struct.unpack("<4B2HIH", group[6 + i * 14 : 20 + i * 14])
            key = (width or 256, bits, size)
            if icon_id in images and (best_key is None or key > best_key):
                best_key, best_id = key, icon_id
        return None if best_id is None else first_data(images[best_id])


def to_png(image):
    """Convert PNG or DIB icon bytes to PNG bytes."""
    if image.startswith(PNG):
        return image
    width = struct.unpack("<i", image[4:8])[0]
    bits = struct.unpack("<H", image[14:16])[0]
    size = 0 if width >= 256 else width
    ico = struct.pack("<3H4B2H2I", 0, 1, 1, size, size, 0, 0, 1, bits, len(image), 22) + image
    try:
        from PIL import Image
    except ImportError:
        if not shutil.which("magick"):
            raise RuntimeError("needs python3-pil or ImageMagick")
        return subprocess.run(["magick", "ico:-", "png:-"], input=ico, stdout=subprocess.PIPE, check=True).stdout
    source = Image.open(io.BytesIO(ico))
    source.size = max(source.ico.sizes())
    source.load()
    out = io.BytesIO()
    source.save(out, "PNG")
    return out.getvalue()


failed = False
for exe in sys.argv[1:]:
    name = os.path.basename(exe)
    try:
        image = largest_exe_icon(exe)
        if not image:
            print(f"{name}: no icon inside")
            continue
        png = to_png(image)
        target = os.path.splitext(exe)[0] + ".png"
        handle, tmp = tempfile.mkstemp(dir=os.path.dirname(os.path.abspath(target)))
        try:
            with os.fdopen(handle, "wb") as f:
                f.write(png)
            os.chmod(tmp, 0o644)
            os.replace(tmp, target)
        except BaseException:
            os.unlink(tmp)
            raise
        print("{}: {}x{} icon saved as {}".format(name, *struct.unpack(">2I", png[16:24]), os.path.basename(target)))
    except Exception as error:
        failed = True
        print(f"{name}: failed: {error}")
sys.exit(1 if failed else 0)
PY
)"
status=$?

echo "$output"
if command -v notify-send >/dev/null; then
    notify-send --icon=image-x-generic "Extract icon" "$output" 2>/dev/null || true
fi
exit "$status"

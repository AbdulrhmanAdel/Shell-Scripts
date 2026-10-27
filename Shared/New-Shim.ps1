[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Name,
    [string] $Target,
    # The .exe/.dll to take the shim's icon from, or an .ico file. Defaults to the target; when it has no icon (e.g. a .cmd), a file is asked for
    [string] $Icon
)

if (-not $Target) {
    $Target = & "$PSScriptRoot\Inputs\File-Picker.ps1" -Title "Select target for shim '$Name'" -Required
}
$Target = (Resolve-Path -LiteralPath $Target).Path
$Icon = $Icon ? (Resolve-Path -LiteralPath $Icon).Path : $Target

$hubsFile = "$PSScriptRoot\Modules\Shim\hubs.local.json"
$hubs = @()
if (Test-Path -LiteralPath $hubsFile) {
    $hubs = @(Get-Content -LiteralPath $hubsFile -Raw | ConvertFrom-Json)
}

$match = $hubs | Where-Object { $Target -like "$($_.Prefix)*" } | Sort-Object { $_.Prefix.Length } -Descending | Select-Object -First 1
if (-not $match) {
    throw "No hub configured for '$Target'. Add a { Prefix, Hub } entry to $hubsFile"
}
$hub = $match.Hub

$shimDir = "$PSScriptRoot\Modules\Shim"

if (-not ("ShimIcon" -as [type])) {
    Add-Type -Namespace "" -Name ShimIcon -MemberDefinition @'
delegate bool EnumResNameProc(System.IntPtr module, System.IntPtr type, System.IntPtr name, System.IntPtr param);
[DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
static extern System.IntPtr LoadLibraryEx(string path, System.IntPtr file, uint flags);
[DllImport("kernel32.dll")]
static extern bool FreeLibrary(System.IntPtr module);
[DllImport("kernel32.dll")]
static extern bool EnumResourceNames(System.IntPtr module, System.IntPtr type, EnumResNameProc callback, System.IntPtr param);
[DllImport("kernel32.dll")]
static extern System.IntPtr FindResource(System.IntPtr module, System.IntPtr name, System.IntPtr type);
[DllImport("kernel32.dll")]
static extern System.IntPtr LoadResource(System.IntPtr module, System.IntPtr resource);
[DllImport("kernel32.dll")]
static extern System.IntPtr LockResource(System.IntPtr data);
[DllImport("kernel32.dll")]
static extern uint SizeofResource(System.IntPtr module, System.IntPtr resource);

static byte[] Read(System.IntPtr module, System.IntPtr name, int type) {
    var resource = FindResource(module, name, (System.IntPtr)type);
    if (resource == System.IntPtr.Zero) return null;
    var bytes = new byte[SizeofResource(module, resource)];
    Marshal.Copy(LockResource(LoadResource(module, resource)), bytes, 0, bytes.Length);
    return bytes;
}

// The first icon group of an .exe/.dll (the one Explorer shows) as the bytes of an .ico file, or null when it has none
public static byte[] Extract(string path) {
    var module = LoadLibraryEx(path, System.IntPtr.Zero, 0x22); // LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE
    if (module == System.IntPtr.Zero) return null;
    try {
        byte[] ico = null;
        EnumResourceNames(module, (System.IntPtr)14, (m, t, name, p) => { // RT_GROUP_ICON
            // A group is a 6-byte header and a 14-byte entry per image; an .ico has 16-byte entries ending with the image offset
            var group = Read(m, name, 14);
            int count = System.BitConverter.ToUInt16(group, 4);
            var images = new byte[count][];
            for (var i = 0; i < count; i++) images[i] = Read(m, (System.IntPtr)System.BitConverter.ToUInt16(group, 6 + i * 14 + 12), 3); // RT_ICON
            var stream = new System.IO.MemoryStream();
            var writer = new System.IO.BinaryWriter(stream);
            writer.Write(group, 0, 6);
            var offset = 6 + count * 16;
            for (var i = 0; i < count; i++) {
                writer.Write(group, 6 + i * 14, 8);
                writer.Write(images[i].Length);
                writer.Write(offset);
                offset += images[i].Length;
            }
            foreach (var image in images) writer.Write(image);
            ico = stream.ToArray();
            return false;
        }, System.IntPtr.Zero);
        return ico;
    } finally {
        FreeLibrary(module);
    }
}
'@
}

# Publishes shim.exe into $Output, unless it is already there and newer than Program.cs
function Publish-Shim([string] $Output, [string[]] $BuildArgs = @()) {
    $exe = "$Output\shim.exe"
    if (-not (Test-Path -LiteralPath $exe) -or (Get-Item "$shimDir\Program.cs").LastWriteTime -gt (Get-Item -LiteralPath $exe).LastWriteTime) {
        dotnet publish "$shimDir\Shim.csproj" -c Release -o $Output @BuildArgs | Out-Null
        if ($LASTEXITCODE -or -not (Test-Path -LiteralPath $exe)) {
            throw "Failed to build shim.exe"
        }
    }
    return $exe
}

function Get-IconBytes([string] $Path) {
    return [IO.Path]::GetExtension($Path) -eq '.ico' ? [IO.File]::ReadAllBytes($Path) : [ShimIcon]::Extract($Path)
}

$iconBytes = Get-IconBytes $Icon
# No icon (e.g. a .cmd target): ask for a file to take one from, cancelling keeps the default icon
while (-not $iconBytes) {
    $Icon = & "$PSScriptRoot\Inputs\File-Picker.ps1" -Title "$(Split-Path $Icon -Leaf) has no icon, select one for shim '$Name' (cancel for the default)" -InitialDirectory (Split-Path $Target) -Filter 'Icons (*.exe;*.dll;*.ico)|*.exe;*.dll;*.ico'
    if (-not $Icon) {
        break
    }
    $iconBytes = Get-IconBytes $Icon
}

# The icon has to be built in: the shim is a single-file bundle, which breaks if its resources are edited afterwards.
# Each icon gets its own build (with its own artifacts folder, so incremental builds never mix up icons), shared by every shim with that icon.
if ($iconBytes) {
    $iconId = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($iconBytes)).Substring(0, 16)
    $iconDir = "$shimDir\obj\icons\$iconId"
    if (-not (Test-Path -LiteralPath "$iconDir\shim.ico")) {
        New-Item -Path $iconDir -ItemType Directory -Force | Out-Null
        [IO.File]::WriteAllBytes("$iconDir\shim.ico", $iconBytes)
    }
    $shimExe = Publish-Shim "$shimDir\bin\icons\$iconId" @('--artifacts-path', $iconDir, "-p:ApplicationIcon=$iconDir\shim.ico")
}
else {
    $shimExe = Publish-Shim "$shimDir\bin"
}

New-Item -Path $hub -ItemType Directory -Force | Out-Null
$shimPath = "$hub\$Name.exe"
# A running shim cannot be overwritten but can be moved aside; the moved copies are deleted once they have exited
Get-ChildItem -LiteralPath $hub -Filter '*.exe.*.old' | Remove-Item -ErrorAction SilentlyContinue
try {
    Copy-Item -LiteralPath $shimExe -Destination $shimPath -Force -ErrorAction Stop
}
catch {
    Move-Item -LiteralPath $shimPath -Destination "$shimPath.$(Get-Random).old"
    Copy-Item -LiteralPath $shimExe -Destination $shimPath
}
Set-Content -Path "$hub\$Name.shim" -Value $Target -Encoding ascii -NoNewline

$iconNote = -not $iconBytes ? ', default icon' : ($Icon -ne $Target ? ", icon from $Icon" : '')
Write-Host "$Name -> $Target (via $hub)$iconNote" -ForegroundColor Green

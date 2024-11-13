[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory)]
    [string]
    $FolderPath
)

enum SHCNE : UInt32 {
    SHCNE_RENAMEITEM = 1
    SHCNE_CREATE = 2
    SHCNE_DELETE = 4
    SHCNE_MKDIR = 8
    SHCNE_RMDIR = 16 # 0x00000010
    SHCNE_MEDIAINSERTED = 32 # 0x00000020
    SHCNE_MEDIAREMOVED = 64 # 0x00000040
    SHCNE_DRIVEREMOVED = 128 # 0x00000080
    SHCNE_DRIVEADD = 256 # 0x00000100
    SHCNE_NETSHARE = 512 # 0x00000200
    SHCNE_NETUNSHARE = 1024 # 0x00000400
    SHCNE_ATTRIBUTES = 2048 # 0x00000800
    SHCNE_UPDATEDIR = 4096 # 0x00001000
    SHCNE_UPDATEITEM = 8192 # 0x00002000
    SHCNE_SERVERDISCONNECT = 16384 # 0x00004000
    SHCNE_UPDATEIMAGE = 32768 # 0x00008000
    SHCNE_DRIVEADDGUI = 65536 # 0x00010000
    SHCNE_RENAMEFOLDER = 131072 # 0x00020000
    SHCNE_FREESPACE = 262144 # 0x00040000
    SHCNE_EXTENDED_EVENT = 67108864 # 0x04000000
    SHCNE_ASSOCCHANGED = 134217728 # 0x08000000
    SHCNE_ALLEVENTS = 2147483647 # 0x7FFFFFFF
    SHCNE_INTERRUPT = 2147483648 # 0x80000000
}

enum SHCNF {
    SHCNF_IDLIST = 0
    SHCNF_PATHA = 1
    SHCNF_PRINTERA = 2
    SHCNF_DWORD = 3
    SHCNF_PATH = 5
    SHCNF_PRINTER = 6
    SHCNF_TYPE = 255 # 0x000000FF
    SHCNF_FLUSH = 4096 # 0x00001000
    SHCNF_FLUSHNOWAIT = 12288 # 0x00003000
    SHCNF_NOTIFYRECURSIVE = 65536 # 0x00010000
}

# $space = ' ';
$Signature = @"
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);

    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr ILCreateFromPathW(string pszPath);
"@
$typeInfo = @{
    MemberDefinition = $Signature
    PassThru         = $true
    Name             = "Shell32"
    Namespace        = 'RefreshIconShell32'
};

$Shell32 = Add-Type @typeInfo;
$Shell32[0]::SHChangeNotify(
    [SHCNE]::SHCNE_ASSOCCHANGED, 
    [SHCNF]::SHCNF_PATH, 
    [IntPtr]::Zero, 
    [IntPtr]::Zero
);
# $pathPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($FolderPath);
# $Shell32[0]::SHChangeNotify([SHCNE]::SHCNE_UPDATEDIR, [SHCNF]::SHCNF_PATH, $pathPtr, [IntPtr]::Zero);
# [System.Runtime.InteropServices.Marshal]::FreeHGlobal($pathPtr);

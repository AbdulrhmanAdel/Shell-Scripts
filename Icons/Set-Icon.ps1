[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory)]
    [string]
    $FolderPath,
    [Parameter(Position = 1, Mandatory)]
    [string]
    $IconPath
)


$Signature = @"
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern int SHGetSetFolderCustomSettings(ref Shfoldercustomsettings pfcs, string pszPath, uint dwReadWrite);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public struct Shfoldercustomsettings
    {
        public uint dwSize;
        public uint dwMask;
        public IntPtr pvid;
        public string pszWebViewTemplate;
        public uint cchWebViewTemplate;
        public string pszWebViewTemplateVersion;
        public string pszInfoTip;
        public uint cchInfoTip;
        public IntPtr pclsid;
        public uint dwFlags;
        public string pszIconFile;
        public uint cchIconFile;
        public int iIconIndex;
        public string pszLogo;
        public uint cchLogo;
    }
"@

$addTypeSplat = @{
    MemberDefinition = $Signature
    PassThru         = $true
    Name             = "Shell32"
    Namespace        = 'Shell32Functions'
}
$Shell32 = Add-Type @addTypeSplat;
$fcs = New-Object $Shell32[1]
$fcs.dwSize = 104;
$fcs.dwMask = 0x00000010;
$fcs.pszIconFile = $IconPath
$fcs.cchIconFile = $IconPath.Length
$fcs.iIconIndex = 0;
$result = $Shell32[0]::SHGetSetFolderCustomSettings([Ref] $fcs, $FolderPath, 0x00000002);
if ($result -ne 0) {
    Write-Host "Failed to set folder custom settings. Error Code: $result" -ForegroundColor Red;
}
else {
    Write-Host "Folder custom settings updated successfully."
}


# Ensure proper cleanup if any unmanaged memory was used
if ($null -ne $fcs.pvid) {
    [System.Runtime.InteropServices.Marshal]::FreeCoTaskMem($fcs.pvid)
}

if ($null -ne $fcs.pclsid) {
    [System.Runtime.InteropServices.Marshal]::FreeCoTaskMem($fcs.pclsid)
}

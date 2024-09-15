$Source = @"
    using System;
    using System.Runtime.InteropServices;
    
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

"@;

Add-Type -TypeDefinition $Source
$iconPath = "D:\Game Of Thrones.ico"; 
$fcs = New-Object Shfoldercustomsettings
$fcs.dwSize = 104;
$fcs.dwMask = 0x00000010;
$fcs.pszIconFile = $iconPath
$fcs.cchIconFile = $iconPath.Length
$fcs.iIconIndex = 0

$Signature = @"
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern int SHGetSetFolderCustomSettings(ref object pfcs, string pszPath, uint dwReadWrite);
"@

$addTypeSplat = @{
    MemberDefinition = $Signature
    PassThru = $true
    Name = "Shell32"
    Namespace = 'Shell32Functions'
}
$ShowWindowAsync = Add-Type @addTypeSplat;
$ShowWindowAsync::SHGetSetFolderCustomSettings([Ref] $fcs, "D:\New folder (3)", 0x00000010)
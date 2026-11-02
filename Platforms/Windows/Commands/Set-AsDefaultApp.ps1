[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $ProgramPath,
    [Parameter()]
    [string[]]
    $Extensions,
    [Parameter()]
    [switch]
    $Machine
)

$global:programName = $ProgramPath;
if (Test-Path -LiteralPath $ProgramPath ) {
    $global:programName = Split-Path -Path $ProgramPath -Leaf
}

$classPath = "HKEY_CURRENT_USER\Software\Classes";
if ($Machine) {
    $classPath = "HKEY_LOCAL_MACHINE\Software\Classes";
}

$fileExtsPath = "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts";
$toastsPath = "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts";

# Register the app itself so it shows up in the Explorer "Open with" list,
# independent of which ProgID currently owns each extension.
$appKey = "$classPath\Applications\$global:programName";
reg add "$appKey\shell\open\command" /d """$ProgramPath"" ""%1""" /f | Out-Null;

$Extensions | ForEach-Object {
    $extension = $_.StartsWith(".") ? $_ : ".$_";
    $base = $classPath;

    reg add "$appKey\SupportedTypes" /v $extension /d "" /f | Out-Null;

    $progId = "$global:programName$extension";
    reg add "$base\$extension" /d $progId /f | Out-Null;
    reg add "$base\$extension\OpenWithProgids" /v $progId /d "" /f | Out-Null;
    reg add "$base\$progId\DefaultIcon" /d """$ProgramPath"",0" /f | Out-Null;
    $key = "$base\$progId\shell\open\command";
    reg add $key /d """$ProgramPath"" ""%1""" /f | Out-Null;

    # Explorer prefers the per-user UserChoice (hash protected) over the Classes default,
    # so drop it to make Windows fall back to the ProgID registered above.
    $fileExtKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("$fileExtsPath\$extension", $true);
    if ($fileExtKey) {
        foreach ($choice in "UserChoice", "UserChoiceLatest") {
            try { $fileExtKey.DeleteSubKeyTree($choice, $false) }
            catch { Write-Warning "Could not remove $choice for ${extension}: $($_.Exception.Message)" }
        }
        $fileExtKey.Close();
    }

    # Mark every handler of the extension as already "seen", otherwise Windows shows the
    # "How do you want to open this file?" picker the first time each extension is opened.
    $handlers = @("Applications\$global:programName", $progId);
    $classesExt = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey("$extension\OpenWithProgids");
    if ($classesExt) { $handlers += $classesExt.GetValueNames(); $classesExt.Close() }
    $userExt = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("$fileExtsPath\$extension\OpenWithProgids");
    if ($userExt) { $handlers += $userExt.GetValueNames(); $userExt.Close() }
    $handlers | Where-Object { $_ } | Select-Object -Unique | ForEach-Object {
        reg add $toastsPath /v "${_}_$extension" /t REG_DWORD /d 0 /f | Out-Null;
    }
}

# Tell Explorer the associations changed (SHCNE_ASSOCCHANGED).
if (-not ("ShellNotify" -as [type])) {
    Add-Type -Namespace "" -Name ShellNotify -MemberDefinition @'
[DllImport("shell32.dll")]
public static extern void SHChangeNotify(int eventId, uint flags, System.IntPtr item1, System.IntPtr item2);
'@
}
[ShellNotify]::SHChangeNotify(0x08000000, 0, [System.IntPtr]::Zero, [System.IntPtr]::Zero);

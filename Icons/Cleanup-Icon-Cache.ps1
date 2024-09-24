Run-As-Admin.ps1;
ie4uinit -show;
taskkill /IM explorer.exe /F;
Start-Process explorer.exe;
DEL /A /Q "$($env:LOCALAPPDATA)\IconCache.db"
DEL /A /F /Q "$($env:LOCALAPPDATA)\Microsoft\Windows\Explorer\iconcache*"
DEL /F /S /Q "$($env:LOCALAPPDATA)\Packages\Microsoft.Windows.Search_cw5n1h2txyewy\localstate\AppIconCache\*.*";

# Do it once in a while
# Dism /Online /Cleanup-Image /CheckHealth
# Dism /Online /Cleanup-Image /ScanHealth
# DISM /Online /Cleanup-Image /RestoreHealth
# sfc /scannow
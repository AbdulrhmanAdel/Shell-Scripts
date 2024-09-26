Run-AsAdmin.ps1;
ie4uinit -show;
taskkill /IM explorer.exe /F;
Start-Process explorer.exe;
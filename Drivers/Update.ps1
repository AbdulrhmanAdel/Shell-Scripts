$windowsVersion = [Environment]::OSVersion.Version -ge (new-object 'Version' 9, 1)?  "windows11" : "win8-win7";
$windowsArchitecture = [Environment]::Is64BitOperatingSystem?  "64bit" : "32bit";

# Generating the download link
$options = @(
    @{
        Key     = "Nvidia"
        Callback = {
            & "$($PSScriptRoot)/Modules/Nvidia.ps1" -OsVersion $windowsVersion -OsArchitecture $windowsArchitecture
        }
    }
)

Multi-Options-Selector.ps1 -options $options | ForEach-Object {
    Write-Host "Updating $($_.Name) driver" 
    $_.Callback.Invoke();
};

exit;

# This script is designed to install the bare essential Nvidia drivers
# This will not install Nvidia GeForce or Shadowplay
# There are options below for customizing the install
# The defaults should suffice for most users

# $scheduleTask = $false  # Creates a Scheduled Task to run to check for driver updates
# $scheduleDay = "Sunday" # When should the scheduled task run (Default = Sunday)
# $scheduleTime = "12pm"  # The time the scheduled task should run (Default = 12pm)


# # Checking if 7zip or WinRAR are installed
# # Check 7zip install path on registry
# $7zipinstalled = $false 
# if ((Test-path HKLM:\SOFTWARE\7-Zip\) -eq $true) {
#     $7zpath = Get-ItemProperty -path  HKLM:\SOFTWARE\7-Zip\ -Name Path
#     $7zpath = $7zpath.Path
#     $7zpathexe = $7zpath + "7z.exe"
#     if ((Test-Path $7zpathexe) -eq $true) {
#         $archiverProgram = $7zpathexe
#         $7zipinstalled = $true 
#     }    
# }
# elseif ($7zipinstalled -eq $false) {
#     if ((Test-path HKLM:\SOFTWARE\WinRAR) -eq $true) {
#         $winrarpath = Get-ItemProperty -Path HKLM:\SOFTWARE\WinRAR -Name exe64 
#         $winrarpath = $winrarpath.exe64
#         if ((Test-Path $winrarpath) -eq $true) {
#             $archiverProgram = $winrarpath
#         }
#     }
# }
# else {
#     Write-Host "Sorry, but it looks like you don't have a supported archiver."
#     Write-Host ""
#     while ($choice -notmatch "[y|n]") {
#         $choice = read-host "Would you like to install 7-Zip now? (Y/N)"
#     }
#     if ($choice -eq "y") {
#         # Download and silently install 7-zip if the user presses y
#         $7zip = "https://www.7-zip.org/a/7z1900-x64.exe"
#         $output = "$PSScriptRoot\7Zip.exe"
#         (New-Object System.Net.WebClient).DownloadFile($7zip, $output)
       
#         Start-Process "7Zip.exe" -Wait -ArgumentList "/S"
#         # Delete the installer once it completes
#         Remove-Item "$PSScriptRoot\7Zip.exe"
#     }
#     else {
#         Write-Host "Press any key to exit..."
#         $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
#         exit
#     }
# }
   


# # Checking currently installed driver version
# Write-Host "Attempting to detect currently installed driver version..."
# try {
#     $VideoController = Get-WmiObject -ClassName Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" }
#     $ins_version = ($VideoController.DriverVersion.Replace('.', '')[-5..-1] -join '').insert(3, '.')
# }
# catch {
#     Write-Host -ForegroundColor Yellow "Unable to detect a compatible Nvidia device."
#     Write-Host "Press any key to exit..."
#     $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
#     exit
# }
# Write-Host "Installed version `t$ins_version"


# # Checking latest driver version
# $uri = 'https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php' +
# '?func=DriverManualLookup' +
# '&psid=120' + # Geforce RTX 30 Series
# '&pfid=929' +  # RTX 3080
# '&osID=57' + # Windows 10 64bit
# '&languageCode=1033' + # en-US; seems to be "Windows Locale ID"[1] in decimal
# '&isWHQL=1' + # WHQL certified
# '&dch=1' + # DCH drivers (the new standard)
# '&sort1=0' + # sort: most recent first(?)
# '&numberOfResults=1' # single, most recent result is enough

# #[1]: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/a9eac961-e77d-41a6-90a5-ce1a8b0cdb9c

# $response = Invoke-WebRequest -Uri $uri -Method GET -UseBasicParsing
# $payload = $response.Content | ConvertFrom-Json
# $version =  $payload.IDS[0].downloadInfo.Version
# Write-Output "Latest version `t`t$version"


# # Comparing installed driver version to latest driver version from Nvidia
# if (!$clean -and ($version -eq $ins_version)) {
#     Write-Host "The installed version is the same as the latest version."
#     Write-Host "Press any key to exit..."
#     $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
#     exit
# }


# # Checking Windows version
# if ([Environment]::OSVersion.Version -ge (new-object 'Version' 9, 1)) {
#     $windowsVersion = "win10-win11"
# }
# else {
#     $windowsVersion = "win8-win7"
# }


# # Checking Windows bitness
# if ([Environment]::Is64BitOperatingSystem) {
#     $windowsArchitecture = "64bit"
# }
# else {
#     $windowsArchitecture = "32bit"
# }


# # Create a new temp folder NVIDIA
# $nvidiaTempFolder = "$folder\NVIDIA"
# New-Item -Path $nvidiaTempFolder -ItemType Directory 2>&1 | Out-Null


# # Generating the download link
# $url = "https://international.download.nvidia.com/Windows/$version/$version-desktop-$windowsVersion-$windowsArchitecture-international-dch-whql.exe"
# $rp_url = "https://international.download.nvidia.com/Windows/$version/$version-desktop-$windowsVersion-$windowsArchitecture-international-dch-whql-rp.exe"


# # Downloading the installer
# $dlFile = "$nvidiaTempFolder\$version.exe"
# Write-Host "Downloading the latest version to $dlFile"
# Start-BitsTransfer -Source $url -Destination $dlFile

# if ($?) {
#     Write-Host "Proceed..."
# }
# else {
#     Write-Host "Download failed, trying alternative RP package now..."
#     Start-BitsTransfer -Source $rp_url -Destination $dlFile
# }

# # Extracting setup files
# $extractFolder = "$nvidiaTempFolder\$version"
# $filesToExtract = "Display.Driver HDAudio NVI2 PhysX EULA.txt ListDevices.txt setup.cfg setup.exe"
# Write-Host "Download finished, extracting the files now..."

# if ($7zipinstalled) {
#     Start-Process -FilePath $archiverProgram -NoNewWindow -ArgumentList "x -bso0 -bsp1 -bse1 -aoa $dlFile $filesToExtract -o""$extractFolder""" -wait
# }
# elseif ($archiverProgram -eq $winrarpath) {
#     Start-Process -FilePath $archiverProgram -NoNewWindow -ArgumentList 'x $dlFile $extractFolder -IBCK $filesToExtract' -wait
# }
# else {
#     Write-Host "Something went wrong. No archive program detected. This should not happen."
#     Write-Host "Press any key to exit..."
#     $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
#     exit
# }


# # Remove unneeded dependencies from setup.cfg
# (Get-Content "$extractFolder\setup.cfg") | Where-Object { $_ -notmatch 'name="\${{(EulaHtmlFile|FunctionalConsentFile|PrivacyPolicyFile)}}' } | Set-Content "$extractFolder\setup.cfg" -Encoding UTF8 -Force


# # Installing drivers
# Write-Host "Installing Nvidia drivers now..."
# $install_args = "-passive -noreboot -noeula -nofinish -s"
# if ($clean) {
#     $install_args = $install_args + " -clean"
# }
# Start-Process -FilePath "$extractFolder\setup.exe" -ArgumentList $install_args -wait


# # Creating a scheduled task if the $scheduleTask varible is set to TRUE
# if ($scheduleTask) {
#     Write-Host "Creating A Scheduled Task..."
#     New-Item C:\Task\ -type directory 2>&1 | Out-Null
#     Copy-Item .\Nvidia.ps1 -Destination C:\Task\ 2>&1 | Out-Null
#     $taskname = "Nvidia-Updater"
#     $description = "Update Your Driver!"
#     $action = New-ScheduledTaskAction -Execute "C:\Task\Nvidia.ps1"
#     $trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval $scheduleTask -DaysOfWeek $scheduleDay -At $scheduleTime
#     Register-ScheduledTask -TaskName $taskname -Action $action -Trigger $trigger -Description $description 2>&1 | Out-Null
# }


# # Cleaning up downloaded files
# Write-Host "Deleting downloaded files"
# Remove-Item $nvidiaTempFolder -Recurse -Force


# # Driver installed, requesting a reboot
# Write-Host -ForegroundColor Green "Driver installed. You may need to reboot to finish installation."
# Write-Host "Would you like to reboot now?"
# $Readhost = Read-Host "(Y/N) Default is no"
# Switch ($ReadHost) {
#     Y { Write-host "Rebooting now..."; Start-Sleep -s 2; Restart-Computer }
#     N { Write-Host "Exiting script in 5 seconds."; Start-Sleep -s 5 }
#     Default { Write-Host "Exiting script in 5 seconds"; Start-Sleep -s 5 }
# }


# # End of script
# exit
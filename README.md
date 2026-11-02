# Shell-Scripts

A large collection of PowerShell scripts for automating and enhancing Windows workflows for my personal usage, media management, subtitle processing, file operations, and more.

---

## 📁 Repository Structure

- **Attributes/**: View and change file/folder attributes.
- **Courses/**: Scripts for organizing and fixing course video files.
- **Crawlers/**: Download and scrape from various sources.
- **Downloaders/**: Download utilities for different services.
- **Drivers/**: Driver management and updates.
- **Icons/**: Icon conversion, cache refresh, and folder icon management.
- **Media/**: Video/audio/image compression, chapter handling, file renaming, and more.
- **NativeHosts/**: Native messaging hosts for browser extensions (Integrate with my extensions' project).
- **Playground/**: Experimental scripts.
- **Shared/**: Common utilities (encoding, renaming, extension communication, etc.).
- **Socials/**: Social media-related scripts.
- **Subtitles/**: Subtitle downloaders, translators, editors, converters, and renamers.
- **Tools/**: General utilities (hashing, copying, syncing, ownership, etc.).
- **Torrent/**: Torrent file utilities.
- **Platforms/Windows/**: Windows setup, tweaks, and package installation, plus the Windows version of the commands in `Platforms/Windows/Commands`.
- **Platforms/Linux/**: The Linux version of the commands in `Platforms/Linux/Commands`.
- **Youtube/**: YouTube downloaders and helpers.

---
## Cross-platform commands

Scripts call shared commands by name (`File-Picker.ps1`, `Run-AsAdmin.ps1`), and `ShellScripts.psm1` decides which file that name runs:

- `Shared/`: one script that works on every OS.
- `Platforms/Windows/Commands/`, `Platforms/Linux/Commands/`, `Platforms/Mac/Commands/`: only the folder of the current OS is loaded. A command that differs per OS has a file with the same name and parameters in each folder.

Run `Setup-EnvironmentVariable.ps1` once on each machine to link the module. Mac has no commands yet.

---
## 🖼️ Folder Icon Converter: [`Icons/Convert-PngToIco.ps1`](Icons/Convert-PngToIco.ps1)

This script converts PNG images to ICO format, making it easy to set custom folder icons in Windows.

## Example usage:

### **How It Works**

1. **Input**:
    - ImagePath* `.png` path you want to convert to `.ico`.
    - SavePath the save to save the converted `.ico` file.

2. **Processing**:
    - The script reads the PNG file using Bitmap
    - It resizes the image to standard icon sizes (16x16, 32x32, 48x48, 64x64, 128x128, 256x256).
    - It setup ico file structure then strats to write the resized images into the ICO file.
    - Save the ICO stream into a file with the `.ico` extension using the savePath provied.

3. **Output**:
    - You get a `.ico` file for each PNG, ready to be used as a folder icon in Windows.

### **Usage**

```powershell
pwsh Icons/Convert-Png-To-Ico.ps1 "Path\To\Image.png"
```

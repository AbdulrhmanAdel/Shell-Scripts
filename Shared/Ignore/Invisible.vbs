' Set objShell = CreateObject("Wscript.Shell")

' objShell.Run $"powershell.exe -File ""{WScript.Arguments(0)}""", 0, True


' Option Explicit
Dim fso, mainLockFile, argFile, scriptArgs, objFile

' File paths for the lock and argument files
Set fso = CreateObject("Scripting.FileSystemObject")
mainLockFile = "D:\Temp\main_script.lock"
argFile = "D:\Temp\args.txt"
scriptArgs = ""

' Check if the main script is running (lock file exists)
If fso.FileExists(mainLockFile) Then
' Another script is already running; pass arguments and exit
    scriptArgs = Join(WScript.Arguments, " ")
    Set objFile = fso.OpenTextFile(argFile, 8, True) ' Append mode
    objFile.WriteLine scriptArgs
    objFile.WriteLine WScript.Arguments(0)
    objFile.Close
    WScript.Quit
Else
' Create the lock file to mark as the main script
    Set objFile = fso.CreateTextFile(mainLockFile, True)
    objFile.Close
End If

WScript.Sleep 5000
' Main script code - read all arguments from the temp file and process
Do While fso.FileExists(argFile)
    Set objFile = fso.OpenTextFile(argFile, 1, False) ' Read mode
    Do Until objFile.AtEndOfStream
        WScript.Echo objFile.ReadLine() ' Replace with your processing logic
    Loop
    objFile.Close
    fso.DeleteFile argFile
Loop

' Clean up by deleting the lock file when done
fso.DeleteFile mainLockFile
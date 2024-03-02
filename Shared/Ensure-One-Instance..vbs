Dim fso, file, scriptDir, scriptPath, textFileName, textFile, data
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
textFileName = WScript.Arguments(1)
textFilePath = scriptDir & "/" & textFileName & ".txt"
data = WScript.Arguments(2)

if fso.FileExists(textFilePath) Then
    Dim attempt, maxAttempts, sleepDuration
    maxAttempts = 5
    sleepDuration = 1000 ' Milliseconds
    attempt = 0
    Do Until attempt >= maxAttempts
        On Error Resume Next ' Enable error handling
        Set file = fso.OpenTextFile(textFilePath, 8, True)
        If Err.Number = 0 Then
            Set file = fso.OpenTextFile(textFilePath, 8)
            file.WriteLine(data)
            file.Close
            Exit Do
        Else
            Err.Clear
            attempt = attempt + 1
            WScript.Sleep sleepDuration ' Wait before retrying
        End If
        On Error GoTo 0 ' Disable error handling
    Loop
else
    Set file = fso.OpenTextFile(textFilePath, 2,True)
    file.WriteLine(data)
    file.Close
    MsgBox "waiting for data"
    WScript.Sleep 10000
    Dim content
    Set file = fso.OpenTextFile(textFilePath, 1)
    content = file.ReadAll()
    file.Close
    MsgBox "Done Wating" & content
    fso.DeleteFile textFilePath, True

    Dim objShell
    Set objShell = CreateObject("WScript.Shell")

    ' PowerShell command to execute
    Dim psCommand
    psCommand = "powershell.exe -NoProfile -Command ""New-Item -Path 'C:\temp\test.txt' -ItemType File -Value 'Hello from PowerShell'"""

    ' Run the PowerShell command
    objShell.Run psCommand, 0, True

    Set objShell = Nothing
end if
Set fso = Nothing
Set file = Nothing

Option Explicit

Dim fileSystem, shell, projectRoot, scriptPath, powershellPath, command, exitCode

Set fileSystem = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

projectRoot = fileSystem.GetParentFolderName(WScript.ScriptFullName)
scriptPath = fileSystem.BuildPath(projectRoot, "LightsOut.ps1")
powershellPath = shell.ExpandEnvironmentStrings("%SystemRoot%") & _
    "\System32\WindowsPowerShell\v1.0\powershell.exe"

command = Quote(powershellPath) & _
    " -NoProfile -NonInteractive -ExecutionPolicy Bypass -File " & _
    Quote(scriptPath)

exitCode = shell.Run(command, 0, True)
WScript.Quit exitCode

Function Quote(value)
    Quote = Chr(34) & value & Chr(34)
End Function

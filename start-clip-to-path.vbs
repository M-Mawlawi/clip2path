' Starts clip-to-path.ps1 hidden (no console window).
' Keep this file in the same folder as clip-to-path.ps1.
' For auto-start: Win+R -> shell:startup -> put a shortcut to this file there.
' Running your tool inside WSL? Add  -Wsl  after the .ps1 path below.
Set fso = CreateObject("Scripting.FileSystemObject")
dir = fso.GetParentFolderName(WScript.ScriptFullName)
CreateObject("WScript.Shell").Run "powershell.exe -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & dir & "\clip-to-path.ps1""", 0, False

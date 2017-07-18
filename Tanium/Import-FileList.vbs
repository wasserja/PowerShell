Set objFSO = CreateObject("Scripting.FileSystemObject")
FileListLog = "C:\Logs\FileList.log"
Set objFileListLog = objFSO.OpenTextFile(FileListLog)
Wscript.Echo objFileListLog.ReadAll
objFileListLog.Close
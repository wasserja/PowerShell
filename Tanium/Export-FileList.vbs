Set objFSO = CreateObject("Scripting.FileSystemObject")

objStartFolder = Wscript.Arguments(0)
FileListLog = "C:\Logs\FileList.log"
Set objFileListLog = objFSO.CreateTextFile(FileListLog, True)

Set objFolder = objFSO.GetFolder(objStartFolder)

Set colFiles = objFolder.Files

For Each objFile in colFiles

    'Wscript.Echo objFile.Path
    objFileListLog.WriteLine objFile.Path

Next


ShowSubfolders objFSO.GetFolder(objStartFolder)


Sub ShowSubFolders(Folder)

    For Each Subfolder in Folder.SubFolders

        Set objFolder = objFSO.GetFolder(Subfolder.Path)

        Set colFiles = objFolder.Files

        For Each objFile in colFiles

            'Wscript.Echo objFile.Path
            objFileListLog.WriteLine objFile.Path

        Next

        ShowSubFolders Subfolder

    Next

End Sub
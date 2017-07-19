Add-Type -AssemblyName System.Web
[string]$Folder = [System.Web.HttpUtility]::UrlDecode("||Folder||")
[bool]$Recurse = $true
[string]$LogPath = 'C:\Logs'

if (!(Test-Path -Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory | Out-Null
}
$FileListLog = $LogPath + '\FileList.log'

if ($Recurse) {
    Write-Verbose -Message "Recursively logging all files from $Folder to $FileListLog"
    Get-ChildItem -Path $Folder -Recurse | Select-Object -ExpandProperty FullName | Out-File -FilePath $FileListLog
}
else {
    Write-Verbose -Message "Logging all files from $Folder to $FileListLog"
    Get-ChildItem -Path $Folder | Select-Object -ExpandProperty FullName | Out-File -FilePath $FileListLog
}

Write-Output "File list has been saved to $FileListLog."
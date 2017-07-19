[CmdletBinding()]
param (
    [ValidateScript( {Test-Path -Path $_ -PathType Container})]    
    [string]$Folder = 'C:\Windows\system32\drivers\etc',
    [bool]$Recurse = $true,
    [ValidateScript( {Test-Path -Path $_ -PathType Container})]
    [string]$LogPath = 'C:\Logs'
        
)
    
begin {
    $FileListLog = $LogPath + '\FileListLog.log'
}
    
process {

    
    if ($Recurse) {
        Write-Verbose -Message "Recursively logging all files from $Folder to $FileListLog"
        Get-ChildItem -Path $Folder -Recurse | Select-Object -ExpandProperty FullName | Out-File -FilePath $FileListLog
    }
    else {
        Write-Verbose -Message "Logging all files from $Folder to $FileListLog"
        Get-ChildItem -Path $Folder | Select-Object -ExpandProperty FullName | Out-File -FilePath $FileListLog
    }
    Start-Process -FilePath $FileListLog

}
    
end {
}

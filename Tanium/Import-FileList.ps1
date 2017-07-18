[CmdletBinding()]
param (
    [ValidateScript( {Test-Path -Path $_})]    
    [string]$FileListLog = 'C:\Logs\FileListLog.log'    
        
)
    
begin {
}
    
process {

    
    Get-Content -Path $FileListLog | Get-Item

}
    
end {
}


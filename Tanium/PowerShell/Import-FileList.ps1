[CmdletBinding()]
param (
    [ValidateScript( {Test-Path -Path $_})]    
    [string]$FileListLog = 'C:\Logs\FileList.log'    
        
)
    
begin {
}
    
process {

    
    Get-Content -Path $FileListLog | Get-Item

}
    
end {
}


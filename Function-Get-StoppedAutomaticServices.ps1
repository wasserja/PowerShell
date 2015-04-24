<#
.Synopsis
   This script checks a remote computer using WMI for any Automatic services that are not running.
.DESCRIPTION
   The script makes a WMI query for all services that have an Automatic start mode, but are stopped. 
   This is useful for checking servers after patching for any services that didn't start automatically.
.NOTES
   By: Jason Wasser
   Modified: 4/24/2015 03:24:50 PM 
   Changelog:
    * Cleanup script to output actual service objects.
.PARAMETER ComputerName
   Enter the name of a computer or a list of computers. Accepts pipeline input. Default: localhost.
.PARAMETER FilterCleanExit
   Use to automatically exclude services which start but then exit because they have nothing else 
   to do (or are trigger start). Use this switch if you need to filter out services that stopped 
   cleanly with an exit code 0. 
.PARAMETER ExclusionList
   Service names that should be excluding from the query. A default list of known services that are set to 
   Automatic but do not run (i.e. Performance Logs and Alerts) is provided.
.EXAMPLE
   Get-StoppedAutomaticService -ComputerName server1
   Lists the stopped automatic services from server1.
.EXAMPLE
   Get-StoppedAutomaticService -ComputerName server1,server2
   Lists the stopped automatic services from server1 and server2.
.EXAMPLE
   Get-StoppedAutomaticService -ComputerName (Get-Content c:\temp\computerlist.txt)
   Lists the stopped automatic services from a list of computers in a text file.
.EXAMPLE
   Get-StoppedAutomaticService -FilterCleanExit
   Get a list of stopped automatic services that exited cleanly. This should exclude services that do start,
   but have no further work to do (includes Trigger Start)
.EXAMPLE
   Get-Content C:\Temp\serverlist.txt | Get-StoppedAutomaticService | Start-Service
#>
Function Get-StoppedAutomaticService {
    [CmdletBinding()]
    [OutputType([System.ServiceProcess.ServiceController])]
    param
    (
	    [Parameter(Mandatory=$false,
		    ValueFromPipeLine=$true,
		    ValueFromPipeLineByPropertyName=$true)]
	    [string[]]$ComputerName = $env:COMPUTERNAME,
        
        # Filter services with exit code 0
        [Parameter(Mandatory=$false,
            ValueFromPipeLine=$false,
		    ValueFromPipeLineByPropertyName=$true)]
        [switch]$FilterCleanExit,
        

        $ExclusionList = @('clr_optimization_v4.0.30319_32','clr_optimization_v4.0.30319_64','SysmonLog','ShellHWDetection','sppsvc','gupdate','MMCSS','RemoteRegistry','ccmsetup')
    )
    begin{}
    process {
        foreach ($Computer in $ComputerName) {
            try {
                $hostdns = [System.Net.DNS]::GetHostEntry($Computer)
                } 
            catch [Exception] {
                Write-Error "$($_.Exception.Message) $Computer."
                return
                }
            Write-Verbose "Checking services on $computer"
            write-Verbose "Exclusion List:"
            $ExclusionList | ForEach-Object {Write-Verbose " * $_"}
            if ($FilterCleanExit) {
                $StoppedAutomaticService = Get-WmiObject -Class win32_service -ComputerName $computer -Filter "state = 'stopped' and startmode = 'auto' and exitcode != 0" | 
                Where-Object { $ExclusionList -notcontains $_.name }
                }
            else {
                $StoppedAutomaticService = Get-WmiObject -Class win32_service -ComputerName $computer -Filter "state = 'stopped' and startmode = 'auto'" | 
                Where-Object { $ExclusionList -notcontains $_.name }
                }
            if ( $StoppedAutomaticService ) {
                Write-Verbose "Services needing attention:"
                $StoppedAutomaticService | ForEach-Object {Write-Verbose " * $($_.DisplayName)"}
                $StoppedAutomaticServiceObject = @()
                $StoppedAutomaticServiceObject += Get-Service $StoppedAutomaticService.name -ComputerName $StoppedAutomaticService.PSComputerName
                $StoppedAutomaticServiceObject
                # 
                }
            else {
                Write-Verbose "$Computer`: All services ok."
                }
            }
        }
    end {}
}
<#
.Synopsis
   This script checks a remote computer using WMI for any Automatic services that are not running.
.DESCRIPTION
   The script makes a WMI query for all services that have an Automatic start mode, but are stopped. 
   This is useful for checking servers after patching for any services that didn't start automatically.

   The $ExclusionList is an array that should be added to for any service you wish to ignore.

   $FilterCleanExit can be used to automatically exclude services which start but then exit 
   because they have nothing else to do (or are trigger start).
.NOTES
   By: Jason Wasser
   Modified: 4/24/2015 03:24:50 PM 
   Changelog:
    * Cleanup script to output actual service objects.

.EXAMPLE
   .\Get-StoppedAutomaticServices.ps1 -ComputerName server1
   Lists the stopped automatic services from server1.
.EXAMPLE
   .\Get-StoppedAutomaticServices.ps1 -ComputerName server1,server2
   Lists the stopped automatic services from server1 and server2.
.EXAMPLE
   .\Get-StoppedAutomaticServices.ps1 -ComputerName (Get-Content c:\temp\computerlist.txt)
   Lists the stopped automatic services from a list of computers in a text file.
.EXAMPLE
   .\Get-StoppedAutomaticServices.ps1 -FilterCleanExit
   Get a list of stopped automatic services that exited cleanly. This should exclude services that do start,
   but have no further work to do (includes Trigger Start)
#>
Function Get-StoppedAutomaticServices {
    [CmdletBinding()]
    [OutputType([System.ServiceProcess.ServiceController])]
    param
    (
	    [Parameter(Mandatory=$false,
		    ValueFromPipeLine=$true,
		    ValueFromPipeLineByPropertyName=$true)]
	    [string[]]$ComputerName = $env:COMPUTERNAME,
        [Parameter(Mandatory=$false,
            ValueFromPipeLine=$false,
		    ValueFromPipeLineByPropertyName=$true)]
        [switch]$FilterCleanExit
    )
    begin{
        #Exclusions List - list of known services that are set to Auto but do not run (i.e. Performance Logs and Alerts)
        $ExclusionList = @('clr_optimization_v4.0.30319_32','clr_optimization_v4.0.30319_64','SysmonLog','ShellHWDetection','sppsvc','gupdate','MMCSS','RemoteRegistry','ccmsetup')
    }
    process {
        foreach ($Computer in $ComputerName) {
            try {
                $hostdns = [System.Net.DNS]::GetHostEntry($Computer)
                } 
            catch [Exception] {
                Write-Error "$($_.Exception.Message) $Computer."
                return
                }
            Write-Verbose "Checking services on $computer using exclusion list:"
            $ExclusionList | ForEach-Object {Write-Verbose $_}
            if ($FilterCleanExit) {
                $stoppedautoservices = Get-WmiObject win32_service -computername $computer -filter "state = 'stopped' and startmode = 'auto' and exitcode != 0" | 
                Where-Object { $ExclusionList -notcontains $_.name }
                }
            else {
                $stoppedautoservices = Get-WmiObject win32_service -computername $computer -filter "state = 'stopped' and startmode = 'auto'" | 
                Where-Object { $ExclusionList -notcontains $_.name }
                }
            if ( $stoppedautoservices ) {
                Write-Verbose "Services needing attention:"
                Write-Verbose $($stoppedautoservices | Select-Object -Property PSComputerName,Name,DisplayName,startmode,state,exitcode | Format-Table –autosize)
                $stoppedautoservices
                Write-Verbose "To start the service type: "
                Write-Verbose "Invoke-Command -computername servername {start-service nameofservice}"
                if ( $stoppedautoservices.count ) {
                    foreach ($stoppedautoservice in $stoppedautoservices) {
                        Write-Verbose "example: Invoke-Command -computername $computer {start-service $($stoppedautoservice.name)}"
                        }
                    }
                else {
                    $examplecomputer = $stoppedautoservices.__SERVER
                    $exampleservice = $stoppedautoservices.name
                    Write-Verbose "Example: Invoke-Command -computername $examplecomputer {start-service $exampleservice}"
                    }
                }
            else {
                Write-Host "$Computer`: All services ok."
                }
        }
        }
    end {}
}
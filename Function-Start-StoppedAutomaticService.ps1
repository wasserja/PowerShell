<#
.Synopsis
   This script starts any stopped Automatic services with exclusions.
.DESCRIPTION
   The script defaults to check the localhost for any stopped Automatic services and
   starts them. It can also run against a single remote computer or a list of remote 
   computers. The script will first check to see if ws-man remoting is enabled, and
   if it isn't it will fall back to using the sc.exe utility to start the services.
   The script assumes you have administrative rights on the remote computer.

   The $FilterCleanExit switch is for excluding any services that have an exit
   code of zero which typically means services that have nothing to do or were
   stopped gracefully.

   Created by: Jason Wasser
   Modified: 4/27/2015 09:17:32 AM 
   Version 1.2

   Changelog:
    * Re-write to use new Get-StoppedAutomaticService function

.EXAMPLE
   Start-StoppedAutomaticServices
   Starts any stopped automatic services on the local machine.
.EXAMPLE
   Start-StoppedAutomaticServices.ps1 -ComputerName server23
   Starts any stopped automatic services on server23
.EXAMPLE
   Start-StoppedAutomaticServices.ps1 -ComputerName (Get-Content c:\temp\computerlist.txt) -FilterCleanExit
   Starts any stopped automatic services on a list of computers in the text file c:\temp\computerlist.txt and 
   excludes any services that were cleanly stopped.
#>
Function Start-StoppedAutomaticService {
    [CmdletBinding()]
    [Alias()]
    [OutputType([System.ServiceProcess.ServiceController])]
    Param
    (
        # The computer name on which you wish to start services.
        [Parameter(Mandatory=$false,
                    ValueFromPipeLine=$true,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
        [string[]]$ComputerName=$env:COMPUTERNAME,

        # Exclude stopped services with an exit code 0.
        [Parameter(Mandatory=$false,
                    ValueFromPipeLine=$false,
                    ValueFromPipeLineByPropertyName=$true)]
        [switch]$FilterCleanExit
    )

    Begin
    {
    }
    Process
    {
        foreach ($Computer in $ComputerName) {
            if ($FilterCleanExit) {
                Get-StoppedAutomaticService -ComputerName $Computer -FilterCleanExit | Start-Service
                }
            else {
                Get-StoppedAutomaticService -ComputerName $Computer | Start-Service
                }
            
        }
    }
    End
    {
    }
}
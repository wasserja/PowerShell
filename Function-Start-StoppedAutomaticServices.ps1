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
   Modified: 3/20/2015 04:03:41 PM 
   Version 1.1

   Changelog:
    * Changed $ComputerName to be an array of strings

   TODO:
    * verify the services have actually started. - create a function to reuse code and 
      keep it clean.

.EXAMPLE
   Start-StoppedAutomaticServices.ps1
   Starts any stopped automatic services on the local machine.
.EXAMPLE
   Start-StoppedAutomaticServices.ps1 -ComputerName server23
   Starts any stopped automatic services on server23
.EXAMPLE
   Start-StoppedAutomaticServices.ps1 -ComputerName (Get-Content c:\temp\computerlist.txt) -FilterCleanExit
   Starts any stopped automatic services on a list of computers in the text file c:\temp\computerlist.txt and 
   excludes any services that were cleanly stopped.
#>
Function Start-StoppedAutomaticServices {
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
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
        #Exclusions List - list of known services that are set to Auto but do not run (i.e. Performance Logs and Alerts)
        $ExclusionList = @('clr_optimization_v4.0.30319_32','clr_optimization_v4.0.30319_64','SysmonLog','ShellHWDetection','sppsvc','gupdate','MMCSS','RemoteRegistry','ccmsetup','wuauserv')
    }
    Process
    {
        foreach ($Computer in $ComputerName) {
            try {
                $hostdns = [System.Net.DNS]::GetHostEntry($Computer)
                } 
            catch [Exception] {
                Write-Error "$($_.Exception.Message) $Computer."
                return
                }
            Write-Output "***********************************************************"
            Write-Output "Checking services on $Computer using exclusion list:"
            Write-Output $ExclusionList
            Write-Output ""
            if ($FilterCleanExit) {
                $stoppedautoservices = Get-WmiObject win32_service -computername $Computer -filter "state = 'stopped' and startmode = 'auto' and exitcode != 0" | 
                Where-Object { $ExclusionList -notcontains $_.name }
                }
            else {
                $stoppedautoservices = Get-WmiObject win32_service -computername $Computer -filter "state = 'stopped' and startmode = 'auto'" | 
                Where-Object { $ExclusionList -notcontains $_.name }
                }
            if ( $stoppedautoservices ) {
                Write-Output "Services needing attention:"
                $stoppedautoservices | Format-Table __SERVER,Name,DisplayName,startmode,state,exitcode -AutoSize
                Write-Output "Starting Services: "
            
                if ( $stoppedautoservices.count ) {
                    foreach ($stoppedautoservice in $stoppedautoservices) {
                        #Write-Output "example: Invoke-Command -computername $computer {start-service $($stoppedautoservice.name)}"
                        Write-Verbose "Checking WS-MAN"
                        try {if (Test-WSMan -ComputerName $computer -ErrorAction Stop) {
                            Write-Output "Starting $($stoppedautoservice.DisplayName) on $computer"
                            Invoke-Command -ComputerName $computer {Start-Service -DisplayName $args[0]} -ArgumentList $stoppedautoservice.DisplayName 
                            # Add Logic here to confirm service is running
                            }
                        }
                        # If PowerShell remoting is not enabled we will use the sc.exe command to cycle the service.
                        catch {
                            Write-Verbose "WS-Man is unavailable. Using sc.exe"
                            Write-Output "Starting $($stoppedautoservice.DisplayName) on $Computer"
                            Invoke-Expression "sc.exe \\$Computer start $($stoppedautoservice.name)"
                            # Add Logic here to confirm service is running
                            }
                        }
                    }
                else {
                    Write-Verbose "Checking WS-MAN"
                    try {if (Test-WSMan -ComputerName $Computer -ErrorAction Stop) {
                        Write-Output "Starting $($stoppedautoservices.DisplayName) on $Computer"
                        Invoke-Command -ComputerName $Computer {Start-Service -DisplayName $args[0]} -ArgumentList $stoppedautoservices.DisplayName 
                        # Add Logic here to confirm service is running
                        }
                    }
                    # If PowerShell remoting is not enabled we will use the sc.exe command to cycle the service.
                    catch {
                        Write-Verbose "WS-Man is unavailable. Using sc.exe"
                        Write-Output "Starting $($stoppedautoservices.DisplayName) on $Computer"
                        Invoke-Expression "sc.exe \\$Computer start $($stoppedautoservices.name)"
                        # Add Logic here to confirm service is running
                        }
                    }
                Write-Output "***********************************************************"
                }
            else {
                write-host "All automatic services are running."
                Write-Output "***********************************************************"
                }
        }
    }
    End
    {
    }
}
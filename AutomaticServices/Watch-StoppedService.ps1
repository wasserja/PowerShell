<#
.Synopsis
   Short description
.DESCRIPTION
   Long description

   Right now the script only accepts a single service name and computer name. 
   I'd like to make it work with multiple service names and/or computer names.
   I'm stuck.

   If I have a more than one service object coming in then I have to go through one at a 
   time in the process block. I don't see a way of doing that.


.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Watch-StoppedService
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ComputerName')]
        [string[]]$MachineName = $env:COMPUTERNAME,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ServiceName')]
        [string[]]$Name = 'wuauserv',
        [int]$SleepTime = 60,
        [Parameter(ValueFromPipeline)]
        [System.ServiceProcess.ServiceController]$Service
    )

    Begin
    {

        $VerbosePreference = 'Continue'

        function Check-ServiceStatus {
            param (
                [Parameter(ValueFromPipelineByPropertyName)]
                [Alias('ComputerName')]
                [string[]]$MachineName,
                [Parameter(ValueFromPipelineByPropertyName)]
                [Alias('ServiceName')]
                [string[]]$Name
                )

            try {
                
                $ServiceStatus = Get-Service -Name $Name -ComputerName $MachineName -ErrorAction Stop
                Write-Verbose "$(Get-Date) Status of Services"
                $ServiceStatus
                <#if ($ServiceStatus.Status -ne 'Stopped' -and $Wait) {
                    Write-Verbose "$(Get-Date) Waiting $SleepTime seconds"
                    Start-Sleep -Seconds $SleepTime
                    }#>
                
                }
            catch {
                Write-Error $Error[0].Exception
                return
                }
            
            }

        function Fix-Service {
            param (
                $StoppedService
                )

            Write-Verbose "$(Get-Date) Starting stopped services"
            $StoppedService | Start-Service
    
            }

    }
    Process
    {
        
        foreach ($Service in $Name) {
            
            #region FirstCheck
        
            # Check to see if the service is already stopped.
            Write-Verbose "$(Get-Date) First check services."
            
            
            $Service = Check-ServiceStatus -Name $Name -MachineName $MachineName
            if ($Service) {
            
                $StoppedService = $Service | Where-Object -FilterScript {$_.Status -eq 'Stopped'}

                if ($StoppedService) {
                    Fix-Service -Name $StoppedService
                    Check-ServiceStatus
                    }
            #endregion

            #region LoopCheck
                else {
    
                    # Loop until it stops
                    do {

                        $Service = Check-ServiceStatus -Wait

                    }
                    until ($Service.Status -eq 'Stopped')

                    Fix-Service
                    Check-ServiceStatus
                    }
            #endregion
                }
            else {
                Write-Verbose "$(Get-Date) Unable to find services"
                return
                }
        
            
            
            }
        


        
    }
    End
    {
    }
}


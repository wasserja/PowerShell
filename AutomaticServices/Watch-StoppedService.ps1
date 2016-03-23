<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
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
        [string]$MachineName = $env:COMPUTERNAME,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ServiceName')]
        [string]$Name = 'wuauserv',
        [int]$SleepTime = 60
    )

    Begin
    {

        $VerbosePreference = 'Continue'

        function Check-ServiceStatus {
            param (
                [string]$ComputerName = $MachineName,
                [string]$ServiceName = $Name,
                [switch]$Wait
                )

            try {
                
                $ServiceStatus = Get-Service -Name $ServiceName -ComputerName $ComputerName -ErrorAction Stop
                Write-Verbose "$(Get-Date) $($ServiceStatus.Name) on $ComputerName is $($ServiceStatus.Status)"
                if ($ServiceStatus.Status -ne 'Stopped' -and $Wait) {
                    Write-Verbose "$(Get-Date) Waiting $SleepTime seconds"
                    Start-Sleep -Seconds $SleepTime
                    }
                $ServiceStatus
                
                }
            catch {
                Write-Error $Error[0].Exception
                return
                }
            
            }

        function Fix-Service {
    
            Write-Verbose "$(Get-Date) Starting $($Service.Name) on $MachineName"
            $Service | Start-Service
    
            }

    }
    Process
    {

        # Check to see if the service is already stopped.
        Write-Verbose "$(Get-Date) First check of $Name on $MachineName."
        $Service = Check-ServiceStatus
        if ($Service) {
            
            if ($Service.Status -eq 'Stopped') {
                Fix-Service
                Check-ServiceStatus
                }

            else {
    
                # Loop until it stops
                do {

                    $Service = Check-ServiceStatus -Wait

                }
                until ($Service.Status -eq 'Stopped')

                Fix-Service
                Check-ServiceStatus
                }

            }
        else {
            Write-Verbose "$(Get-Date) Unable to find $Name on $MachineName"
            return
            }
        
    }
    End
    {
    }
}


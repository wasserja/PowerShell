[CmdletBinding()]
param (
    [string]$Class = 'win32_operatingsystem',
    [string[]]$ComputerName=$env:COMPUTERNAME,
    [string]$Namespace='root\cimv2',
    $Credential = [System.Management.Automation.PSCredential]::Empty
    )

# Try CIM first, fall back on WMI
begin {}
process {
    foreach ($Computer in $ComputerName) {
       # Attempt to use CIM first to gather the data from the remote host. 
       try {
            # If credentials were provided, we have to establish a CIM session.
            if ($Credential) {
                $Session = $null
                $Session = New-CimSession -Name $Computer -ComputerName $Computer -Credential $Credential -ErrorAction Stop
                $Data = Get-CimInstance -Namespace $Namespace -ClassName $Class -CimSession $Session -ErrorAction Stop 
                if ($session) {Remove-CimSession $session}
                }
            # If no credentials were provided assume to use the current logon and do not establish session.
            else {
                $Data = Get-CimInstance -Namespace $Namespace -ClassName $Class -ComputerName $Computer -ErrorAction Stop 
                }
        }
        # If we were unable to get the data using CIM, we're going to attempt to get it through WMI.
        catch {
            Write-Verbose "Unable to connect to $Computer using WSMan protocol. $($Error[0].Exception.Message) Falling back to WMI."
            try {
                $Data = Get-WmiObject -Namespace $Namespace -Class $Class -ComputerName $Computer -ErrorAction Stop
                }
            # If we were unable to get the data through WMI we're going to output an error.
            catch {
                Write-Error "Unable to connect to $Computer using CIM or WMI $($Error[0].Exception)"
                return
                }
            } 
        $Data
        }
    }
end {}
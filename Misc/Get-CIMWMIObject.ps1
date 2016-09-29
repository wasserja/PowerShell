[CmdletBinding()]
param (
    [string]$Class = 'win32_operatingsystem',
    [string[]]$ComputerName=$env:COMPUTERNAME,
    [string]$Namespace='root\cimv2'
    )

# Try CIM first, fall back on WMI
begin {}
process {
    foreach ($Computer in $ComputerName) {
        
       try {
            $Data = Get-CimInstance -Namespace $Namespace -ClassName $Class -ComputerName $Computer -ErrorAction Stop 
        }
        catch {
            Write-Verbose "Unable to connect to $Computer using WSMan protocol. $($Error[0].Exception.Message) Falling back to WMI."
            try {
                $Data = Get-WmiObject -Namespace $Namespace -Class $Class -ComputerName $Computer -ErrorAction Stop
                }
            catch {
                Write-Error "Unable to connect to $Computer using CIM or WMI $($Error[0].Exception)"
                return
                }
            } 
        $Data
        }
    }
end {}
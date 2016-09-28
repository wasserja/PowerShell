param (
    [string]$ClassName = 'win32_operatingsystem',
    [string[]]$ComputerName=$env:COMPUTERNAME,
    $Namespace='root\cimv2'
    )

# Try CIM first, fall back on WMI

try {
    $isWSManAlive = if (Test-WSMan -ComputerName) {
        $Data = Get-CimInstance -Namespace $Namespace -ClassName $ClassName -ComputerName $ComputerName
        } 
    }
catch {
    }
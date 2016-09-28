param (
    [string]$ClassName = 'win32_operatingsystem',
    [string[]]$ComputerName=$env:COMPUTERNAME,
    $Namespace='root\cimv2'
    )

# Try CIM first, fall back on WMI

process {
    foreach ($Computer in $ComputerName) {
        
       try {
            if (Test-WSMan -ComputerName $Computer) {
            $Data = Get-CimInstance -Namespace $Namespace -ClassName $ClassName -ComputerName $Computer
            
            } 
        }
        catch {
            Write-Error $Error[0].Exception
            } 

        $Data
        }
    
    }

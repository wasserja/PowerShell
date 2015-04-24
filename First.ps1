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
function Verb-Noun
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]$ComputerName=$env:COMPUTERNAME,

        # Param2 help description
        [int]
        $Param2
    )

    Begin
    {
    }
    Process
    {
        foreach ($Computer in $ComputerName) {
            Write-Output $Computer
            }
    }
    End
    {
    }
}
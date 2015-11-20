<#
.Synopsis
   This script gets a list of any VM with a checkpoint/snapshot from a System Center Virtual Machine Manager Server.
.DESCRIPTION
   This script gets a list of any VM with a checkpoint/snapshot from a System Center Virtual Machine Manager Server.
.NOTES
   Created by: Jason Wasser
   Modified: 3/26/2015 10:07:19 AM 
.EXAMPLE
   .\Get-SCVMM-CheckPoints.ps1
   Outputs a list of VM's with checkpoints from the local server.
.EXAMPLE
   .\Get-SCVMM-CheckPoints.ps1 -SCVMMServerName scvmm01 -SendEmail
   Outputs a list of VM's with checkpoints from server scvmm01 and sends the report as an email.
#>
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$false,
                   ValuefromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$SCVMMServerName=$env:COMPUTERNAME,
        [string]$SCVMMModulePath="C:\Program Files\Microsoft System Center 2012 R2\Virtual Machine Manager\bin\psModules\virtualmachinemanager\virtualmachinemanager.psd1",

        [switch]$SendEmail,
        # Email Parameters
        [string]$SmtpServer = "smtp.domain.com",
        [string]$ToAddress = "email@domain.com",
        [string]$FromAddress = "automaton@domain.com",
        [string]$Subject = "Automaton Alert $(get-date -Format "MM/dd/yyyy HH:mm") Hyper-V VM Checkpoints",
        [string]$MessageBody = "<br>Sincerely,<br>Your friendly AutoMaton.",
        [string]$Username = "anonymous",
        [string]$Password = "anonymous"
    )

    Begin
    {
        if (Test-Path $SCVMMModulePath ) {
            Import-Module $SCVMMModulePath
            }
        else {
            Write-Error "Unable to find SCVMM PowerShell Module at $SCVMMModulePath"
            exit
            }
    }
    Process
    {
        $SCVMMServer = Get-SCVMMServer -ComputerName $SCVMMServerName
        $Snapshots = Get-SCVMCheckpoint
        if ($Snapshots) {
            $Snapshotsinfo = $Snapshots | Select-Object -Property VM, AddedTime,Name
            $Snapshotsinfo
            
            
            if ($SendEmail) {
                $Snapshotsinfo = $Snapshots | Select-Object -Property VM, AddedTime,Name | ConvertTo-Html
                $MessageBody = $Snapshotsinfo + $MessageBody
            
                # SMTP Authentication
                $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
                $Credential = New-Object System.Management.Automation.PSCredential($Username,$SecurePassword)
                Send-MailMessage -To $ToAddress -From $FromAddress -Subject $Subject -Body $MessageBody -BodyAsHtml -SmtpServer $smtpServer -Credential $Credential 
                }
            
            }
    }
    End
    {
    }
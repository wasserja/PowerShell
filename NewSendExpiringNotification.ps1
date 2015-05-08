##############Variables#################            
$verbose = $false           
$notificationstartday = 10
$sendermailaddress = "no-reply@domain.com"            
$SMTPserver = "smtp-tpa.domain.com"            
$DN = "DC=domain,DC=com" 
$expiringpassusers = @()           
# SMTP Authentication
$username = "anonymous" 
$Password = "anonymous"
$SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($Username,$SecurePassword)
$messagebody = "Below is the list of users with expiring password" +  "`r`n`r`n" 
########################################            
            
##############Function##################            
function PreparePasswordPolicyMail ($ComplexityEnabled,$MaxPasswordAge,$MinPasswordAge,$MinPasswordLength,$PasswordHistoryCount)            
{            
    $verbosemailBody = "Below is a summary of the applied Password Policy settings:`r`n`r`n"            
    $verbosemailBody += "Complexity Enabled = " + $ComplexityEnabled + "`r`n`r`n"            
    $verbosemailBody += "Maximum Password Age = " + $MaxPasswordAge + "`r`n`r`n"            
    $verbosemailBody += "Minimum Password Age = " + $MinPasswordAge + "`r`n`r`n"            
    $verbosemailBody += "Minimum Password Length = " + $MinPasswordLength + "`r`n`r`n"            
    $verbosemailBody += "Remembered Password History = " + $PasswordHistoryCount + "`r`n`r`n"            
    return $verbosemailBody            
}            
            
function SendMail ($SMTPserver,$sendermailaddress,$usermailaddress,$mailBody)            
{            
    $smtpServer = $SMTPserver            
    $msg = new-object Net.Mail.MailMessage            
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)            
    $msg.From = $sendermailaddress            
    $msg.To.Add($usermailaddress)            
    $msg.Subject = "Your password is about to expire"            
    $msg.Body = $mailBody            
    $smtp.Send($msg)            
}            
########################################            
            
##############Main######################            
$domainPolicy = Get-ADDefaultDomainPasswordPolicy            
$passwordexpirydefaultdomainpolicy = $domainPolicy.MaxPasswordAge.Days -ne 0            
            
if($passwordexpirydefaultdomainpolicy)            
{            
    $defaultdomainpolicyMaxPasswordAge = $domainPolicy.MaxPasswordAge.Days            
    if($verbose)            
    {            
        $defaultdomainpolicyverbosemailBody = PreparePasswordPolicyMail $PSOpolicy.ComplexityEnabled $PSOpolicy.MaxPasswordAge.Days $PSOpolicy.MinPasswordAge.Days $PSOpolicy.MinPasswordLength $PSOpolicy.PasswordHistoryCount            
    }            
}            
            
# foreach ($user in (Get-ADUser -SearchBase "DC=welldynerx,DC=com" -Filter '*' -properties mail)) 
  foreach ($user in (Get-ADUser -SearchBase "DC=welldynerx,DC=com" -Filter '*' -properties mail | ? {$_.samaccountname -match "bvazquez|jwasser"}  ))


{           
 $samaccountname = $user.samaccountname            
    $PSO= Get-ADUserResultantPasswordPolicy -Identity $samaccountname            
    if ($PSO -ne $null)            
    {                         
        $PSOpolicy = Get-ADUserResultantPasswordPolicy -Identity $samaccountname            
        $PSOMaxPasswordAge = $PSOpolicy.MaxPasswordAge.days            
        $pwdlastset = [datetime]::FromFileTime((Get-ADUser -LDAPFilter "(&(samaccountname=$samaccountname))" -properties pwdLastSet).pwdLastSet)            
        $expirydate = ($pwdlastset).AddDays($PSOMaxPasswordAge)            
        $delta = ($expirydate - (Get-Date)).Days            
        $comparionresults = (($expirydate - (Get-Date)).Days -le $notificationstartday) -AND ($delta -ge 1)            
        if ($comparionresults)            
        {            
            $mailBody = "Dear " + $user.GivenName + ",`r`n`r`n"            
            $mailBody += "Your Windows password will expire after " + $delta + " days. You will need to change your password to keep using it.`r`n`r`n"            
            if ($verbose)            
            {            
                $mailBody += PreparePasswordPolicyMail $PSOpolicy.ComplexityEnabled $PSOpolicy.MaxPasswordAge.Days $PSOpolicy.MinPasswordAge.Days $PSOpolicy.MinPasswordLength $PSOpolicy.PasswordHistoryCount            
            }            
            $mailBody += "`r`n`r`nWellDyneRx IT Department"            
            $usermailaddress = $user.mail            
            SendMail $SMTPserver $sendermailaddress $usermailaddress $mailBody            
        }            
    }            
    else            
    {            
        if($passwordexpirydefaultdomainpolicy)            
        {            
            $pwdlastset = [datetime]::FromFileTime((Get-ADUser -LDAPFilter "(&(samaccountname=$samaccountname))" -properties pwdLastSet).pwdLastSet)            
            $expirydate = ($pwdlastset).AddDays($defaultdomainpolicyMaxPasswordAge)            
            $delta = ($expirydate - (Get-Date)).Days            
            $comparionresults = (($expirydate - (Get-Date)).Days -le $notificationstartday) -AND ($delta -ge 1)            
            if ($comparionresults)            
            {            
                $expiringpassusers += $samaccountname
                $mailBody = "Dear " + $user.GivenName + ",`r`n`r`n"            
                $delta = ($expirydate - (Get-Date)).Days            
                $mailBody += "Your Windows password will expire after " + $delta + " days. You will need to change your password to keep using your account. You will continue to receive a daily reminder until you do change it. `r`n`r`n"            
                $mailBody += "If you need any help resetting your password please contact our helpdesk at 855-404-0966 or internally at ext. 5555. `r`n`r`n" 
                if ($verbose)            
                {            
                    $mailBody += $defaultdomainpolicyverbosemailBody            
                }            
                $mailBody += "`r`n`r`n IT Department"            
                $usermailaddress = $user.mail            
                SendMail $SMTPserver $sendermailaddress $usermailaddress $mailBody
                           
            }            
            
        }            
    }            
}
#Sending list to Help Desk 
#SendMail $SMTPserver $sendermailaddress $usermailaddress $mailBody
$expiringpassusers | foreach {$messagebody = $messagebody + "`n" + $_} 
Send-MailMessage -to email@domain.com -From automaton@domain.com -Subject "List of Users with Expiring Password" -Body $messagebody -SmtpServer $SMTPserver -Credential $credential 
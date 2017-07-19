Add-Type -AssemblyName System.Web
$DecodedParameter = [System.Web.HttpUtility]::UrlDecode("||Parameter||")
Write-Output $DecodedParameter
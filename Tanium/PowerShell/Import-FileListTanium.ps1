Add-Type -AssemblyName System.Web
[string]$FileListLog = [System.Web.HttpUtility]::UrlDecode("||FileListLog||")
(Get-Content -Path $FileListLog | Get-Item).FullName
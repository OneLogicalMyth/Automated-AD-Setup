#requires -version 4.0
#requires -runasadministrator


#Grab configuration for the new forest
[xml]$Config = Get-Content (Join-Path $PSScriptRoot '..\Config.xml') -ErrorAction Stop
$ForestConfig = $Config.Config.Forest

#update progress
$Progress = Import-Clixml -Path 'C:\AD-Config\Progress.xml' -ErrorAction Stop
if(-not $Progress.PrepareDC){
    Write-Error 'This domain controller is not prepared for joining to the domain!'
    Return
}else{
    $Progress.JoinDC = $true
}
$Progress | Export-Clixml -Path 'C:\AD-Config\Progress.xml'

#Join the domain controller to the domain
$Credentials = Get-Credential -Message 'Please enter the administrative account for the domain.' -UserName "$($ForestConfig.NetBIOS)\$($ENV:USERNAME)"
Add-Computer -DomainName $ForestConfig.FQDN -Credential $Credentials -Restart
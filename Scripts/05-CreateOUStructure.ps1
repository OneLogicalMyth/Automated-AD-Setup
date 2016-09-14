#requires -version 4.0
#requires -runasadministrator

#Grab OU structure from config
[xml]$OUStructure = Get-Content (Join-Path $PSScriptRoot '..\Config Files\OUStructure.xml')

#Import logging function and ou path function
. (Join-Path $PSScriptRoot '..\Functions\Write-LogEntry.ps1')
. (Join-Path $PSScriptRoot '..\Functions\Get-OUPaths.ps1')

#Create logs directory and file
$LogFile = (Join-Path $PSScriptRoot "..\Logs\$((Get-Item $PSCommandPath).BaseName)-$((Get-Date).ToString('ddMMyyyy')).log")
New-Item -Path $LogFile -ItemType File -ErrorAction SilentlyContinue | Out-Null

#Define root level OUs
$Domain         = $(Get-ADDomain).DistinguishedName
$OUsToCreate    = Get-OUPaths -ParentDN $Domain -OUStructure $OUStructure.OUStructure

Foreach($OU IN $OUsToCreate){
	Write-LogEntry -LogFile $LogFile -Message "Creating OU named '$($OU.Name)' under '$($OU.ParentDN)'"
	New-ADOrganizationalUnit -Name $OU.Name -Description $OU.Description -Path $OU.ParentDN
}
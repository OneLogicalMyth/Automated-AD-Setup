#requires -version 4.0
#requires -runasadministrator
#requires -module ADDSDeployment

#Create logs directory and file
$LogFile = (Join-Path $PSScriptRoot "..\Logs\$((Get-Item $PSCommandPath).BaseName)-$((Get-Date).ToString('ddMMyyyy')).log")
$ADLogFile = (Join-Path $PSScriptRoot "..\Logs\$((Get-Item $PSCommandPath).BaseName)-$((Get-Date).ToString('ddMMyyyy'))-ADInstall.log")
New-Item -Path $LogFile -ItemType File -ErrorAction SilentlyContinue | Out-Null

#Import logging and scheduled task function
. (Join-Path $PSScriptRoot '..\Functions\Write-LogEntry.ps1')
. (Join-Path $PSScriptRoot '..\Functions\ADConfigTask.ps1')

#Setting scheduled task
Write-LogEntry -LogFile $LogFile -Message 'Setting up scheduled task so setup can continue after reboot'
Set-ADConfigTask -Step 3

#Grab configuration for the new forest
[xml]$Config = Get-Content (Join-Path $PSScriptRoot '..\Config Files\Forest.xml') -ErrorAction Stop
$ForestConfig = $Config.Forest

#Prompt for safe mode password
$Match = $false
Write-LogEntry -LogFile $LogFile -Message 'Requesting safe mode password'
while($Match -eq $false)
{                
    # Ask for current credentials for autologon
    $SafeModePass1 = Get-Credential -Message 'Please enter safe mode password to use' -UserName 'NOT NEEDED'
    $Password1 = $SafeModePass1.GetNetworkCredential().Password

	$SafeModePass2 = Get-Credential -Message 'Please confirm the safe mode password' -UserName 'NOT NEEDED'
    $Password2 = $SafeModePass2.GetNetworkCredential().Password
	
	if($Password1 -eq $Password2)
	{
		$Match = $true
		Write-LogEntry -LogFile $LogFile -Message 'Safe mode password confirmation matched continuing'
	}
}

#Install required feature for promoting server to a domain controller
Write-LogEntry -LogFile $LogFile -Message "Starting AD install for forest log file at - '$ADLogFile'"
$null = Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

#Create New Forest, add Domain Controller
$Options = @{
    CreateDnsDelegation = $false
    DomainMode = $ForestConfig.DomainMode
    DomainName = $ForestConfig.FQDN
    DomainNetbiosName = $ForestConfig.NetBIOS
    InstallDns = $true
    NoRebootOnCompletion = $false
    Force = $true
	LogPath = $ADLogFile
	SafeModeAdministratorPassword = $SafeModePass1.Password
}

Install-ADDSForest @Options
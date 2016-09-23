#requires -version 4.0
#requires -runasadministrator
param([int]$ServerID)

#Create logs directory and file
$LogFile = "C:\ADConfiguration\Logs\$((Get-Item $PSCommandPath).BaseName)-$((Get-Date).ToString('ddMMyyyy')).log"
New-Item -Path $LogFile -ItemType File -ErrorAction SilentlyContinue | Out-Null

#Import logging and scheduled task function
. (Join-Path $PSScriptRoot '..\Functions\Write-LogEntry.ps1')
. (Join-Path $PSScriptRoot '..\Functions\ADConfigTask.ps1')

#Remove any variables that could cause conflict
Remove-Variable -Name ServerConfig -ErrorAction SilentlyContinue

# Create loop to validate username and password
$ValidAccount = $false
while($ValidAccount -eq $false)
{                
    # Ask for current credentials for autologon
    $CurrentCreds = Get-Credential -Message 'Please enter the CURRENT local administrative username and password' -UserName $env:USERNAME
    $Username = $CurrentCreds.GetNetworkCredential().UserName
    $Password = $CurrentCreds.GetNetworkCredential().Password

    Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    $ValidAccount = (New-Object System.DirectoryServices.AccountManagement.PrincipalContext('machine',$env:COMPUTERNAME)).ValidateCredentials($Username, $Password) 
            
    # Configure server for autologon
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUserName -Value $Username
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultPassword -Value $Password
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -Value "1"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name ForceAutoLogon -Value "1"
}

#Get configuration
Write-LogEntry -LogFile $LogFile -Message 'Loading configuration file DomainControllers.xml from root directory'
[xml]$Config = Get-Content (Join-Path $PSScriptRoot '..\Config Files\DomainControllers.xml')
$ServerConfig = $Config.DomainControllers.DC | Where-Object { $_.ID -eq $ServerID }
while(-not $ServerConfig){
    Write-Host
    $Config.DomainControllers.DC | Select-Object ComputerName, Description, ID | Format-Table -AutoSize
    Write-Host
    $ProposedID = Read-Host 'Which server do you want to prepare, enter an ID number?'
    $ServerConfig = $Config.DomainControllers.DC | Where-Object { $_.ID -eq $ProposedID }
}

#Get adapter index
Write-LogEntry -LogFile $LogFile -Message 'Identifing adapter index number'
$Adapter_Index = (Get-NetAdapter).ifIndex
while($Adapter_Index.Count -ne 1){
    Write-LogEntry -LogFile $LogFile -Message 'Multiple Network Adapters Found! Please use the table below to give an index number.' -IsWarning
    Write-Host
    Get-NetAdapter | Select-Object Name, ifIndex | Format-Table -AutoSize
    Write-Host
    $ProposedIndex = Read-Host 'Which index number?'
    $Adapter_Index = (Get-NetAdapter -InterfaceIndex $ProposedIndex -ErrorAction SilentlyContinue).ifIndex
}

#Set DNS suffix
Write-LogEntry -LogFile $LogFile -Message "Setting DNS suffix '$($ServerConfig.DNSSuffix)' for network adapter $Adapter_Index"
Set-DnsClient -InterfaceIndex $Adapter_Index -ConnectionSpecificSuffix $ServerConfig.DNSSuffix

#Set DNS servers
Write-LogEntry -LogFile $LogFile -Message "Setting DNS server addresses '$($ServerConfig.DNSServers.IP -join ',')' for network adapter $Adapter_Index"
Set-DnsClientServerAddress -InterfaceIndex $Adapter_Index -ServerAddresses $ServerConfig.DNSServers.IP

#Rename the computer 
Write-LogEntry -LogFile $LogFile -Message "Renaming computer to $($ServerConfig.ComputerName)"
Rename-Computer -NewName $ServerConfig.ComputerName -force 

#Remove GUI
if([bool]([int]$ServerConfig.RemoveGUI))
{
    Write-LogEntry -LogFile $LogFile -Message 'Removing windows features Desktop-Experience and Server-Gui-Shell'
    $null = Uninstall-WindowsFeature -Name Desktop-Experience,Server-Gui-Shell -Remove

    #Set PowerShell as default
    Write-LogEntry -LogFile $LogFile -Message 'Changing shell to PowerShell instead of cmd prompt, also setting sconfig to launch at logon'
    Set-ItemProperty -Path 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name Shell -Value 'powershell.exe -noexit -Command "Set-Location ${Env:USERPROFILE};start sconfig"'
}

#Install AD-Domain-Services
Write-LogEntry -LogFile $LogFile -Message 'Installing AD domain services role'
$null = Install-WindowsFeature -Name AD-Domain-Services

#Setting scheduled task
Write-LogEntry -LogFile $LogFile -Message 'Setting up scheduled task so setup can continue after reboot'
Set-ADConfigTask -Step 2

# Stop server manager at logon
Write-LogEntry -LogFile $LogFile -Message 'Disabling server manager launch at logon'
$null = New-ItemProperty -Path HKLM:\Software\Microsoft\ServerManager -Name DoNotOpenServerManagerAtLogon -PropertyType DWORD -Value '0x1' -Force

#Finish by restarting the computer 
Write-LogEntry -LogFile $LogFile -Message 'All finished restarting the server in 10 seconds'
Start-Sleep -Seconds 10
Restart-Computer -Force
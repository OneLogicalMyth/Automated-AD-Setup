#requires -version 4.0
#requires -runasadministrator

#Create logs directory and file
$LogFile = (Join-Path $PSScriptRoot "..\Logs\$((Get-Item $PSCommandPath).BaseName)-$((Get-Date).ToString('ddMMyyyy')).log")
New-Item -Path $LogFile -ItemType File -ErrorAction SilentlyContinue | Out-Null

#Import logging function
. (Join-Path $PSScriptRoot '..\Functions\Write-LogEntry.ps1')

#Get PDC for current domain
$Domain       = Get-ADDomain
$PDC          = $Domain.PDCEmulator.ToString()
$ADZone       = $Domain.DNSRoot
$WriteableDCs = $Domain.ReplicaDirectoryServers

#Build timespan objects
$7Days = New-TimeSpan -Days 7
$4Days = New-TimeSpan -Days 4

#Set primary AD zone to secure only
Write-LogEntry -LogFile $LogFile -Message "Switching dynamic updates for zone '$ADZone' to secure"
Set-DnsServerPrimaryZone -Name $ADZone -ComputerName $PDC -DynamicUpdate Secure

#Set primary AD zone aging
Write-LogEntry -LogFile $LogFile -Message "Enabling aging for '$ADZone', no refresh interval and refresh interval set to 7 days"
Set-DnsServerZoneAging -Aging $true -Name $ADZone -ComputerName $PDC -NoRefreshInterval $7Days -RefreshInterval $7Days

#Enable scavinging only on the PDC
Write-LogEntry -LogFile $LogFile -Message "Enabling scavenging on '$PDC' scavenging interval set to 4 days"
Set-DnsServerScavenging -ComputerName $PDC -ScavengingInterval $4Days -ScavengingState $true

#Get configuration
Write-LogEntry -LogFile $LogFile -Message "Reading configuration file for DNS forwarders"
[xml]$Config = Get-Content (Join-Path $PSScriptRoot '..\Config Files\DNSForwarders.xml') -ErrorAction Stop
$DNSForwardersRAW = $Config.DNSForwarders.IP

#check if forwarders are set
if($DNSForwardersRAW){
    Write-LogEntry -LogFile $LogFile -Message "DNS forwards have been specified will set forwarders on all writeable DCs"
    #Build forwarders as an array of IPAddress
    $DNSForwarders = @()
    Foreach($IP IN $DNSForwardersRAW){
        $DNSForwarders += [ipaddress]::Parse($IP)
    }

    #Add forwarders to all domain controllers on the domain
    Foreach($DC IN $WriteableDCs){
        Write-LogEntry -LogFile $LogFile -Message "Setting DNS forwarders '$($DNSForwardersRAW -join ',')' on $DC"
        set-DnsServerForwarder -IPAddress $DNSForwarders -ComputerName $DC
    }
}

Write-LogEntry -LogFile $LogFile -Message 'DNS configuration completed ok'
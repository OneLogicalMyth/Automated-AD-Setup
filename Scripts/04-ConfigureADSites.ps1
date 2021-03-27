#requires -version 4.0
##requires -runasadministrator

#Function to test if AD site is present
Function Test-ADSite {
Param($SiteName)

	try{
		Get-ADReplicationSite –Identity $SiteName
		return $true
	}
	catch{
		return $false
	}

}

#Function to test if AD subnet is present
Function Test-ADSubnet {
Param($Subnet)

	try{
		Get-ADReplicationSubnet $Subnet
		return $true
	}
	catch{
		return $false
	}

}

#Create logs directory and file
$LogFile = (Join-Path $PSScriptRoot "..\Logs\$((Get-Item $PSCommandPath).BaseName)-$((Get-Date).ToString('ddMMyyyy')).log")
New-Item -Path $LogFile -ItemType File -ErrorAction SilentlyContinue | Out-Null

#Import logging function
. (Join-Path $PSScriptRoot '..\Functions\Write-LogEntry.ps1')

#Get configuration
Write-LogEntry -LogFile $LogFile -Message 'Loading configuration file ADSites.xml from Config Files directory'

[System.Xml.XmlDocument]$SitesFile = New-Object System.Xml.XmlDocument
$SitesFile.load((Join-Path $PSScriptRoot '..\Config Files\ADSites.xml'))
$ADSites = $SitesFile.SelectNodes("/ADSites/Site")

#Grab the first site on the list
$FirstSite = $ADSites[0]

#Get default site and rename it to the first one on the list
Write-LogEntry -LogFile $LogFile -Message "If 'Default-First-Site-Name' is present it will now be renamed to '$($FirstSite.Name)' at location '$($FirstSite.Location)'"
if(Test-ADSite 'Default-First-Site-Name'){
	Get-ADReplicationSite –Identity Default-First-Site-Name | Rename-ADObject –NewName $FirstSite.Name
}

#Loop through each site and create it if not present then assign subnets
Foreach($Site IN $ADSites){

	Write-LogEntry -LogFile $LogFile -Message "Processing AD site named '$($Site.Name)'"

    If(-not (Test-ADSite $Site.Name)){
        Write-LogEntry -LogFile $LogFile -Message "Creating new AD site named '$($Site.Name)'"
        New-ADReplicationSite -Name $Site.Name -Description $Site.Description -OtherAttributes @{Location=$Site.Location}
    }else{
		Write-LogEntry -LogFile $LogFile -Message "AD site named '$($Site.Name)' already exists"
		Get-ADReplicationSite $Site.Name | Set-ADReplicationSite -Description $Site.Description -Replace @{Location=$Site.Location}
	}

    Foreach($Subnet IN $Site.Subnets.Subnet){
		if(-not (Test-ADSubnet $Subnet.IP)){
			Write-LogEntry -LogFile $LogFile -Message "Adding subnet '$($Subnet.IP)' to site '$($Site.Name)'"
			try{
				New-ADReplicationSubnet -Name $Subnet.IP -Site $Site.Name -Location $Subnet.Location -Description $Subnet.Description
				Write-LogEntry -LogFile $LogFile -Message "Subnet '$($Subnet.IP)' has been added to site '$($Site.Name)'"
				}
			catch{
				Write-LogEntry -LogFile $LogFile -Message "Failed adding subnet '$($Subnet.IP)' to site '$($Site.Name)'" -IsWarning
			}
		}else{
			Write-LogEntry -LogFile $LogFile -Message "Subnet '$($Subnet.IP)' already exists on site '$($Site.Name)'"
		}
    }

}
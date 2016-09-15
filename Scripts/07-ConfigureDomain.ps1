#requires -version 4.0
#requires -runasadministrator

#Grab OU structure and admin details from config
$DomainConfig = ([xml](Get-Content (Join-Path $PSScriptRoot '..\Config Files\DomainConfig.xml'))).DomainConfig
$AdminDetails = ([xml](Get-Content (Join-Path $PSScriptRoot '..\Config Files\NewAdminDetails.xml'))).NewAdminDetails

#Get domain object and values
$Domain       = Get-ADDomain
$DomainDN     = $Domain.DistinguishedName
$AdminAccount = $Domain.DomainSID.Value + '-500'
$DomainFQDN   = $Domain.DNSRoot

#Replace values
$DefaultComputerOU = $DomainConfig.DefaultComputerOU.Replace('{{DomainDN}}',$DomainDN)
$DefaultUserOU     = $DomainConfig.DefaultUserOU.Replace('{{DomainDN}}',$DomainDN)
$DisplayNameFormat = $DomainConfig.DisplayNameFormat.Replace('{{LastName}}','%<sn>').Replace('{{FirstName}}','%<givenName>')

#Update domain configuration

#Set display name
Get-ADObject "CN=user-Display,CN=409,CN=DisplaySpecifiers,$((Get-ADRootDSE).configurationNamingContext)" | Set-ADObject -Replace @{createDialog=$DisplayNameFormat}

#redirect users and computers
Write-Host "Setting default computer OU to 'OU=New Machines,OU=Administrative,$($Domain.DistinguishedName)'"
redircmp $DefaultComputerOU

Write-Host "Setting default user OU to 'OU=People,OU=Live,$($Domain.DistinguishedName)'"
redirusr $DefaultUserOU




#rename master admin account
$AdminName     = Import-Csv (Join-Path $PSScriptRoot '..\Config Files\NewAdminNames.csv') | Get-Random
$AdminUsername =  "A-$($AdminName.Surname)$($AdminName.GivenName.Substring(0,1))"

$NewAdminDetails = @{
	Office        = $AdminDetails.Office
	StreetAddress = $AdminDetails.StreetAddress
	City          = $AdminDetails.City
	PostalCode    = $AdminDetails.PostalCode
	Country       = $AdminDetails.Country
	EmailAddress  = $AdminDetails.EmailAddress
	OfficePhone   = $AdminDetails.OfficePhone
	Title         = $AdminDetails.Title
	Company       = $AdminDetails.Company
	Description   = $AdminDetails.Description
	HomePage      = $AdminDetails.HomePage
	GivenName     = $AdminName.GivenName
	Surname       = $AdminName.Surname
    
    UserPrincipalName = "$AdminUsername@$DomainFQDN"
    SamAccountName    = $AdminUsername
}

#Check for empty values as Set-ADUser does not allow empty values only null values
$Empties = $NewAdminDetails.Keys | Where-Object { [string]::IsNullOrEmpty($NewAdminDetails.$_) }
$Empties | foreach{ $NewAdminDetails.$_ = $null }

#Rename the administartor account and move it to the desired location
Get-ADUser $AdminAccount | Set-ADUser @NewAdminDetails | Move-ADObject -TargetPath "$($AdminDetails.Location),$DomainDN"

#Enable the Recycle Bin
Enable-ADOptionalFeature "Recycle Bin Feature" -Scope ForestOrConfigurationSet -Target (Get-ADDomain).DnsRoot.ToString() -Confirm:$false

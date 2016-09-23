#requires -version 4.0
#requires -runasadministrator

$Domain     = Get-ADDomain
$DNSRoot    = $Domain.DNSRoot
$DomainDN   = $Domain.DistinguishedName
$BackupPath = Resolve-Path (Join-path $PSScriptRoot '..\Config Files\Group Policy')

#Copy over Policy Definitions to central store
Copy-Item 'C:\Windows\PolicyDefinitions'  "\\$DNSRoot\SYSVOL\$DNSRoot\Policies\" -Recurse -Force

#Grab GPO listing from config
$GPOs = ([xml](Get-Content (Join-Path $PSScriptRoot '..\Config Files\GroupPolicy.xml'))).GroupPolicy.GPO

# Loop through each GPO then create, link and import the settings
Foreach($GPO IN $GPOs){

    # Import and create the GPOs    
    $null = Import-GPO -BackupId $GPO.BackupID -Path $BackupPath -TargetName $GPO.Name -CreateIfNeeded

    # Get current GPO
    $CurrentGPO = $null
    $CurrentGPO = Get-GPO -Name $GPO.Name

    # Link to each link target
    Foreach($Link IN $GPO.LinksTo.Link)
    {
        Write-Host "$Link,$DomainDN"
        $null = $CurrentGPO | New-GPLink -Target "$Link,$DomainDN"
    }
    
}

#requires -version 4.0
#requires -runasadministrator

#Grab OU structure from config
$RBACGroups = ([xml](Get-Content (Join-Path $PSScriptRoot '..\Config Files\RBACGroups.xml'))).RBACGroups 

#Import logging function and ou path function
. (Join-Path $PSScriptRoot '..\Functions\Write-LogEntry.ps1')

#Grab domain DN
$DomainDN = $(Get-ADDomain).DistinguishedName

#Create logs directory and file
$LogFile = (Join-Path $PSScriptRoot "..\Logs\$((Get-Item $PSCommandPath).BaseName)-$((Get-Date).ToString('ddMMyyyy')).log")
New-Item -Path $LogFile -ItemType File -ErrorAction SilentlyContinue | Out-Null

#Active directory module does not SilentlyContinue will still error regardless
#Function to test if the group exists
Function Test-ADGroup
{
param($GroupIdentity)
    try
    {
        return (Get-ADGroup $GroupIdentity -ErrorAction SilentlyContinue)
    }
    catch
    {
        return $false
    }
}


#Function to create a group or move if existing and not in correct place
Function Invoke-CreateADGroup
{
param($Name,$Description,$Location,$DomainDN,$LogFile)

    $GroupObject = Test-ADGroup $Name

    if($GroupObject)
    {
        $null = $GroupObject | Set-ADObject -ProtectedFromAccidentalDeletion $false 
        $null = $GroupObject | Move-ADObject -TargetPath "$Location,$DomainDN"
        $null = $GroupObject | Set-ADGroup -Description $Description
    }
    else
    {
        $GroupObject = New-ADGroup -Description $Description -SamAccountName $Name -Name $Name -Path "$Location,$DomainDN" -GroupCategory Security -GroupScope Global -ErrorAction Stop
    }

    try
    {
        $null = $GroupObject | Set-ADObject -ProtectedFromAccidentalDeletion $true

    }
    catch
    {
        Write-Warning $_
    }

}

#Create all the required groups to work with
Foreach($Group IN ($RBACGroups.Roles.Group + $RBACGroups.Permissions.Group + $RBACGroups.Managers.Group))
{
    Invoke-CreateADGroup -Name $Group.Name -Description $Group.Description -Location $Group.Location -DomainDN $DomainDN -LogFile $LogFile
    $Group = $null
}

#Loop through and add permissive groups to the roles
ForEach ($Group in $RBACGroups.Roles.Group)
{   try
    {
        $null = $Group.MemberOf.Group | Add-ADGroupMember -Members $Group.Name -ErrorAction Stop
    }
    catch
    {
        Write-Error "Error adding members to $($Group.Name) because $($Error[0])"
    }
    $Group = $null
}

#Now grant the manager groups management of the roles
Foreach ($Group IN $RBACGroups.Roles.Group)
{
    if(-not [string]::IsNullOrEmpty($Group.ManagedBy))
    {
        #Add the management group to the 'Managed By' tab
        $ADGroup = Get-ADGroup $Group.Name
        $ADGroup | Set-ADGroup -ManagedBy $Group.ManagedBy

        #Grant the management group access to remove and add members
        $perm = @{
            DN              = $ADGroup.DistinguishedName
            Identity        = $Group.ManagedBy
            ADRights        = 'WriteProperty'
            Type            = 'Allow'
            ObjectType      = ([guid]'bf9679c0-0de6-11d0-a285-00aa003049e2')
            InheritanceType = 'All'
            InheritedObject = $null
        }
        Add-DelegatedRight @perm
        Remove-Variable perm
    }
}
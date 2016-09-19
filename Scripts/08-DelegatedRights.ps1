#requires -version 4.0
#requires -runasadministrator
#requires -module ActiveDirectory

#Import OU data
$OUStructure = ([xml](Get-Content (Join-Path $PSScriptRoot '..\Config Files\OUStructure.xml'))).OUStructure
. (Join-Path $PSScriptRoot '..\Functions\Get-OUPaths.ps1')
. (Join-Path $PSScriptRoot '..\Functions\Add-DelegatedRight.ps1')

#Get a reference to the RootDSE of the current domain
$RootDSE = Get-ADRootDSE

#Get a reference to the current domain
$Domain = Get-ADDomain

#Get rights to process
$OUs = Get-OUPaths -ParentDN $Domain.DistinguishedName -OUStructure $OUStructure | Where-Object { $_.DelegatedRights -ne $null }

#Create a hashtable to store the GUID value of each schema class and attribute
$guidmap = @{}
Get-ADObject -SearchBase ($rootdse.SchemaNamingContext) -LDAPFilter `
"(schemaidguid=*)" -Properties lDAPDisplayName,schemaIDGUID | 
% {$guidmap[$_.lDAPDisplayName]=[System.GUID]$_.schemaIDGUID}

#Create a hashtable to store the GUID value of each extended right in the forest
# $extendedrightsmap = @{}
# Get-ADObject -SearchBase ($rootdse.ConfigurationNamingContext) -LDAPFilter `
# "(&(objectclass=controlAccessRight)(rightsguid=*))" -Properties displayName,rightsGuid | 
# % {$extendedrightsmap[$_.displayName]=[System.GUID]$_.rightsGuid}

#Process the delegated rights
Foreach($OU IN ($OUs | Select-Object DN -ExpandProperty DelegatedRights))
{
    #Todo tidy up this mess :(
    if($OU.ObjectType -eq 'NULL')
    {
    $ObjectType = 'NULL'
    }
    elseif([string]::IsNullOrEmpty($OU.ObjectType))
    {
    $ObjectType = $null
    }else{
    $ObjectType = [guid]$($guidmap[$OU.ObjectType])
    }

    if($OU.InheritedObjectType -eq 'NULL')
    {
        $InheritedObjectType = 'NULL'
    }
    elseif([string]::IsNullOrEmpty($OU.InheritedObjectType))
    {
        $InheritedObjectType = $null
    }else{
        $InheritedObjectType = [guid]$($guidmap[$OU.InheritedObjectType])
    }

    $perm = @{
        DN                  = $OU.DN
        Identity            = $OU.Identity
        ADRights            = $OU.ADRights
        Type                = $OU.Type
        ObjectType          = $ObjectType
        InheritanceType     = $OU.InheritanceType
        InheritedObjectType = $InheritedObjectType
    }

    Add-DelegatedRight @perm
    Remove-Variable perm
}
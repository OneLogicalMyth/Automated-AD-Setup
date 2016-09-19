Function Add-DelegatedRight
{
param($DN,$Identity,$ADRights,$Type,$ObjectType,$InheritanceType,$InheritedObjectType)

    # First grab the current ACL information
    $ACL = Get-ACL -Path "AD:\$DN"

    # Grab the group SID
    if($Identity -notlike 'S-*')
    {
        $Identity = New-Object System.Security.Principal.SecurityIdentifier (Get-ADGroup $Identity).SID
    }
    else
    {
        $Identity = New-Object System.Security.Principal.SecurityIdentifier $Identity
    }

    # Create the access rule
    if
    (
        -not [string]::IsNullOrEmpty($Identity) -and
        -not [string]::IsNullOrEmpty($ADRights) -and
        -not [string]::IsNullOrEmpty($Type) -and
        [string]::IsNullOrEmpty($ObjectType) -and
        [string]::IsNullOrEmpty($InheritanceType) -and
        [string]::IsNullOrEmpty($InheritedObjectType)
    )
    {
        $AccessRule = (New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Identity,$ADRights,$Type)
    }
    elseif
    (
        -not [string]::IsNullOrEmpty($Identity) -and
        -not [string]::IsNullOrEmpty($ADRights) -and
        -not [string]::IsNullOrEmpty($Type) -and
        [string]::IsNullOrEmpty($ObjectType) -and
        -not [string]::IsNullOrEmpty($InheritanceType) -and
        [string]::IsNullOrEmpty($InheritedObjectType)
    )
    {
        $AccessRule = (New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Identity,$ADRights,$Type,$InheritanceType)
    }
    elseif
    (
        -not [string]::IsNullOrEmpty($Identity) -and
        -not [string]::IsNullOrEmpty($ADRights) -and
        -not [string]::IsNullOrEmpty($Type) -and
        [string]::IsNullOrEmpty($ObjectType) -and
        -not [string]::IsNullOrEmpty($InheritanceType) -and
        -not [string]::IsNullOrEmpty($InheritedObjectType)
    )
    {
        if($InheritedObjectType -eq 'NULL')
        {
            $InheritedObjectType = [System.Guid]::Empty
        }
        
        $AccessRule = (New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Identity,$ADRights,$Type,$InheritanceType,$InheritedObjectType)
    }
    elseif
    (
        -not [string]::IsNullOrEmpty($Identity) -and
        -not [string]::IsNullOrEmpty($ADRights) -and
        -not [string]::IsNullOrEmpty($Type) -and
        -not [string]::IsNullOrEmpty($ObjectType) -and
        [string]::IsNullOrEmpty($InheritanceType) -and
        [string]::IsNullOrEmpty($InheritedObjectType)
    )
    {
        $AccessRule = (New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Identity,$ADRights,$Type,$ObjectType)
    }
    elseif
    (
        -not [string]::IsNullOrEmpty($Identity) -and
        -not [string]::IsNullOrEmpty($ADRights) -and
        -not [string]::IsNullOrEmpty($Type) -and
        -not [string]::IsNullOrEmpty($ObjectType) -and
        -not [string]::IsNullOrEmpty($InheritanceType) -and
        [string]::IsNullOrEmpty($InheritedObjectType)
    )
    {
        $AccessRule = (New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Identity,$ADRights,$Type,$ObjectType,$InheritanceType)
    }
    elseif
    (
        -not [string]::IsNullOrEmpty($Identity) -and
        -not [string]::IsNullOrEmpty($ADRights) -and
        -not [string]::IsNullOrEmpty($Type) -and
        -not [string]::IsNullOrEmpty($ObjectType) -and
        -not [string]::IsNullOrEmpty($InheritanceType) -and
        -not [string]::IsNullOrEmpty($InheritedObjectType)
    )
    {
        if($InheritedObjectType -eq 'NULL')
        {
            $InheritedObjectType = [System.Guid]::Empty
        }
        
        $AccessRule = (New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Identity,$ADRights,$Type,$ObjectType,$InheritanceType,$InheritedObjectType)
    }
    

    $ACL.AddAccessRule($AccessRule)
    Set-Acl -AclObject $ACL -Path "AD:\$DN"

}

#requires -version 4.0
#requires -runasadministrator
Param($Step=1)

if(-not (Test-Path C:\ADConfiguration\Start-ADConfiguration.ps1)){
    Write-Host 'Copying script files to C:\ADConfiguration, please wait'
    $null = robocopy $PSScriptRoot "${ENV:SystemDrive}\ADConfiguration" /E
    if($LASTEXITCODE -eq 1){

    }
}



$null = robocopy $PSScriptRoot "${ENV:SystemDrive}\ADConfiguration" /E


switch ($Step)
{
    1
    {
        # Get the current server role - checking for standalone server
        $DomainRole = (Get-CimInstance win32_computersystem).DomainRole
        if($DomainRole -eq 2)
        {
            # Server is standalone and not part of a domain, correct for first DC for new forest/domain
            # Prepare server for forest/domain setup
            &(Join-Path $PSScriptRoot 'Scripts\01-PrepareServer.ps1') -ServerID 1
        }
        elseif(3,4,5 -contains $DomainRole)
        {
            # Server is already part of the domain setup step 1 can not continue
            Write-Error 'This server is part of a domain already!' -TargetObject $env:COMPUTERNAME
            return
        }
        elseif(0,1 -contains $DomainRole)
        {
            # Server is actually a workstation so not possible for AD :p
            Write-Error "This is not a server! You can't install AD on a workstation." -TargetObject $env:COMPUTERNAME
            return
        }           

    }

    2
    {
        &(Join-Path $PSScriptRoot 'Scripts\02-CreateForest.ps1')
    }

    3
    {
        # Remove auto logon we don't need it anymore
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUserName
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultPassword
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -Value '0'
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name ForceAutoLogon

        # Remove scheduled task as this is no longer needed
        . (Join-Path $PSScriptRoot '.\Functions\ADConfigTask.ps1')
        Remove-ADConfigTask

        # Execute final configuration of the forest/domain and domain controllers
        &(Join-Path $PSScriptRoot 'Scripts\03-ConfigureDNS.ps1')
        &(Join-Path $PSScriptRoot 'Scripts\04-ConfigureADSites.ps1')
        &(Join-Path $PSScriptRoot 'Scripts\05-CreateOUStructure.ps1')
        &(Join-Path $PSScriptRoot 'Scripts\06-CreateRBACGroups.ps1')
        &(Join-Path $PSScriptRoot 'Scripts\07-ConfigureDomain.ps1')
        &(Join-Path $PSScriptRoot 'Scripts\08-DelegatedRights.ps1')

        # All completed
        $Domain       = Get-ADDomain
        $AdminAccount = $Domain.DomainSID.Value + '-500'
        $AdminDetails = Get-ADUser $AdminAccount

        # Place modal popup on screen to ensure username is not missed
        $Shell = New-Object -ComObject Wscript.Shell
        $Shell.Popup("AD Configuration Completed Successfully.`r`n`r`nThe new administrator username is;`r`n$($AdminDetails.SamAccountName)`r`n`r`nThe password will remain the same!`r`nYou will now be logged off.",0,"AD Configuration",(0x1000 + 0x40))
        logoff

    }

    default
    {
        Write-Error 'Please give a valid step to execute' -TargetObject "Step given $Step"
    }
}
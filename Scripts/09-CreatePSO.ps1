#requires -version 4.0
#requires -runasadministrator

#Grab OU structure from config
$PSO_Items = ([xml](Get-Content (Join-Path $PSScriptRoot '..\Config Files\PSO.xml'))).PSO.PSO

#Import logging function and ou path function
. (Join-Path $PSScriptRoot '..\Functions\Write-LogEntry.ps1')


Foreach($PSO IN $PSO_Items)
{


    Write-LogEntry -Message "Creating PSO '$($PSO.Name)'"
    $Current = @{
        Name                        = [string]$PSO.Name
        Precedence                  = [int]$PSO.Precedence
        ComplexityEnabled           = [bool]([int]$PSO.ComplexityEnabled)
        Description                 = [string]$PSO.Description
        DisplayName                 = [string]$PSO.DisplayName
        LockoutDuration             = [timespan]$PSO.LockoutDuration
        LockoutObservationWindow    = [timespan]$PSO.LockoutObservationWindow
        LockoutThreshold            = [int]$PSO.LockoutThreshold
        MaxPasswordAge              = [timespan]$PSO.MaxPasswordAge
        MinPasswordAge              = [timespan]$PSO.MinPasswordAge
        MinPasswordLength           = [int]$PSO.MinPasswordLength
        PasswordHistoryCount        = [int]$PSO.PasswordHistoryCount
        ReversibleEncryptionEnabled = [bool]([int]$PSO.ReversibleEncryptionEnabled)
    }

    New-ADFineGrainedPasswordPolicy @Current

    $AppliesTo = $PSO.AppliesTo.Group | Get-ADGroup 
    Set-ADFineGrainedPasswordPolicy -Identity $Current.Name -Replace @{'msDS-PSOAppliesTo'=$AppliesTo.DistinguishedName}

}
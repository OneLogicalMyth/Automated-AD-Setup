Enable-ADOptionalFeature "Recycle Bin Feature" -Scope ForestOrConfigurationSet -Target (Get-ADDomain).DnsRoot.ToString() -Confirm:$false

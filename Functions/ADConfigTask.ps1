Function Set-ADConfigTask {
param([int]$Step)

	if((Get-ScheduledTask 'AD Config Setup' -ErrorAction SilentlyContinue))
	{
		Remove-ADConfigTask
	}

	if($Step -gt 0)
	{
		$Trigger = New-ScheduledTaskTrigger -AtLogOn
		$Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-ExecutionPolicy Bypass -File C:\ADConfiguration\Start-ADConfiguration.ps1 -Step $Step"
		$null = Register-ScheduledTask -TaskName 'AD Config Setup' -Action $Action -Trigger $Trigger -RunLevel Highest
	}
	else
	{
		Write-Error 'Step must be given'
		return
	}
	
}


Function Remove-ADConfigTask {
	
	Unregister-ScheduledTask -TaskName "AD Config Setup" -Confirm:$false
	
}
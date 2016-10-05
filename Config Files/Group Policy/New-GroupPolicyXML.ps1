# intended only to be run from the 'Group Policy' directory

Set-Location $PSScriptRoot
$XMLs = Get-ChildItem -File -Recurse -Filter gpreport.xml | Select-Object -ExpandProperty FullName

$GPOs = Foreach($XML IN $XMLs)
{
    $GPOGuid = ((Split-Path $XMLs[0]).split('\') | Select -Last 1).Trim()
    $GPOName = ([xml](Get-Content $XML)).GPO.Name

@"
	<GPO>
		<Name>$GPOName</Name>
		<LinksTo>
			<Link>OU=Servers,OU=Live</Link>
			<Link>OU=Servers,OU=Test</Link>
		</LinksTo>
		<BackupID>$GPOGuid</BackupID>
	</GPO>

"@

}

@"
<GroupPolicy>
$GPOs</GroupPolicy>
"@
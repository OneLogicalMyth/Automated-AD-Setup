Function Get-OUPaths {
param($ParentDN,[System.Xml.XmlElement]$OUStructure,[int]$OUDepth=1)

    
    $OUStructure.OU | Foreach{

        $Out                 = '' | Select-Object Name, Description, ParentDN, DN, OUDepth, DelegatedRights
        $Out.Name            = $_.Name
		$Out.Description     = $_.Description
        $Out.ParentDN        = $ParentDN
        $Out.DN              = "OU=$($_.Name)",$ParentDN -join ','
        $Out.OUDepth         = $OUDepth
        $Out.DelegatedRights = $_.DelegatedRights.DelegatedRight
        $Out

        if($_.OU){

            Get-OUPaths -ParentDN $Out.DN -OUStructure $_ -OUDepth ($OUDepth + 1)

        }

    } | Sort-Object OUDepth, Name

}
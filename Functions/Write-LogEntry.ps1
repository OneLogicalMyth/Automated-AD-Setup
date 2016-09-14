Function Write-LogEntry {
<#
.Synopsis
  Writes a log entry to file and screen
.Description
  This aids in keeping a consitent format for logging
 .Example
    Write-LogEntry 'computer1','computer2'
    Would display and log computer1 and then computer2 as 2 entries
 .Example
  'computer1','computer2' | Write-LogEntry
  Would display and log computer1 and then computer2 as 2 entries
 .Parameter Message
  The message you wish to displayed and logged
 .Parameter LogFile
  The full file path to log file, if not specified no log file is written
 .Parameter DateFormat
  The format of how you want the date displayed and logged, default is 'yyyy-MM-dd - HH:mm:ss'
 .Parameter IsWarning
  Will change output to console font to yellow to highlight message is a warning, write-warning was not used so format did not break
 .Parameter NoDate
  Removes the date at the begining of the line, useful for headers and footers of log files
  .Notes
  NAME:     Write-LogEntry
  AUTHOR:   Liam Glanfield
  LASTEDIT: 11/04/2016
#>
  [CmdletBinding()]
  param(
        [parameter(ValueFromPipeline=$True)]
        [Alias('msg')]
        [string[]]$Message,
        [string]$DateFormat = 'yyyy-MM-dd - HH:mm:ss',
		[string]$LogFile,
        [switch]$IsWarning,
        [switch]$NoDate

  )

    process
    {
        if($NoDate){
        
	        if($IsWarning){
                $LogMessage = 'WARNING - ' + $Message
		        Write-Host $LogMessage -ForegroundColor Yellow
	        }else{
                $LogMessage = $Message
		        Write-Host $LogMessage
	        }
            
        }else{
        
	        if($IsWarning){
                $LogMessage = $(Get-Date -Format $DateFormat) + ' - WARNING - ' + $Message
		        Write-Host $LogMessage -ForegroundColor Yellow
	        }else{
                $LogMessage = $(Get-Date -Format $DateFormat) + ' - ' + $Message
		        Write-Host $LogMessage
	        }

        }

        if($LogFile){
            Add-Content $LogFile $LogMessage.Trim()
        }
    }
}

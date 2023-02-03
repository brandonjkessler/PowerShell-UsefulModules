function Write-Log {
	<#
	.SYNOPSIS
	Write Logs in a CMTrace compatible format
	
	.DESCRIPTION
	Will write a Log that can be opened in CMTrace and provide better details.
	You can set the severity or Type for Info, Warning, or Error through the number system
	
	.PARAMETER Message
	Message to write to the Log
	
	.PARAMETER Path
	Location to save the Log. This is NOT the path to the log itself, i.e. this needs to be a directory
	
	.PARAMETER Type
	This is the Type of information.
	1 - Info
	2 - Warning
	3 - Error
	
	.PARAMETER Component
	A Specific component that made the log. Can be left blank, but will be auto-populated if left blank.
	
	.EXAMPLE
	Write-Log -Message "Testing out as a module" -Type 3 -Component "Testing Component"

	.EXAMPLE
	Write-Log -Message "Testing out as a module" -Type 1 -Component "Testing Component" -Verbose

	.EXAMPLE
	Write-Log -Message "Testing out as a module" -Path "C:\ProgramData\Logs\Testing" -Type 3 -Component "Testing Component"

	.EXAMPLE
	Write-Log "Testing out as a module" "C:Windows\Logs\SpecificLogs" 3 "Testing Component"
	
	.NOTES
	Reference
	https://janikvonrotz.ch/2017/10/26/powershell-logging-in-cmtrace-format/
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true,HelpMessage="Message to write to the log.",Position=0)]
		[string]$Message,
		[Parameter(Mandatory=$false, HelpMessage = 'Path to Save Log Files',Position=1)]
		[ValidateScript(
			{
				if(Test-Path -Path $PSItem){
					$true
				} else {
					Throw "Unable to locate $PSItem."
				}
			}
		)]
    	[string]$Path = "$env:Windir\Logs",
		[Parameter(Mandatory=$false,HelpMessage="Severity or Type of message. 1 = Info, 2 = Warning, 3 = Error",Position=2)]
		[ValidateSet(1,2,3)]
		[int]$Type = 1,
		[Parameter(Mandatory=$false,HelpMessage="The specific component to list for writing the log.",Position=3)]
		[string]$Component = ""
	)


	if($Path -match '\\$'){
		Write-Verbose -Message 'Trimming trailing \'
		$Path = $Path.Substring(0,($Path.Length - 1))
	}

	Write-Verbose -Message "Checking if running in a script."
	$ScriptName =  $MyInvocation.ScriptName

	Write-Verbose -Message "Checking for Component value and setting to a default value if empty."
	switch($Component){
		{$PSItem -ne ""}{
			Write-Verbose -Message "Component set to $Component"
			$LogFile = "$($Component).log"
			Break
		}
		{$PSItem -eq "" -and $ScriptName -ne ""}{
			Write-Verbose -Message "Component not set, using Script Name $ScriptName"
			$ScriptName = Split-Path -Path $ScriptName -Leaf
			$ScriptName = $ScriptName.Replace('.psm1','').Replace('.ps1','')
			$Component = "Script - $($ScriptName)"
			$LogFile = "$($ScriptName).log"
			Break
		}
		{$PSItem -eq "" -and $ScriptName -eq ""}{
			Write-Verbose -Message "Component not set, Not running from a Script, using Command"
			$Component = "Command - $($MyInvocation.MyCommand.Name)"
			$LogFile = "$($MyInvocation.MyCommand.Name).log"
			Break
		}
		
	}

	
	Write-Verbose -Message "Creating $LogFile file at $Path."
	$Log = "$($Path)\$($LogFile)"

	# Setup log content Variables
	# This will be used to output in a CMTrace compatible format
	$DateStamp = "$(Get-Date -Format "M-d-yyyy")"
	$TimeStamp = "$(Get-Date -Format "HH:mm:ss.ffffff")"
	$Thread = "$([Threading.Thread]::CurrentThread.ManagedThreadId)"

	$Content = "<![LOG[$Message]LOG]!><time=`"$TimeStamp`" date=`"$DateStamp`" component=`"$Component`" context=`"`" type=`"$Type`" thread=`"$Thread`" file=`"`">"

	if((Test-Path -Path $Log) -ne $true){
		Write-Verbose -Message "No $Log file found, now creating."
		New-Item -Path $Log -ItemType File -Force
	}
	Add-Content -Path $Log -Value $Content -Encoding Ascii
}
function New-VirtualDriveMountLetter {
	[cmdletbinding(SupportsShouldProcess)]
	Param(
		[Parameter(Mandatory = $true,HelpMessage="Requested Drive Letter.")]
		[ValidatePattern('^[A-Z]:?')]
		[string]$DriveLetter,
		[parameter(Mandatory)]
		[string]$TaskName,
		[parameter(Mandatory = $false)]
		[String]$TaskPath = "\UsefulModules",
		[parameter(Mandatory,HelpMessage="Path to the VHDX to Mount")]
		[ValidateScript({Test-Path -Path "$PSItem"})]
		[string]$VHDX
	)

	
	if($DriveLetter -notmatch ':$'){
		$DriveLetter = $DriveLetter + ':'
		Write-Verbose "Formatting $DriveLetter to have ':' after the letter"
	}
	
	## Mount a folder as a drive letter
	Write-Verbose -Message "Creating Task action to Mount $VHDX on startup."            
	$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -Command {Mount-DiskImage -ImagePath `"$VHDX`" -StorageType VHDX -Access ReadWrite}"
	# Create Scheduled task to mount that folder
	
	Write-Verbose -Message "Checking for existing Task Name $TAskName."
	if($null -eq (Get-ScheduledTask -TaskName $TaskName)){
		Write-Verbose -Message "No existing $TaskName found. Now Creating."
		$TaskTrigger = New-ScheduledTaskTrigger -AtStartup
		Register-ScheduledTask -TaskName $TaskName -Trigger $TaskTrigger -Action $TaskAction -RunLevel Highest -User "System" -TaskPath "$TaskPath"
	} else {
		Write-Error "$TaskName alread exists."
		Exit 3
	}

	Write-Verbose -Message "Now running Scheduled Task $TaskName"
	Start-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath

	$VHDXDrive = Get-DiskImage -ImagePath "$VHDX" | Get-Disk | Get-Partition | Get-Volume
	if($VHDXDrive.DriveLetter -notmatch "$DriveLetter"){
		Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$($VHDXDrive.DriveLetter):'" | Set-CimInstance -Property @{DriveLetter = "'$($DriveLetter)'"}
	}


}


function Set-VirtualDriveMountLetter{
	[cmdletbinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory = $true,HelpMessage="Requested Drive Letter.")]
		[ValidatePattern('^[A-Z]:?')]
		[string]$DriveLetter,
		[Parameter(Mandatory = $false,HelpMessage="Drive letters to ignore")]
		[array]$ExcludedLetters
	)
	
	## Create Array for Drive letters in use
	[array]$TakenLetters = @('A:','B:')
	##-- Create an array of available letters
	##-- Taken from https://social.technet.microsoft.com/Forums/lync/en-US/0b2a0a4f-df68-486b-8249-735f7c4fad4e/graceful-way-to-create-an-alphabet-array
	##-- The [char[]] is saying this object is a system.object type char. 0..255 is all the unicode characters, and clike is matching to regex.
	[array]$AvailLetters = @([char[]](0..255) -clike '[A-Z]')
	Write-Verbose "Adding a colon to each letter."
	for($l=0; $l -lt $AvailLetters.Count; $l++){
		$AvailLetters[$l] =  $AvailLetters[$l] + ":"
	}


	## Add Taken letters to the arrive
	$currentDriveLetters = Get-CimInstance -ClassName Win32_Volume | Select-Object -Property DriveLetter
	Write-Verbose -Message "Searching for assigned drive letters."
	ForEach($d in $currentDriveLetters){
		if($null -ne $d.DriveLetter){
			Write-Verbose -Message "Adding $d to Array of currently assigned drive letters."
			$TakenLetters += "$($d.DriveLetter)"
			Write-Verbose -Message "Sorting array and removing duplicates."
			$TakenLetters = $TakenLetters | Sort-Object -Unique
		}
	}

	$AvailLetters = $AvailLetters | Where-Object{($TakenLetters -notcontains $PSItem) -and ($ExcludedLetters -notcontains $PSItem)}


	
	Write-Verbose -Message "Verifying if $DriveLetter can be assigned or is already assigned."
	Switch($DriveLetter){
		{$PSItem -in $TakenLetters}{
			Write-Warning "$DriveLetter is already assigned to another drive."
			Write-Warning "Re-assigning currently mapped $DriveLetter to $($AvailLetters[0])."
			Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = `'$DriveLetter`'"| Set-CimInstance -Property @{DriveLetter="$($AvailLetters[0])"}
		}
		{$PSItem -in $ExcludedLetters}{
			Write-Error "$DriveLetter was excluded. Please re-run the command without excluding the drive."
			Exit 2
		}
		Default{
			Write-Verbose "$DriveLetter is available to be assigned."
		}
	}
}

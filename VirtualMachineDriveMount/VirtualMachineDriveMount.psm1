function New-VirtualDriveMount {
	[cmdletbinding()]
	Param(
		[parameter(Mandatory)]
		[string]$MountPointPath,
		[parameter(Mandatory)]
		[string]$TaskName,
		[parameter(Mandatory,HelpMessage="Path to the VHDX to Mount")]
		[ValidateScript({
			if(Test-Path -Path "$VHDX"){
				$true
			}
		})]
		[string]$VHDX
	)
	if((Test-Path -Path $MountPointPath) -ne $true){
		Write-Verbose -Message "$MountPointPath does not exist. Creating now."
		new-item -Path $MountPointPath -ItemType Directory -Force # Check to see if a folder exists and if not create it
	}
	
	## Mount a folder as a drive letter
	Write-Verbose -Message "Mounting $VHDX at $MountPointPath."            
	$TaskAction = New-ScheduledTaskAction -Action "powershell.exe" -Argument "-Bypass -ScriptBlock {Mount-DiskImage -ImagePath "$($MountPointPath)\$VHDX" -StorageType VHDX -Access ReadWrite}"
	# Create Scheduled task to mount that folder
	
	Write-Verbose -Message "Checking for existing Task Name."
	if($null -eq (Get-ScheduledTask -TaskName $TaskName)){
		Write-Verbose -Message "No existing $TaskName found. Now Creating."
		$TaskTrigger = New-ScheduledTaskTrigger -AtStartup
		Register-ScheduledTask -TaskName $TaskName -Trigger $TaskTrigger -Action $TaskAction -RunLevel Highest -User "System"
	} else {
		Write-Error "$TaskName alread exists."
		Exit 3
	}
}


function Set-VirtualDriveMount{
	[cmdletbinding(SupportsShouldProcess)]
	param(
		[Parameter(Mandatory = $true,HelpMessage="Requested Drive Letter")]
		[string]$DriveLetter
	)
	
	## Excluded Letters
	[array]$ExcludedLetters = @('A:','B:','C:')
	## Create Array for Drive letters in use
	[array]$TakenLetters = @()

	## Add Taken letters to the arrive
	$currentDriveLetters = Get-CimInstance -ClassName Win32_Volume | Select-Object -Property DriveLetter
	ForEach($d in $currentDriveLetters){
		$TakenLetters += "$($_.DriveLetter)"
		$TakenLetters = $TakenLetters | Sort-Object -Unique
	}
	
	## Get Letters that can be assigned
	[array]$AvailLetters = $StandardLetters | Where-Object{$PSItem -notin $TakenLetters}
	
	## Find if the $DriveLetter is available to assign
	If(($AvailLetters | Where-Object{$PSItem -contains "$DriveLetter"}) -ne $null){
		New-VirtualDriveMount -MountPointPath $MountPointPath -TaskName $TaskName -VHDX $VHDX
	} else {
		$DiskDrive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = `'$DriveLetter`'"
		$NewLetter = "$($AvailLetters[0])"
		$DiskDrive | Set-CimInstance -Property @{DriveLetter="$NewLetter"}
		New-VirtualDriveMount -MountPointPath $MountPointPath -TaskName $TaskName -VHDX $VHDX
	} 
}
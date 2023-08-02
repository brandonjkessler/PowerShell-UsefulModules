function Get-IntuneWin32PrepTool {
    <#
    .SYNOPSIS
    Downloads the Intune Win32 Prep tool from Github
    
    .DESCRIPTION
    Downloads the Intune Win32 Prep Tool from Github. It will check to make sure it can reach the URI before downloading.
    It also has parameters for changing the URI, Path, and name of the Exe, but those are also already filled out.
    
    .PARAMETER Path
    Path to where the executable should be downloaded.
    
    .PARAMETER Uri
    URI to the Prep Tool archive file.
    
    .EXAMPLE
    Get-IntuneWin32PrepTool -Verbose

    .EXAMPLE
    Get-IntuneWin32PrepTool -Path "C:\Program Files\IntunePrepTool"
    
    .NOTES
    General notes
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $false,HelpMessage="The name of the executable or application file for the prep tool.")]
        [ValidatePattern('*.exe$')]
        [string]$IntuneExe = 'IntuneWinAppUtil.exe',
        [parameter(Mandatory = $false,HelpMessage="Path to where the executable should be downloaded.")]
        [ValidateScript(
            {
                if((Test-Path -Path $PSItem -PathType Container) -ne $true){
                    Write-Error "Could not locate $PSItem or path is a file and not a directory."
                    Exit 1
                } else {
                    $true
                }
            }
        )]
        [string]$Path = "$PSScriptRoot",
        [parameter(Mandatory = $false,HelpMessage="URI to the Prep Tool archive file.")]
        [ValidateScript(
            {
                $webTest = Invoke-WebRequest -Uri $PSItem -UseBasicParsing -DisableKeepAlive -Method Head
                $successCodes = @('200','201','202','203','204')
                if($successCodes -notcontains $webTest.StatusCode ){
                    Write-Error "Unable to reach $PSItem. StatusCode: $($webTest.StatusCode)."
                    Exit 2
                } else {
                    $true
                }
            }
        )]
        [string]$Uri = 'https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/archive/refs/heads/master.zip'
    )

    if((Test-Path -Path "$Path\$IntuneExe") -ne $true){
        $ZipFile = "Win32PrepTool.zip"
        ##-- Test and download from URI
        Write-Host "Attempting to download from $Uri"
        Write-Host "Downloading archive from $Uri"
        Start-BitsTransfer -Source $Uri -Destination "$($Path)\$($ZipFile)"
        

        ##-- Decompress zip file
        Write-Verbose -Message "Expanding the zip file."
        Expand-Archive -Path "$Path\$ZipFile" -DestinationPath "$Path\IntunePrepTool" -Force
        ##-- Delete the zip
        Write-Verbose -Message "Removing the zip file."
        Remove-Item -Path "$Path\$ZipFile" -Force

        try{
            ##-- Move the EXE to the Path
            Write-Verbose -Message "Checking for the $IntuneExe file in the expanded location and copying it to $Path."
            $file = Get-ChildItem -Path "$Path" -Recurse -Filter "*.exe" | Where-Object{$PSItem.Name -match "$IntuneExe"}
            Copy-Item -Path "$($file.FullName)" -Destination "$Path"
        } catch {
            Write-Error $_.Exception.Message
	        Write-Error $_.Exception.ItemName
            Write-Error "Unable to copy file."
            Exit 2
        }
        
        Write-Verbose -Message "Deleting IntunePrepTool folder."
        Remove-Item -Path "$Path\IntunePrepTool" -Force -Recurse


    
    } else {
        Write-Host "$IntuneExe alread exists at $Path."
    }
}
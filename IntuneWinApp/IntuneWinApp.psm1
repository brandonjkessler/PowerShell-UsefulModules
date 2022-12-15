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
                    Throw "Could not locate $PSItem or path is a file and not a directory."
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
                    Throw "Unable to reach $PSItem. StatusCode: $($webTest.StatusCode)."
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

function New-IntuneWin32App {
    <#
    .SYNOPSIS
    Creates a package for Intune using the prep tool
    
    .DESCRIPTION
    Creates an .intunewin file from a source folder. It will also name it based on the source folder name.
    
    .PARAMETER Path
    Path to source files to create package
    
    .PARAMETER Destination
    Destination to copy the package. Defaults to the source folder in "Path"
    
    .PARAMETER SetupFile
    Setup file to pass to the prep tool.
    
    .PARAMETER Name
    Name of the file. Defaults to the name of the source folder in "Path"
    
    .PARAMETER IntuneExePath
    Path to the Prep Tool executable. Defaults to $PSScriptRoot.    
    
    .PARAMETER IntuneExe
    Name of the Prep tool executable. Defaults to IntuneWinAppUtil.exe but useful for later on if the name changes or if you want to rename the file yourself.
    
    .EXAMPLE
    New-IntuneWin32App -Path 'C:\Scripts\InstallerSetupPSADT' -SetupFile 'Deploy-application.exe' -Destination 'C:\Scripts\IntunePackages'

    .EXAMPLE
    New-IntuneWin32App -Path 'C:\Scripts\InstallerSetupPSADT' -SetupFile 'Deploy-application.exe'

    .EXAMPLE
    New-IntuneWin32App -Path 'C:\Scripts\InstallerSetupPSADT' -SetupFile 'Deploy-application.exe' -Name 'MoreDifferentName'
    
    .NOTES
    General notes
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true,HelpMessage="The path to the content that needs to be packaged.")]
        [ValidateScript(
            {
                if((Test-Path -Path $PSItem -PathType Container) -ne $true){
                    Throw "Could not locate $PSItem or path is a file and not a directory."
                } else {
                    $true
                }
            }
        )]
        [String]$Path,
        [parameter(Mandatory=$false,HelpMessage="The destination path to place the .intunewin file. Defaults to the same as Path.")]
        [ValidateScript(
            {
                if((Test-Path -Path $PSItem -PathType Container) -ne $true){
                    Throw "Could not locate $PSItem or path is a file and not a directory."
                } else {
                    $true
                }
            }
        )]
        [String]$Destination = "$Path",
        [parameter(Mandatory=$true,HelpMessage="The executable or setup file that the .intunewin file will use to execute.")]
        [String]$SetupFile,
        [parameter(Mandatory=$false,HelpMessage="The name you want the .intunewin to be called.")]
        [String]$Name = "$(Split-Path -Path $Path -Leaf)",
        [parameter(Mandatory=$false,HelpMessage="The Path to the Intune Win32 Prep Tool executable. Defaults to the directory where the module is loaded.")]
        [ValidateScript(
            {
                if((Test-Path -Path $PSItem -PathType Container) -ne $true){
                    Throw "Could not locate $PSItem or path is a file and not a directory."
                } else {
                    $true
                }
            }
        )]
        [string]$IntuneExePath = "$PSScriptRoot",
        [parameter(Mandatory = $false,HelpMessage="The name of the executable or application file for the prep tool.")]
        [ValidatePattern('*.exe$')]
        [string]$IntuneExe = 'IntuneWinAppUtil.exe'
    )

    ##-- Test for executable and download if not present
    if((Test-Path -Path "$IntuneExePath/$IntuneExe") -ne $true){
        Write-Warning "Could not locate $IntuneExe in $IntuneExePath."
        Try{
            Write-Host -Message "Attempting Download of executable."
            Get-IntuneWin32PrepTool -Path IntuneExePath -IntuneExe $IntuneExe
        } Catch {
            Write-Error $_.Exception.Message
        }           
    }

    ##-- Run the exe
    Write-Host "Creating file for upload to Intune."
    ##-- IntuneWinAppUtil -c <source_folder> -s <source_setup_file> -o <output_folder> <-a> <catalog_folder> <-q>
    ##-- If -q is specified, it will be in quiet mode. If the output file already exists, it will be overwritten. Also if the output folder does not exist, it will be created automatically. 
    Start-Process -FilePath "$PSScriptRoot\$IntuneExe" -ArgumentList "-c `"$Path`" -s `"$SetupFile`" -o `"$Destination`" -q" -Wait
    Write-Verbose -Message "Searching for new file to rename."
    $intunewinFile = Get-ChildItem -Path "$Destination" -Filter "*.intunewin" | Where-Object{$PSItem.Name -match "$(($SetupFile.Split('.'))[0])"}
    if($null -eq $intunewinFile){
        Write-Error "There was an issue finding the file at $Destination."
        Exit 2
    }
    ## Rename the Item to the preferred Name
    Rename-Item -Path $intunewinFile.FullName -NewName "$($Name)_$(Get-Date -Format yyyy_MM_dd).intunewin" -Force

}
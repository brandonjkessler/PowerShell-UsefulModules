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
                    Write-Error "Could not locate $PSItem or path is a file and not a directory."
                    Exit 1
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
                    Write-Error "Could not locate $PSItem or path is a file and not a directory."
                    Exit 1
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
                    Write-Error "Could not locate $PSItem or path is a file and not a directory."
                    Exit 1
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
            Get-IntuneWin32PrepTool -Path $IntuneExePath -IntuneExe $IntuneExe
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
# SYNOPSIS
PowerShell Module for creating Intune packages (.intunewin)

# DESCRIPTION
Imports multiple functions for working with the [Intune Win32 Prep Tool](https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool).

# HOW TO INSTALL
1. Copy `IntuneWinApp.psm1` to a folder named `IntuneWinApp`.
1. Copy that folder to one of your module locations such as `C:\Program Files\WindowsPowerShell\Modules`
1. ?????
1. Profit
1. Alternatively you can use the `Import-Module` cmdlet to import it for that session.

# FUNCTIONS

## Get-IntuneWin32PrepTool
### SYNOPSIS
Downloads the Intune Win32 Prep tool from Github
    
### DESCRIPTION
Downloads the Intune Win32 Prep Tool from Github. It will check to make sure it can reach the URI before downloading.
It also has parameters for changing the URI, Path, and name of the Exe, but those are also already filled out.
    
### PARAMETER Path
Path to where the executable should be downloaded.
    
### PARAMETER Uri
URI to the Prep Tool archive file.
    
### EXAMPLE
`Get-IntuneWin32PrepTool -Verbose`

### EXAMPLE
`Get-IntuneWin32PrepTool -Path "C:\Program Files\IntunePrepTool"`

## New-IntuneWin32App
### SYNOPSIS
Creates a package for Intune using the prep tool
    
### DESCRIPTION
Creates an .intunewin file from a source folder. It will also name it based on the source folder name.
    
### PARAMETER Path
Path to source files to create package
    
### PARAMETER Destination
Destination to copy the package. Defaults to the source folder in "Path"
    
### PARAMETER SetupFile
Setup file to pass to the prep tool.
    
### PARAMETER Name
Name of the file. Defaults to the name of the source folder in "Path"
    
### PARAMETER IntuneExePath
Path to the Prep Tool executable. Defaults to $PSScriptRoot.    
    
### PARAMETER IntuneExe
Name of the Prep tool executable. Defaults to IntuneWinAppUtil.exe but useful for later on if the name changes or if you want to rename the file yourself.
    
### EXAMPLE
`New-IntuneWin32App -Path 'C:\Scripts\InstallerSetupPSADT' -SetupFile 'Deploy-application.exe' -Destination 'C:\Scripts\IntunePackages'`

### EXAMPLE
`New-IntuneWin32App -Path 'C:\Scripts\InstallerSetupPSADT' -SetupFile 'Deploy-application.exe'`

### EXAMPLE
`New-IntuneWin32App -Path 'C:\Scripts\InstallerSetupPSADT' -SetupFile 'Deploy-application.exe' -Name 'MoreDifferentName'`

# ROADMAP

1. Add an Update function to pull in the latest version of the Prep Tool
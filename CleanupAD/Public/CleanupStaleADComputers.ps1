function Get-StaleADComputers{
    <#
    .SYNOPSIS
    Gets a collection of computers that have not been logged into for '$Days'
    
    .DESCRIPTION
    Gets a collection of computers that have not been logged into for '$Days'.
    User can set the amount of days, but the default is 90.
    Only looks for devices that are Enabled.
    
    .PARAMETER Days
    Amount of days back from current date to look for computers.
    
    .EXAMPLE
    Get-StaleADComputers -Days 180

    .EXAMPLE
    $StaleDevices = Get-StaleADComputers -Days 180
    foreach($i in $StaleDevices){
        Write-Host "$($i.Name) last logged in $($i.LastLogonDate)"
    }
    
    .NOTES
    General notes
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $false,Position = 0)]
        [int]$Days = 90
    )
    #-- Import Modules
    Try{
        Import-Module ActiveDirectory
    } Catch {
        Write-Error "Unable to import Active Directory."
        Write-Error "$($PSItem.Exception.Message)"
        Exit 1

    }
    


    #-- Creates a generic list for returning objects
    #-- similar to an Array but much faster computationally
    [System.Collections.Generic.List[object]]$StaleComputers = @()
    
    $Date = Get-Date
    $DisableDate = ($Date.AddDays(-$Days))
    $Computers = Get-ADComputer -Filter {(OperatingSystem -notlike '*SERVER*') -and (Enabled -eq $true) -and (LastLogonDate -lt $DisableDate)} -Properties LastLogonDate,DistinguishedName,Name,OperatingSystem,Enabled
    #-- Check if each computer is older than the disable days
    foreach($i in $Computers){
        $LastLogon = $i.LastLogonDate
        $LastLogonDays = [math]::Round((New-TimeSpan -Start $LastLogon -End $date).Days)
        Try{
            Write-Verbose "$($i.Name) is Enabled and last logged in $LastLogon, $LastLogonDays days ago."
            $StaleComputers.Add($i)
        } Catch {
            Write-Error "Failed to Disable $($i.Name)."
            Write-Error "$($PSItem.Exception.Message)"
        }
    }

    $StaleComputers
}

function Get-DisabledADComputers {
    <#
    .SYNOPSIS
    Get a list of computers that are disabled in Active Directory
    
    .DESCRIPTION
    Get a list of Active Directory computers that have been disabled.
    Useful for placing in loops or exporting to a text file or csv
    
    .PARAMETER Days
    Amount of days from today's date to check for disabled computers older than that date.
    Defaults to 180 days.

    .EXAMPLE
    Get-DisabledADComputers -Days 180

    .EXAMPLE
    $StaleDevices = Get-DisabledADComputers -Days 180
    foreach($i in $StaleDevices){
        Write-Host "$($i.Name) last logged in $($i.LastLogonDate)"
    }
    
    .NOTES
    General notes
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $false,Position = 0)]
        [int]$Days = 180
    )
    
    #-- Import Modules
    Try{
        Import-Module ActiveDirectory
    } Catch {
        Write-Error "Unable to import Active Directory."
        Write-Error "$($PSItem.Exception.Message)"
        Exit 1

    }

    #-- Creates a generic list for returning objects
    #-- similar to an Array but much faster computationally
    [System.Collections.Generic.List[object]]$DisabledComputers = @()
    
    $Date = Get-Date
    $DeleteDate = ($Date.AddDays(-$Days))
    $Computers = Get-ADComputer -Filter {(OperatingSystem -notlike '*SERVER*') -and (Enabled -eq $false) -and (LastLogonDate -lt $DeleteDate)} -Properties LastLogonDate,DistinguishedName,Name,OperatingSystem,Enabled

    #-- Check if each computer is older than the disable days
    foreach($i in $Computers){
        $LastLogon = $i.LastLogonDate
        $LastLogonDays = [math]::Round((New-TimeSpan -Start $LastLogon -End $date).Days)
        Try{
            Write-Verbose "$($i.Name) is Disabled and last logged in $LastLogon, $LastLogonDays days ago."
            $DisabledComputers.Add($i)
        } Catch {
            Write-Error "Failed to Delete $($i.Name)."
            Write-Error "$($PSItem.Exception.Message)"
        }

    }

    $DisabledComputers

}

function Get-SccmDevices {
    <#
    .SYNOPSIS
    Get a list of SCCM devices
    
    .DESCRIPTION
    Get a list of SCCM devices to save to a variable.
    It makes it faster to compare devices and works with the other functions.
    
    .EXAMPLE
    $sccmDevices = Get-SccmDevices
    
    .NOTES
    General notes
    #>
    [cmdletbinding()]
    param(
        
    )
    try{
        Write-Verbose "Now importing Configuration Manager PowerShell module"
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
        
    } Catch {
        Write-Error "Unable to load SCCM Module."
        Write-Error "$($PSItem.Exception.Message)"
        Exit 1
    }

    ## Create a Return path variable to come back to this spot if needed
    $ReturnPath = (Get-Location).Path


    #--Mount the new PS Drive

    ## Get the CMSite
    Write-Verbose "Getting the Site from PSDrive."
    $Site = Get-PSDrive | Where-Object{$PSItem.Provider -like '*CMSite'}

    ## Mount the CMSite PS Drive
    if($null -eq $Site){
        Write-Error "Unable to pull Site information from PSProvider."
        Exit 1
    }

    try{
        Set-Location "$($Site.Name):"
        Write-Verbose "Setting location to $($Site.Name):"
    } catch {
        Write-Error "Unable to set location to $($Site.Name):"
        Exit 1
    }
    

    ## Create Variables to loop through
    $SccmDevices = Get-CMDevice | Select-Object -Property Name,ResourceID

    Set-Location $ReturnPath

    $SccmDevices

}

function Disable-ADComputer{
    <#
    .SYNOPSIS
    Disables a computer in Active Directory
    
    .DESCRIPTION
    Disables a computer in Active Directory
    
    .PARAMETER ComputerName
    Computer Name of the device to disable

    .EXAMPLE
    Disable-ADComputer -ComputerName DESKTOP-EXAMPLE
    
    .EXAMPLE
    $StaleDevices = Get-DisabledADComputers -Days 180
    foreach($i in $StaleDevices){
        Disable-ADComputer -ComputerName $i.Name
    }
    
    .NOTES
    General notes
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory,Position = 0)]
        [string[]]$ComputerName
    )
    #-- Import Modules
    Try{
        Import-Module ActiveDirectory
    } Catch {
        Write-Error "Unable to import Active Directory."
        Write-Error "$($PSItem.Exception.Message)"
        Exit 1

    }
    $date = Get-Date

    #-- Check if each computer is older than the disable days
    foreach($i in $ComputerName){
        $computer = Get-ADComputer -Filter {Name -like $i} -Properties LastLogonDate,DistinguishedName,Name,OperatingSystem,Enabled
        $LastLogon = $computer.LastLogonDate
        $LastLogonDays = [math]::Round((New-TimeSpan -Start $LastLogon -End $date).Days)
        Try{
            if($PSCmdlet.ShouldProcess("$($computer.DistinguishedName)","Disabling AD Account.")){
                Disable-ADAccount -Identity "$($computer.DistinguishedName)"
                Write-Verbose "$($computer.Name) last logon $lastLogon was $LastLogonDays days ago."
            }
        } Catch {
            Write-Error "Failed to Disable $($computer.Name)."
            Write-Error "$($PSItem.Exception.Message)"
        }
    }
}

function Remove-ADComputer {
    <#
    .SYNOPSIS
    Remove a computer from Active Directory
    
    .DESCRIPTION
    Remove a computer from Active Directory
    
    .PARAMETER ComputerName
    Computer name that you would like to remove.
    
    .EXAMPLE
    Remove-ADComputer -ComputerName DESKTOP-EXAMPLE
    
    .EXAMPLE
    $StaleDevices = Get-DisabledADComputers -Days 180
    foreach($i in $StaleDevices){
        Remove-ADComputer -ComputerName $i.Name
    }
    
    .NOTES
    General notes
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory,Position = 0)]
        [string[]]$ComputerName
    )
    
    #-- Import Modules
    #-- Import Modules
    Try{
        Import-Module ActiveDirectory
    } Catch {
        Write-Error "Unable to import Active Directory."
        Write-Error "$($PSItem.Exception.Message)"
        Exit 1

    }
    $date = Get-Date

    #-- Check if each computer is older than the disable days
    foreach($i in $ComputerName){

        $computer = Get-ADComputer -Filter {Name -like $i} -Properties LastLogonDate,DistinguishedName,Name,OperatingSystem,Enabled
        $LastLogon = $computer.LastLogonDate
        $LastLogonDays = [math]::Round((New-TimeSpan -Start $LastLogon -End $date).Days)
        Try{
            if($PSCmdlet.ShouldProcess("$($computer.DistinguishedName)","Removing AD Object.")){
                Remove-ADObject -Identity "$($computer.DistinguishedName)" -Recursive -Confirm:$false
                Write-Verbose "$($computer.Name) last logon $lastLogon was $LastLogonDays days ago."
            }
        } Catch {
            Write-Error "Failed to Delete $($computer.Name)."
            Write-Error "$($PSItem.Exception.Message)"
        }

    }

}



function Remove-SccmDevice {
    <#
    .SYNOPSIS
    Removes a device from SCCM
    
    .DESCRIPTION
    Removes a device from SCCM.
    Requires ResourceID instead of Computer Name.
    Use in conjunction with Get-SccmDevices
    
    .PARAMETER ResourceID
    The resource ID of the device to remove.
    
    .EXAMPLE
    Remove-SccmDevice -ResourceID 7987987
    
    .EXAMPLE
    $Devices = Get-SccmDevices
    $StaleDevices = Get-DisabledADComputers -Days 180
    foreach($i in $Devices){
        foreach($j in $StaleDevices){
            if($j.Name -match $i.Name){ 
                Remove-SccmDevice -ResourceID $i.ResourceID
            }
        }
        
    }
    
    .NOTES
    General notes
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory,Position = 0)]
        [String[]]$ResourceID
    )
    try{
        Write-Verbose "Now importing Configuration Manager PowerShell module"
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
        
    } Catch {
        Write-Error "Unable to load SCCM Module."
        Write-Error "$($PSItem.Exception.Message)"
        Exit 1
    }

    ## Create a Return path variable to come back to this spot if needed
    $ReturnPath = (Get-Location).Path


    #--Mount the new PS Drive

    ## Get the CMSite
    Write-Verbose "Getting the Site from PSDrive."
    $Site = Get-PSDrive | Where-Object{$PSItem.Provider -like '*CMSite'}

    ## Mount the CMSite PS Drive
    if($null -eq $Site){
        Write-Error "Unable to pull Site information from PSProvider."
        Exit 1
    }

    try{
        Set-Location "$($Site.Name):"
        Write-Verbose "Setting location to $($Site.Name):"
    } catch {
        Write-Error "Unable to set location to $($Site.Name):"
        Exit 1
    }
    


    #-- Look through the SCCM Devices
    foreach($i in $ResourceID){
        Write-Verbose "Now checking CM Devices for a matching $i"
        #-- Now loop through the devices supplied to Computer
        try{
            if($PSCmdlet.ShouldProcess("$($i)","Removing Object from SCCM.")){
                Remove-CMResource -ResourceID "$($i)" -Force
            }
        } Catch {
            Write-Error "Failed to remove $i from SCCM."
            Write-Error "$($PSItem.Exception.Message)"
        }
        
    }

    Set-Location $ReturnPath

}
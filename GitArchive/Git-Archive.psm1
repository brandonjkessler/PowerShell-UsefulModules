function New-GitArchive {
    <#
    .SYNOPSIS
    Uses Git command line to export a Git repo.

    .DESCRIPTION
    Uses Git command line to export a Git repo.  
    Useful for removing bloat of .git folder.
    
    .PARAMETER Path
    Path to the Git repo. This will be the folder that has the .git folder below it.

    .PARAMETER Branch
    This is the branch from git you wish to archive from.
    
    .INPUTS
    Accepts inputs from pipeline that are Path or Branch

    .OUTPUTS
    None.

    .EXAMPLE
    Git-Archive -Path C:\Github\Some-Project -Branch Main

    .LINK
    
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory,ValueFromPipelineByPropertyName,HelpMessage='Path to the folder that has the .git folder under it.')]
        [string]
        $Path,
        [parameter(Mandatory,ValueFromPipelineByPropertyName,HelpMessage='Branch of the git repo that you want to export.')]
        [string]
        $Branch,
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName,HelpMessage='Tag of the git repo that you want to export.')]
        [string]
        $Tag,
        [Parameter(Mandatory = $false, HelpMessage = 'Path to Save Log Files')]
        [string]$LogPath = "$env:Temp\Logs"
    )

    begin{
        #-- BEGIN: Executes First. Executes once. Useful for setting up and initializing. Optional
        if($LogPath -match '\\$'){
            $LogPath = $LogPath.Substring(0,($LogPath.Length - 1))
        }
        Write-Verbose -Message "Creating log file at $LogPath."
        #-- Use Start-Transcript to create a .log file
        #-- If you use "Throw" you'll need to use "Stop-Transcript" before to stop the logging.
        #-- Major Benefit is that Start-Transcript also captures -Verbose and -Debug messages.
        $ScriptName = & { $myInvocation.ScriptName }
        $ScriptName =  (Split-Path -Path $ScriptName -Leaf)
        Start-Transcript -Path "$LogPath\$($ScriptName.Substring(0,($ScriptName.Length) -5)).log"
        $curLoc = Get-Location

        if($Path -match '\\$'){
            $Path = $Path.Substring(0,($Path.Length -1))
        }
        set-location -Path $Path
    }

    process{
        #-- PROCESS: Executes second. Executes multiple times based on how many objects are sent to the function through the pipeline. Optional.
        try{
            #-- Try the things
            $output = "..\"
            $file = split-path "$Path" -leaf ## Name the file the same as the folder
            ## Remove spaces
            $file = $file.Replace(' ','')
            ## Convert dashes to Underscores
            $file = $file.Replace('-','_')
            if($null -eq $Tag -or $Tag -eq ''){
                $gitTag = (git tag -l) | sort-object -Descending ## Test for versions
                if($null -eq $gitTag){ ## If no tags
                    Write-Warning "No Tags."
                } elseif(($gitTag[0].length) -lt 3) { ## if only one tag
                    $file = "$($file)" + "_" + "$($gitTag)"
                } else { ## Multiple tags will name with the latest
                    $file = "$($file)" + "_" + "$($gitTag[0])"
                }
            } else {
                $file = "$($file)" + "_" + "$($Tag)"
            }
        
            powershell.exe -ExecutionPolicy Bypass -Command "git archive --format=zip $Branch --output=$output\$file.zip -0 ."

            #-- Test for Submodule file
            if($null -ne (Get-ChildItem -Path $Path -filter ".gitmodules")){
                $folder = "$($output)$($file)"
                Write-Verbose -Message "Found .gitmodules file. Extracting git archive $folder.zip to copy files."
                if(Test-Path -Path $folder){
                    Write-Warning "Found existing folder with matching name. Renaming."
                    Move-Item -Path "$folder" -Destination "$($folder)_$((Get-Date -Format yyyy-MM-dd_HH-mm))" -force
                }
                Expand-Archive -Path "$folder.zip" -DestinationPath "$folder"
                Write-Verbose -Message "Now removing the archived file $folder.zip."
                Remove-Item -Path "$folder.zip" -Force
                Get-Content -Path ".\.gitmodules" | Where-Object{$_ -Match "path ="} | ForEach-Object{
                    $subFolder = $_.Substring('8').Replace('/','\')
                    Write-Verbose -Message "Now copying submodule $subFolder"
                    Copy-Item -Path "$($Path)\$($subFolder)\*" -Destination "$($folder)\$($subFolder)" -Recurse
                }

                Write-Verbose -Message "Now removing all .gitinclude files."
                Get-ChildItem -Path $folder -Filter "*.gitinclude" -Recurse | ForEach-Object{
                    Write-Verbose -Message "Removing $($_.FullName)"
                    Remove-Item -Path $_.FullName -Force
                }
                Write-Verbose -Message "Creating zip file for $folder."
                Compress-Archive -Path "$folder\*" -DestinationPath "$folder.zip" -CompressionLevel Optimal -Force
                ## Remove the folder after a zip is detected
                if(Test-Path -Path "$($folder).zip"){
                    if(Test-Path -Path $folder){
                        Remove-Item -Path "$folder" -Recurse -Force
                    }
        
                }

            }
        } catch {
            #-- Catch the error
	        Write-Error $_.Exception.Message
	        Write-Error $_.Exception.ItemName
        }
    }
    end{
        # END: Executes Once. Executes Last. Useful for all things after process, like cleaning up after script. Optional.
        Set-Location -Path $curLoc
        Stop-Transcript
    }
}






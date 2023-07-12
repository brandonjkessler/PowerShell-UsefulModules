# Synopsis
Scripts to clean up Active Directory and SCCM.

# Description
Run to cleanup up AD and SCCM using Scheduled tasks on the SCCM Server.
Needs to run as an account that has add/delete/move pivileges in AD and SCCM.
The Functions that remove or disable devices support `-WhatIf`

# How to Run
1. Copy the `CleanupADDevices.ps1` file, and the `Dependencies` folder with all the `.ps1` files in it. To your SCCM Server.
    - **NOTE**: Maintain the folder hierarchy when copying
2. To initially run open PowerShell as a user who can add/delete/move computer objects in both AD and SCCM 
3. Change to the directory where you copied the files and run `CleanupADDevices.ps1`. 
    
    ```
    ./CleanupADDevices.ps1
    ```

    
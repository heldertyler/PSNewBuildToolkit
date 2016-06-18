# PSNewBuildToolkit
PowerShell module to help automate workstation and server deployment where software like SCCM are unavailable to you or your company.

#Purpose
When working for a mid size company with little money to spend on tools, imaging can take a lot of time and can be a very manual process which creates room for error and mistakes. So I created the PowerShell module PSNewBuildToolkit to help automate and make the task of imaging much smoother when enterprise tools are unavailiable to you or your company.

#Requirements
At this time, Windows 7+ and PowerShell version 5.0+ are required to use some of the functions contained within this module. PSWindowsUpdate is also required but functions in this module will install it as needed from PowerShell Gallery.

#Functions
See Help for more details on each function in the module.

Get-SupportStatus is a function that can be used in scripts to easily determine if a workstation is supported. This will prevent the script from running on workstation/server models that you no longer support. The SupportedModels provided should use the WMI Model name. After you run the function  you will get a global variable called $SupportStatus which will return $true or $false that you can use to validate against.
- Syntax: Get-SupportStatus -SupportedModels "Model 1", "Model 2", "Model 3"

Get-WorkstationType is a function that can be used to determine what type of system the script is running on. The idea here is to have this function determine which OU to use when joining the workstation to the domain. A global variable called OU is created with the correct OU for systemtype.
- Syntax: Get-WorkstationType -Laptop "OU=Laptop,DC=Domain,DC=Local" -Desktop "OU=Desktop,DC=Domain,DC=Local" -Server "OU=Server,DC=Domain,DC=Local"

Get-Drivers is a function that allows you to download custom internal driver packs. Basically go to your manufatuer's web site and download their driver pack usually in either a .exe format or .cab format. Extract the drivers to flat files, make any changes or additions to the extracted files and then zip the files (recommended name for zip file would be WMI Model Name with all spaces replaced with "_", Example: HP_EliteBook_745_G2.zip). This function can then be used to download the files from an interally hosted website when needed for the build.
- Syntax: Get-Drivers -BITSSource http//localserver/workstation -BITSDestination C:\Temp -ExtractDestination C:\Drivers -FileName $false

Invoke-Process is a function used to kill explorer if running and to start explorer if it is not running. This prevents technicians from making changes or installations while the script is running.
- Syntax: Invoke-Process -Name explorer

Invoke-InstallDrivers is a function to install drivers. A variable in the function gets all of the class GUIDs of the hardware installed and then it parses through all of the inf driver setup files to see if the class GUID of the driver matches any installed hardware, if there is a match the driver is installed, if there is no matches the driver is skipped. This can be used with Get-Drivers to obtain drivers during process.
- Syntax: Invoke-InstallDrivers -Source C:\SomePath

Invoke-WindowsUpdates is a function that checks is the PSWindowsUpdate module is installed, if it is Windows Updates will be installed, if it isn't the module is installed and then Windows Updates will be installed.
- Syntax: Invoke-WindowsUpdates -UpdateType <Update Type will Prefill>

Invoke-InstallSoftware is a function that allows you to install/update a select few third party software utilizing chocolatey. This allows you to install popular up-to-date third party software without needing to maintain a software fileshare. Enterprise users could implement a local repository using visual studio/IIS which allows companies to host personal packages which would be more secure. This function was created to only install "verified" chocolatey packages which means the package is getting the base software from the actual third parties web site. First the function checks to see if chocolatey has been installed as a Package Provider, if it is, the function will get the installed version and current version of the software and compare the versions. If a mismatch is detected the current version will be installed. If chocolatey is not installed the function will install it and then proceed. Note supported packages will prefil after using the package parameter.
- Syntax: Invoke-InstallSoftware -Packages <Package 1>, <Package 2>, <Package 3> 

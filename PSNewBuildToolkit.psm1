Function Get-SupportStatus {
<#
    .SYNOPSIS
        Get-SupportStatus compares support models against the model of the workstation.

    .DESCRIPTION
        Get-SupportStatus checks if a device is supported by comparing a list of supported models against the actual model of the workstation or server. A global variable $SupportStatus will return $true or $false.

    .PARAMETER SupportedModels
        Used to specify a model or models that are supported within an environment
		
    .EXAMPLE
		Specify Specific Suppport Models (Name's Used Must Match the WMI Model):
			Get-SupportStatus -SupportModels "HP EliteBook 745 G1", "HP EliteBook 745 G2", "HP EliteBook 745 G3"
#>

    [CmdletBinding()]
    param
        (
            [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
            [String[]] $SupportedModels
        )

    $Model = Get-CimInstance -ClassName Win32_ComputerSystem | Select -ExpandProperty Model

    if ($Model -in $SupportedModels)
        
        {
            $Global:SupportStatus = $true
        }

    ELSE
        
        {
            $Global:SupportStatus = $false
        }
}

Function Get-WorkstationType {
<#
    .SYNOPSIS
        Get-WorkstationType determines what the system type is.

    .DESCRIPTION
        Confirm-WorkstationType detmines what the pc system type is and then creates a global variable $OU with the correct OU for the system type

    .PARAMETER Laptop
        Specified specific OU for Laptops

    .PARAMETER Desktop
        Specifies specific OU for Desktops

    .PARAMETER Server
        Specifies specific OU for Servers

    .EXAMPLE
        Set $OU as appropriate OU to use based on the system it is run on:
            Get-WorkstationType -Laptop "OU=Laptop,DC=Domain,DC=Local" -Desktop "OU=Desktop,DC=Domain,DC=Local" -Server "OU=Server,DC=Domain,DC=Local"
#>

    [CmdletBinding()]
    param
        (
            [Parameter(Mandatory=$false)]
            [String] $Laptop,

            [Parameter(Mandatory=$false)]
            [String] $Desktop, 
             
            [Parameter(Mandatory=$false)]
            [String] $Server
        )

    $SystemType = (Get-CimInstance -ClassName Win32_ComputerSystem).PCSystemType
    $Laptop = 2
    $Desktop = @("1","3")
    $Server = @("4","5","7")

    if ($SystemType -eq $Laptop)
        {
            $Global:OU = "$Laptop"
        }

    ELSEIF ($SystemType -in $Desktop)

        {
            $Global:OU = "$Desktop"
        }

    ELSEIF ($SystemType -in $Server)

        {
            $Global:OU = "$Server"
        }

    ELSE

        {
            [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
            $Global:OUPath = [Microsoft.VisualBasic.Interaction]::InputBox("SystemType Not Detected! Please Enter Path: (Example:OU=Laptops,DC=test,DC=local)", "OU Path")
        }
}

Function Get-LastWinUpdate {
<#
    .SYNOPSIS
        Get-LastWinUpdate checks if windows updates were recently installed

    .DESCRIPTION
        Get-LastWinUpdate checks if windows updates were install today, if they are a global variable $WUStatus is created with $true or $false which can be used to validate against.

    .EXAMPLE
        Check is Windows Updates Were Insstalled Today:
			Get-LastWinUpdate
#>

    $LastWUInstallDate = Get-CimInstance -ClassName Win32_QuickFixEngineering -Property InstalledOn | Sort InstalledOn -Descending | Select -ExpandProperty InstalledOn -First 1

    if ((Get-Date).Date -eq $LastWUInstallDate)

        {
            $Global:WUStatus = $true
        }

    ELSE

        {
            $Global:WUStatus = $false
        }
}

Function Get-Drivers {
<#
    .SYNOPSIS
        Get-Drivers utilizes BITS to download custom drivers packs.

    .DESCRIPTION
        Get-Drivers creates a way to download a custom driver pack (in zip format) and then extracts the drivers to a specified location.

    .PARAMETER BITSSource
        Used to specify the root url to a custom driver pack.

    .PARAMETER BITSDestination
        Used to specify location where custom driver pack should be downloaded to.

    .PARAMETER ExtractDestination
        Used to specify location where custom driver pack should be extracted to.

    .PARAMETER FileName
        Used to specify the name of the file to download from internal web site. Use $false is you want to use functions naming scheme

    .NOTES
        If the value of $false is provided for parameter FileName, the following naming scheme will be used: WMI Computer Model Name (all spaces replaced with _) and .zip as file extension.
        Example: HP_EliteBook_745_G2.zip

    .EXAMPLE
		Download Custom Driver Pack Using Function naming Scheme from Interal Website and Extract to Local Drive: 
			Get-Drivers -BITSSource http//localserver/workstation -BITSDestination C:\Temp -ExtractDestination C:\Drivers -FileName $false

        Download Custom Driver Pack from Interal Website and Extract to Local Drive:
            Get-Drivers -BITSSource http://localserver/workstation -BITSDestination C:\Temp -ExtractDestination C:\Drivers -FileName Custom-Filename.zip 
#>

    [CmdletBinding()]
    param
        (
            [Parameter(Mandatory=$true)]
            [String] $BITSSource,
            
            [Parameter(Mandatory=$true)]
            [String] $BITSDestination,
            
            [Parameter(Mandatory=$true)]
            [String] $ExtractDestination,
            
            [Parameter(Mandatory=$true)]
            [AllowNull()]
            [String] $FileName
        )

    if ($FileName -eq $false)

        {
            $FileName = (Get-CimInstance -ClassName Win32_ComputerSystem).Model -replace (' ','_') | ForEach-Object {$_ + '.zip'}
        }
    
    Try
        {
            Start-BitsTransfer -DisplayName "Requesting Driver's" -Description "Initializing Background Intelligent Transfer Service (BITS)" -Source $BITSSource/$filename -Destination $BITSDestination -TransferType Download -Priority High -Verbose -ErrorAction Stop
                Expand-Archive -Path "$BITSDestination\$FileName" -DestinationPath $Extractdestination -Force
                    Remove-Item -Path "$BITSDestination\$FileName" -Force
        }

    Catch [System.Exception]

        {
            Write-Host "ERROR: The Content-Length header is unavailable in the server's HTTP reply. Please Confirm Source URL." -ForegroundColor Red
        }
}

Function Invoke-Process {
<#
    .SYNOPSIS
        Invoke-Process kills explorer if running and starts explorer if not running.

    .DESCRIPTION
        Invoke-Process was created to kill explorer when the build starts so the technician is unable to make changes while the sciprt is running. One the new build process is complete this function should be called again to start explorer.

    .PARAMETER Name
        Specifies the name of the process.

    .EXAMPLE
        Kill Explorer Process if Running, Start Explorer Process if not:
            Invoke-Process -Name explorer.exe
#>

    [CmdletBinding()]
    param
        (
            [Parameter(Mandatory=$true)]
            [String] $Name
        )

    $Process = Get-Process -Name $Name -ErrorAction SilentlyContinue
    if ($Process)
    {
        TASKKILL /F /IM "$Name.exe"
    }
    ELSE
    {
        Start-Process $Name
    }
}

Function Invoke-InstallDrivers {
<#
    .SYNOPSIS
        Invoke-InstallDrivers installs drivers at path provided.

    .DESCRIPTION
        Invoke-InstallDrivers creates a way to bulk install drivers for workstation or server imaging. The function will detect what hardware is installed and will parse the driver setup file (.INF). After parsing, if there is a match between the driver and a peice of hardware installed the driver will be loaded. If there is no match the driver is skipped.

    .PARAMETER Source
        Used to specify a path that contains driver files, path must include the driver setup files.

    .EXAMPLE
		Install Drivers from a Local Source: 
			Invoke-InstallDrivers -Source C:\Drivers
		
		Install Drivers from a Network Share:
			Invoke-InstallDrivers -Source \\Share\Drivers    
#>

    [CmdletBinding()]
    param(

        [Parameter(Mandatory=$true)]
        [String[]] $Source

         )

    $WorkstationGUIDs = (Get-CimInstance -ClassName Win32_PnpEntity).ClassGuid | Sort
    $Drivers = Get-ChildItem -Path "$Source\*" -Recurse | Where {$_.Name -ne "Autorun.inf" -and $_.Extension -eq ".inf"} | Select -ExpandProperty FullName  
    
    Foreach ($Driver in $Drivers)
        {
            $GUID = (Get-Content -Path "$Driver" | Select-String "ClassGuid").Line.Split('=')[-1].Split(' ').Split(';')
            if ($GUID -in $WorkstationGUIDs)

                {
                    Write-Verbose -Message "Installing: $Driver ($GUID)" -Verbose

                        pnputil -i -a $Driver
                }

            ELSE
                
                {
                    Write-Verbose -Message "Skipping: $Driver ($GUID)" -Verbose
                }
        }
}

Function Invoke-WindowsUpdates {
<#
    .SYNOPSIS
        Invoke-WindowsUpdates installs windows updates on workstation.

    .DESCRIPTION
        Invoke-WindowsUpdates is a wrapper function for Get-WUInstall. Function checks if PSWindowsUpdate module is in installed, if not the module is installed and the function is restarted. If it is installed the function will install either software or driver updates.

    .PARAMETER UpdateType
        Used to specify what type of updates you would like to install.
		
    .EXAMPLE
		Install Windows Updates with Type Software:
			Invoke-WindowsUpdates -UpdateType Software
		
		Install Windows Updates with Type Drivers:
			Invoke-WindowsUpdates -UpdateType Drivers
#>

    [CmdletBinding()]
    param
        (

        [Parameter(Mandatory=$true)]
        [ValidateSet("Drivers","Software")]
        [String] $UpdateType

         )

    Get-LastWinUpdate

    if ($WuStatus -eq $false)
        
        { 
            if ((Get-Module -ListAvailable -Name PSWindowsUpdate -ErrorAction SilentlyContinue) -or $Answer -eq "Y")

                {
                    Write-Verbose -Message "Installing Windows Update, Please Be Patient..." -Verbose

                        Get-WUInstall -UpdateType $UpdateType -AcceptAll -IgnoreReboot -verbose
                }

            ELSE

                {
                    Write-Verbose -Message "Installing: PSWindowsUpdate Module..." -Verbose
                
                        Install-Module -Name PSWindowsUpdate -Force

                    Invoke-WindowsUpdates
                }
        }

    ELSE

        {
            Write-Output "Windows Updates Have Been Installed Today"
            $Answer = Read-Host -Prompt "Do you want to run windows updates again? Y or N"

            if ($answer -eq "Y")
                
                {
                    Invoke-WindowsUpdates -UpdateType $UpdateType
                }
        }
}

Function Invoke-InstallSoftware {
<#
    .SYNOPSIS
        Invoke-InstallSoftware installs select third party software.

    .DESCRIPTION
        Invoke-InstallSoftware compares select installed software against current software version. If software is not installed or the installed version doesnt match the current version, the software will be installed/updated. If the installed version matches the current version, no action is taken.

    .PARAMETER Packages
        Used to specify package or packages to run function against
		
    .EXAMPLE
		NOTE: Packages available for use will populate after adding -packages parameter
		Run function against one package:
			Invoke-InstallSoftware -Packages package1
			
		Run function against multiple packages:
			Invoke-InstallSoftware -Packages package1, package2, package3
#>

    [CmdletBinding()]
    param
        (

           [Parameter(Mandatory=$true)]
           [ValidateSet("Adobe*Reader*u*","*flash*player*activex*","Google*Chrome", "*firefox*")]
           [String[]] $Packages

        )

    $PackageList = Find-Package -Name 7zip, adobereader-, ccleaner, cdburnerxp, dropbox, flashp, filezilla, googlechrome, firefox, itunes, jre8, keepass, notepadplusplus, opera, putty, skype, teamviewer, vlc, winrar, winscp -ProviderName Chocolatey | Sort Name

    Try
        {
            if ((Get-PackageProvider -Name "Chocolatey" -ErrorAction Stop).Name -eq "Chocolatey")

                {
                    Write-Verbose -Message "No Additional Package Providers Needed." -Verbose
                }

            ELSE

                {
                    Write-Verbose -Message "Package Provider Chocolatey Missing. Installing..." -Verbose
                        Find-PackageProvider -Name "Chocolatey" -Force -Verbose -ErrorAction Stop
                }
        }

    Catch [System.Exception]

        {
            Write-Host "ERROR: Unable to Find Package Provider. Please Confirm Your Network Connection." -ForegroundColor Red
        }

    Try
        {
            foreach ($Package in $Packages)
                {
                    $Name = ($PackageList | Where {$_.Name -like $Package}).Name
                    $InstalledVersion = (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where {$_.DisplayName -like $Package}).DisplayVersion
                    $CurrentVersion = ($PackageList | Where {$_.Name -like $Package}).Version

                        Write-Output "Software: $Name"
                        Write-Output "Installed Version: $InstalledVersion"
                        Write-Output "Current Version  : $CurrentVersion"

                    if ($InstalledVersion -ne $CurrentVersion)
                        {
                            Write-Verbose -Message "Version Mismatch Found." -Verbose
                            Write-Verbose -Message "Installing $Name, Please Be Patient." -Verbose
                                Install-Package -Name $Name -Credential $Credentials -Verbose -Force -ErrorAction Stop
                        }

                    ELSE
                        
                        {
                            Write-Verbose -Message "$Name is Installed and Current. No Action Taken." -Verbose
                        }
                }
        }

    Catch [System.Exception]

        {
            Write-Host "ERROR: Unable to Find Package. Please Confirm Your Network Connection." -ForegroundColor Red
        }
}
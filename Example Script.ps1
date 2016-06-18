$Host.UI.RawUI.WindowTitle = "New Build Toolkit"

$Date = Get-Date -Format MM-dd-yyyy
$PSNewBuildToolkit = "PSNewBuildToolkit.22F169EDEB3C3F89DFF0F50EBD72FF09.zip"
$Credentials = Get-Credential -Message "Please Enter Your Administrative Domain Credentials:"

    
    Start-Transcript -Path "C:\Temp\$Date.txt" -Append -NoClobber -Force #Creates log file of new build

    Invoke-Process -Name explorer #Kills explorer process to prevent changes while script is running

    Write-Output "Checking if Workstation is Supported."

        Get-SupportStatus -SupportedModels "HP EliteBook 745 G1", "HP EliteBook 800 G2", "Dell Latitute 7550" #Set's supported models for the sciprt

            if ($SupportStatus -eq $true) #Checks if workstation is supported, only continues if true.
                {
                    Start-BitsTransfer -Source "http://webserver/tools/$PSNewBuildToolkit" -Destination "C:\Temp" -Priority High -TransferType Download #Downloads powershell module

                    if (Test-Path C:\Temp\$PSNewBuildToolkit) #Checks if file was downloaded and verifies is file has been modified since packaged in zip
                        {
                            $File = Get-Item -Path "C:\Temp\$PSNewBuildToolkit" | Select -ExpandProperty Name
                            $Hash = Get-FileHash -Path "C:\Temp\$PSNewBuildToolkit" -Algorithm MD5 | Select -ExpandProperty Hash

                            if ($File.Split(".")[1] -eq $Hash)
                                {
                                    Write-Output "Module Has Not Been Modified Since Created."
                                    Write-Output "Extracting Module, Please Be Patient..."

                                        Expand-Archive -Path "C:\Temp\$PSNewBuildToolkit" -DestinationPath "$env:USERPROFILE\Documents\WindowsPowerShell\Modules" -Verbose -Force #Extracts module zip file
                                }

                            ELSE

                                {
                                    Write-Output "$File Has Been Tampered With, Possible Security Concern! Ending Script."
                                    Write-Output "Please contact your administrator."
                                    Break
                        
                                }
                        }

                    Import-Module PSNewBuildToolkit #Imports Module for use

                    if ($env:USERDOMAIN -ne "test.local") #Checks if already on domain, skips is already on domain
                        {
                            Write-Output "Workstation is Supported, Proceeding with Build."
                            Write-Verbose -Message "Downloading and Preparing Driver Pack, Please be Patient..." -Verbose
                                Get-Drivers -BITSSource http://localserver/workstation -BITSDestination C:\Temp -ExtractDestination C:\Drivers -FileName $false #Downloads custom driver pack from internal web server

                            Write-Verbose -Message "Installing Drivers, Please Be Patient..." -Verbose
                                Invoke-InstallDrivers -Source C:\Drivers #note path used should be the same as ExtractDestination in Get-Drivers if used. Installs Drivers

                            Write-Verbose -Message "Checking Which OU to Use..." -Verbose
                            #Outputs correct OU in $OU variable based on what systemtype is detected.
                                Get-WorkstationType -Laptop "OU=Laptops,DC=test,DC=local" -Desktop "OU=Desktops,DC=test,DC=local" -Server "OU=Servers,DC=test,DC=local" 
                                    $NewName = Read-Host "Please Enter New Workstation Name: "
                                    Add-Computer -ComputerName $env:COMPUTERNAME -NewName $NewName -DomainName test.local -OUPath $OU -Credential $Credentials
                        }

                    Get-LastWinUpdate #Gets last windows update date

                    if ($WUStatus -eq $false) #Installs updates if not updated.
                        {
                            Write-Verbose -Message "Installing Windows Updates, Please Be Patient..." -Verbose
                                Invoke-WindowsUpdates -UpdateType Software
                        }

                    Write-Verbose -Message "Installing/Updating Third Party Software, Please Be Patient..."
                        Invoke-InstallSoftware -Packages *firefox*, *flash*player*activex*, Adobe*Reader*u*, Google*Chrome #Installs/updates third party software.


    Invoke-Process -Name explorer #Starts explorer

    Stop-Transcript #Stops transcript log file.

                }

            ELSE
    
                {
                    Write-Output "This Workstation is Currently Not Supported. Please contact your administator."

                        Invoke-Process -Name explorer

                    Stop-Transcript
                }

<#PSScriptInfo

.VERSION 0.1.0

.GUID fb58f019-3bf6-4708-8e72-f6fc1d0025e7

.AUTHOR Michael Greene

.COMPANYNAME Microsoft

.COPYRIGHT 

.TAGS DSCConfiguration

.LICENSEURI https://github.com/mgreenegit/VideoDriverConfig/blob/dev/LICENSE

.PROJECTURI https://github.com/mgreenegit/VideoDriverConfig/

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
https://github.com/mgreenegit/VideoDriverConfig/blob/dev/README.md#ReleaseNotes

.PRIVATEDATA 2016-Datacenter

#>

#Requires -Module @{ModuleName = 'xPSDesiredStateConfiguration'; ModuleVersion = '8.1.0.0'}
#Requires -Module @{ModuleName = 'xPendingReboot'; ModuleVersion = '0.3.0.0'}

<# 

.DESCRIPTION 
 Demonstrates installing video drivers for N series VMs. 

#> 

Configuration VideoDriverConfig
{
    # Folloing documentation located at:
    # https://docs.microsoft.com/en-us/azure/virtual-machines/windows/n-series-driver-setup

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName @{ModuleName = 'xPSDesiredStateConfiguration'; ModuleVersion = '8.1.0.0'}
    Import-DscResource -ModuleName @{ModuleName = 'xPendingReboot'; ModuleVersion = '0.3.0.0'}

    $DriverPath = 'http://us.download.nvidia.com/Windows/Quadro_Certified/390.85/390.85-tesla-desktop-winserver2016-international.exe'
    $AgentPath = 'http://techsupport.teradici.com/FileManagement/Download/fd026319cd364924a696bca7f6659321?token=VFeZ8qyGMDpda0E3s12uj3CAu15PDXUIRol3@H@lhKt5ZTB8jbiLp1t9N5ZWE3L6LpoKi2cXJzt0l/UgD0P4QNw64SUaG5@6HR1h8BNtLxMf4d3fBGXPCDdwkM2Tn7Xi'
    $AgentDestination = 'c:\Teradici\GRA-Win_2.11.0.zip'
    $AgentInstallFiles = 'c:\Teradici\GRA-Win_2.11.0\'
    $AgentInstaller = 'C:\Teradici\GRA-Win_2.11.0\Graphics Agent\Windows\PCoIP_agent_release_installer_2.11.0.9616_graphics.exe'
    $ClientPath = 'http://techsupport.teradici.com/FileManagement/Download/08be589befc94712b3dcf516658f9256?token=yw2O7tvl79SOP3chLW5N4WnVXSy1qgenbZYwmJvtyLFeJHcZ09hOVKg4FyIx1gDvgCs1zbTGEqeO78HnaD7OW4RNFEEWa3a709Wgcro6nDw4gSl79D/VVPUToCDzUl0x'
    $ClientDestination = 'c:\Teradici\SC-Win_3.4.0.zip'
    $ClientInstallFiles = 'c:\Teradici\SC-Win_3.4.0\'
    $ClientInstaller = 'C:\Teradici\SC-Win_3.4.0\Software Clients\Windows\PCoIP_client_release_installer_3.4.0.exe'

    LocalConfigurationManager
    {
     ActionAfterReboot = 'ContinueConfiguration'
     ConfigurationMode = 'ApplyandMonitor'
     RebootNodeIfNeeded = $true
    }

    Package Driver
    {
        Ensure = 'Present'
        Name = 'NVIDIA Graphics Driver 390.85'
        Path = $DriverPath
        ProductId = ''
        Arguments = "/s"
        ReturnCode = '-522182368'
    }

    xPendingReboot Driver
    {
        Name = 'Driver'
        SkipCcmClientSDK = $true
        DependsOn = '[Package]Driver'
    }

    xRemoteFile Agent
    {
        Uri = $AgentPath
        DestinationPath = $AgentDestination
        MatchSource = $false
    }

    Archive Agent
    {
        Ensure = 'Present'
        Path = $AgentDestination
        Destination = $AgentInstallFiles
        DependsOn = '[xRemoteFile]Agent'
    }

    Package Agent
    {
        Ensure = 'Present'
        Name = 'Windows Driver Package - Teradici Printer  (07/13/2016 1.7.0.0)'
        Path = $AgentInstaller
        Arguments = "/S /NoPostReboot _?=$AgentInstaller"
        ProductId = ''
        DependsOn = '[Archive]Agent'
    }

    xRemoteFile Client
    {
        Uri = $ClientPath
        DestinationPath = $ClientDestination
        MatchSource = $false
    }
    
    Archive Client
    {
        Ensure = 'Present'
        Path = $ClientDestination
        Destination = $ClientInstallFiles
        DependsOn = '[xRemoteFile]Client'
    }

    Package Client
    {
        Ensure = 'Present'
        Name = 'Teradici PCoIP Client'
        Path = $ClientInstaller
        Arguments = "/S /NoPostReboot _?=$ClientInstaller"
        ProductId = ''
        DependsOn = '[Archive]Client'
    }

    xPendingReboot AgentClient
    {
        Name = 'AgentClient'
        SkipCcmClientSDK = $true
        DependsOn = '[Package]Agent','[Package]Client'
    }
}

VideoDriverConfig -out c:\dsc
Set-DscLocalConfigurationManager -Path 'c:\dsc' -Verbose
Start-DscConfiguration -Wait -Force -Path 'c:\dsc' -Verbose
<#
    .SYNOPSIS
    Beknopte omschrijving doel van script.
    .DESCRIPTION
    Template voor het maken van scripts

    .NOTES
    Bestandsnaam    : Template.ps1
    Auteur          : Willem Loeven
    Requirements    : Powershell Vx en hoger
                    : modules / infrastructuur etc.
    Referenties     : https://adamtheautomator.com/html-report/

    .LINK
    https://github.com/wloeven
    https://www.willemloeven.nl

    .INPUTS
    inputs voor script parameters etc.
    .OUTPUTS
    outputs van script (logfiles/exports/wijzigingen)
    .EXAMPLE
    Voorbeeld 1

    .EXAMPLE
    Voorbeeld 2
#>
##########################################################################################
# REQUIREMENTS 
##########################################################################################
#Requires -Version 4
#Requires -RunAsAdministrator

##########################################################################################
# Script parameters definieren en laden 
##########################################################################################
[CmdletBinding()]
param (    
    # Help tekst ten behoeve van dit script weergeven.
    [Parameter(Mandatory = $false)]
    [Switch]
    $help,
    # P2 omschrijving.
    [Parameter(Mandatory = $false)]
    [int]
    $P2
)

##########################################################################################
# INCLUDES .Sources en 
##########################################################################################
#laden includes $PSscriptRoot\script.ps1
$ScriptRoot = Switch ($Host.name){
    'Visual Studio Code Host' { split-path $psEditor.GetEditorContext().CurrentFile.Path }
    'Windows PowerShell ISE Host' {  Split-Path -Path $psISE.CurrentFile.FullPath }
    'ConsoleHost' { $PSScriptRoot }
}
. $scriptroot\ReportStyleCSS.ps1
##########################################################################################
# FUNCTIES
##########################################################################################
function Reset-Memory {
    <#
    .SYNOPSIS
    F01 - Reset memory after script completion
    
    .DESCRIPTION
    Function to clear variables and memory after succesfull script execution.
    
    .EXAMPLE
    Reset-Memory
    
    #>
    [CmdletBinding()]
    param (
    )
    begin {
        Write-verbose "$(get-date) Functie Reset-Memory"
    }
    process {
        try {
            Get-Variable | Where-Object { $startupVariables -notcontains $_.Name } | ForEach-Object { try { Remove-Variable -Name "$($_.Name)" -Force -Scope "global" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue } catch { } }              
        }
        catch {
            Write-Error "Error: $($_.Exception)"
            break
        }
    }
    end {
        If ($?) {
            Write-verbose "$(get-date) Functie uitgevoerd."
        }
    }
}
##########################################################################################
# GLOBALE Variabelen
##########################################################################################
$ScriptVersion = "0.1"
$ErrorActionPreference = "SilentlyContinue"
$ScriptDescription = "<Template script>"

##########################################################################################
# Parameter gebaseerde acties
##########################################################################################
if ($help -eq $true) {
    # Show script help.
    Get-Help $MyInvocation.MyCommand.Definition
    return 
}

if ($parameter -eq $true) {
    #Parameter acties
}

##########################################################################################
# Start Script
##########################################################################################
write-verbose "Scriptversie      : $($scriptversion)"
write-verbose "Scriptlocatie     : $($PSSCRIPTROOT)\$($MyInvocation.MyCommand.Name)"
write-verbose "Omschrijving      : $($ScriptDescription)"
write-verbose "Gestart door      : $($env:USERDOMAIN)\$($env:USERNAME)"

#The command below will get the name of the computer
$ComputerName = "<h1>Computer name: $env:computername</h1>"

#The command below will get the Operating System information, convert the result to HTML code as table and store it to a variable
$OSinfo = Get-CimInstance -Class Win32_OperatingSystem | ConvertTo-Html -As List -Property Version,Caption,BuildNumber,Manufacturer -Fragment -PreContent "<h2>Operating System Information</h2>"

#The command below will get the Processor information, convert the result to HTML code as table and store it to a variable
$ProcessInfo = Get-CimInstance -ClassName Win32_Processor | ConvertTo-Html -As List -Property DeviceID,Name,Caption,MaxClockSpeed,SocketDesignation,Manufacturer -Fragment -PreContent "<h2>Processor Information</h2>"

#The command below will get the BIOS information, convert the result to HTML code as table and store it to a variable
$BiosInfo = Get-CimInstance -ClassName Win32_BIOS | ConvertTo-Html -As List -Property SMBIOSBIOSVersion,Manufacturer,Name,SerialNumber -Fragment -PreContent "<h2>BIOS Information</h2>"

#The command below will get the details of Disk, convert the result to HTML code as table and store it to a variable
$DiscInfo = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | ConvertTo-Html -As List -Property DeviceID,DriveType,ProviderName,VolumeName,Size,FreeSpace -Fragment -PreContent "<h2>Disk Information</h2>"

#The command below will get first 10 services information, convert the result to HTML code as table and store it to a variable
$ServicesInfo = Get-CimInstance -ClassName Win32_Service | Select-Object -First 30  |ConvertTo-Html -Property Name,DisplayName,State -Fragment -PreContent "<h2>Services Information</h2>"
$ServicesInfo = $ServicesInfo -replace '<td>Running</td>','<td class="RunningStatus">Running</td>'
$ServicesInfo = $ServicesInfo -replace '<td>Stopped</td>','<td class="StopStatus">Stopped</td>'

#The command below will combine all the information gathered into a single HTML report
$Report = ConvertTo-HTML -Body "$ComputerName $OSinfo $ProcessInfo $BiosInfo $DiscInfo $ServicesInfo" -Head $header -Title "Computer Information Report" -PostContent "<p id='CreationDate'>Creation Date: $(Get-Date)</p>"

#The command below will generate the report to an HTML file
$Report | Out-File $scriptroot\Basic-Computer-Information-Report.html

##########################################################################################
# Einde script
##########################################################################################
Reset-Memory
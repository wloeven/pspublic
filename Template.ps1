<#
    .SYNOPSIS
    Doel van script
    .DESCRIPTION
    Template voor het maken van scrips

    .NOTES
    Bestandsnaam    : Template.ps1
    Auteur          : Willem Loeven
    Requirements    : Powershell V4 en hoger
                    : modules / infrastructuur etc.

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
################################################
# REQUIREMENTS 
################################################
#Requires -Version 4
#Requires -RunAsAdministrator

################################################
# Script parameters definieren en laden 
################################################
[CmdletBinding()]
param (    
    # P1 omschrijving.
    [Parameter(Mandatory = $false)]
    [String]
    $P1,
    # P2 omschrijving.
    [Parameter(Mandatory = $false)]
    [int]
    $P2
)

################################################
# INCLUDES en .Sources
################################################
#laden includes $PSscriptRoot\script.ps1

################################################
# FUNCTIES
################################################
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
        Write-host -foregroundcolor cyan "$(get-date) Functie Reset-Memory"
    }
    
    process {
        try {
            Get-Variable | Where-Object { $startupVariables -notcontains $_.Name } | ForEach-Object { try { Remove-Variable -Name "$($_.Name)" -Force -Scope "global" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue } catch { } }              
        }
        catch {
            Write-Host -BackgroundColor Red "Error: $($_.Exception)"
            break
        }
    }
    
    end {
        If ($?) {
            Write-Host -ForegroundColor Cyan "$(get-date) Functie uitgevoerd."
        }
    }
}
################################################
# GLOBALE Variabelen
################################################
$ScriptVersion = "0.1"
$ErrorActionPreference = "SilentlyContinue"
$ScriptDescription = "<Template script>"

################################################
# Parameter gebaseerde acties
################################################
if ( $PSBoundParameters.Values.Count -eq 0 -and $args.count -eq 0 ) {
    Get-Help $MyInvocation.MyCommand.Definition
    return 
    }
if ( $PSBoundParameters.Values.Count -eq 0 ){ 
    Write-Output ("Geen parameters opgegeven")     
    return
    }
if ( $args -and $args.count -gt 0 ) {
    Write-Output ("Volgende argumenten opgegeven $args")  
}

if ($parameter -eq $true) {
    #Parameter acties
}

################################################
# Start Script
################################################
write-verbose "Scriptversie      : $($scriptversion)"
write-verbose "Scriptlocatie     : $($PSSCRIPTROOT)\$($MyInvocation.MyCommand.Name)"
write-verbose "Omschrijving      : $($ScriptDescription)"
write-verbose "Gestart door      : $($env:USERDOMAIN)\$($env:USERNAME)"
Write-verbose ""



################################################
# Einde script
################################################
Reset-Memory
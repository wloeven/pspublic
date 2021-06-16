<#
    .SYNOPSIS
    vergelijken gebruikers en hun groepslidmaatschappen.
    .DESCRIPTION
    vergelijken gebruikers en hun groepslidmaatschappen.

    .NOTES
    Bestandsnaam    : CompareUsers.ps1
    Auteur          : Willem Loeven
    Requirements    : Powershell Vx en hoger
                    : ActiveDirectory module en leesrechten

    .LINK
    https://github.com/wloeven
    https://www.willemloeven.nl

    .INPUTS
    -left = Referentie gebruikersnaam
    -right = te controleren gebruiker
    .OUTPUTS
    CSV bestand met daarin de vergelijking tussen de opgegeven gebruikers.
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
    #Left part of the comparison
    [Parameter(Mandatory = $true)]
    [string]
    $left,
    #Right part of the comparison
    [Parameter(Mandatory = $true)]
    [string]
    $right
        
)

##########################################################################################
# INCLUDES en .Sources
##########################################################################################
#laden includes $PSscriptRoot\script.ps1

##########################################################################################
# FUNCTIES
##########################################################################################
function Reset-Memory {
    <#
    .SYNOPSIS
    F01 - Reset memory after script completion
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
function Compare-Users {
    <#
    .SYNOPSIS
    Functie voor het vergelijken van lidmaatschap van groepen tussen 2 gebruikers
    .PARAMETER user1
    Referentie gebruiker
    
    .PARAMETER user2
    te testen gebruiker
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true)]
        [string]$user1,
        [Parameter(Mandatory=$true)]
        [string]$user2
    )
    begin {
        Write-verbose "$(get-date) Functie Compare-Users"        
    }
    process {
        $ul1 = Get-AdPrincipalGroupMembership $user1 | select-object name | sort-object name
        $ul2 = Get-AdPrincipalGroupMembership $user2 | select-object name | sort-object name
        $compared = Compare-Object -ReferenceObject $ul1 -DifferenceObject $ul2 -property name -includeEqual
        $list = { } | select-object Group, $user1, $user2
        foreach ($g in $compared){
            write-verbose "$($g.name) | $($user1) $($g.sideIndicator) $($user2)"
            $list.$($user1) = ""
            $list.$($user2) = ""
            $list.group = $g.name
            if ($($g.SideIndicator) -eq "=="){
                $list.$($user1) = "X"
                $list.$($user2) = "X"
            }
            if ($($g.SideIndicator) -eq "<="){
                $list.$($user1) = "X"
                $list.$($user2) = " "
            }
            if ($($g.SideIndicator) -eq "=>"){
                $list.$($user1) = " "
                $list.$($user2) = "X"
            }
            $csvfile = "$($user1)-$($user2)-$(get-date -format ddMMyy-Hm).csv"
            $list | Export-Csv -Path $PSSCRIPTROOT\$csvfile -Delimiter ";" -Append -NoTypeInformation
        }
    }
    end {
        If ($?) {
            Write-verbose "$(get-date) Functie uitgevoerd."
            Write-verbose "$(get-date) CSV aangemaakt: $($PSSCRIPTROOT)\$csvfile.csv"
        }        
    }
}
##########################################################################################
# GLOBALE Variabelen
##########################################################################################
$ScriptVersion = "0.1"
$ErrorActionPreference = "SilentlyContinue"
$ScriptDescription = "Compare User memberships and security descriptors"

##########################################################################################
# Parameter gebaseerde acties
##########################################################################################
if ($help -eq $true) {
    # Show script help.
    Get-Help $MyInvocation.MyCommand.Definition
    return 
}

##########################################################################################
# Start Script
##########################################################################################
write-verbose "Scriptversie      : $($scriptversion)"
write-verbose "Scriptlocatie     : $($PSSCRIPTROOT)\$($MyInvocation.MyCommand.Name)"
write-verbose "Omschrijving      : $($ScriptDescription)"
write-verbose "Gestart door      : $($env:USERDOMAIN)\$($env:USERNAME)"

Compare-Users -user1 $left -user2 $right

##########################################################################################
# Einde script
##########################################################################################
Reset-Memory

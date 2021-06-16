<#
    .SYNOPSIS
    Cleanup Stale SID history of users in AD
    .DESCRIPTION
    Script used to cleanup SID history for users in Active Directory environments to facilitate Exchange operations

    .NOTES
    Bestandsnaam    : CleanUpSid-Exchange.ps1
    Auteur          : Willem Loeven
    Requirements    : Powershell Vx en hoger
                    : modules / infrastructuur etc.
    References      : Microsoft Technet
                      https://lazywinadmin.com/2011/11/active-directory-how-to-remove-sid.html
                      https://ingogegenwarth.wordpress.com/2015/04/01/the-good-the-bad-and-sidhistory/

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

function Get-RightsGuid {
    <#
    .SYNOPSIS
    Functie om GUID op te halen van gespecificeerde rechten in parameter $right
    
    .DESCRIPTION
    Deze functie haalt de GUID op van een specifiek rechten object uit Active Directory
    
    .PARAMETER right
    Het Recht waarvan het GUID opgevraagd moet worden.
    
    .EXAMPLE
    Get-RightsGuid -right Send-As 
    Hiermee wordt het GUID van Send-As binnen het Active Directory opgevraagd
    #>
    [CmdletBinding()]
    param (
    $right     
    )
    
    begin {
        Write-verbose "$(get-date) Functie Get-RightsGuid"        
    }
    
    process {
        try {
            $Filter = "(&(objectClass=controlAccessRight)(name=$right))"
            $root= ([ADSI]'LDAP://RootDse').configurationNamingContext
            $searcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI]"LDAP://$root")
            $searcher.filter = "$Filter"
            $searcher.pagesize = 1000
            $results = $searcher.findone()
            $results.Properties.rightsguid
        }
        catch {
            $_.ErrorMessage
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

# get history for user
Get-ADUser -Identity Test1 -Properties SidHistory | Select-Object -ExpandProperty SIDHistory

# remove history for user
Set-ADUser -Identity Test1 -Remove @{SIDHistory='S-1-5-21-2318250509-2900162015-863429321-1127'}
Get-ADUser -Identity Migrated3 -Properties SidHistory | Select-Object -ExpandProperty SIDHistory | Select-Object -ExpandProperty Value
Get-ADUser -Identity Migrated3 -Properties SidHistory | Select-Object -ExpandProperty SIDHistory | Select-Object -ExpandProperty Value | ForEach-Object {Set-ADUser -Identity Migrated3 -Remove @{SIDHistory="$_"}}
Get-ADUser -Identity Migrated3 -Properties SidHistory | Select-Object -ExpandProperty SIDHistory


# obv rechten guid SID's uitlezen
([ADSI](([ADSISearcher]"(samaccountname=Shared01)").FindOne().Path)).psbase.ObjectSecurity
([ADSI](([ADSISearcher]"(samaccountname=Shared01)").FindOne().Path)).psbase.ObjectSecurity.Sddl.split("(") | ForEach-Object {$_.Trim(")")}

$allSIDs=([ADSI](([ADSISearcher]"(samaccountname=Shared01)").FindOne().Path)).psbase.ObjectSecurity.Sddl.split("(") | ForEach-Object{$_.Trim(")")}
$sids = $allSIDs -match $right | Select-Object @{l="SID";e={$_.Split(";")[5]}} | Where-Object {$_ -match "S-1"}
$sids

##########################################################################################
# Einde script
##########################################################################################
Reset-Memory
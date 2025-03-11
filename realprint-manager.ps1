# Configurables
Set-Location "\\epic-dc1-fs01\root\Citrix\RealPrint\"
$host.UI.RawUI.WindowTitle = "Real Print Manager"
$ErrorActionPreference = 'SilentlyContinue'
$dataBase = "\\epic-dc1-fs01\root\Citrix\RealPrint\database\" # need trailing \ here
$endpoint = $null # clear any other value
$PrintServers = @(
"lcmc-prtsrv01.lcmchealth.org",
"lcmc-prtsrv02.lcmchealth.org",
"lcmc-prtsrv03.lcmchealth.org")

function Get-Heading {
    Clear-Host
    Write-Host ""
    .\Convertto-TextASCIIArt.ps1 -Text ' Real Print' -FontColor Yellow
    Write-Host "  Citrix app & desktop printing simplified."
    Start-Sleep -S 1
    Write-Host ""
    Write-Host ""
}

function Get-Endpoint {
Write-Host "Seleted endpoint: " -ForegroundColor Cyan -nonewline
If ($endPoint -eq $null) {Write-Host "" -ForegroundColor Yellow -NoNewLine
    Write-Host "[" -NoNewLine
    Write-Host "No endpoint selected" -Foreground Red -NoNewLine
    Write-Host "]"
    }
Else {
    Write-Host "$endPoint" -ForegroundColor Yellow
    }
$isThere = $dataBase + $endPoint + '.json'
if (Test-Path -Path $isThere) {
    $assignedPrinters = get-content $isThere -Raw | ConvertFrom-Json
    $outputPrinters = $assignedPrinters.computer.printers | Out-String -Stream | Where { $_.Trim().Length -gt 0 }
    If ($outputPrinters) {
        Write-Host "--------------------------------------------------------------------" -nonewline
        write-host ""
        write-host "Printers assigned" -foregroundcolor green
        $outputPrinters
        Write-Host "--------------------------------------------------------------------"
        }
    Else {
        Write-Host "--------------------------------------------------------------------"
        Write-Host "[" -NoNewLine
        Write-Host "No printers added" -foreground red -NoNewLine
        Write-Host "]"
        Write-Host "--------------------------------------------------------------------"
        }
    }
Else {
    Write-Host "--------------------------------------------------------------------"
    Write-Host "[" -NoNewLine
    Write-Host "No printers added" -foreground red -NoNewLine
    Write-Host "]"
    Write-Host "--------------------------------------------------------------------"
    }
}

function Get-Menu {
    Start-Sleep -S 1
    Write-Host ""
    Write-Host ""
    Write-Host "Main menu" -Foreground Cyan
    Write-Host "--------------------------------------------------------------------"
    Write-Host "  Enter " -NoNewline
    Write-Host " S " -NoNewline -ForegroundColor Yellow
    Write-Host "for: " -NoNewline
    Write-Host "Select endpoint to manage" -ForegroundColor Green
    Write-Host "--------------------------------------------------------------------"

    Write-Host "  Enter " -NoNewline
    Write-Host " 1 " -NoNewline -ForegroundColor Yellow
    Write-Host "for: " -NoNewline
    Write-Host "Add printer" -ForegroundColor Green

    Write-Host "  Enter " -NoNewline
    Write-Host " 2 " -NoNewline -ForegroundColor Yellow
    Write-Host "for: " -NoNewline
    Write-Host "Delete printer" -ForegroundColor Green

    Write-Host "  Enter " -NoNewline
    Write-Host " 3 " -NoNewline -ForegroundColor Yellow
    Write-Host "for: " -NoNewline
    Write-Host "Set default printer" -ForegroundColor Green -NoNewLine
    Write-Host " [" -NoNewLine
    Write-Host "printer must be added already" -Foregroundcolor yellow -NoNewLine
    Write-Host "]"

    Write-Host "  Enter " -NoNewline
    Write-Host " 4 " -NoNewline -ForegroundColor Yellow
    Write-Host "for: " -NoNewline
    Write-Host "List print servers and printers" -ForegroundColor Green

    Write-Host "  Enter " -NoNewline
    Write-Host " 5 " -NoNewline -ForegroundColor Yellow
    Write-Host "for: " -NoNewline
    Write-Host "How to use Real Print Manager?" -ForegroundColor Green

    Write-Host "--------------------------------------------------------------------"
    Write-Host "  Enter " -NoNewLine
    Write-Host " Q " -NoNewLine -Foreground yellow
    Write-Host "to quit Real Print Manager"
    Write-Host "" -NoNewline
}

# Show menu function
function Show-Menu
{
    param (
           [string]$Title = 'Real Print'
    )

Get-Heading
Get-Endpoint
Get-Menu

}


# Run menu function
do
{
     Show-Menu
     $input = Read-Host "  `nPlease make a selection"
     switch ($input)
     {
         's' {
        Get-Heading
        Get-Endpoint

        Write-Host ""
        Write-Host "Select endpoint to manage" -Foreground Cyan
        Write-Host "--------------------------------------------------------------------"
        Write-Host "  Enter the name of a different endpoint."
        Write-Host "--------------------------------------------------------------------"
        Write-Host ""
        $switchEndpoint = Read-Host "Endpoint (or R to return to Main Menu)"
        If ($switchEndpoint -eq 'r') {Write-Host ""
             Pause
             Break}
        # Endpoint results
        $endPoint = $switchEndpoint
        Write-Host "--------------------------------------------------------------------" -nonewline
        $isThere = $dataBase + $endPoint + '.json'
        $assignedPrinters = get-content $isThere -Raw | ConvertFrom-Json
        write-host ""
        write-host "Printers assigned" -foregroundcolor green
        $assignedPrinters.computer.printers | Out-String -Stream | Where { $_.Trim().Length -gt 0 }
        Write-Host "--------------------------------------------------------------------"

        # If not found prompt to add endpoint entry
        If (-not $assignedPrinters) {
        Clear-Host
        Get-Heading
        Write-Host "Endpoint:" -ForegroundColor Cyan -NoNewline
        Write-Host " $endPoint" -ForegroundColor Yellow
        Write-Host "No record found!" -ForegroundColor Red
        Write-Host ""
        $addEndpoint = Read-Host "Would you like to add an entry? (y/n)"
        If ($addEndpoint -eq 'y') {$createFolder = New-Item $isThere
            Write-Host ""

# because of formating needs to be all the way left
$jsonString = @"
{
  "computer": {
    "name": "$endPoint",
    "printers": []
  }
}
"@
            $jsonString | Set-Content -Path $isThere
            Write-Host "Entry for $endPoint created!" -ForegroundColor Green
            Pause}
        Else {Write-Host ""
            $endPoint = $null
            Pause}
            }

        } '1' {
        Get-Heading
        Get-Endpoint

        Write-Host ""
        Write-Host ""
        Write-Host "Add printer" -Foreground Cyan
        Write-Host "--------------------------------------------------------------------"
        Write-Host "  Enter the name of the printer you'd like to assign to"
        Write-Host "  This end point. The print server info is not required."
        Write-Host "--------------------------------------------------------------------"
        Write-Host ""
        $addPrinter = Read-Host "Add printer (or R to return to Main Menu)"
            If ($addPrinter -eq 'r') {Write-Host ""
                Pause
                Break}
            $printServers = $printServers | Sort-Object -Property {Get-Random}
            ForEach ($PrintServer in $PrintServers) {
                $searchResult = invoke-command -computername $PrintServer -ScriptBlock {Get-Printer -name $using:addPrinter}
                If (($searchResult).name -eq $addPrinter) {
                $newPrinter = [PSCustomObject]@{
                    name = $addPrinter
                    server = $PrintServer
                    isDefault = $false
                }
                    $json = Get-Content -Path $isThere | ConvertFrom-Json
                    $json.computer.printers += $newPrinter
                    $json | ConvertTo-Json -Depth 3 | Set-Content -Path $isThere
                break
                }
            }
            Write-Host ""
            Pause

        } '2' {
        Get-Heading
        Get-Endpoint

        Write-Host ""
        Write-Host ""
        Write-Host "Delete printer" -Foreground Red
        Write-Host "--------------------------------------------------------------------"
        Write-Host "  You need only enter the printer name. The print"
        Write-Host "  server or full path is not required."
        Write-Host "--------------------------------------------------------------------"
        Write-Host ""
        $deletePrinter = Read-Host "Delete printer (or R to return to Main Menu)"
        If ($deletePrinter -eq 'r') {Write-Host ""
            Pause
            Break}

        $json = Get-Content -Path $isThere | ConvertFrom-Json
        $json.computer.printers = @($json.computer.printers | Where-Object { $_.name -ne $deletePrinter })
        $json | ConvertTo-Json -Depth 3 | Set-Content -Path $isThere

        Write-Host ""
        Pause

        } '3' {
        Get-Heading
        Get-Endpoint

        write-host ""
        Write-Host ""
        Write-Host "Set default printer" -Foreground Cyan
        Write-Host "--------------------------------------------------------------------"
        Write-Host "  You need only enter the printer name. The print"
        Write-Host "  server or full path is not required. If a default"
        Write-Host "  is already set the printer will continue to be"
        Write-Host "  mapped but your new choice will become the default."
        Write-Host "--------------------------------------------------------------------"
        Write-Host ""
        $defaultPrinter = Read-Host "Default printer (or R to return to Main Menu)"
        If ($defaultPrinter -eq 'r') {Write-Host ""
            Pause
            Break}

        $json = Get-Content -Path $isThere | ConvertFrom-Json
        foreach ($printer in $json.computer.printers) {
        if ($printer.name -eq $defaultPrinter) {
            $printer.isDefault = $true
            }
        else  {
            $printer.isDefault = $false
            }
        }
        $json | ConvertTo-Json -Depth 3 | Set-Content -Path $isThere

        write-host ""
        pause

        } '4' {
        Get-Heading
        Get-Endpoint

        Write-Host ""
        Write-Host ""
        Write-Host "!Feature under construction!" -ForegroundColor Red
        Write-Host "Current print servers accessed by Real Print" -ForegroundColor Cyan
        Write-Host "--------------------------------------------------------------------"
        $PrintServers
        Write-Host "--------------------------------------------------------------------"
        Write-Host ""
        Write-Host "Generating list of printservers and printers..." -ForegroundColor Yellow -NoNewLine
        $PrinterResults = $PrintServers | Foreach-Object { get-printer -cn $_  -ErrorAction SilentlyContinue | select @{name='Printer Name';expression={$($_.Name)}}, @{name='Print Server';expression={$($_.ComputerName)}}, @{name='Site';expression={$($_.Location)}}, @{name='Print Driver Installed';expression={$($_.DriverName)}} }
        $PrinterResults | Out-GridView -Title 'Easy Search for all LCMC Printer Info'
        Write-Host "completed!" -ForegroundColor Green
        Write-Host ""
        Pause

        } '5' {
        Get-Heading

        Write-Host "Welcome to Real Print Manager" -ForegroundColor Yellow
        Write-Host "Here you can assign printers to endpoints which"
        Write-Host "will result in these printers being mapped to"
        Write-Host "user sessions for Citrix session connected"
        Write-Host "through that endpoint."
        Write-Host ""
        Write-Host "What is an Endpoint?" -ForegroundColor Yellow
        Write-Host "Any computer connecting to a Citrix session."
        Write-Host " • " -NoNewLine
        Write-Host "Windows" -ForegroundColor Cyan
        Write-Host " • " -NoNewLine
        Write-Host "Linux" -ForegroundColor Cyan
        Write-Host " • " -NoNewLine
        Write-Host "MAC" -ForegroundColor Cyan
        Write-Host " • " -NoNewLine
        Write-Host "iOS" -ForegroundColor Cyan
        Write-Host " • " -NoNewLine
        Write-Host "Android" -ForegroundColor Cyan
        Write-Host " • " -NoNewLine
        Write-Host "Igel" -ForegroundColor Cyan
        Write-Host " • " -NoNewLine
        Write-Host "Wyse device" -ForegroundColor Cyan
        Write-Host " • " -NoNewLine
        Write-Host "Windows embedded" -ForegroundColor Cyan
        Write-Host " • " -NoNewLine
        Write-Host "Thin client of any kind" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "When does this happen?" -ForegroundColor Yellow
        Write-Host "At each user login or new session for a Citrix"
        Write-Host "session."
        Write-Host ""
        Write-Host "What do you need to know?" -ForegroundColor Yellow
        Write-Host "To start the name of an endpoint. Enter that below"
        Write-Host "to look up what printers are assigned or create an"
        Write-Host "entry for this endpoint to then assign printers."
        Write-Host ""
        Pause

          } 'm' {

          }

     }
}
until ($input -eq 'q')
t "to look up what printers are assigned or create an"
        Write-Host "entry for this endpoint to then assign printers."
        Write-Host ""
        Pause

          } 'm' {

          }

     }
}
until ($input -eq 'q')

# Configurables
Set-Location "\\epic-dc1-fs01\root\Citrix\RealPrint\"
$host.UI.RawUI.WindowTitle = "Real Print Manager"
$ErrorActionPreference = 'SilentlyContinue'

# Global Variables
$dataBase = "\\epic-dc1-fs01\root\Citrix\RealPrint\database\"  # Requires trailing \
$endpoint = $null                                              # Clear any previous value
$PrintServers = @(
    "lcmc-prtsrv01.lcmchealth.org"
    "lcmc-prtsrv02.lcmchealth.org"
    "lcmc-prtsrv03.lcmchealth.org"
)

# Functions
function Get-Heading {
    Clear-Host
    Write-Host ""
    .\Convertto-TextASCIIArt.ps1 -Text ' Real Print' -FontColor Yellow
    Write-Host "  Citrix app & desktop printing simplified."
    Start-Sleep -Seconds 1
    Write-Host "`n"
}

function Get-Endpoint {
    Write-Host "Selected endpoint: " -ForegroundColor Cyan -NoNewline
    if ($null -eq $endPoint) {
        Write-Host "" -ForegroundColor Yellow -NoNewLine
        Write-Host "[" -NoNewLine
        Write-Host "No endpoint selected" -ForegroundColor Red -NoNewLine
        Write-Host "]"
    } else {
        Write-Host "$endPoint" -ForegroundColor Yellow
    }

    $isThere = Join-Path $dataBase "$endPoint.json"
    if (Test-Path -Path $isThere) {
        $assignedPrinters = Get-Content $isThere -Raw | ConvertFrom-Json
        $outputPrinters = $assignedPrinters.computer.printers | 
                         Out-String -Stream | 
                         Where-Object { $_.Trim().Length -gt 0 }
        
        if ($outputPrinters) {
            Write-Host "--------------------------------------------------------------------"
            Write-Host "Printers assigned" -ForegroundColor Green
            $outputPrinters
            Write-Host "--------------------------------------------------------------------"
        } else {
            Write-Host "--------------------------------------------------------------------"
            Write-Host "[" -NoNewLine
            Write-Host "No printers added" -ForegroundColor Red -NoNewLine
            Write-Host "]"
            Write-Host "--------------------------------------------------------------------"
        }
    } else {
        Write-Host "--------------------------------------------------------------------"
        Write-Host "[" -NoNewLine
        Write-Host "No printers added" -ForegroundColor Red -NoNewLine
        Write-Host "]"
        Write-Host "--------------------------------------------------------------------"
    }
}

function Get-Menu {
    Start-Sleep -Seconds 1
    Write-Host "`n`nMain menu" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------------------"
    
    $menuOptions = @(
        @{Key="S"; Desc="Select endpoint to manage"}
        @{Key="1"; Desc="Add printer"}
        @{Key="2"; Desc="Delete printer"}
        @{Key="3"; Desc="Set default printer"; Note="printer must be added already"}
        @{Key="4"; Desc="List print servers and printers"}
        @{Key="5"; Desc="How to use Real Print Manager?"}
    )
    
    foreach ($option in $menuOptions) {
        Write-Host "  Enter " -NoNewline
        Write-Host "$($option.Key) " -ForegroundColor Yellow -NoNewline
        Write-Host "for: " -NoNewline
        Write-Host "$($option.Desc)" -ForegroundColor Green -NoNewline
        if ($option.Note) {
            Write-Host " [" -NoNewline
            Write-Host "$($option.Note)" -ForegroundColor Yellow -NoNewline
            Write-Host "]"
        } else {
            Write-Host ""
        }
    }
    
    Write-Host "--------------------------------------------------------------------"
    Write-Host "  Enter " -NoNewLine
    Write-Host "Q " -ForegroundColor Yellow -NoNewLine
    Write-Host "to quit Real Print Manager"
    Write-Host ""
}

function Show-Menu {
    param (
        [string]$Title = 'Real Print'
    )
    Get-Heading
    Get-Endpoint
    Get-Menu
}

# Main Menu
do {
    Show-Menu
    $input = Read-Host "  `nPlease make a selection"
    
    switch ($input) {
        's' {
            Get-Heading
            Get-Endpoint
            Write-Host "`nSelect endpoint to manage" -ForegroundColor Cyan
            Write-Host "--------------------------------------------------------------------"
            Write-Host "  Enter the name of a different endpoint."
            Write-Host "--------------------------------------------------------------------"
            $switchEndpoint = Read-Host "`nEndpoint (or R to return to Main Menu)"
            
            if ($switchEndpoint -eq 'r') { Write-Host ""; Pause; Break }
            
            $endPoint = $switchEndpoint
            $isThere = Join-Path $dataBase "$endPoint.json"
            
            if (Test-Path $isThere) {
                $assignedPrinters = Get-Content $isThere -Raw | ConvertFrom-Json
                Write-Host "--------------------------------------------------------------------"
                Write-Host "Printers assigned" -ForegroundColor Green
                $assignedPrinters.computer.printers | 
                    Out-String -Stream | 
                    Where-Object { $_.Trim().Length -gt 0 }
                Write-Host "--------------------------------------------------------------------"
            } else {
                Clear-Host
                Get-Heading
                Write-Host "Endpoint:" -ForegroundColor Cyan -NoNewline
                Write-Host " $endPoint" -ForegroundColor Yellow
                Write-Host "No record found!" -ForegroundColor Red
                $addEndpoint = Read-Host "`nWould you like to add an entry? (y/n)"
                
                if ($addEndpoint -eq 'y') {
                    $null = New-Item $isThere -Force
                    $jsonString = @{
                        computer = @{
                            name = $endPoint
                            printers = @()
                        }
                    } | ConvertTo-Json -Depth 3
                    $jsonString | Set-Content -Path $isThere
                    Write-Host "`nEntry for $endPoint created!" -ForegroundColor Green
                    Pause
                } else {
                    $endPoint = $null
                    Write-Host ""
                    Pause
                }
            }
        }
        
        '1' {
            Get-Heading
            Get-Endpoint
            Write-Host "`n`nAdd printer" -ForegroundColor Cyan
            Write-Host "--------------------------------------------------------------------"
            Write-Host "  Enter the name of the printer you'd like to assign to"
            Write-Host "  this endpoint. The print server info is not required."
            Write-Host "--------------------------------------------------------------------"
            $addPrinter = Read-Host "`nAdd printer (or R to return to Main Menu)"
            
            if ($addPrinter -eq 'r') { Write-Host ""; Pause; Break }
            
            $printServers = $printServers | Sort-Object { Get-Random }
            foreach ($PrintServer in $PrintServers) {
                $searchResult = Invoke-Command -ComputerName $PrintServer -ScriptBlock {
                    Get-Printer -Name $using:addPrinter
                }
                if ($searchResult.Name -eq $addPrinter) {
                    $newPrinter = [PSCustomObject]@{
                        name     = $addPrinter
                        server   = $PrintServer
                        isDefault = $false
                    }
                    $json = Get-Content $isThere | ConvertFrom-Json
                    $json.computer.printers += $newPrinter
                    $json | ConvertTo-Json -Depth 3 | Set-Content $isThere
                    break
                }
            }
            Write-Host ""
            Pause
        }
        
        '2' {
            Get-Heading
            Get-Endpoint
            Write-Host "`n`nDelete printer" -ForegroundColor Red
            Write-Host "--------------------------------------------------------------------"
            Write-Host "  You need only enter the printer name. The print"
            Write-Host "  server or full path is not required."
            Write-Host "--------------------------------------------------------------------"
            $deletePrinter = Read-Host "`nDelete printer (or R to return to Main Menu)"
            
            if ($deletePrinter -eq 'r') { Write-Host ""; Pause; Break }
            
            $json = Get-Content $isThere | ConvertFrom-Json
            $json.computer.printers = @($json.computer.printers | Where-Object { $_.name -ne $deletePrinter })
            $json | ConvertTo-Json -Depth 3 | Set-Content $isThere
            Write-Host ""
            Pause
        }
        
        '3' {
            Get-Heading
            Get-Endpoint
            Write-Host "`n`nSet default printer" -ForegroundColor Cyan
            Write-Host "--------------------------------------------------------------------"
            Write-Host "  You need only enter the printer name. The print"
            Write-Host "  server or full path is not required. If a default"
            Write-Host "  is already set the printer will continue to be"
            Write-Host "  mapped but your new choice will become the default."
            Write-Host "--------------------------------------------------------------------"
            $defaultPrinter = Read-Host "`nDefault printer (or R to return to Main Menu)"
            
            if ($defaultPrinter -eq 'r') { Write-Host ""; Pause; Break }
            
            $json = Get-Content $isThere | ConvertFrom-Json
            foreach ($printer in $json.computer.printers) {
                $printer.isDefault = ($printer.name -eq $defaultPrinter)
            }
            $json | ConvertTo-Json -Depth 3 | Set-Content $isThere
            Write-Host ""
            Pause
        }
        
        '4' {
            Get-Heading
            Get-Endpoint
            Write-Host "`n`n!Feature under construction!" -ForegroundColor Red
            Write-Host "Current print servers accessed by Real Print" -ForegroundColor Cyan
            Write-Host "--------------------------------------------------------------------"
            $PrintServers
            Write-Host "--------------------------------------------------------------------"
            Write-Host "Generating list of printservers and printers..." -ForegroundColor Yellow -NoNewLine
            $PrinterResults = $PrintServers | ForEach-Object { 
                Get-Printer -ComputerName $_ -ErrorAction SilentlyContinue | 
                Select-Object @{
                    Name = 'Printer Name'; 
                    Expression = {$_.Name}
                }, @{
                    Name = 'Print Server'; 
                    Expression = {$_.ComputerName}
                }, @{
                    Name = 'Site'; 
                    Expression = {$_.Location}
                }, @{
                    Name = 'Print Driver Installed'; 
                    Expression = {$_.DriverName}
                }
            }
            $PrinterResults | Out-GridView -Title 'Easy Search for all LCMC Printer Info'
            Write-Host "completed!" -ForegroundColor Green
            Write-Host ""
            Pause
        }
        
        '5' {
            Get-Heading
            Write-Host "Welcome to Real Print Manager" -ForegroundColor Yellow
            Write-Host "Here you can assign printers to endpoints which"
            Write-Host "will result in these printers being mapped to"
            Write-Host "user sessions for Citrix session connected"
            Write-Host "through that endpoint."
            Write-Host "`nWhat is an Endpoint?" -ForegroundColor Yellow
            Write-Host "Any computer connecting to a Citrix session."
            $platforms = @("Windows", "Linux", "MAC", "iOS", "Android", "Igel", "Wyse device", "Windows embedded", "Thin client of any kind")
            foreach ($platform in $platforms) {
                Write-Host " • " -NoNewLine
                Write-Host $platform -ForegroundColor Cyan
            }
            Write-Host "`nWhen does this happen?" -ForegroundColor Yellow
            Write-Host "At each user login or new session for a Citrix"
            Write-Host "session."
            Write-Host "`nWhat do you need to know?" -ForegroundColor Yellow
            Write-Host "To start the name of an endpoint. Enter that below"
            Write-Host "to look up what printers are assigned or create an"
            Write-Host "entry for this endpoint to then assign printers."
            Write-Host ""
            Pause
        }
    }
} until ($input -eq 'q')

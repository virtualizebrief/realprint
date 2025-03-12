<#
.SYNOPSIS
    Real Print Agent - Manages printer connections for Citrix environments
#>

$runTime = Measure-Command {

# Terminate other instances of this script
$currentScriptPath = $PSCommandPath
$currentPID = $PID

$psProcesses = Get-Process -Name "powershell" | Where-Object { $_.Id -ne $currentPID }

foreach ($process in $psProcesses) {
    try {
        $commandLine = (Get-WmiObject Win32_Process -Filter "ProcessId = $($process.Id)").CommandLine
        
        if ($commandLine -like "*$currentScriptPath*") {
            Write-Host "Found another instance with PID: $($process.Id)" -ForegroundColor Yellow
            Stop-Process -Id $process.Id -Force
            
            if ($?) {
                Write-Host "Terminated process PID: $($process.Id)" -ForegroundColor Green
            } else {
                Write-Host "Failed to terminate PID: $($process.Id)" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "Error checking PID: $($process.Id): $_" -ForegroundColor Red
    }
}

# Verify no other instances remain
$remainingInstances = Get-Process -Name "powershell" | Where-Object { 
    $_.Id -ne $currentPID -and 
    (Get-WmiObject Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine -like "*$currentScriptPath*"
}

if ($remainingInstances.Count -eq 0) {
    Write-Host "No other instances running..." -ForegroundColor Green
} else {
    Write-Host "Warning: $($remainingInstances.Count) instance(s) still running" -ForegroundColor Yellow
}

# Configuration
Set-Location "\\epic-dc1-fs01\root\Citrix\RealPrint\"
$dataBase = "\\epic-dc1-fs01\root\Citrix\RealPrint\database\"
$ErrorActionPreference = "SilentlyContinue"

# Initialization
$getDate = Get-Date -Format "yyyyMMddTHHmmss"
$hostName = hostname
$getUserID = (Get-Process -PID $pid).SessionID
$endPoint = Get-ItemProperty -Path "HKLM:\SOFTWARE\Citrix\ICA\Session\$getUserID\Connection" -Name "ClientName" | 
            Select-Object -ExpandProperty "ClientName"
$endpointFile = Join-Path $dataBase "$endPoint.json"
$endpointFileExist = Test-Path -Path $endpointFile -PathType Leaf
$logfile = "C:\Support\RealPrint.log"
$logFileCSV = "C:\Support\RealPrint.csv"

# Printer Setup
if ($endpointFileExist) {
    $addPrinters = Get-Content $endpointFile -Raw | ConvertFrom-Json
    $setDefaultPrinter = ($addPrinters.computer.printers | Where-Object { $_.isDefault -eq $true }).name
    $defaultServer = ($addPrinters.computer.printers | Where-Object { $_.isDefault -eq $true }).server
    $defaultPrinterServer = "\\$defaultServer\$setDefaultPrinter"
}

# Get current printers
$uncPaths = (Get-WMIObject Win32_Printer | Where-Object { $_.Network -eq $true }).Name
$printerArray = @()

foreach ($path in $uncPaths) {
    $server = $path.Split('\')[2]
    $printer = $path.Split('\')[3]
    
    $printerArray += [PSCustomObject]@{
        name     = $printer
        server   = $server
        isDefault = ($path -eq $uncPaths[0])
        status   = "Active"
    }
}

$printerData = [PSCustomObject]@{
    computer = @{
        name     = $endPoint
        printers = $printerArray
    }
}

$json = $printerData | ConvertTo-Json -Depth 3
$currentPrinters = $json | ConvertFrom-Json
if ($null -eq $currentPrinters) { $currentPrinters = "none" }

# Logging Setup
$logHeader = @"
$getDate ========================================
$getDate   Real Print
$getDate   Release: 2025.03.08
$getDate ========================================
$getDate   ...Running User Processes
$getDate   ...User found: $env:UserName
$getDate   ...Endpoint: $endPoint
$getDate   ...Citrix Desktop: $hostName
$getDate
$getDate   Printer processing...
$getDate   -------------------------------
"@

$csvHeader = @"
$getDate,Release,Real Print 2023.07.21
$getDate,Running as,User process
$getDate,User name,$env:UserName
$getDate,Endpoint,$endPoint
$getDate,Citrix desktop,$hostName
"@

Add-Content -Path $LogFile -Value $logHeader
Add-Content -Path $LogFileCSV -Value $csvHeader

# Display Header
Clear-Host
Write-Host "----- Real Print ------" -ForegroundColor Cyan
Write-Host "`nWelcome to Real Print Mapper" -ForegroundColor Yellow
Write-Host "The thing that connects your printers."
Write-Host "`nSettings" -ForegroundColor Yellow
Write-Host "Endpoint: $endPoint"
Write-Host "Citrix Desktop: $hostname"
Write-Host "Start time: $getDate"
Write-Host "`nPrinter mapping results" -ForegroundColor Cyan
Write-Host "--------------------------------------------------"

if (-not $endpointFileExist) {
    Write-Host "Error 420: $endPoint has no database entry!" -ForegroundColor Red
    Write-Host "--------------------------------------------------"
    Write-Host ""
    Pause
    Exit
}


# Printer Management
$compareCurrent = ($currentPrinters.computer.printers).name
$compareAdd = ($addPrinters.computer.printers).name
if ($compareCurrent -eq $null){$compareCurrent = "1"}

# Delete printers
$realDeletePrinters = Compare-Object -ReferenceObject $compareCurrent -DifferenceObject $compareAdd -IncludeEqual |
    Where-Object { $_.SideIndicator -eq "<=" } |
    ForEach-Object { $_.InputObject }

foreach ($printer in $realDeletePrinters) {
    if ($printer -ne "1") {
        $getDate = Get-Date -Format "yyyyMMddTHHmmss"
        Write-Host "deleting: $printer" -ForegroundColor Yellow
        Add-Content -Path $LogFile -Value "$getDate   deleting: $printer"
        Add-Content -Path $LogFileCSV -Value "$getDate,Deleting,$printer"
        $null = (Get-WmiObject -Class Win32_Printer | Where-Object { $_.Name -like "*$printer*" }).Delete()
    }
}

# Skip existing printers
$realSkipPrinters = Compare-Object -ReferenceObject $compareCurrent -DifferenceObject $compareAdd -IncludeEqual |
    Where-Object { $_.SideIndicator -eq "==" } |
    ForEach-Object { $_.InputObject }

foreach ($printer in $realSkipPrinters) {
    $getDate = Get-Date -Format "yyyyMMddTHHmmss"
    Write-Host "skip    : $printer" -ForegroundColor Yellow
    Add-Content -Path $LogFile -Value "$getDate   skipping: $printer"
    Add-Content -Path $LogFileCSV -Value "$getDate,Skipping,$printer"
}

# Add new printers
$realAddPrinters = Compare-Object -ReferenceObject $compareCurrent -DifferenceObject $compareAdd -IncludeEqual |
    Where-Object { $_.SideIndicator -eq "=>" } |
    ForEach-Object { $_.InputObject }

foreach ($printer in $realAddPrinters) {
    $getDate = Get-Date -Format "yyyyMMddTHHmmss"
    Write-Host "add     : $printer" -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value "$getDate   adding  : $printer"
    Add-Content -Path $LogFileCSV -Value "$getDate,Adding,$printer"
    
    $server = ($addPrinters.computer.printers | Where-Object { $_.name -eq $printer }).server
    $printerPath = "\\$server\$printer"
    $null = ([wmiclass]"Win32_Printer").AddPrinterConnection($printerPath)
}

# Default Printer Setup
if ($setDefaultPrinter) {
    $maxTries = 1
    $tries = 0
    $condition = $false

    Write-Host "default : $setDefaultPrinter" -ForegroundColor Green
    Add-Content -Path $LogFile -Value "$getDate   default : $setDefaultPrinter"
    Add-Content -Path $LogFileCSV -Value "$getDate,Default is,$setDefaultPrinter"

    do {
        $tries++
        $getDate = Get-Date -Format "yyyyMMddTHHmmss"
        Write-Host "default : attempt $tries (60 second pause & retry)" -ForegroundColor Green
        Add-Content -Path $LogFile -Value "$getDate   default : attempt $tries (60 second pause & retry)"
        Add-Content -Path $LogFileCSV -Value "$getDate,Default set,default : attempt $tries (60 second pause & retry)"
        
        $null = (Get-WmiObject -Class Win32_Printer | Where-Object { $_.Name -eq $defaultPrinterServer }).SetDefaultPrinter()
        Start-Sleep -Seconds 60
        $condition = ((Get-WmiObject -Class Win32_Printer | Where-Object { $_.Default -eq $true }).Name -eq $defaultPrinterServer)
    } until ($condition -or $tries -ge $maxTries)
}
} | foreach { $_.Seconds }

# Cleanup
Write-Host "-------------------------------"
Write-Host "`nSeconds to complete: $runTime" -NoNewline
Add-Content -Path $LogFile -Value "$GetDate   -------------------------------"
Add-Content -Path $LogFile -Value "$GetDate   Seconds to complete work: $runTime"
Add-Content -Path $LogFileCSV -Value "$GetDate,Seconds to complete,$runTime"
Add-Content -Path $LogFileCSV -Value "....."
Add-Content -Path $LogFile -Value "."

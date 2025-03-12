# End real print agent if another is running
$currentScriptPath = $PSCommandPath
$currentPID = $PID
$psProcesses = Get-Process -Name "powershell" | Where-Object { $_.Id -ne $currentPID }

foreach ($process in $psProcesses) {
    try {
        $commandLine = (Get-WmiObject Win32_Process -Filter "ProcessId = $($process.Id)").CommandLine
        
        if ($commandLine -like "*$currentScriptPath*") {
            Write-Host "Found another instance of this script running with PID: $($process.Id)" -ForegroundColor Yellow
            
            # Terminate the process
            Stop-Process -Id $process.Id -Force
            if ($?) {
                Write-Host "Successfully terminated process with PID: $($process.Id)" -ForegroundColor Green
            } else {
                Write-Host "Failed to terminate process with PID: $($process.Id)" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "Error checking process with PID: $($process.Id): $_" -ForegroundColor Red
    }
}

# Verify no other instances are running
$remainingInstances = Get-Process -Name "powershell" | Where-Object { 
    $_.Id -ne $currentPID -and 
    (Get-WmiObject Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine -like "*$currentScriptPath*"
}

if ($remainingInstances.Count -eq 0) {
    Write-Host "No other instances of this script are running..." -ForegroundColor Green
} else {
    Write-Host "Warning: $($remainingInstances.Count) other instance(s) still running" -ForegroundColor Yellow
}

$runTime = Measure-Command {

#-things you need to set
Set-Location "\\epic-dc1-fs01\root\Citrix\RealPrint\"
$dataBase = "\\epic-dc1-fs01\root\Citrix\RealPrint\database\"

# get all the info needed for setup
$ErrorActionPreference = "SilentlyContinue"; #This will hide errors
$getDate = Get-Date -format "yyyyMMddTHHmmss"
$hostName = hostname
$getUserID = (Get-Process -PID $pid).SessionID
$endPoint = Get-ItemProperty -path "HKLM:\SOFTWARE\Citrix\ICA\Session\$getUserID\Connection" -Name "ClientName" | Select-Object "ClientName" | foreach { $_.ClientName }
$endpointFile = $dataBase + $endPoint + '.json'
$endpointFileExist = Test-Path -Path $endpointFile -PathType Leaf
$addPrinters = get-content $endpointFile -Raw | ConvertFrom-Json
$setDefaultPrinter = ($addPrinters.computer.printers | where-object {$_.isDefault -eq $true}).name
$defaultServer = ($addPrinters.computer.printers | where-object {$_.isDefault -eq $true}).server
$defaultPrinterServer = "\\" + $defaultServer + "\" + $setDefaultPrinter

# default printer tries
$maxTries = 5
$tries = 0
$condition = $false

# get current printers
$uncPaths = (Get-WMIObject Win32_Printer | where{$_.Network -eq 'true'}).name
# Create an array to hold printer objects
$printerArray = @()

# Process each UNC path
foreach ($path in $uncPaths) {
    $server = $path.Split('\')[2]    # Get server name
    $printer = $path.Split('\')[3]   # Get printer name
    
    # Create printer object
    $printerObj = [PSCustomObject]@{
        name = $printer
        server = $server
        isDefault = if ($path -eq $uncPaths[0]) { $true } else { $false }  # First printer is default
        status = "Active"
    }
    
    $printerArray += $printerObj
}

# Create main object structure
$printerData = [PSCustomObject]@{
    computer = @{
        name = $endPoint
        printers = $printerArray
    }
}
$json = $printerData | ConvertTo-Json -Depth 3
$currentPrinters = $json | ConvertFrom-Json
If ($currentPrinters -eq $null){$currentPrinters = "none"}
$user = $env:UserName
$logfile = "C:\Support\RealPrint.log"
$logFileCSV = "C:\Support\RealPrint.csv"

#-Setup log file
Add-Content -Path $LogFile -Value "$GetDate ========================================="
Add-Content -Path $LogFile -Value "$GetDate   Real Print"
Add-Content -Path $LogFile -Value "$GetDate   Release: 2025.03.08"
Add-Content -Path $LogFile -Value "$GetDate ========================================="
Add-Content -Path $LogFile -Value "$GetDate   ...Running User Processes"
Add-Content -Path $LogFile -Value "$GetDate   ...User found: $User"
Add-Content -Path $LogFile -Value "$GetDate   ...Endpoint: $endPoint"
Add-Content -Path $LogFile -Value "$GetDate   ...Citrix Desktop: $hostName"
Add-Content -Path $LogFile -Value "$GetDate"
Add-Content -Path $LogFile -Value "$GetDate   Printer processing..."
Add-Content -Path $LogFile -Value "$GetDate   -------------------------------"
Add-Content -Path $LogFileCSV -Value "$GetDate,Release,Real Print 2023.07.21"
Add-Content -Path $LogFileCSV -Value "$GetDate,Running as,User process"
Add-Content -Path $LogFileCSV -Value "$GetDate,User name,$User"
Add-Content -Path $LogFileCSV -Value "$GetDate,Endpoint,$endPoint"
Add-Content -Path $LogFileCSV -Value "$GetDate,Citrix desktop,$hostName"

#-Header
Clear-Host
Write-Host "----- Real Print ------" -Foreground Cyan
Write-Host ""
Write-Host "Welcome to Real Print Mapper" -Foreground Yellow
Write-Host "The thing that connects your printers."
Write-Host ""
Write-Host "Settings" -Foreground Yellow
Write-Host "Endpoint: $endPoint"
Write-Host "Citrix Desktop: $hostname"
Write-Host "Start time: $getDate"
Write-Host ""
Write-Host "Printer mapping results..." -Foreground Cyan
Write-Host "--------------------------------------------------"
If (-Not $endpointFileExist){Write-Host "Error 420: $endPoint has no database entry!" -Foreground Red
    Write-Host "--------------------------------------------------"
    Write-Host ""
    Pause
    Exit}

#if $compareCurrent is $null then compare-object fails
$compareCurrent = ($currentPrinters.computer.printers).name
$compareAdd = ($addPrinters.computer.printers).name
if ($compareCurrent -eq $null){$compareCurrent = "1"}

#-Delete those current printers not found on add printer list
$realDeletePrinters = Compare-Object -ReferenceObject $compareCurrent -DifferenceObject $compareAdd -IncludeEqual |
 Where-Object {$_.SideIndicator -like "<="} |
  foreach { $_.InputObject }
Foreach ($realDeletePrinter in $realDeletePrinters){
    If ($realDeletePrinter -ne "1"){
    $getDate = Get-Date -format "yyyyMMddTHHmmss"
    Add-Content -Path $LogFile -Value "$GetDate   deleting: $realDeletePrinter"
    Add-Content -Path $LogFileCSV -Value "$GetDate,Deleting,$realDeletePrinter"
    Write-Host "deleting: $realDeletePrinter" -ForegroundColor yellow
    $toNull = (gwmi -Class Win32_Printer | ? Name -like *$realDeletePrinter*).Delete()
    }
}

#-Skipping those current printers found on both lists
$compareCurrent = ($currentPrinters.computer.printers).name
$compareAdd = ($addPrinters.computer.printers).name
if ($compareCurrent -eq $null){$compareCurrent = "1"} #if $compareCurrent is $null then compare-object fails
$realSkipPrinters = Compare-Object -ReferenceObject $compareCurrent -DifferenceObject $compareAdd -IncludeEqual |
 Where-Object {$_.SideIndicator -like "=="} |
  foreach { $_.InputObject }
Foreach ($realSkipPrinter in $realSkipPrinters){
$getDate = Get-Date -format "yyyyMMddTHHmmss"
Add-Content -Path $LogFile -Value "$GetDate   skipping: $realSkipPrinter"
Add-Content -Path $LogFileCSV -Value "$GetDate,Skipping,$realSkipPrinter"
Write-Host "skip    : $realSkipPrinter" -ForegroundColor yellow}

#-Add printers not found on current list
$compareCurrent = ($currentPrinters.computer.printers).name
$compareAdd = ($addPrinters.computer.printers).name
if ($compareCurrent -eq $null){$compareCurrent = "1"} #if $compareCurrent is $null then compare-object fails
$realAddPrinters = Compare-Object -ReferenceObject $compareCurrent -DifferenceObject $compareAdd -IncludeEqual |
 Where-Object {$_.SideIndicator -like "=>"} |
  foreach { $_.InputObject }
Foreach ($realAddPrinter in $realAddPrinters){
$getDate = Get-Date -format "yyyyMMddTHHmmss"
Add-Content -Path $LogFile -Value "$GetDate   adding  : $realAddPrinter"
Add-Content -Path $LogFileCSV -Value "$GetDate,Adding,$realAddPrinter"
Write-Host "add     : $realAddPrinter" -ForegroundColor cyan
$realAddPrinterServer = ($addPrinters.computer.printers | where name -eq $realAddPrinter).server
$realAddPrinterNameServer = "\\" + $realAddPrinterServer + "\" + $realAddPrinter
([wmiclass]"Win32_Printer").AddPrinterConnection($realAddPrinterNameServer)
}

#----------------------

#-Set default print if one is in real print
$getDate = Get-Date -format "yyyyMMddTHHmmss"
Write-Host "default : $setDefaultPrinter" -ForegroundColor green
Add-Content -Path $LogFile -Value "$GetDate   default : $setDefaultPrinter"
Add-Content -Path $LogFileCSV -Value "$GetDate,Default is,$setDefaultPrinter"

do {

    $tries++
    $getDate = Get-Date -format "yyyyMMddTHHmmss"
    Write-Host "default : attempt $tries (60 second pause & retry)" -ForegroundColor green
    Add-Content -Path $LogFile -Value "$GetDate   default : attempt $tries (60 second pause & retry)"
    Add-Content -Path $LogFileCSV -Value "$GetDate,Default set,default : attempt $tries (60 second pause & retry)"
    
    # actually set default
    $toNull = (gwmi -Class Win32_Printer | ? Name -eq $defaultPrinterServer).SetDefaultPrinter()  
    Start-Sleep -S 60
    $condition = ((Get-WmiObject -Class Win32_Printer | Where-Object {$_.Default -eq $true}).Name -eq $defaultPrinterServer)

} until ($condition -or $tries -ge $maxTries)

#---------------------

#-Goodbye
Write-Host "-------------------------------"
Write-Host ""
Write-Host "Seconds to complete: " -NoNewline

} | foreach { $_.Seconds }

Add-Content -Path $LogFile -Value "$GetDate   -------------------------------"
Add-Content -Path $LogFile -Value "$GetDate   Seconds to complete work: $runTime"
Add-Content -Path $LogFileCSV -Value "$GetDate,Seconds to complete,$runTime"
Add-Content -Path $LogFileCSV -Value "....."
Add-Content -Path $LogFile -Value "."

# Stop-Process -Id $Pid -Force onds to complete,$runTime"
Add-Content -Path $LogFileCSV -Value "....."
Add-Content -Path $LogFile -Value "."

# Stop-Process -Id $Pid -Force 

function Get-LastOctet {
    param (
        [string]$ip
    )
    $split = $ip.Split(".")
    return [int]$split[3]
}

function Set-LastOctet {
    param (
        [string]$ip,
        [string]$octet
    )
    $parts = $ip.Split(".")
    $parts[3] = $octet
    return $parts -join "."
}

function Test-ModuleInstallation {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ModuleName
    )

    if (!(Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Host "The $ModuleName module is not installed. Installing..." -ForegroundColor Yellow
        try {
            Install-Module -Name $ModuleName -Force -ErrorAction Stop
        } catch {
            Write-Host "Failed to install $ModuleName. Please install it manually." -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "Importing $ModuleName..." -ForegroundColor Green
        Import-Module $ModuleName
    }

    return $true
}
$modules = @("SNMP")
foreach ($module in $modules) {
    $result = Test-ModuleInstallation -ModuleName $module
    if (-not $result) {
        Write-Host "Please restart the script after installing the required modules." -ForegroundColor Red
        exit
    }
}
if (-not $scriptRoot) {
    $scriptRoot = $PSScriptRoot
}
$envFilePath = Join-Path -Path $scriptRoot -ChildPath ".env"
if (Test-Path $envFilePath) {
    Get-Content $envFilePath | ForEach-Object {
        if ($_ -match "^\s*([^#][^=]+?)\s*=\s*(.*?)\s*$") {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
        }
    }
} else {
    Write-Host "You need a .env. I will create one with the default location of C:\ChangeMe" -ForegroundColor Red
    # Create the .env file and add the required content
    $envContent = @"
StartIP = "192.168.1.1",
EndIP = "192.168.1.254",
CommunityName = "public",
OutputDir = "C:\ChangeMe"
"@
    Set-Content -Path $envFilePath -Value $envContent
    Write-Host ".env file created with default values." -ForegroundColor Green
    [System.Environment]::SetEnvironmentVariable("StartIP", "192.168.1.1")
    [System.Environment]::SetEnvironmentVariable("EndIP", "192.168.1.254")
    [System.Environment]::SetEnvironmentVariable("CommunityName", "Cpublic")
    [System.Environment]::SetEnvironmentVariable("OutputDir", "C:\ChangeMe")
}
$startIP = [System.Environment]::GetEnvironmentVariable("StartIP")
$endIP = [System.Environment]::GetEnvironmentVariable("EndIP")
$communityName = [System.Environment]::GetEnvironmentVariable("CommunityName")
$outputDir = [System.Environment]::GetEnvironmentVariable("OutputDir")
if (-not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir
}
# Get the last octets of the start and end IP addresses
$startNumber = Get-LastOctet $startIP
$endNumber = Get-LastOctet $endIP 

$totalIPs = $endNumber - $startNumber + 1
$snmpDataCollection = @()
$logCollection = @()
# Loop through the IP range based on the last octet
for ($i = $startNumber; $i -le $endNumber; $i++) {
    $currentIp = Set-LastOctet $startIP $i
    Write-Progress -Activity "Processing IPs" -Status "Checking $currentIp" -PercentComplete (($i - $startNumber + 1) / $totalIPs * 100)
    
    if (Test-Connection -ComputerName $currentIp -Count 1 -Quiet -TimeoutSeconds 1) {
        $success = $false
        $foundSNMP = $true
        $snmpData = $null
        try {
            $snmpData = Get-SNMPData -IP $currentIp -Community $communityName -OID "1.3.6.1.2.1.1.1.0"
            $snmpDataCollection += $snmpData
            $success = $true
        } catch {
            $result = "Failed to perform SNMP walk on $currentIp"
            Write-Host $result -ForegroundColor Red
            $foundSNMP = $false
        } finally {
            if ($success) {
                $result = "Walk finished on $currentIp"
                Write-Host $result -ForegroundColor Green
            }
        }
    } else {
        Write-Host "$currentIp is not reachable." -ForegroundColor Yellow
        $foundSNMP = $false
    }
    $logCollection += [PSCustomObject]@{
        IPAddress = $currentIp
        FoundSNMP = $foundSNMP
        SNMPData = $snmpData
    }
}

if ($logCollection.Count -gt 0) {
    $logCollection | Export-Csv -Path "$outputDir\SNMPLog.csv" -NoTypeInformation
    Write-Host "Log data exported to CSV." -ForegroundColor Green
} else {
    Write-Host "No log data to export." -ForegroundColor Red
}
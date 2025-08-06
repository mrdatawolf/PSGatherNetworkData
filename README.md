# PSGatherNetworkData

## Overview
PSGatherNetworkData is a collection of PowerShell scripts designed to gather network data including IP and MAC addresses, as well as SNMP data, across a specified range of IP addresses. These scripts are useful for network administrators and engineers who need to inventory network devices or monitor network health.

## Scripts

### PSGatherIPAndMAC.ps1

#### Description
This script pings a range of IP addresses and retrieves the corresponding MAC addresses. The results are saved to a CSV file.

#### Parameters
- `StartIP`: The starting IP address of the range.
- `EndIP`: The ending IP address of the range.
- `OutputDir`: The directory where the results will be saved.

#### Usage
1. **Create a .env File**: The script requires a `.env` file with the following format:
    ```ini
    StartIP = "192.168.1.1"
    EndIP = "192.168.1.254"
    CommunityName = "public"
    OutputDir = "C:\ChangeMe"
    ```
    If the `.env` file is not present, the script will create one with default values.

2. **Run the Script**:
    ```powershell
    .\PSGatherIPAndMAC.ps1
    ```

#### Example
```powershell
.\PSGatherIPAndMAC.ps1
```
<!-- Purpose: Pings a IP range and retrieves the corresponding MAC addresses saved to a CSV file. -->
<!-- INSTALL_COMMAND: curl -L -o PSGatherIPAndMAC.ps1 https://raw.githubusercontent.com/mrdatawolf/PSGatherNetworkData/refs/heads/main/PSGatherIPAndMAC.ps1; curl -L -o PSGatherIPAndMAC.ps1 https://raw.githubusercontent.com/mrdatawolf/PSGatherNetworkData/refs/heads/main/PSGatherSNMPData.ps1 -->
<!-- RUN_COMMAND: ./PSGatherIPAndMAC.ps1 -->

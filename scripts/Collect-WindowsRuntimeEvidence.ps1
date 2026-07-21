[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$SessionDirectory,

    [string[]]$UsbVidPid = @(),
    [string]$TargetPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-VersionCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [string[]]$Arguments = @()
    )

    $resolved = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $resolved) {
        return [ordered]@{ available = $false; output = @() }
    }

    try {
        $output = & $resolved.Source @Arguments 2>&1 | ForEach-Object { [string]$_ }
        return [ordered]@{ available = $true; output = @($output) }
    }
    catch {
        return [ordered]@{ available = $true; output = @(); inspection_error = $_.Exception.GetType().Name }
    }
}

function Normalize-VidPid {
    param([Parameter(Mandatory = $true)][string]$Value)

    $normalized = $Value.Trim().ToUpperInvariant() -replace '^VID_', '' -replace 'PID_', ''
    $normalized = $normalized -replace '[_:&-]+', ':'
    if ($normalized -notmatch '^[0-9A-F]{4}:[0-9A-F]{4}$') {
        throw "Invalid VID:PID value '$Value'. Expected format 0E8D:2000."
    }
    return $normalized
}

$sessionRoot = (Resolve-Path -LiteralPath $SessionDirectory).Path
$manifestPath = Join-Path $sessionRoot "session-manifest.json"
$evidenceDirectory = Join-Path $sessionRoot "evidence"
$outputPath = Join-Path $evidenceDirectory "windows-runtime-inventory.json"

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Session manifest not found: $manifestPath"
}

New-Item -ItemType Directory -Path $evidenceDirectory -Force | Out-Null

$requestedUsb = @($UsbVidPid | ForEach-Object { Normalize-VidPid $_ } | Sort-Object -Unique)

$vcRuntimes = [System.Collections.Generic.List[object]]::new()
$uninstallRoots = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
foreach ($root in $uninstallRoots) {
    Get-ItemProperty $root -ErrorAction SilentlyContinue |
        Where-Object { [string]$_.DisplayName -match '^Microsoft Visual C\+\+.*Redistributable' } |
        ForEach-Object {
            $vcRuntimes.Add([ordered]@{
                display_name = [string]$_.DisplayName
                display_version = [string]$_.DisplayVersion
                publisher = [string]$_.Publisher
                architecture_hint = if ([string]$_.DisplayName -match 'x86') { 'x86' } elseif ([string]$_.DisplayName -match 'x64') { 'x64' } elseif ([string]$_.DisplayName -match 'ARM64') { 'arm64' } else { 'unknown' }
            })
        }
}

$usbDrivers = [System.Collections.Generic.List[object]]::new()
if ($requestedUsb.Count -gt 0) {
    $driverRecords = Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue
    foreach ($driver in $driverRecords) {
        $deviceId = ([string]$driver.DeviceID).ToUpperInvariant()
        foreach ($identity in $requestedUsb) {
            $parts = $identity.Split(':')
            if ($deviceId -match "VID_$($parts[0])" -and $deviceId -match "PID_$($parts[1])") {
                $usbDrivers.Add([ordered]@{
                    vid = $parts[0]
                    pid = $parts[1]
                    device_class = [string]$driver.DeviceClass
                    manufacturer = [string]$driver.Manufacturer
                    driver_provider = [string]$driver.DriverProviderName
                    driver_version = [string]$driver.DriverVersion
                    inf_name = [string]$driver.InfName
                    is_signed = [bool]$driver.IsSigned
                    signer = [string]$driver.Signer
                })
                break
            }
        }
    }
}

$relatedServices = [System.Collections.Generic.List[object]]::new()
if (-not [string]::IsNullOrWhiteSpace($TargetPath) -and (Test-Path -LiteralPath $TargetPath -PathType Container)) {
    $resolvedTarget = (Resolve-Path -LiteralPath $TargetPath).Path
    foreach ($service in (Get-CimInstance Win32_Service -ErrorAction SilentlyContinue)) {
        $servicePath = [string]$service.PathName
        if ($servicePath -and $servicePath.IndexOf($resolvedTarget, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $binaryName = ''
            if ($servicePath -match '^\s*"([^"]+)"') {
                $binaryName = Split-Path $matches[1] -Leaf
            }
            elseif ($servicePath -match '^\s*([^\s]+)') {
                $binaryName = Split-Path $matches[1] -Leaf
            }
            $relatedServices.Add([ordered]@{
                name = [string]$service.Name
                display_name = [string]$service.DisplayName
                state = [string]$service.State
                start_mode = [string]$service.StartMode
                binary_name = $binaryName
            })
        }
    }
}

$payload = [ordered]@{
    schema_version = "1.0"
    record_type = "ttg.sanitized_windows_runtime_inventory"
    generated_utc = [DateTimeOffset]::UtcNow.ToString("o")
    machine_identity_retained = $false
    absolute_paths_retained = $false
    platform = [ordered]@{
        os_version = [Environment]::OSVersion.VersionString
        process_architecture = [Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture.ToString().ToLowerInvariant()
        os_architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
        powershell_version = $PSVersionTable.PSVersion.ToString()
    }
    commands = [ordered]@{
        dotnet_runtimes = Invoke-VersionCommand -Command "dotnet" -Arguments @("--list-runtimes")
        dotnet_sdks = Invoke-VersionCommand -Command "dotnet" -Arguments @("--list-sdks")
        java = Invoke-VersionCommand -Command "java" -Arguments @("-version")
        python = Invoke-VersionCommand -Command "python" -Arguments @("--version")
        adb = Invoke-VersionCommand -Command "adb" -Arguments @("version")
        fastboot = Invoke-VersionCommand -Command "fastboot" -Arguments @("--version")
    }
    visual_cpp_redistributables = @($vcRuntimes | Sort-Object display_name, display_version -Unique)
    requested_usb_identities = $requestedUsb
    matching_usb_drivers = @($usbDrivers | Sort-Object vid, pid, driver_provider, driver_version, inf_name -Unique)
    related_services = @($relatedServices | Sort-Object name -Unique)
}

$payload | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $outputPath -Encoding utf8
$outputHash = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash.ToLowerInvariant()

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$existingEvidence = @($manifest.evidence) | Where-Object { $_.path -ne "evidence/windows-runtime-inventory.json" }
$newEvidence = [pscustomobject]@{
    path = "evidence/windows-runtime-inventory.json"
    kind = "runtime_inventory"
    sha256 = $outputHash
    sanitized = $true
    notes = "Machine identity and unique USB device IDs were not retained."
}
$manifest.evidence = @($existingEvidence) + $newEvidence
$manifest | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $manifestPath -Encoding utf8

Write-Host "Runtime evidence written: $outputPath"
Write-Host "Matching USB driver records: $($usbDrivers.Count)"
Write-Host "Runtime inventory SHA-256: $outputHash"

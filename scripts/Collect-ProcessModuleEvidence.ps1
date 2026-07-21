[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 2147483647)]
    [int]$ProcessId,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$SessionDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$sessionRoot = (Resolve-Path -LiteralPath $SessionDirectory).Path
$manifestPath = Join-Path $sessionRoot "session-manifest.json"
$evidenceDirectory = Join-Path $sessionRoot "evidence"
$outputPath = Join-Path $evidenceDirectory "process-module-inventory.json"

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Session manifest not found: $manifestPath"
}

$process = Get-Process -Id $ProcessId -ErrorAction Stop
New-Item -ItemType Directory -Path $evidenceDirectory -Force | Out-Null

$moduleRecords = [System.Collections.Generic.List[object]]::new()
$inspectionErrors = [System.Collections.Generic.List[string]]::new()

try {
    foreach ($module in ($process.Modules | Sort-Object ModuleName)) {
        $filePath = [string]$module.FileName
        if ([string]::IsNullOrWhiteSpace($filePath) -or -not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
            continue
        }

        $file = Get-Item -LiteralPath $filePath -ErrorAction Stop
        $hash = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash.ToLowerInvariant()
        $signatureStatus = "not_applicable"
        $signer = ""
        if ($file.Extension.ToLowerInvariant() -in @(".exe", ".dll", ".sys", ".ocx")) {
            try {
                $signature = Get-AuthenticodeSignature -LiteralPath $filePath
                $signatureStatus = [string]$signature.Status
                if ($signature.SignerCertificate) {
                    $signer = [string]$signature.SignerCertificate.Subject
                }
            }
            catch {
                $signatureStatus = "inspection_failed"
            }
        }

        $moduleRecords.Add([ordered]@{
            module_name = [string]$module.ModuleName
            filename = $file.Name
            size_bytes = $file.Length
            sha256 = $hash
            file_version = [string]$file.VersionInfo.FileVersion
            product_version = [string]$file.VersionInfo.ProductVersion
            company_name = [string]$file.VersionInfo.CompanyName
            signature_status = $signatureStatus
            signer = $signer
        })
    }
}
catch {
    $inspectionErrors.Add("Module enumeration failed: $($_.Exception.GetType().Name). Run with matching architecture and administrator rights if authorized.")
}

$childProcesses = [System.Collections.Generic.List[object]]::new()
try {
    Get-CimInstance Win32_Process -Filter "ParentProcessId = $ProcessId" -ErrorAction Stop |
        Sort-Object Name |
        ForEach-Object {
            $childProcesses.Add([ordered]@{
                name = [string]$_.Name
                executable_name = if ([string]$_.ExecutablePath) { Split-Path ([string]$_.ExecutablePath) -Leaf } else { "" }
            })
        }
}
catch {
    $inspectionErrors.Add("Child-process enumeration failed: $($_.Exception.GetType().Name).")
}

$payload = [ordered]@{
    schema_version = "1.0"
    record_type = "ttg.sanitized_process_module_inventory"
    generated_utc = [DateTimeOffset]::UtcNow.ToString("o")
    process = [ordered]@{
        name = [string]$process.ProcessName
        executable_name = if ([string]$process.Path) { Split-Path ([string]$process.Path) -Leaf } else { "" }
        command_line_retained = $false
        process_id_retained = $false
        username_retained = $false
    }
    module_count = $moduleRecords.Count
    modules = $moduleRecords
    child_processes = $childProcesses
    inspection_errors = $inspectionErrors
    memory_dump_created = $false
    absolute_paths_retained = $false
}

$payload | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $outputPath -Encoding utf8
$outputHash = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash.ToLowerInvariant()

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$existingEvidence = @($manifest.evidence) | Where-Object { $_.path -ne "evidence/process-module-inventory.json" }
$newEvidence = [pscustomobject]@{
    path = "evidence/process-module-inventory.json"
    kind = "other"
    sha256 = $outputHash
    sanitized = $true
    notes = "Process/module metadata only; no command line, username, process ID, absolute path or memory dump retained."
}
$manifest.evidence = @($existingEvidence) + $newEvidence
$manifest | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $manifestPath -Encoding utf8

Write-Host "Process/module evidence written: $outputPath"
Write-Host "Modules recorded: $($moduleRecords.Count)"
Write-Host "Evidence SHA-256: $outputHash"

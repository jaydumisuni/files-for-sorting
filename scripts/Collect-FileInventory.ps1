[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$TargetPath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$SessionDirectory,

    [ValidateRange(1, 16384)]
    [int]$MaxFileSizeMB = 2048
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-TextSha256 {
    param([Parameter(Mandatory = $true)][string]$Text)

    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
        return ([BitConverter]::ToString($algorithm.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant()
    }
    finally {
        $algorithm.Dispose()
    }
}

function Get-SafeRelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$FullPath
    )

    $rootPath = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    $filePath = [IO.Path]::GetFullPath($FullPath)
    $rootUri = New-Object System.Uri($rootPath)
    $fileUri = New-Object System.Uri($filePath)
    return [Uri]::UnescapeDataString($rootUri.MakeRelativeUri($fileUri).ToString())
}

$targetRoot = (Resolve-Path -LiteralPath $TargetPath).Path
$sessionRoot = (Resolve-Path -LiteralPath $SessionDirectory).Path
$manifestPath = Join-Path $sessionRoot "session-manifest.json"
$evidenceDirectory = Join-Path $sessionRoot "evidence"
$outputPath = Join-Path $evidenceDirectory "file-inventory.json"

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Session manifest not found: $manifestPath"
}

New-Item -ItemType Directory -Path $evidenceDirectory -Force | Out-Null

$blockedExtensions = @(
    ".key", ".pem", ".pfx", ".p12", ".env", ".pcap", ".pcapng", ".dmp", ".dump"
)
$signatureExtensions = @(".exe", ".dll", ".sys", ".msi", ".cat", ".ocx")
$maximumBytes = [int64]$MaxFileSizeMB * 1MB
$records = [System.Collections.Generic.List[object]]::new()
$skipped = [System.Collections.Generic.List[object]]::new()

$files = Get-ChildItem -LiteralPath $targetRoot -File -Recurse -ErrorAction Stop | Sort-Object FullName
foreach ($file in $files) {
    $relativePath = Get-SafeRelativePath -Root $targetRoot -FullPath $file.FullName
    $extension = $file.Extension.ToLowerInvariant()

    if ($blockedExtensions -contains $extension) {
        $skipped.Add([ordered]@{
            relative_path = $relativePath
            reason = "blocked_sensitive_extension"
        })
        continue
    }

    if ($file.Length -gt $maximumBytes) {
        $skipped.Add([ordered]@{
            relative_path = $relativePath
            reason = "exceeds_maximum_size"
            size_bytes = $file.Length
        })
        continue
    }

    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $versionInfo = $file.VersionInfo
    $signatureStatus = "not_applicable"
    $signer = ""

    if ($signatureExtensions -contains $extension) {
        try {
            $signature = Get-AuthenticodeSignature -LiteralPath $file.FullName
            $signatureStatus = [string]$signature.Status
            if ($signature.SignerCertificate) {
                $signer = [string]$signature.SignerCertificate.Subject
            }
        }
        catch {
            $signatureStatus = "inspection_failed"
        }
    }

    $records.Add([ordered]@{
        relative_path = $relativePath
        filename = $file.Name
        extension = $extension
        size_bytes = $file.Length
        sha256 = $hash
        file_version = [string]$versionInfo.FileVersion
        product_version = [string]$versionInfo.ProductVersion
        company_name = [string]$versionInfo.CompanyName
        signature_status = $signatureStatus
        signer = $signer
    })
}

$identityLines = $records |
    Sort-Object relative_path |
    ForEach-Object { "$($_.relative_path)`t$($_.size_bytes)`t$($_.sha256)" }
$aggregateDigest = Get-TextSha256 (($identityLines -join "`n") + "`n")

$payload = [ordered]@{
    schema_version = "1.0"
    record_type = "ttg.sanitized_file_inventory"
    generated_utc = [DateTimeOffset]::UtcNow.ToString("o")
    target_label = (Split-Path $targetRoot -Leaf)
    copies_target_files = $false
    absolute_paths_retained = $false
    file_count = $records.Count
    skipped_count = $skipped.Count
    aggregate_sha256 = $aggregateDigest
    files = $records
    skipped = $skipped
}

$payload | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $outputPath -Encoding utf8
$outputHash = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash.ToLowerInvariant()

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$existingEvidence = @($manifest.evidence) | Where-Object { $_.path -ne "evidence/file-inventory.json" }
$newEvidence = [pscustomobject]@{
    path = "evidence/file-inventory.json"
    kind = "file_inventory"
    sha256 = $outputHash
    sanitized = $true
    notes = "Metadata-only recursive inventory; no target file was copied."
}
$manifest.evidence = @($existingEvidence) + $newEvidence
$manifest | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $manifestPath -Encoding utf8

Write-Host "Inventory written: $outputPath"
Write-Host "Files recorded: $($records.Count)"
Write-Host "Files skipped:  $($skipped.Count)"
Write-Host "Inventory SHA-256: $outputHash"

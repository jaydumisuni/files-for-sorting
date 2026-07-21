[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ToolFamily,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ProductName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ProductVersion,

    [string]$Publisher = "",
    [string]$AuthorizationBasis = "Licensed or otherwise authorized evaluation",
    [string]$OutputRoot = (Join-Path (Split-Path $PSScriptRoot -Parent) "sessions")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-Slug {
    param([Parameter(Mandatory = $true)][string]$Value)

    $slug = $Value.Trim().ToLowerInvariant()
    $slug = $slug -replace '[^a-z0-9._-]+', '-'
    $slug = $slug.Trim('-', '.', '_')
    if ([string]::IsNullOrWhiteSpace($slug)) {
        throw "Value cannot be converted to a safe session slug."
    }
    return $slug
}

$started = [DateTimeOffset]::UtcNow
$timestamp = $started.ToString("yyyyMMdd'T'HHmmss'Z'")
$toolSlug = ConvertTo-Slug $ToolFamily
$productSlug = ConvertTo-Slug $ProductName

if (-not $toolSlug.StartsWith("ttg-", [StringComparison]::Ordinal)) {
    throw "ToolFamily must use a TTG internal name such as ttg-meta. External product names belong in ProductName only."
}

$sessionId = "$($timestamp.ToLowerInvariant())-$toolSlug-$productSlug"
$sessionDirectory = Join-Path (Join-Path $OutputRoot $toolSlug) $sessionId

if (Test-Path -LiteralPath $sessionDirectory) {
    throw "Session directory already exists: $sessionDirectory"
}

New-Item -ItemType Directory -Path $sessionDirectory -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $sessionDirectory "evidence") -Force | Out-Null

$architecture = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

$manifest = [ordered]@{
    schema_version = "1.0"
    record_type = "ttg.authorized_software_evidence_session"
    session_id = $sessionId
    tool_family = $toolSlug
    observed_product = [ordered]@{
        name = $ProductName
        version = $ProductVersion
        publisher = $Publisher
    }
    capture = [ordered]@{
        started_utc = $started.ToString("o")
        platform = "Windows"
        platform_version = [Environment]::OSVersion.VersionString
        architecture = $architecture
        isolated_test_environment = $false
    }
    authorization = [ordered]@{
        authorized_use = $true
        basis = $AuthorizationBasis
        account_material_retained = $false
        licence_bypass_attempted = $false
    }
    dependencies = @()
    usb_modes = @()
    operations = @()
    evidence = @()
    privacy_review = [ordered]@{
        sanitized = $false
        contains_device_identifiers = $false
        contains_credentials = $false
        contains_proprietary_binaries = $false
        review_notes = "Set isolated_test_environment and complete privacy review before promotion."
    }
    status = "draft"
}

$manifestPath = Join-Path $sessionDirectory "session-manifest.json"
$manifest | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $manifestPath -Encoding utf8

$notes = @"
# TTG capture notes

Session: $sessionId
TTG family: $toolSlug
Observed external product: $ProductName $ProductVersion

Record only sanitized interoperability and dependency evidence. Do not paste credentials, device identifiers, proprietary binaries, temporary signed URLs or customer data here.
"@
$notes | Set-Content -LiteralPath (Join-Path $sessionDirectory "NOTES.md") -Encoding utf8

Write-Host "Created authorized TTG capture session:"
Write-Host "  $sessionDirectory"
Write-Host "Manifest:"
Write-Host "  $manifestPath"
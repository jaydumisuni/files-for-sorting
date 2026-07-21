# Redistribution and Licensing Policy

The evidence repository separates **knowing what is required** from **having permission to distribute it**.

## Classification

### `redistributable`

Use only when an official licence, vendor agreement or trusted source explicitly permits redistribution in our installer.

Required evidence:

- licence/source reference;
- exact version and architecture;
- SHA-256 and size;
- publisher/signer;
- approved packaging conditions.

### `vendor_fetch`

The dependency may be downloaded by the installer from an official stable vendor source, but is not stored in our repository or release.

Required evidence:

- official source URL or documented resolver;
- checksum/signature verification rule;
- acceptable versions;
- offline/error behaviour.

Temporary signed URLs must never be committed. Store the stable resolver or vendor landing page instead.

### `operator_supplied`

The licensed technician/operator must provide the artifact from their own authorized installation or account. Our installer detects and validates it locally but does not upload or redistribute it.

Required evidence:

- expected filename/version/architecture;
- signer and SHA-256 when version-fixed;
- detection path chosen by the operator;
- compatibility and failure message.

The installer must not extract credentials, defeat activation or transform a temporary/rented account into permanent access.

### `metadata_only`

The artifact is proprietary or otherwise restricted. Retain only sanitized facts needed for interoperability, replacement planning or compatibility testing.

Allowed examples:

- filename and version;
- cryptographic hash;
- signer/publisher;
- imports/runtime dependencies;
- observed USB mode and operation result;
- public documentation/source reference.

### `unknown_blocked`

Default for anything not yet reviewed. It cannot be promoted into the runtime registry or installer.

## TSM, UnlockTool and similar licensed products

Authorized temporary access may be used to observe normal operation and document interoperability facts. It may not be used to:

- copy or publish proprietary binaries/databases;
- retain or reuse credentials, cookies, tokens or session files after access expires;
- bypass activation, time limits, device limits or server authorization;
- impersonate the vendor service;
- redistribute protected firmware or loaders without permission.

What we can retain is the operating contract: required drivers/runtimes, signed file identities, mode transitions, sanitized operation stages, inputs/outputs, error categories and device-side results. That evidence can guide an independent THETECHGUY implementation.

## Public/private split

`files-for-sorting` is public and metadata-only.

Future storage should be split as follows:

- public metadata registry: approved manifests, checksums and vendor sources;
- private evidence store: sanitized but commercially sensitive logs and test bundles;
- controlled artifact store: only owned or explicitly redistributable packages;
- operator-local source: restricted licensed artifacts supplied at install/run time.

## Fail-closed rule

An installer package is blocked when any of these are missing or conflicting:

- licence classification;
- source ownership/authority;
- version/architecture identity;
- expected signer;
- SHA-256 or equivalent trusted signature;
- install and detection rule;
- privacy review.

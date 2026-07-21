# THETECHGUY Files for Sorting

This repository is the **metadata and evidence intake area** for software, device-service and installer research used by THETECHGUY tools.

It is not the final customer package registry and it must not become a dump of third-party applications.

## Naming boundary

All internal tool families, folders, manifests, engine names, package IDs and future runtime names use **TTG/THETECHGUY** branding.

External product names such as TSM may appear only where they identify an `observed_product`, publisher, donor source or compatibility observation. An external product name must never become the name of our engine, session family, installer component or runtime package.

## Purpose

Use this repository to retain reproducible, reviewable evidence about what a tool needs to operate:

- dependency names, versions, architectures and SHA-256 hashes;
- vendor download/source references;
- Authenticode signer and certificate metadata;
- USB VID/PID, interface and driver requirements;
- services, processes, modules and runtime prerequisites;
- device mode transitions and observable operation results;
- sanitized logs and protocol evidence produced during authorized testing;
- installer order, detection rules and rollback requirements;
- redistribution/licensing classification for every item.

This applies to TTG META research and later authorized evaluations of other external products. The goal is to learn the complete operating contract needed by our own implementation, not to copy or rename another product as ours.

## Public repository boundary

This repository is public. Commit only metadata, scripts, schemas, documentation and sanitized evidence.

Do **not** commit:

- third-party proprietary executables, DLLs, databases, loaders or cracked files;
- account credentials, activation tokens, cookies, session files or rented-account data;
- signing keys, certificates with private keys or API secrets;
- raw customer/device identifiers such as IMEI, serial, ECID, UDID or phone numbers;
- firmware or drivers unless their licence explicitly permits redistribution;
- packet captures or logs containing credentials or private customer data.

Approved redistributable artifacts belong in a controlled release/package store. Restricted artifacts remain vendor-fetched at install time or are supplied by the licensed operator.

## Intake flow

1. Create a TTG capture session with `scripts/New-CaptureSession.ps1`.
2. Run authorized tests on an isolated workstation and device.
3. Record file/runtime evidence with `scripts/Collect-FileInventory.ps1`.
4. Add sanitized observations to the session manifest.
5. Classify every dependency using `docs/REDISTRIBUTION_POLICY.md`.
6. Review hashes, sources, licensing and privacy.
7. Promote approved metadata into the future TTG runtime registry consumed by the installer UI.

## Repository layout

```text
catalog/                 schemas and the searchable intake index
docs/                    capture and redistribution rules
scripts/                 local evidence collectors
sessions/                sanitized TTG capture-session manifests
templates/               reusable TTG session templates
```

## Planned runtime path

```text
Authorized external-product observation
        -> sanitized TTG evidence bundle
        -> files-for-sorting review
        -> approved TTG package manifest
        -> private artifact store / official vendor source
        -> Software Builder installer plan
        -> signed THETECHGUY installer
```

The installer must verify TTG tool ID, channel, version, source, file name, size, architecture and SHA-256 before executing or installing anything. Missing or conflicting evidence fails closed.
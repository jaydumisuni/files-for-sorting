# TSM / MTK META Capture Matrix

This document turns authorized TSM observations into a repeatable evidence plan for an independent THETECHGUY META implementation.

It does not authorize copying TSM binaries, databases, credentials or protected service access.

## Existing starting evidence to preserve and reproduce

| Stage | Known starting observation | Evidence still required |
|---|---|---|
| Preloader enumeration | MediaTek `VID_0E8D PID_2000` appears as a COM transport | Signed driver identity/version, interface details, timeout window |
| META enumeration | MediaTek `VID_0E8D PID_2007` appears after boot-to-META | Exact transition timing, reconnect rules, driver binding |
| Boot request | `_InitMtkDll@0` followed by `_SPMeta_Preloader_BootMode@8(COM, 5)` returned success in prior authorized testing | DLL identity/version/hash, exported-call contract evidence, equivalent independent sequence |
| Existing META attach | Connection to an already-present PID 2007 target succeeded | Attach timeout/retry/error categories |
| Target information | Target version information was read on an MT6789 Android 13 test device | Sanitized request/response field map and profile compatibility |
| Factory reset | Vendor META factory-reset operation completed in prior testing | Preconditions, exact risk gate, result confirmation and recovery behaviour |

Treat the call names above as observed compatibility evidence, not as an instruction to redistribute or depend permanently on a proprietary DLL. The final engine should use an independently implemented transport/service path where lawful and technically practical.

## Capture sessions

Create a separate session for each product version, driver set and device/profile combination. Do not mix evidence from different builds into one manifest.

Recommended session naming:

```text
sessions/tsm-meta/<UTC>-tsm-<version>-<chipset>-<operation>/
```

## Layer 1: Installation and dependency inventory

Capture metadata for:

- main executable and supporting DLLs;
- signed MediaTek USB/VCOM drivers and INF packages;
- Visual C++, .NET or other runtimes;
- services/processes started by the application;
- local databases/configuration names and hashes as `metadata_only`;
- official vendor download/update sources;
- architecture and supported Windows builds.

Do not commit files copied from the licensed installation.

## Layer 2: Process and module behaviour

For an authorized run, record:

- process tree and executable names;
- loaded module names, versions, signers and SHA-256;
- service names and start/stop timing;
- temporary directory purpose without copying sensitive contents;
- child processes used for drivers, USB, archives or networking;
- failure behaviour when a dependency is absent.

Never retain memory dumps, credentials, decrypted secrets or activation material.

## Layer 3: USB state machine

For each test, record timestamps relative to cable connection:

1. device powered off or rebooted;
2. Preloader PID 2000 appears;
3. boot-to-META request begins;
4. Preloader disconnects;
5. Kernel META PID 2007 appears;
6. service handshake completes;
7. operation begins;
8. operation result is confirmed;
9. clean disconnect/reboot.

Required facts:

- VID/PID and interface/COM class;
- signed driver provider/version/INF;
- port selection rule;
- handshake timeout and retry count;
- whether the port number changes;
- reconnect/power-cycle requirements;
- error category for every failed stage.

Do not retain the unique USB serial or device serial.

## Layer 4: META service families

Capture read-only families first:

- target/version information;
- modem/baseband information;
- supported service/query list where observable;
- partition/NVRAM inventory metadata;
- device capability/profile identification.

Then capture backup-capable state-changing families:

- NVRAM/NVDATA/proinfo backup and restore;
- configuration writes with before/after hashes;
- ADB-enable state changes;
- reboot/mode-change commands.

Destructive families are last:

- factory reset;
- FRP-related operations only where lawful and device ownership is verified;
- erase/format operations;
- write operations that can affect calibration, radio identity or bootability.

Every destructive record must include a backup requirement, explicit owner gate and device-side confirmation.

## Layer 5: Operation record format

For each operation, capture:

```text
operation_id
profile/chipset scope
required mode and transport
required dependency IDs
preconditions
authorization/ownership check
ordered stage names
input field names and validation rules
sanitized output field names
success confirmation
known errors and retryability
backup/rollback rule
risk class
```

Do not publish raw values that identify a customer or test device.

## Layer 6: Independent implementation gap

For each observed dependency or operation classify it as:

- `replace_now` — public/documented protocol or owned implementation is available;
- `wrap_temporarily` — authorized operator-supplied component can be detected locally while replacement is built;
- `research_required` — evidence is incomplete;
- `blocked_licensing` — cannot be packaged or invoked without additional permission;
- `not_supported` — unsafe, unlawful or outside product scope.

The target is not permanent reliance on TSM. The target is a complete, independently testable THETECHGUY operating contract.

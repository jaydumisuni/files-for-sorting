# TTG MTK META Research Matrix

This document turns authorized observations from external products into a repeatable evidence plan for the independent **TTG META engine**.

## Branding boundary

- `ttg-meta` is the internal tool family, folder and future runtime identity.
- External product names belong only in `observed_product`, source references and compatibility notes.
- TSM is currently one external donor/observation source. It is not the name of our engine, package, installer component or session family.
- No donor binary, database, credential, account material or protected service access becomes a TTG artifact merely because it was observed.

## Existing starting evidence to preserve and reproduce

The following facts were observed during authorized external-product testing and must be independently reproduced by the TTG engine:

| Stage | Known starting observation | Evidence still required |
|---|---|---|
| Preloader enumeration | MediaTek `VID_0E8D PID_2000` appears as a COM transport | Signed driver identity/version, interface details, timeout window |
| META enumeration | MediaTek `VID_0E8D PID_2007` appears after boot-to-META | Exact transition timing, reconnect rules, driver binding |
| Boot request | `_InitMtkDll@0` followed by `_SPMeta_Preloader_BootMode@8(COM, 5)` returned success in prior authorized testing | External DLL identity/version/hash, call-contract evidence and an independent TTG sequence |
| Existing META attach | Connection to an already-present PID 2007 target succeeded | TTG attach timeout/retry/error categories |
| Target information | Target version information was read on an MT6789 Android 13 test device | Sanitized request/response field map and TTG profile compatibility |
| Factory reset | An external META factory-reset operation completed in prior testing | TTG preconditions, exact risk gate, result confirmation and recovery behaviour |

Treat external call names as observed compatibility evidence, not as permanent TTG API names and not as authorization to redistribute proprietary components.

## Capture sessions

Create a separate TTG session for each observed product version, driver set and device/profile combination. Do not mix evidence from different builds into one manifest.

Recommended session naming:

```text
sessions/ttg-meta/<UTC>-ttg-meta-<observed-product>-<version>-<chipset>-<operation>/
```

The external donor name may appear only in the `<observed-product>` portion and the manifest's `observed_product` object.

## Layer 1: Installation and dependency inventory

Capture metadata for:

- main executable and supporting libraries used by the observed product;
- signed MediaTek USB/VCOM drivers and INF packages;
- Visual C++, .NET or other runtimes;
- services/processes started by the application;
- local database/configuration names and hashes as `metadata_only`;
- official vendor download/update sources;
- architecture and supported Windows builds;
- install order, detection rules, restart requirements and failure behaviour.

Do not commit files copied from a licensed installation.

## Layer 2: Process, module and network behaviour

For an authorized run, record:

- process tree and executable names;
- loaded module names, versions, signers and SHA-256;
- service names and start/stop timing;
- temporary-directory purpose without copying sensitive contents;
- child processes used for drivers, USB, archives, ADB/Fastboot or networking;
- failure behaviour when a dependency is absent;
- official domains/routes used for updates, model data and support resources;
- destination filenames, content type, checksum/signature behaviour and cache rules.

Never retain memory dumps, credentials, decrypted secrets, activation material, signed temporary URLs or account sessions.

## Layer 3: USB state machine

For each test, record timestamps relative to cable connection:

1. device powered off or rebooted;
2. Preloader PID 2000 appears;
3. TTG boot-to-META request begins;
4. Preloader disconnects;
5. Kernel META PID 2007 appears;
6. TTG service handshake completes;
7. operation begins;
8. operation result is confirmed;
9. clean disconnect/reboot.

Required facts:

- VID/PID and interface/COM class;
- signed driver provider/version/INF;
- port-selection rule;
- handshake timeout and retry count;
- whether the port number changes;
- reconnect/power-cycle requirements;
- error category for every failed stage.

Do not retain a unique USB serial or device serial.

## Layer 4: TTG META service families

Capture and independently implement read-only families first:

- target/version information;
- modem/baseband information;
- supported service/query list where observable;
- partition/NVRAM inventory metadata;
- device capability/profile identification;
- APDB/MDDB compatibility and version-selection rules;
- chipset/build/profile matching.

Then capture backup-capable state-changing families:

- NVRAM/NVDATA/proinfo backup and restore;
- configuration writes with before/after hashes;
- ADB-enable state changes;
- reboot/mode-change commands;
- profile/database acquisition and local cache validation.

Destructive families are last:

- factory reset;
- FRP-related operations only where lawful and device ownership is verified;
- erase/format operations;
- write operations that can affect calibration, radio identity or bootability.

Every destructive TTG record must include a backup requirement, explicit owner gate and device-side confirmation.

## Layer 5: Operation record format

For each TTG operation, capture:

```text
ttg_operation_id
profile/chipset scope
required mode and transport
required dependency IDs
preconditions
authorization/ownership check
ordered TTG stage names
input field names and validation rules
sanitized output field names
success confirmation
known errors and retryability
backup/rollback rule
risk class
external observation source
```

Do not publish raw values that identify a customer or test device.

## Layer 6: Independent implementation gap

For each observed dependency or operation classify it as:

- `replace_now` — public/documented protocol or owned TTG implementation is available;
- `wrap_temporarily` — an authorized operator-supplied component can be detected locally while the TTG replacement is built;
- `research_required` — evidence is incomplete;
- `blocked_licensing` — cannot be packaged or invoked without additional permission;
- `not_supported` — unsafe, unlawful or outside TTG product scope.

The target is a complete, independently testable TTG operating contract—not permanent reliance on or rebranding of an external product.
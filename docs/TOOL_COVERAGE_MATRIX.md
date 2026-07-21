# TTG Full Tool Evidence Coverage Matrix

The intake system is broader than any single external donor application. Each engine or workflow gets the same TTG evidence treatment so the future THETECHGUY installer and runtime know exactly what is required.

| Area | Capture | Future TTG use |
|---|---|---|
| Windows prerequisites | OS build range, architecture, Visual C++, .NET, Java/Python/runtime versions | Preflight and ordered installation |
| USB drivers | VID/PID, interface, provider, signed INF/version, mode | Driver detection and approved install |
| MTK Preloader/BROM | mode IDs, handshake stages, timeouts, reconnect rules | TTG MTK transport/profile engine |
| MTK META | Preloader-to-META transition, service handshake, target-info reads, operation stages | TTG META engine and profiles |
| Qualcomm DIAG | COM/USB mode, driver, command family, result/error categories | TTG DIAG transport and supported operations |
| Qualcomm EDL | USB identity, signed loader source/classification, handshake/result | Authorized TTG EDL workflows with loader policy |
| SPD/Unisoc | USB identities, driver/runtime, handshake and profile differences | TTG SPD/Unisoc transport engine |
| ADB | adb version, server/client behaviour, authorization state, shell capability | TTG shared ADB core and preflight |
| Fastboot | binary/version, USB interface, getvar behaviour and state transitions | TTG shared Fastboot core |
| MTP | Windows component/provider, device enumeration and supported launch actions | TTG MTP support-page/settings flows |
| USB serial | baud/parity/control lines, reconnect and timeout behaviour | TTG shared serial transport |
| Firmware packages | source, model/region/build identity, hash, extraction layout, licence | TTG approved firmware resolver and verifier |
| Device profiles | chipset/model aliases, mode sequence, quirks, operation support | TTG profile-driven engine settings |
| Operations | preconditions, risk, stages, result, backup/rollback, confirmation | TTG UI action contract and safety gates |
| Network dependencies | official domain/route purpose, content/signature expectations | Vendor fetch and offline failure handling |
| Installer/update | TTG package ID, channel, source, size, hash, detection/install/rollback | Software Builder manifest and signed installer |
| Diagnostics | sanitized failure stage/category/fingerprint | Hunter/owner diagnostics without customer data |

## Per-operation minimum evidence

Every supported TTG operation should eventually have:

1. a stable TTG operation ID;
2. supported chipset/model/profile scope;
3. required device mode and transport;
4. dependency and driver IDs;
5. preflight checks;
6. ordered observable stages;
7. timeout/retry/reconnect rules;
8. backup and rollback requirements;
9. success evidence from the device side;
10. sanitized error categories;
11. risk class: read-only, state-changing or destructive;
12. legal/licensing boundary for any external artifact.

## Priority capture order

1. Shared Windows runtimes, signed drivers and USB identities.
2. TTG MTK Preloader -> Kernel META connection and read-only information services.
3. TTG META backup/read/write service families with explicit safety gates.
4. TTG ADB, Fastboot, MTP and USB-serial dependencies already used by the ecosystem.
5. TTG Qualcomm DIAG/EDL and SPD/Unisoc transport requirements.
6. TTG firmware/package resolver and model/profile data.
7. Destructive operations only after read/backup/restore evidence is complete.

## Promotion rule

An external observation is not automatically a TTG feature. It becomes eligible for implementation only after:

- independent reproduction on an authorized test device;
- exact dependency/source/hash evidence;
- sanitized logs or test result;
- profile scope and failure behaviour are known;
- licensing and redistribution are classified;
- destructive behaviour has a backup/rollback or explicit owner gate;
- the promoted engine, package, folder and operation IDs use TTG naming.
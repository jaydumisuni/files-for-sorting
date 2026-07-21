# Sanitized TTG Capture Sessions

Each committed session belongs under:

```text
sessions/<ttg-tool-family>/<session-id>/
```

The tool family must start with `ttg-`, for example:

```text
sessions/ttg-meta/
sessions/ttg-adb/
sessions/ttg-fastboot/
sessions/ttg-qualcomm/
```

External product names belong only in the session manifest's `observed_product` object and, when useful, the observed-product portion of the session ID. They must not replace the TTG tool-family name.

Minimum committed contents:

```text
session-manifest.json
NOTES.md
evidence/<sanitized metadata or result files>
```

Raw capture material must remain in `.local-captures/` or another private working location until reviewed and sanitized.

A session may be committed only when it contains no credentials, account/session material, unique device identifiers, customer data or proprietary binaries. Draft manifests are allowed, but they must still satisfy the authorization boundary and contain no protected data.
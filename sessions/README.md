# Sanitized Capture Sessions

Each committed session belongs under:

```text
sessions/<tool-family>/<session-id>/
```

Minimum committed contents:

```text
session-manifest.json
NOTES.md
evidence/<sanitized metadata or result files>
```

Raw capture material must remain in `.local-captures/` or another private working location until reviewed and sanitized.

A session may be committed only when it contains no credentials, account/session material, unique device identifiers, customer data or proprietary binaries. Draft manifests are allowed, but they must still satisfy the authorization boundary and contain no protected data.

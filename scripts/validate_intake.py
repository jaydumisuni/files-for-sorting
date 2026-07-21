#!/usr/bin/env python3
"""Validate public THETECHGUY evidence intake without external packages."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
TTG_TOOL_FAMILY_RE = re.compile(r"^ttg-[a-z0-9][a-z0-9._-]{0,75}$")
SECRET_RE = re.compile(
    r"(?i)(github_pat_|gh[pousr]_|bearer\s+[a-z0-9._-]+|"
    r"authorization\s*[:=]|password\s*[:=]|cookie\s*[:=]|token\s*[:=])"
)
UNIQUE_DEVICE_RE = re.compile(
    r"(?i)\b(imei|ecid|udid|device[_ -]?serial|apple[_ -]?serial)\b\s*[:=]"
)
FORBIDDEN_SUFFIXES = {
    ".exe", ".dll", ".sys", ".msi", ".msix", ".appx", ".apk", ".ipa",
    ".bin", ".img", ".pac", ".zip", ".7z", ".rar", ".pfx", ".p12",
    ".pem", ".key", ".pcap", ".pcapng", ".dmp", ".dump",
}
REDISTRIBUTION = {
    "redistributable",
    "vendor_fetch",
    "operator_supplied",
    "metadata_only",
    "unknown_blocked",
}
STATUSES = {
    "draft",
    "captured",
    "sanitized",
    "reviewed",
    "approved_for_promotion",
    "blocked",
}


def fail(errors: list[str], path: Path, message: str) -> None:
    errors.append(f"{path.relative_to(ROOT)}: {message}")


def load_json(path: Path, errors: list[str]) -> Any | None:
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(errors, path, f"unreadable JSON: {exc}")
        return None


def walk_strings(value: Any):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for item in value.values():
            yield from walk_strings(item)
    elif isinstance(value, list):
        for item in value:
            yield from walk_strings(item)


def require_bool(record: dict[str, Any], key: str, expected: bool, errors: list[str], path: Path) -> None:
    if record.get(key) is not expected:
        fail(errors, path, f"{key} must be {expected!r}")


def validate_manifest(path: Path, errors: list[str]) -> None:
    payload = load_json(path, errors)
    if not isinstance(payload, dict):
        if payload is not None:
            fail(errors, path, "manifest root must be an object")
        return

    required = {
        "schema_version",
        "record_type",
        "session_id",
        "tool_family",
        "observed_product",
        "capture",
        "authorization",
        "dependencies",
        "usb_modes",
        "operations",
        "evidence",
        "privacy_review",
        "status",
    }
    missing = sorted(required - payload.keys())
    if missing:
        fail(errors, path, f"missing required fields: {', '.join(missing)}")
        return

    if payload.get("schema_version") != "1.0":
        fail(errors, path, "schema_version must be 1.0")
    if payload.get("record_type") != "ttg.authorized_software_evidence_session":
        fail(errors, path, "record_type is invalid")
    if payload.get("status") not in STATUSES:
        fail(errors, path, "status is invalid")

    tool_family = payload.get("tool_family")
    if not isinstance(tool_family, str) or not TTG_TOOL_FAMILY_RE.fullmatch(tool_family):
        fail(
            errors,
            path,
            "tool_family must be an internal TTG name such as ttg-meta; external product names belong in observed_product",
        )

    authorization = payload.get("authorization")
    if not isinstance(authorization, dict):
        fail(errors, path, "authorization must be an object")
    else:
        require_bool(authorization, "authorized_use", True, errors, path)
        require_bool(authorization, "account_material_retained", False, errors, path)
        require_bool(authorization, "licence_bypass_attempted", False, errors, path)

    privacy = payload.get("privacy_review")
    if not isinstance(privacy, dict):
        fail(errors, path, "privacy_review must be an object")
    else:
        require_bool(privacy, "contains_device_identifiers", False, errors, path)
        require_bool(privacy, "contains_credentials", False, errors, path)
        require_bool(privacy, "contains_proprietary_binaries", False, errors, path)
        if payload.get("status") in {"sanitized", "reviewed", "approved_for_promotion"}:
            require_bool(privacy, "sanitized", True, errors, path)

    dependencies = payload.get("dependencies")
    if not isinstance(dependencies, list):
        fail(errors, path, "dependencies must be an array")
    else:
        seen_ids: set[str] = set()
        for index, dependency in enumerate(dependencies):
            label = f"dependencies[{index}]"
            if not isinstance(dependency, dict):
                fail(errors, path, f"{label} must be an object")
                continue
            dependency_id = dependency.get("id")
            if not isinstance(dependency_id, str) or not dependency_id:
                fail(errors, path, f"{label}.id is required")
            elif dependency_id in seen_ids:
                fail(errors, path, f"duplicate dependency id: {dependency_id}")
            else:
                seen_ids.add(dependency_id)
            if dependency.get("redistribution") not in REDISTRIBUTION:
                fail(errors, path, f"{label}.redistribution is invalid")
            digest = dependency.get("sha256")
            if digest is not None and (not isinstance(digest, str) or not SHA256_RE.fullmatch(digest)):
                fail(errors, path, f"{label}.sha256 must be 64 lowercase hexadecimal characters")
            source = dependency.get("source")
            if not isinstance(source, dict) or not str(source.get("reference", "")).strip():
                fail(errors, path, f"{label}.source.reference is required")

    evidence = payload.get("evidence")
    if not isinstance(evidence, list):
        fail(errors, path, "evidence must be an array")
    else:
        for index, item in enumerate(evidence):
            label = f"evidence[{index}]"
            if not isinstance(item, dict):
                fail(errors, path, f"{label} must be an object")
                continue
            evidence_path = item.get("path")
            if not isinstance(evidence_path, str) or not evidence_path:
                fail(errors, path, f"{label}.path is required")
            elif Path(evidence_path).is_absolute() or ".." in Path(evidence_path).parts:
                fail(errors, path, f"{label}.path must be a safe relative path")
            digest = item.get("sha256")
            if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest):
                fail(errors, path, f"{label}.sha256 is invalid")
            if item.get("sanitized") is not True:
                fail(errors, path, f"{label}.sanitized must be true")

    for text in walk_strings(payload):
        if SECRET_RE.search(text):
            fail(errors, path, "possible credential/token material detected")
            break
        if UNIQUE_DEVICE_RE.search(text):
            fail(errors, path, "possible unique device identifier detected")
            break


def validate_repository_files(errors: list[str]) -> None:
    ignored_roots = {".git", ".local-captures", "work", "temp", "tmp", "private", "secrets"}
    for path in ROOT.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(ROOT)
        if any(part in ignored_roots for part in relative.parts):
            continue
        if path.suffix.lower() in FORBIDDEN_SUFFIXES:
            fail(errors, path, f"forbidden public artifact type: {path.suffix.lower()}")


def main() -> int:
    errors: list[str] = []
    validate_repository_files(errors)

    manifests = sorted((ROOT / "sessions").glob("**/session-manifest.json")) if (ROOT / "sessions").exists() else []
    for manifest in manifests:
        validate_manifest(manifest, errors)

    index_path = ROOT / "catalog" / "intake-index.json"
    index = load_json(index_path, errors) if index_path.exists() else None
    if isinstance(index, dict):
        if index.get("record_type") != "ttg.software_evidence_intake_index":
            fail(errors, index_path, "record_type is invalid")
        if not isinstance(index.get("entries"), list):
            fail(errors, index_path, "entries must be an array")

    if errors:
        print("Intake validation FAILED:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"Intake validation passed ({len(manifests)} session manifest(s)).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
#!/usr/bin/env python3
"""Read-only live T08 media acceptance. No raw images, tokens or identifiers printed."""
import argparse
import getpass
import hashlib
import json
from pathlib import Path
import re
import ssl
import urllib.error
import urllib.request
import uuid
import warnings

BASE = "https://api.khanhtn45.id.vn"
MAX_IMAGE = 55 * 1024
MAX_JSON = 2_000_000

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None

OPENER = urllib.request.build_opener(NoRedirect(),
    urllib.request.HTTPSHandler(context=ssl.create_default_context()))

def require(ok, reason):
    if not ok:
        raise ValueError(reason)

def get(path, token=None, binary=False):
    headers = {"Accept": "image/jpeg" if binary else "application/json",
               "Cache-Control": "no-cache"}
    if token:
        headers["Authorization"] = "Bearer " + token
    request = urllib.request.Request(BASE + path, headers=headers, method="GET")
    try:
        with OPENER.open(request, timeout=20) as response:
            limit = MAX_IMAGE if binary else MAX_JSON
            raw = response.read(limit + 1)
            require(len(raw) <= limit, "response too large")
            if binary:
                require(response.headers.get_content_type() == "image/jpeg", "unexpected media type")
                return response.status, raw
            return response.status, json.loads(raw)
    except urllib.error.HTTPError as error:
        return error.code, None

def data(path, token):
    status, body = get(path, token)
    require(status == 200 and isinstance(body, dict) and body.get("success") is True
            and isinstance(body.get("data"), dict), "invalid API response")
    return body["data"]

def identity(role, area=None, outside=False):
    token = getpass.getpass(role + (" outside area" if outside else "") + " access JWT (hidden): ").strip()
    require(bool(token) and "\n" not in token and "\r" not in token, "invalid token")
    user = data("/api/auth/me", token)
    require(user.get("role") == role and user.get("isActive") is True, "wrong or inactive identity")
    if area:
        assigned = {str(x).lower() for x in (user.get("farmingAreaIds") or [])}
        if user.get("farmingAreaId"):
            assigned.add(str(user["farmingAreaId"]).lower())
        require((area not in assigned) if outside else (area in assigned), "wrong area fixture")
    return token

def guid(value):
    return str(uuid.UUID(value))

def hex16(value):
    if not re.fullmatch("[0-9a-f]{16}", value):
        raise argparse.ArgumentTypeError("expected 16 lowercase hexadecimal characters")
    return value

def digest(raw):
    return hashlib.sha256(raw).hexdigest()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--area", required=True, type=guid)
    parser.add_argument("--station", required=True, type=guid)
    parser.add_argument("--boot", required=True, type=hex16)
    parser.add_argument("--batch", required=True, type=hex16)
    parser.add_argument("--analyte", required=True, choices=("NO2", "NO3", "NH3"))
    parser.add_argument("--original", required=True, type=Path, help="original Kiosk JPEG, not a screenshot or re-encoded copy")
    args = parser.parse_args()
    with args.original.open("rb") as source:
        original = source.read(MAX_IMAGE + 1)
    require(4 <= len(original) <= MAX_IMAGE and original[:2] == b"\xff\xd8" and original[-2:] == b"\xff\xd9", "invalid original JPEG")
    warnings.simplefilter("error", getpass.GetPassWarning)
    system = identity("SystemAdministrator")
    readiness = data("/api/system/media-storage/readiness", system)
    require(readiness.get("provider") == "GoogleDrive" and readiness.get("distinctRoots") is True
            and readiness.get("status") == "metadata_ready"
            and readiness.get("privateRoot", {}).get("status") == "metadata_ready"
            and readiness.get("publicRoot", {}).get("status") == "metadata_ready",
            "Drive roots or permissions not ready")
    print("PASS Drive root metadata; upload and quota not verified")
    del system
    admin = identity("FarmAdministrator", args.area)
    batch = f"/api/areas/{args.area}/water-bench/batches/{args.station}/{args.boot}/{args.batch}"
    evidence_path = batch + f"/results/{args.analyte}/evidence"
    receipts = data(batch + "/receipts", admin)
    rows = [r for r in receipts.get("items", []) if r.get("kind") == "media" and r.get("analyte") == args.analyte]
    require(len(rows) == 1, "ambiguous or missing media receipt")
    row = rows[0]
    require(row.get("privateMediaMetadataPresent") is True, "private metadata missing")
    media_id = guid(row["mediaId"])
    sha = digest(original)
    require(row.get("sha256") == sha, "original does not match receipt")
    evidence = data(evidence_path, admin)
    require(evidence.get("provenanceStatus") == "snapshot_verified", "AI snapshot not verified")
    image = evidence["image"]
    provenance = evidence["provenance"]
    require(guid(image["mediaId"]) == media_id and guid(image["receiptId"]) == guid(row["receiptId"])
            and image.get("sha256") == sha and provenance.get("imageSha256") == sha
            and guid(provenance["mediaId"]) == media_id and guid(provenance["imageReceiptId"]) == guid(row["receiptId"])
            and guid(provenance["stationId"]) == args.station and provenance.get("bootId") == args.boot
            and provenance.get("batchId") == args.batch and provenance.get("analyte") == args.analyte,
            "AI provenance mismatch")
    meta_path = f"/api/media/{media_id}"
    content_path = meta_path + "/content"
    meta = data(meta_path, admin)
    require(meta.get("provider") == "GoogleDrive" and meta.get("isShared") is False
            and meta.get("contentType") == "image/jpeg" and meta.get("sizeBytes") == len(original),
            "media metadata mismatch")
    require(get(content_path, binary=True)[0] == 401, "unauthenticated download must fail")
    for role in ("FarmAdministrator", "FarmManager", "FarmStaff"):
        token = admin if role == "FarmAdministrator" else identity(role, args.area)
        status, raw = get(content_path, token, binary=True)
        require(status == 200 and len(raw) == len(original) and digest(raw) == sha,
                "authorized byte readback mismatch")
        other = data(evidence_path, token)
        require(other.get("provenanceSha256") == evidence.get("provenanceSha256")
                and other.get("provenanceStatus") == "snapshot_verified", "role snapshot mismatch")
        print("PASS " + role + " scoped receipt, SHA-256 and current download")
        del token
    outsider = identity("FarmAdministrator", args.area, outside=True)
    require(get(content_path, outsider, binary=True)[0] == 403, "foreign media access must fail")
    require(get(evidence_path, outsider)[0] == 403, "foreign evidence access must fail")
    print("PASS foreign scope denied")
    print("PASS current read-only evidence; no upload, quota, retention, chemistry or hardware acceptance")
    return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, OSError, KeyError, TypeError, getpass.GetPassWarning):
        print("FAIL/BLOCKED: contract, fixture, permission or connection check failed. No secrets or raw data logged.")
        raise SystemExit(1)

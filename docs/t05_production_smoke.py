#!/usr/bin/env python3
"""Read-only production smoke. No credentials or response bodies are printed."""
import argparse
import datetime
import decimal
import getpass
import json
import ssl
import urllib.error
import urllib.parse
import urllib.request
import uuid
import warnings

BASE = "https://api.khanhtn45.id.vn"
REPORT = "/api/reports/operational-efficiency"
ROLES = ("FarmAdministrator", "FarmManager", "FarmStaff", "SystemAdministrator")
COUNTS = ("totalCrabs", "aliveCrabs", "moltingCrabs", "moltedCrabs",
          "harvestedCrabs", "deadCrabs", "unclassifiedCrabs")
RATES = ("survivalRate", "moltingRate", "harvestRate", "mortalityRate", "aliveRate")

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None

OPENER = urllib.request.build_opener(NoRedirect(),
    urllib.request.HTTPSHandler(context=ssl.create_default_context()))

def require(condition, label):
    if not condition:
        raise ValueError(label)

def get(path, token=None, query=None):
    headers = {"Accept": "application/json", "Cache-Control": "no-cache"}
    if token:
        headers["Authorization"] = "Bearer " + token
    url = BASE + path + ("?" + urllib.parse.urlencode(query) if query else "")
    request = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with OPENER.open(request, timeout=15) as response:
            raw = response.read(2_000_001)
            require(len(raw) <= 2_000_000, "response too large")
            return response.status, json.loads(raw, parse_float=decimal.Decimal)
    except urllib.error.HTTPError as error:
        return error.code, None

def envelope(status, body):
    require(status == 200, "expected HTTP 200")
    require(isinstance(body, dict) and body.get("success") is True and
            isinstance(body.get("data"), dict), "invalid envelope")
    return body["data"]

def report_query(area, start, end):
    return {"farmingAreaId": area, "fromDate": start, "toDate": end}

def validate(data, area, expected_total):
    require(data.get("cohortBasis") == "stockedAt-current-status-v1", "legacy basis")
    require(str(data.get("farmingAreaId", "")).lower() == area, "scope mismatch")
    require(all(type(data.get(k)) is int and data[k] >= 0 for k in COUNTS), "invalid counts")
    total, alive, molting, molted, harvested, dead, unknown = (data[k] for k in COUNTS)
    require(sum((alive, molting, molted, harvested, dead, unknown)) == total, "count mismatch")
    require(total == expected_total, "count differs from independently known total")
    require("healthScore" in data and data["healthScore"] is None, "unverified health score")
    numerators = (alive + molting + molted, molting, harvested, dead, alive)
    for key, numerator in zip(RATES, numerators):
        require(key in data, "missing rate")
        if total == 0:
            require(data[key] is None, "empty cohort rate must be null")
        else:
            require(type(data[key]) in (int, decimal.Decimal), "invalid rate type")
            expected = (decimal.Decimal(numerator) * 100 / total).quantize(
                decimal.Decimal("0.01"), rounding=decimal.ROUND_HALF_EVEN)
            require(data[key] == expected, "rate formula mismatch")
    return any(data[k] == 0 for k in RATES) if total else False

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--area", required=True, type=lambda s: str(uuid.UUID(s)))
    parser.add_argument("--denied-area", required=True, type=lambda s: str(uuid.UUID(s)))
    parser.add_argument("--from-date", required=True, type=datetime.date.fromisoformat)
    parser.add_argument("--to-date", required=True, type=datetime.date.fromisoformat)
    parser.add_argument("--empty-from", required=True, type=datetime.date.fromisoformat)
    parser.add_argument("--empty-to", required=True, type=datetime.date.fromisoformat)
    parser.add_argument("--expected-total", required=True, type=int)
    args = parser.parse_args()
    require(args.area != args.denied_area, "areas must differ")
    require(args.expected_total > 0, "known positive total required")
    require(args.from_date <= args.to_date and args.empty_from <= args.empty_to, "invalid dates")
    require(args.to_date < args.empty_from or args.empty_to < args.from_date, "date ranges overlap")
    query = report_query(args.area, args.from_date, args.to_date)
    empty = report_query(args.area, args.empty_from, args.empty_to)
    forbidden = report_query(args.denied_area, args.from_date, args.to_date)
    status, body = get("/health/edge-control")
    require(status == 200 and isinstance(body, dict) and body.get("hardwareControlDisabled") is True,
            "hardware-disabled health not confirmed")
    print("PASS health/edge-control")
    require(get(REPORT, query=query)[0] == 401, "unauthenticated report must be 401")
    print("PASS unauthenticated denial")
    saw_zero = False
    warnings.simplefilter("error", getpass.GetPassWarning)
    for role in ROLES:
        token = getpass.getpass(role + " access JWT (hidden): ").strip()
        require(bool(token) and "\n" not in token and "\r" not in token, "missing/invalid token")
        user = envelope(*get("/api/auth/me", token))
        require(user.get("role") == role and user.get("isActive") is True, "wrong or inactive identity")
        if role in ROLES[:2]:
            assigned = {str(x).lower() for x in (user.get("farmingAreaIds") or [])}
            if user.get("farmingAreaId"):
                assigned.add(str(user["farmingAreaId"]).lower())
            require(args.area in assigned and args.denied_area not in assigned, "invalid scope fixture")
            saw_zero = validate(envelope(*get(REPORT, token, query)), args.area, args.expected_total) or saw_zero
            validate(envelope(*get(REPORT, token, empty)), args.area, 0)
            require(get(REPORT, token, forbidden)[0] == 403, "foreign area must be 403")
            print("PASS " + role + " identity, allowed scope, empty cohort, foreign scope")
        else:
            require(get(REPORT, token, query)[0] == 403, "management report must be denied")
            print("PASS " + role + " identity and management denial")
        del token, user
    print("PASS actual zero" if saw_zero else "BLOCKED actual zero: choose known nonempty cohort with a zero rate")
    print("API checks only; UI, export, lifecycle and physical checks remain manual.")
    return 0 if saw_zero else 2

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, OSError, getpass.GetPassWarning):
        print("FAIL/BLOCKED: a contract assertion or transport/credential check failed; no response or secret logged.")
        raise SystemExit(1)

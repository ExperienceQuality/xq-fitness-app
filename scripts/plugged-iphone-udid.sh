#!/usr/bin/env bash
# Print the hardware UDID of a plugged-in iPhone (xcodebuild/devicectl format).
# Uses devicectl so custom device names and model strings are resolved reliably.
set -euo pipefail

JSON="$(mktemp)"
trap 'rm -f "${JSON}"' EXIT

if ! xcrun devicectl list devices --timeout 30 --json-output "${JSON}" >/dev/null 2>&1; then
  echo "error: devicectl could not list devices" >&2
  exit 1
fi

python3 - "${JSON}" <<'PY'
import json
import os
import sys

path = sys.argv[1]
name_filter = os.environ.get("IOS_DEVICE_NAME", "").strip().lower()
model_filter = os.environ.get("IOS_DEVICE_MODEL", "").strip().lower()

with open(path, encoding="utf-8") as handle:
    data = json.load(handle)

iphones = []
for device in data.get("result", {}).get("devices", []):
    hardware = device.get("hardwareProperties") or {}
    if hardware.get("deviceType") != "iPhone" or hardware.get("reality") != "physical":
        continue

    connection = device.get("connectionProperties") or {}
    if connection.get("tunnelState") != "connected":
        continue

    udid = hardware.get("udid")
    if not udid:
        continue

    properties = device.get("deviceProperties") or {}
    iphones.append(
        {
            "name": properties.get("name") or "",
            "model": hardware.get("marketingName") or "",
            "udid": udid,
        }
    )


def matches(phone: dict) -> bool:
    if name_filter and name_filter not in phone["name"].lower():
        return False
    if model_filter and model_filter not in phone["model"].lower():
        return False
    return True


candidates = [phone for phone in iphones if matches(phone)] if (name_filter or model_filter) else iphones

if not iphones:
    print("error: no connected iPhone found via devicectl", file=sys.stderr)
    print("Connect, unlock, trust the device, and enable Developer Mode, then retry.", file=sys.stderr)
    sys.exit(1)

if not candidates:
    print(
        "error: no connected iPhone matched "
        f"IOS_DEVICE_NAME={name_filter!r} IOS_DEVICE_MODEL={model_filter!r}",
        file=sys.stderr,
    )
    for phone in iphones:
        print(f"  {phone['name']} ({phone['model']}) {phone['udid']}", file=sys.stderr)
    sys.exit(1)

if len(candidates) > 1:
    print(
        "error: multiple connected iPhones matched; set IOS_DEVICE_NAME or IOS_DEVICE_MODEL:",
        file=sys.stderr,
    )
    for phone in candidates:
        print(f"  {phone['name']} ({phone['model']}) {phone['udid']}", file=sys.stderr)
    sys.exit(1)

print(candidates[0]["udid"])
PY

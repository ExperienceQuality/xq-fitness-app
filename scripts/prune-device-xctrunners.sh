#!/usr/bin/env bash
# Remove stale XCTest runner apps from a device to free free-developer-profile slots.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="${1:-${IOS_DEVICE_ID:-$("${ROOT}/scripts/plugged-iphone-udid.sh")}}"

log() {
  printf '==> %s\n' "$*" >&2
}

JSON="$(mktemp)"
trap 'rm -f "${JSON}"' EXIT

if ! xcrun devicectl device info apps --device "${DEVICE_ID}" --json-output "${JSON}" >/dev/null 2>&1; then
  log "Skipping xctrunner cleanup; could not list apps on ${DEVICE_ID}"
  exit 0
fi

RUNNERS="$(
  python3 - "${JSON}" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

for app in data.get("result", {}).get("apps", []):
    bundle_id = app.get("bundleIdentifier", "")
    if bundle_id.endswith(".xctrunner"):
        print(bundle_id)
PY
)"

if [[ -z "${RUNNERS}" ]]; then
  log "No xctrunner apps on ${DEVICE_ID}"
  exit 0
fi

while IFS= read -r bundle_id; do
  [[ -z "${bundle_id}" ]] && continue
  log "Uninstalling stale runner ${bundle_id} from ${DEVICE_ID}"
  xcrun devicectl device uninstall app --device "${DEVICE_ID}" "${bundle_id}"
done <<<"${RUNNERS}"

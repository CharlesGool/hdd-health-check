#!/usr/bin/env bash
# Synthetic validation only: no SMART commands or target-device reads.
set -Eeuo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
python3 scripts/check-project.py
while IFS= read -r -d '' file; do
    bash -n "$file"
done < <(find src/checker deploy tests -type f -name '*.sh' -print0)
bash -n hdd-health-check.sh
python3 -m py_compile src/web/server.py scripts/check-project.py
for file in tests/*.sh; do bash "$file"; done
for file in tests/*.py; do python3 "$file"; done

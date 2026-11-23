#!/usr/bin/env bash
set -Eeuo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
rpm_file="$(find "$repo_root/dist" -maxdepth 1 -name 'python3-vcert-*.el9.x86_64.rpm' -print -quit)"
test -n "$rpm_file"

dnf -y --setopt=install_weak_deps=False install "$rpm_file"
python3 - <<'PY'
import sys
assert not any("/vcert/_vendor" in p for p in sys.path)
PY
python3 - <<'PY'
import sys
from pathlib import Path
from importlib.metadata import version
import vcert
import cryptography
import requests
import nacl
assert sys.version_info[:2] == (3, 9), sys.version
assert version("vcert") == "0.23.0"
assert version("cryptography") == "48.0.1"
assert version("requests") == "2.32.4"
for module in (cryptography, requests, nacl):
    assert "/vcert/_vendor/" in str(Path(module.__file__).resolve()), module.__file__
assert vcert.Connection(fake=True)
print("PASS: python3 imports VCert on a clean EL9 host")
PY
rpm -q python3-vcert
rpm -q --requires python3-vcert

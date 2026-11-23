#!/usr/bin/env bash
set -Eeuo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
rpm_file="$(find "$root/dist" -maxdepth 1 -name 'python3-vcert-*.el9.noarch.rpm' -print -quit)"
test -n "$rpm_file"

dnf -y --setopt=install_weak_deps=False install   dnf-plugins-core
dnf config-manager --set-enabled ubi-9-codeready-builder-rpms
dnf -y --setopt=install_weak_deps=False install   https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf -y --setopt=install_weak_deps=False install "$rpm_file"
python3 - <<'PY'
from importlib import metadata
import sys
import vcert
assert sys.version_info[:2] == (3, 9), sys.version
assert metadata.version('vcert') == '0.15.0'
assert vcert.Connection(fake=True)
print("PASS: VCert import and fake connection with EL9 Python 3.9")
PY
rpm -q python3-vcert
rpm -q --requires python3-vcert
rpm -ql python3-vcert

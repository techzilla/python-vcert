#!/usr/bin/env bash
set -Eeuo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
if [[ "$(id -u)" -ne 0 ]]; then
  echo "This script must run as root in an AlmaLinux 9 build container." >&2
  exit 1
fi

dnf -y --setopt=install_weak_deps=False install \
  python3 python3-pip python3-rpm-macros rpm-build \
  tar gzip findutils coreutils curl

version="$(sed -n 's/^vcert==//p' packaging/requirements.txt)"
spec_version="$(sed -n 's/^Version:[[:space:]]*//p' packaging/python3-vcert.spec)"
test -n "$version" && test "$version" = "$spec_version"

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
python3 -m venv "$scratch/venv"
"$scratch/venv/bin/python" -m pip install --disable-pip-version-check --upgrade pip

mkdir -p "$scratch/wheels"
"$scratch/venv/bin/python" -m pip download \
  --disable-pip-version-check --only-binary=:all: \
  --dest "$scratch/wheels" -r packaging/requirements.txt

bundle="$scratch/vcert-bundle-$version"
site="$bundle/python-site"
mkdir -p "$site"
"$scratch/venv/bin/python" -m pip install \
  --disable-pip-version-check --no-index --find-links="$scratch/wheels" \
  --only-binary=:all: --no-compile --target="$site" \
  -r packaging/requirements.txt
test -f "$site/vcert/__init__.py"
test -d "$site/vcert-$version.dist-info"

# Move wheel dependencies into the VCert package; never overwrite
# distro-owned modules in global site-packages.
mkdir -p "$site/vcert/_vendor"
rm -rf "$site/bin"
shopt -s nullglob
for entry in "$site"/*; do
  base="$(basename "$entry")"
  case "$base" in
    vcert|vcert-*.dist-info) continue ;;
  esac
  mv "$entry" "$site/vcert/_vendor/"
done

"$scratch/venv/bin/python" - "$site/vcert/__init__.py" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
src = path.read_text()
injection = '''# RPM bootstrap: prefer bundled dependencies when VCert is imported.
import os as _vcert_os
import sys as _vcert_sys
_vcert_vendor_path = _vcert_os.path.join(_vcert_os.path.dirname(__file__), "_vendor")
if _vcert_vendor_path not in _vcert_sys.path:
    _vcert_sys.path.insert(0, _vcert_vendor_path)
del _vcert_os, _vcert_sys, _vcert_vendor_path

'''
path.write_text(injection + src)
PY

license_file="$(find "$site/vcert-$version.dist-info" -type f \
  \( -name LICENSE -o -name LICENSE.txt \) -print -quit)"
if [[ -n "$license_file" ]]; then
  cp "$license_file" "$bundle/LICENSE"
else
  curl -fLsS "https://raw.githubusercontent.com/Venafi/vcert-python/v$version/LICENSE" \
    -o "$bundle/LICENSE"
fi
(
  cd "$scratch/wheels"
  sha256sum ./* > "$bundle/WHEEL-SHA256SUMS.txt"
)

rpmtop="$scratch/rpmbuild"
mkdir -p "$rpmtop"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
tar -C "$scratch" -czf "$rpmtop/SOURCES/vcert-bundle-$version.tar.gz" "vcert-bundle-$version"
rpmbuild --define "_topdir $rpmtop" --define "dist .el9" \
  -bb packaging/python3-vcert.spec
mkdir -p "$repo_root/dist"
find "$rpmtop/RPMS" -type f -name '*.rpm' -exec cp -v {} "$repo_root/dist/" \;
test -n "$(find "$repo_root/dist" -name 'python3-vcert-*.el9.x86_64.rpm' -print -quit)"

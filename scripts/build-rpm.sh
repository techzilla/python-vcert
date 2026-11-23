#!/usr/bin/env bash
set -Eeuo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

# Run in registry.access.redhat.com/ubi9/ubi (Red Hat UBI 9).
test "$(id -u)" -eq 0

dnf -y --setopt=install_weak_deps=False install   rpm-build python3 python3-devel python3-setuptools python3-rpm-macros   curl-minimal tar gzip findutils dnf-plugins-core

# UBI's CodeReady Builder packages supply python3-ruamel-yaml.
dnf config-manager --set-enabled ubi-9-codeready-builder-rpms
# PyNaCl and python3-future come from EPEL 9, not base RHEL 9.
dnf -y --setopt=install_weak_deps=False install   https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

dnf -y --setopt=install_weak_deps=False install   python3-requests python3-dateutil python3-six python3-cryptography   python3-ruamel-yaml python3-pynacl python3-future

version="$(sed -n 's/^Version:[[:space:]]*//p' packaging/python3-vcert.spec)"
test -n "$version"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
rpmtop="$scratch/rpmbuild"
mkdir -p "$rpmtop"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
curl -fLsS --retry 3   "https://github.com/Venafi/vcert-python/archive/refs/tags/v$version.tar.gz"   -o "$rpmtop/SOURCES/vcert-python-$version.tar.gz"

rpmbuild --define "_topdir $rpmtop" --define "dist .el9"   -ba packaging/python3-vcert.spec
mkdir -p dist
find "$rpmtop/RPMS" -name '*.rpm' -exec cp -v {} dist/ \;
find "$rpmtop/SRPMS" -name '*.rpm' -exec cp -v {} dist/ \;
test -n "$(find dist -name "python3-vcert-$version-*.el9.noarch.rpm" -print -quit)"

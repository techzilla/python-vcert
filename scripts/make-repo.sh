#!/usr/bin/env bash
set -Eeuo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
dnf -y --setopt=install_weak_deps=False install createrepo_c
rpm_file="$(find dist -maxdepth 1 -name 'python3-vcert-*.el9.noarch.rpm' -print -quit)"
test -n "$rpm_file"
mkdir -p public/el9/x86_64
cp "$rpm_file" public/el9/x86_64/
createrepo_c public/el9/x86_64
cp packaging/python-vcert.repo public/python-vcert.repo
cat > public/index.html <<'HTML'
<!doctype html><html lang="en"><meta charset="utf-8">
<title>python-vcert EL9 RPM repository</title>
<body><h1>python-vcert for Enterprise Linux 9</h1>
<p><a href="python-vcert.repo">DNF repository configuration</a></p>
<p>Requires CodeReady Builder and EPEL 9. RPM signatures are not yet configured.</p></body></html>
HTML

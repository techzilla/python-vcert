#!/usr/bin/env bash
set -Eeuo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
dnf -y --setopt=install_weak_deps=False install createrepo_c
rpm_file="$(find dist -maxdepth 1 -name 'python3-vcert-*.el9.x86_64.rpm' -print -quit)"
test -n "$rpm_file"
mkdir -p public/el9/x86_64
cp "$rpm_file" public/el9/x86_64/
createrepo_c public/el9/x86_64
cp packaging/python-vcert.repo public/python-vcert.repo
cat > public/index.html <<'HTML'
<!doctype html>
<html lang="en"><meta charset="utf-8"><title>python-vcert EL9 RPM repository</title>
<body><h1>python-vcert for Enterprise Linux 9</h1>
<p><a href="python-vcert.repo">Download the DNF repository configuration</a></p>
<p>Packages and metadata: <a href="el9/x86_64/">el9/x86_64/</a></p>
<p>Unsigned community RPMs. See the GitHub repository for details.</p></body></html>
HTML

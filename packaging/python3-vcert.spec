%global pypi_name vcert

Name:           python3-vcert
Version:        0.15.0
Release:        1%{?dist}
Summary:        Python client for Venafi Trust Protection Platform and Venafi Cloud
License:        Apache-2.0
URL:            https://github.com/Venafi/vcert-python
Source0:        https://github.com/Venafi/vcert-python/archive/refs/tags/v%{version}.tar.gz#/vcert-python-%{version}.tar.gz
BuildArch:      noarch

BuildRequires:  python3-devel
BuildRequires:  python3-setuptools
BuildRequires:  python3-rpm-macros
BuildRequires:  python3-requests
BuildRequires:  python3-dateutil
BuildRequires:  python3-six
BuildRequires:  python3-cryptography
BuildRequires:  python3-ruamel-yaml
BuildRequires:  python3-pynacl
BuildRequires:  python3-future

Requires:       python3-requests
Requires:       python3-dateutil
Requires:       python3-six
Requires:       python3-cryptography
Requires:       python3-ruamel-yaml
Requires:       python3-pynacl
Requires:       python3-future

%description
The VCert Python client library for Venafi certificate-management services.
Built for the default Python 3.9 interpreter on Enterprise Linux 9 with
system-installed Python RPM dependencies. No dependencies are bundled.

%prep
%autosetup -n vcert-python-%{version}
# The upstream 0.15.0 setup.py pins versions that don't match the stable
# RHEL 9 API-compatible libraries. Recreate metadata for distro packaging.
# Do not silently discard an upstream dependency that is actually imported.
python3 - <<'PY'
from pathlib import Path
import re
setup = Path("setup.py")
source = setup.read_text()
imports = [
    line for file in Path("vcert").rglob("*.py")
    for line in file.read_text().splitlines()
    if re.match(r"\s*(from|import)\s+certvalidator\b", line)
]
if imports:
    raise SystemExit("certvalidator is used by upstream source; package it separately before proceeding")
requirements = ("install_requires=['requests', 'python-dateutil', 'six', "
                "'cryptography', 'ruamel.yaml', 'pynacl', 'future']")
source, count = re.subn(r"install_requires=\[[\s\S]*?\]", requirements, source, count=1)
if count != 1:
    raise SystemExit("Upstream setup.py changed; check dependencies")
setup.write_text(source)
PY

%build
%py3_build

%install
%py3_install

%check
PYTHONPATH=%{buildroot}%{python3_sitelib} python3 -c "import vcert; assert vcert.Connection(fake=True)"

%files
%license LICENSE
%doc README.md
%{python3_sitelib}/vcert/
%{python3_sitelib}/vcert-*.egg-info

%changelog
* Mon Nov 23 2026 RPM Maintainers - 0.15.0-1
- Package upstream source for EL9 Python 3.9 using external RPM dependencies

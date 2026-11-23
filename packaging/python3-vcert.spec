# Vendored Python packages must not advertise dependencies/provides globally.
%global __requires_exclude ^python3(\.9)?dist\(.*$
%global __provides_exclude ^python3(\.9)?dist\(.*$

Name:           python3-vcert
Version:        0.23.0
Release:        1%{?dist}
Summary:        VCert Python client bundled for EL9 Python 3.9
License:        Apache-2.0
URL:            https://github.com/Venafi/vcert-python
Source0:        vcert-bundle-%{version}.tar.gz
BuildArch:      x86_64
BuildRequires:  python3-rpm-macros
Requires:       python(abi) = 3.9
Requires:       glibc >= 2.34
Provides:       python3dist(vcert) = %{version}
Provides:       python3.9dist(vcert) = %{version}

%description
VCert for the default EL9 Python 3.9 interpreter with bundled
Python dependencies stored under vcert/_vendor.

%prep
%setup -q -n vcert-bundle-%{version}

%build
:

%install
install -d %{buildroot}%{python3_sitelib}
cp -a python-site/. %{buildroot}%{python3_sitelib}/

%files
%license LICENSE
%doc WHEEL-SHA256SUMS.txt
%{python3_sitelib}/vcert/
%{python3_sitelib}/vcert-*.dist-info/

%changelog
* Mon Nov 23 2026 RPM Maintainers - 0.23.0-1
- Initial EL9 bundled Python 3.9 RPM

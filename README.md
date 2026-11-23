# python3-vcert for Red Hat Enterprise Linux 9

This project builds a **conventional source-built, noarch RPM** of upstream
[Venafi/vcert-python](https://github.com/Venafi/vcert-python), version **0.15.0**.
Build and test containers use **Red Hat UBI 9** (not AlmaLinux).
The package uses the default Python 3.9 and **does not bundle Python libraries**.

## Compatibility and dependencies

Upstream vcert 0.15.0 was selected because it pinned cryptography 36.0.1, the
version family provided by RHEL 9. Other upstream dependency pins are relaxed
in `%prep` to use distro-maintained RPM packages. This is a downstream
compatibility change: correctness requires the clean UBI 9 test to pass.

System packages: python3-requests, python3-dateutil, python3-six,
python3-cryptography, python3-ruamel-yaml, python3-pynacl, python3-future.

**Additional repositories required:** CodeReady Builder (for ruamel.yaml) and
EPEL 9 (for PyNaCl and future). This package is therefore **not installable
using BaseOS/AppStream alone**. No pip or venv is used on the target.

The packaging verifies that the old upstream certvalidator dependency is not
imported from source. If that check fails, the build intentionally stops
rather than publishing an RPM missing a runtime dependency.

The package does not include newer VCert features released after 0.15.0.

## CI, building and publishing

GitHub Actions builds an RPM and SRPM in `registry.access.redhat.com/ubi9/ubi`,
then installs the binary RPM on a fresh UBI 9 image. This workflow is the
compatibility gate; do not tag a release until it passes.

Local reproduction (requires Docker):

```sh
docker run --rm -v "$PWD:/work" -w /work registry.access.redhat.com/ubi9/ubi:latest bash scripts/build-rpm.sh
docker run --rm -v "$PWD:/work" -w /work registry.access.redhat.com/ubi9/ubi:latest bash scripts/test-rpm.sh
```

Once a build passes, tag `v0.15.0` to publish both RPM and SRPM to GitHub
Releases and generate a DNF repository through GitHub Pages. Select
**Settings → Pages → GitHub Actions** to activate Pages.

The RPM remains unsigned until a signing key is configured. Do not use the
unsigned repository for production distribution without establishing trust.

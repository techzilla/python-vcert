# python-vcert: RHEL 9 RPM packaging

Third-party packaging for [CyberArk/Venafi vcert-python](https://github.com/Venafi/vcert-python). This repository builds an RPM named `python3-vcert` for the **default RHEL 9 Python 3.9** on **x86_64**.

Upstream version: **0.23.0**. No alternate interpreter, `pip install`, or virtual environment is required on the target host.

## Install

After the [GitHub Pages DNF repository](https://techzilla.github.io/python-vcert/python-vcert.repo) has been deployed:

```bash
sudo curl -fsSL https://techzilla.github.io/python-vcert/python-vcert.repo \
  -o /etc/yum.repos.d/python-vcert.repo
sudo dnf install python3-vcert
python3 -c 'import vcert; print(vcert.__file__)'
```

Alternatively install the RPM directly from the [Releases](https://github.com/techzilla/python-vcert/releases) page with `sudo dnf install ./python3-vcert-*.el9.x86_64.rpm`.

**The RPM is currently unsigned**; the sample DNF repo uses `gpgcheck=0`. For managed production deployments, sign packages, distribute the signing key and enable GPG verification.

## Why a bundled RPM?

VCert 0.23.0 requires newer Python modules than RHEL 9 normally ships, notably `cryptography >=48.0.1`. This build bundles Python dependencies under `vcert/_vendor`, leaves RHEL-managed Python modules untouched, and adds the private path **when vcert is imported**. It does not modify the default Python interpreter.

This technique has a limitation: after importing `vcert`, the process may resolve common modules such as `requests` and `cryptography` from the bundled versions. Applications that pre-import incompatible system versions may still encounter a conflict. Test integrations that mix vcert with other Python frameworks. A dedicated virtual environment is preferable for strict isolation.

## Build and test

The workflow builds and tests against **AlmaLinux 9**, a RHEL 9-compatible distribution. It has **not** been certified on subscription-protected RHEL 9, or validated for RHEL FIPS mode.

To reproduce locally with Docker:

```bash
docker run --rm -v "$PWD:/work" -w /work almalinux:9 bash scripts/build-rpm.sh
docker run --rm -v "$PWD:/work" -w /work almalinux:9 bash scripts/test-rpm.sh
```

The build downloads wheels from PyPI in a temporary isolated environment; no internet access is needed during `rpmbuild`. The build records the downloaded wheel hashes in the RPM documentation. Versions of direct requirements are pinned in `packaging/requirements.txt`; transitive versions are resolver-selected.

## Publishing

1. Push changes or dispatch the workflow to build and smoke-test an RPM. Passing builds are retained as workflow artifacts.
2. Push a tag that matches the VCert version, such as `v0.23.0`. The workflow creates a GitHub Release and attaches the tested RPM.
3. In repository **Settings → Pages**, select **GitHub Actions** as the Pages build source. The same tag workflow deploys a DNF repository to GitHub Pages.

Repository directory: `el9/x86_64/`. The Pages repository currently contains the latest tagged RPM; older packages remain available through GitHub Releases. To publish a new upstream VCert release, update `packaging/requirements.txt`, the RPM spec `Version`, and the release tag together.

## Files

- `packaging/python3-vcert.spec`: RPM spec.
- `packaging/requirements.txt`: upstream and direct dependency versions.
- `scripts/build-rpm.sh`: downloads wheels, builds a bundled source archive and produces the RPM.
- `scripts/test-rpm.sh`: clean AlmaLinux 9 installation smoke test.
- `scripts/make-repo.sh`: generates DNF repository metadata for GitHub Pages.
- `.github/workflows/rpm.yml`: CI, releases, and optional Pages deployment.

VCert is licensed under Apache-2.0 by its upstream authors. This repository is an independent packaging project and is not endorsed by CyberArk.

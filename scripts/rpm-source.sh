#!/bin/bash

set -e

# install templated-dictionary
mkdir td-source
pushd td-source >/dev/null
wget https://github.com/xsuchy/templated-dictionary/archive/refs/tags/python-templated-dictionary-1.5-1.tar.gz
tar -xf python-templated-dictionary-1.5-1.tar.gz
cd templated-dictionary-python-templated-dictionary-1.5-1

python3 ./setup.py build
sudo python3 ./setup.py install --optimize=1 --skip-build

popd >/dev/null
sudo rm -r td-source

# install mock
sudo apt-get install python3-pyroute2 python3-backoff python3-rpm

mkdir mock-source
pushd mock-source >/dev/null
wget https://github.com/rpm-software-management/mock/releases/download/mock-5.9-1/mock-5.9.tar.gz
tar -xf mock-5.9.tar.gz

sitelib=$(python3 -c 'from sysconfig import get_path; import sys; sys.stdout.write(get_path(name="purelib"))')
pkgver=5.9
rpmrel=1

# see https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=mock and mock-$pkgver.tar.gz/mock.spec
cd mock-$pkgver
sed -r -i py/mockbuild/constants.py py/mock-parse-buildlog.py \
	-e 's|^VERSION\s*=.*|VERSION="'$pkgver'"|' \
	-e 's|^SYSCONFDIR\s*=.*|SYSCONFDIR="/etc"|' \
	-e 's|^PYTHONDIR\s*=.*|PYTHONDIR="'$sitelib'"|' \
	-e 's|^PKGPYTHONDIR\s*=.*|PKGPYTHONDIR="'$sitelib'/mockbuild"|'
sudo sed -i 's/^_MOCK_NVR = None$/_MOCK_NVR = "mock-'$pkgver-$rpmrel'"/' \
    py/mock.py
sudo mkdir -p /etc/mock/eol/templates
sudo mkdir -p /etc/mock/templates

sudo install -Dp -m755 py/mock.py /usr/bin/mock
sudo install -Dp -m755 mockchain  /usr/bin/mockchain
sudo install -Dp -m755 py/mock-hermetic-repo.py /usr/bin/mock-hermetic-repo
sudo install -Dp -m755 py/mock-parse-buildlog.py /usr/bin/mock-parse-buildlog
# sudo install create_default_route_in_container.sh /usr/libexec/mock/

sudo cp -a etc/pam/* /etc/pam.d/

sudo install -d /etc/mock
sudo cp -a etc/mock/* /etc/mock/

sudo install -d /etc/security/console.apps/
sudo cp -a etc/consolehelper/mock /etc/security/console.apps/mock

# sudo install -d /usr/share/bash-completion/completions/
# sudo cp -a etc/bash_completion.d/* /usr/share/bash-completion/completions/
# sudo cp -a mock.complete /usr/share/bash-completion/completions/mock
# sudo ln -s mock /usr/share/bash-completion/completions/mock-parse-buildlog

sudo install -d /etc/pki/mock
sudo cp -a etc/pki/* /etc/pki/mock/

sudo cp -a py/mockbuild $sitelib/

# sudo install -d /usr/share/man/man1
# sudo cp -a docs/mock.1 docs/mock-parse-buildlog.1 mock-hermetic-repo.1 /usr/share/man/man1/
sudo install -d /usr/share/cheat
sudo cp -a docs/mock.cheat /usr/share/cheat/mock

sudo install -d /var/lib/mock
sudo install -d /var/cache/mock

sudo mkdir -p /usr/share/doc/mock
install -p -m 0644 docs/buildroot-lock-schema-*.json /usr/share/doc/mock/
install -p -m 0644 docs/site-defaults.cfg /usr/share/doc/mock

# sudo mkdir -p /usr/lib/sysusers.d
echo 'g  mock  -  -' | sudo tee /usr/lib/sysusers.d/mock.conf

popd >/dev/null
rm -r mock-source

sudo mock --version

sudo apt-get install dnf

ls /etc/mock

SOURCE_DIR="$(dirname $(realpath $0))/.."
RPM_DIR="$SOURCE_DIR"/contrib/rpm
CONFIG_FILE="$SOURCE_DIR"/contrib/conf/config.toml

spec_version=$(grep '^Version:' "$RPM_DIR"/python-ruyi.spec | head -n1 | sed "s/ //g" | cut -d':' -f2)
spec_oe_version=$(grep '^Version:' "$RPM_DIR"/python-ruyi-oe.spec | head -n1 | sed "s/ //g" | cut -d':' -f2)
spec_release=$(grep '^Release:' "$RPM_DIR"/python-ruyi.spec | head -n1 | sed "s/ //g" | cut -d':' -f2)
spec_oe_release=$(grep '^Release:' "$RPM_DIR"/python-ruyi-oe.spec | head -n1 | sed "s/ //g" | cut -d':' -f2)
upstream_version="${spec_version//'~'/-}"

if [[ "$spec_version" != "$spec_oe_version" ]]; then
	echo "Check spec versions"
	exit -1
fi

SRPM_FILE="python-ruyi-"$spec_version"-"$spec_release".src.rpm"
SRPM_OE_FILE="python-ruyi-"$spec_oe_version"-"$spec_oe_release".src.rpm"

cd "$RPM_DIR"

# get upstream source
wget https://github.com/ruyisdk/ruyi/releases/download/"$upstream_version"/ruyi-"$upstream_version".tar.gz
cp -v ruyi-"$upstream_version".tar.gz ruyi-"$spec_version".tar.gz


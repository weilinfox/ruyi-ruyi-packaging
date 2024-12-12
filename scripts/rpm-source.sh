#!/bin/bash

set -e

sudo apt-get install dnf

whoami

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


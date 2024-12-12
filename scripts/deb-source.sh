#!/bin/bash

set -e

SOURCE_DIR="$(dirname $(realpath $0))/.."
DEBIAN_DIR="$SOURCE_DIR"/contrib/debian
CONFIG_FILE="$SOURCE_DIR"/contrib/conf/config.toml

changelog_version=$(head -n1 "$DEBIAN_DIR"/changelog | cut -d' ' -f2)
if [[ "$changelog_version" =~ ^\(([0-9]+:)?([a-zA-Z0-9.+~:-]+)-([a-zA-Z0-9.+~]+)\)$ ]]; then
	orig_version="${BASH_REMATCH[2]}"
	debian_reversion="${BASH_REMATCH[3]}"

	# Replace '~' with '-' in the upstream version
	upstream_version="${orig_version//'~'/-}"
	echo "Ruyi version $upstream_version"
	echo "Upstream version $orig_version"
	echo "Debian reversion $debian_reversion"
else
	echo "Invalid Debian version format: $changelog_version"
	return 1
fi

DSC_FILE="python-ruyi_$orig_version-$debian_reversion.dsc"
ORIG_TARBALL="python-ruyi_$orig_version.orig.tar.gz"
# gz or xz or ?
DEBIAN_TARBALL="python-ruyi_$orig_version-$debian_reversion.debian.tar"

cd "$DEBIAN_DIR"
# copy config file
mkdir bin
cp "$CONFIG_FILE" bin/

cd ..
# get orig package
wget https://github.com/ruyisdk/ruyi/releases/download/"$upstream_version"/ruyi-"$upstream_version".tar.gz
cp -v ruyi-"$upstream_version".tar.gz "$ORIG_TARBALL"

# extract ruyi source
mkdir ruyi-source
cp -r "$DEBIAN_DIR" ruyi-source
cd ruyi-source
tar xf ../ruyi-"$upstream_version".tar.gz
# build source package
dpkg-source -b .

cd ..
# cat dsc content
cat "$DSC_FILE"
ls -la "$ORIG_TARBALL" ${DEBIAN_TARBALL}*


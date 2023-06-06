#!/bin/bash
set -e
export MAKEFLAGS="-j$(nproc)"

# WITH_UPX=1

platform="$(uname -s)"
platform_arch="$(uname -m)"

if [ -x "$(which apt 2>/dev/null)" ]
    then
        apt update && apt install -y python3-pip patchelf \
            autoconf git cmake upx-ucl libx11-dev xutils-dev libxmuu-dev \
            build-essential clang pkg-config gettext
fi
pip install staticx

if [ -d build ]
    then
        echo "= removing previous build directory"
        rm -rf build
fi

if [ -d release ]
    then
        echo "= removing previous release directory"
        rm -rf release
fi

# create build and release directory
mkdir build
mkdir release
pushd build

# download xorg-xhost
git clone https://gitlab.freedesktop.org/xorg/app/xhost.git
xorg_xhost_version="$(cd xhost && git describe --long --tags|sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g;s|xhost.||g')"
mv xhost "xorg-xhost-${xorg_xhost_version}"
echo "= downloading xorg-xhost v${xorg_xhost_version}"

echo "= building xorg-xhost"
pushd xorg-xhost-${xorg_xhost_version}
./autogen.sh
./configure
make
popd # xorg-xhost-${xorg_xhost_version}

popd # build

shopt -s extglob

echo "= packaging xorg-xhost binary"
if [[ "$WITH_UPX" == 1 && -x "$(which upx 2>/dev/null)" ]]
    then
        staticx --strip "build/xorg-xhost-${xorg_xhost_version}/xhost" release/xhost
    else
        staticx --no-compress --strip "build/xorg-xhost-${xorg_xhost_version}/xhost" release/xhost
fi

echo "= create release tar.xz"
tar --xz -acf xorg-xhost-static-v${xorg_xhost_version}-${platform_arch}.tar.xz release
# cp xorg-xhost-static-*.tar.xz ~/ 2>/dev/null

if [ "$NO_CLEANUP" != 1 ]
    then
        echo "= cleanup"
        rm -rf release build
fi

echo "= xorg-xhost v${xorg-xhost_version} done"

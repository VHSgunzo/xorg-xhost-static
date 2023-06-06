#!/bin/sh
set -e
export MAKEFLAGS="-j$(nproc)"
export PATH="$HOME/.local/bin:$PATH"

# WITH_UPX=1

platform="$(uname -s)"
platform_arch="$(uname -m)"

if [ -x "$(which apk 2>/dev/null)" ]
    then
        apk add python3 py3-pip patchelf xhost xz tar \
            make upx gcc pkgconfig binutils musl-dev
fi
pip install -U setuptools
pip install -U wheel
pip install scons
pip install staticx

if [ -d release ]
    then
        echo "= removing previous release directory"
        rm -rf release
fi

echo "= create release directory"
mkdir release

echo "= packaging xorg-xhost binary"
if [[ "$WITH_UPX" == 1 && -x "$(which upx 2>/dev/null)" ]]
    then
        staticx --strip "$(which xhost 2>/dev/null)" release/xhost
    else
        staticx --no-compress --strip "$(which xhost 2>/dev/null)" release/xhost
fi

echo "= create release tar.xz"
xorg_xhost_version="$(apk list -I xhost|awk '{print$1}'|sed 's|xhost-||')"
tar --xz -acf xorg-xhost-static-v${xorg_xhost_version}-${platform_arch}.tar.xz release
mv xorg-xhost-static-*.tar.xz ~/ 2>/dev/null

if [ "$NO_CLEANUP" != 1 ]
    then
        echo "= cleanup"
        rm -rf release
fi

echo "= xorg-xhost v${xorg_xhost_version} done"

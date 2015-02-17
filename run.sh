#!/bin/bash

archpath=''

if [ -n "$UBUNTU_APP_LAUNCH_ARCH" ]; then
	archpath="$UBUNTU_APP_LAUNCH_ARCH"
elif which dpkg-architecture &> /dev/null; then
	archpath="$(dpkg-architecture -qDEB_HOST_GNU_TYPE)"
fi

if [ -z "$archpath" ]; then
	arch=$(dpkg --print-architecture)

	if [ "$arch" == "amd64" ]; then
		archpath="x86_64-linux-gnu"
	elif [ "$arch" == "armhf" ]; then
		archpath="arm-linux-gnueabihf"
	else
		archpath="$arch-linux-gnu"
	fi
fi

export QML2_IMPORT_PATH=$QML2_IMPORT_PATH:$PWD/lib/qml:$PWD/lib/$archpath/qml
qmlscene $* qml/uBullet.qml

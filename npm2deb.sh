#!/bin/sh

package="$1"
version="$2"

#tmpdir=$(mktemp -d npm2deb/$package)
builddir="npm2deb-$package"

mkdir -p $builddir
cat > $builddir/.npmrc <<NPMRC
root = $PWD/$builddir/usr/lib/node
NPMRC

# Trick npm into using a custom .npmrc
env - PATH=$PATH HOME=$PWD/$builddir npm install $package $version

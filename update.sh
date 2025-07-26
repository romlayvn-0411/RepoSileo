#!/bin/sh

# Tạo Packages
apt-ftparchive packages ./debs > ./Packages

# Tính toán MD5 hash
PKG_MD5=$(md5sum ./Packages | cut -d ' ' -f 1)
PKG_SIZE=$(stat ./Packages --printf="%s")

# Tạo file Release
cat > Release << EOF
Origin: RepoSileo
Label: Simple Repo
Suite: stable
Version: 1.0
Codename: ios
Architectures: iphoneos-arm64
Components: main
Description: A simple repository
MD5Sum:
 $PKG_MD5 $PKG_SIZE Packages
EOF
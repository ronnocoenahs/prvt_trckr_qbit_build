#!/usr/bin/env bash

# Exit immediately if any command exits with a non-zero status
set -e

QBT_VERSION="5.2.4"
ARCHIVE_URL="https://sourceforge.net/projects/qbittorrent/files/qbittorrent/qbittorrent-${QBT_VERSION}/qbittorrent-${QBT_VERSION}.tar.xz/download"

echo "=== Step 1: Installing dependencies via pacman ==="
# Note: zlib is omitted here to prevent conflicts with zlib-ng-compat
sudo pacman -Syu --needed \
    base-devel \
    cmake \
    ninja \
    git \
    pkgconf \
    openssl \
    boost \
    libtorrent-rasterbar \
    qt6-base \
    qt6-svg \
    qt6-tools \
    python

echo "=== Step 2: Downloading qBittorrent v${QBT_VERSION} source code ==="
cd /tmp
if [ -f "qbittorrent-${QBT_VERSION}.tar.xz" ]; then
    rm -f "qbittorrent-${QBT_VERSION}.tar.xz"
fi
curl -L -o "qbittorrent-${QBT_VERSION}.tar.xz" "${ARCHIVE_URL}"

echo "=== Step 3: Extracting archive ==="
if [ -d "qbittorrent-${QBT_VERSION}" ]; then
    rm -rf "qbittorrent-${QBT_VERSION}"
fi
tar -xf "qbittorrent-${QBT_VERSION}.tar.xz"
cd "qbittorrent-${QBT_VERSION}"

echo "=== Step 4: Applying compatibility patch for libtorrent 2.1+ ==="
sed -i 's/const Path savePath {storageParams.path};/const Path savePath {std::string(storageParams.path)};/g' src/base/bittorrent/customstorage.cpp
sed -i 's/storageParams.mapped_files ? \*storageParams.mapped_files : storageParams.files,/storageParams.files,/g' src/base/bittorrent/customstorage.cpp

echo "=== Step 5: Configuring build with CMake (SSL enabled) ==="
cmake -G "Ninja" -B build \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/usr/local

echo "=== Step 6: Compiling qBittorrent ==="
cmake --build build -j$(nproc)

echo "=== Step 7: Installing qBittorrent system-wide ==="
sudo cmake --install build

echo "=== Installation Complete! ==="
echo "qBittorrent v${QBT_VERSION} has been successfully built and installed with SSL support."
echo "You can launch it by running: qbittorrent (GUI) or qbittorrent-nox (Headless/WebUI)"

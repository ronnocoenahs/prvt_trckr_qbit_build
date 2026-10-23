#!/usr/bin/env bash

# Exit immediately if any command exits with a non-zero status
set -e

QBT_VERSION="5.2.4"
ARCHIVE_URL="https://sourceforge.net/projects/qbittorrent/files/qbittorrent/qbittorrent-${QBT_VERSION}/qbittorrent-${QBT_VERSION}.tar.xz/download"

echo "=== Step 1: Detecting Operating System & Package Manager ==="
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Detected OS: ${NAME}"
fi

if command -v pacman &> /dev/null; then
    echo "Detected Arch Linux. Installing dependencies via pacman..."
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
elif command -v apt-get &> /dev/null; then
    echo "Detected Debian/Ubuntu-based OS. Installing dependencies via apt..."
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        cmake \
        ninja-build \
        git \
        pkg-config \
        libssl-dev \
        libboost-dev \
        libtorrent-rasterbar-dev \
        qt6-base-dev \
        qt6-svg-dev \
        qt6-tools-dev \
        python3
elif command -v dnf &> /dev/null; then
    echo "Detected Fedora/RHEL-based OS. Installing dependencies via dnf..."
    sudo dnf install -y \
        gcc-c++ \
        cmake \
        ninja-build \
        git \
        pkgconf \
        openssl-devel \
        boost-devel \
        libtorrent-rasterbar-devel \
        qt6-qtbase-devel \
        qt6-qtsvg-devel \
        qt6-qttools-devel \
        python3
elif command -v zypper &> /dev/null; then
    echo "Detected openSUSE. Installing dependencies via zypper..."
    sudo zypper install -y -t pattern devel_C_C++
    sudo zypper install -y \
        cmake \
        ninja \
        git \
        pkgconf \
        libopenssl-devel \
        boost-devel \
        libtorrent-rasterbar-devel \
        qt6-base-devel \
        qt6-svg-devel \
        qt6-tools-devel \
        python3
else
    echo "Error: Could not detect a supported package manager (pacman, apt, dnf, zypper)." >&2
    exit 1
fi

echo "=== Step 2: Downloading qBittorrent v${QBT_VERSION} source code ==="
cd /tmp
if [ -f "qbittorrent-${QBT_VERSION}.tar.xz" ]; then
    rm -f "qbittorrent-${QBT_VERSION}.tar.xz"
fi
curl -L -o "qbittorrent-${QBT_VERSION}.tar.xz" "${ARCHIVE_URL}"

echo "=== Step 3: Extracting source code ==="
if [ -d "qbittorrent-${QBT_VERSION}" ]; then
    rm -rf "qbittorrent-${QBT_VERSION}"
fi
tar -xf "qbittorrent-${QBT_VERSION}.tar.xz"
cd "qbittorrent-${QBT_VERSION}"

echo "=== Step 4: Conditionally patching source code for modern libtorrent API ==="
if grep -q "storageParams.path" src/base/bittorrent/customstorage.cpp 2>/dev/null; then
    sed -i 's/const Path savePath {storageParams.path};/const Path savePath {std::string(storageParams.path)};/g' src/base/bittorrent/customstorage.cpp
fi
if grep -q "mapped_files" src/base/bittorrent/customstorage.cpp 2>/dev/null; then
    sed -i 's/storageParams.mapped_files ? \*storageParams.mapped_files : storageParams.files/storageParams.files/g' src/base/bittorrent/customstorage.cpp
fi

echo "=== Step 5: Configuring build with CMake (SSL enabled & Linuxbrew ignored) ==="
cmake -G "Ninja" -B build \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCMAKE_IGNORE_PATH="/home/linuxbrew/.linuxbrew"

echo "=== Step 6: Compiling qBittorrent ==="
cmake --build build -j$(nproc)

echo "=== Step 7: Installing qBittorrent system-wide ==="
sudo cmake --install build

echo "=== Installation Complete! ==="
echo "qBittorrent v${QBT_VERSION} has been successfully built and installed with SSL support."
echo "You can launch it by running: qbittorrent (GUI) or qbittorrent-nox (Headless/WebUI)"

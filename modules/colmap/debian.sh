#!/bin/bash
set -eu

echo "Installing COLMAP for Debian/Ubuntu..."

# Install dependencies
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  git \
  cmake \
  ninja-build \
  build-essential \
  libboost-program-options-dev \
  libboost-filesystem-dev \
  libboost-graph-dev \
  libboost-system-dev \
  libeigen3-dev \
  libflann-dev \
  libfreeimage-dev \
  libmetis-dev \
  libgoogle-glog-dev \
  libgtest-dev \
  libsqlite3-dev \
  libglew-dev \
  qtbase5-dev \
  libqt5opengl5-dev \
  libcgal-dev \
  libceres-dev \
  libcgal-qt5-dev \
  gcc-10 \
  g++-10

export CC=gcc-10
export CXX=g++-10
export CUDAHOSTCXX=g++-10
export CMAKE_CUDA_ARCHITECTURES=89

# Clone COLMAP
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

git clone https://github.com/colmap/colmap.git

# Build and install
mkdir -p colmap/build
cd colmap/build
cmake .. -GNinja -DCMAKE_CUDA_ARCHITECTURES=$CMAKE_CUDA_ARCHITECTURES
ninja
sudo ninja install

# Clean up
cd
rm -rf "$TEMP_DIR" 
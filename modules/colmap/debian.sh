#!/bin/bash
set -eu

echo "Installing COLMAP for Debian/Ubuntu..."

sudo apt-get install -y colmap

exit 0

# Set CUDA compiler path
if [ -z "${CUDACXX:-}" ]; then
  if command -v nvcc &> /dev/null; then
    export CUDACXX="nvcc"
  else
    export CUDACXX="/usr/local/cuda/bin/nvcc"
  fi
fi

# Check if CUDA is installed
if [ -z "$CUDACXX" ]; then
  log_error "CUDA Toolkit is not installed or CUDACXX is not set."
  exit 1
fi

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

# Clean up temp directory on exit
trap "rm -rf '$TEMP_DIR'" EXIT

git clone https://github.com/colmap/colmap.git

# Build and install
mkdir -p colmap/build
cd colmap/build
cmake .. -GNinja -DCMAKE_CUDA_ARCHITECTURES=$CMAKE_CUDA_ARCHITECTURES
ninja -j$(nproc)
sudo ninja install
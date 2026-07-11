#!/bin/bash

set -euxo pipefail

# libxc {version} module - DFT exchange-correlation functionals library

# Install build dependencies
# build-essential, gfortran         provides gfortran, gcc, g++, make
# autoconf automake libtool         provides full Autotools toolchain
apt-get update && apt-get install -y -q \
    wget \
    build-essential gfortran \
    cmake
    #    autoconf automake libtool \ 

# Set installation prefix
LIBXC_PREFIX=${INSTALL_DIR}/libxc-${LIBXC_VERSION}

# Download and extract
cd /tmp
wget https://gitlab.com/libxc/libxc/-/archive/${LIBXC_VERSION}/libxc-${LIBXC_VERSION}.tar.gz
tar xf libxc-${LIBXC_VERSION}.tar.gz
cd libxc-${LIBXC_VERSION}


cmake -S . -B build \
  -DCMAKE_INSTALL_PREFIX="${LIBXC_PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DENABLE_FORTRAN=ON \
  -DENABLE_PYTHON=ON
cmake --build build -j "${BUILD_THREADS}"
ctest --parallel "${BUILD_THREADS}" --test-dir build     # replaces 'make check'; drop if too slow
cmake --install build                                    # root: writes to /opt


# Configure with optimizations
# autoreconf -i
# ./configure --prefix=${LIBXC_PREFIX} \
#     --enable-shared \
#     --disable-static \
#     --enable-fortran

# # Build and install
# make -j ${BUILD_THREADS}
# make check
# make install

# Create symlink for easy reference
ln -sfn "${LIBXC_PREFIX}" "${INSTALL_DIR}/libxc"

# Cleanup
#cd /tmp
#rm -rf libxc-${LIBXC_VERSION}*

echo "libxc {version} installed successfully"


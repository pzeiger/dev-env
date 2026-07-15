#!/bin/bash

set -euxo pipefail

# libMBD — many-body dispersion library (https://github.com/libmbd/libmbd).
# This is the compiled Fortran backend for the `pymbd` Python package: without
# it, `pip install pymbd` either fails or falls back to a pure-Python path
# (no pymbd.fortran). Built from the release source with CMake against the
# system OpenBLAS/LAPACK.

apt-get update && apt-get install -y -q \
    wget \
    build-essential gfortran \
    cmake

# Versioned install prefix, with a stable symlink like the other libs.
LIBMBD_PREFIX_DIR=${INSTALL_DIR}/libmbd-${LIBMBD_VERSION}

cd /tmp
rm -rf libmbd-${LIBMBD_VERSION}
wget -q https://github.com/libmbd/libmbd/releases/download/${LIBMBD_VERSION}/libmbd-${LIBMBD_VERSION}.tar.gz
tar xzf libmbd-${LIBMBD_VERSION}.tar.gz
cd libmbd-${LIBMBD_VERSION}

# Serial build (ScaLAPACK/MPI off — pymbd here is used single-process per rank).
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${LIBMBD_PREFIX_DIR} \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SCALAPACK_MPI=OFF
cmake --build build -j "${BUILD_THREADS}"
cmake --install build

ln -sfn ${LIBMBD_PREFIX_DIR} ${INSTALL_DIR}/libmbd

# Cleanup
cd /
rm -rf /tmp/libmbd-${LIBMBD_VERSION}*

echo "✓ libmbd ${LIBMBD_VERSION} installed to ${LIBMBD_PREFIX_DIR}"

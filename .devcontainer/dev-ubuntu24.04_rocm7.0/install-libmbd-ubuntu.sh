#!/bin/bash

set -euxo pipefail

# libMBD — many-body dispersion library (https://github.com/libmbd/libmbd).
# This is the compiled Fortran backend for the `pymbd` Python package: without
# it, `pip install pymbd` either fails or falls back to a pure-Python path
# (no pymbd.fortran). Built with CMake against the system OpenBLAS/LAPACK.

apt-get update && apt-get install -y -q \
    git \
    wget \
    build-essential gfortran \
    cmake

# ---------------------------------------------------------------------------
# git build (current): track upstream master, paired with the git install of
# pymbd in requirements.txt, until a numpy-2-compatible pymbd release lands on
# PyPI. LIBMBD_GIT_REF optionally pins a commit/tag (empty = default branch).
# ---------------------------------------------------------------------------
LIBMBD_PREFIX_DIR=${INSTALL_DIR}/libmbd-git

cd /tmp
rm -rf libmbd-git
git clone https://github.com/libmbd/libmbd.git libmbd-git
cd libmbd-git
if [ -n "${LIBMBD_GIT_REF:-}" ]; then
    git checkout "${LIBMBD_GIT_REF}"
fi

# ---------------------------------------------------------------------------
# versioned release build (kept for the future): to switch back from git to a
# PyPI release, comment out the git block above, uncomment this block, and
# restore `ENV LIBMBD_VERSION=...` in the Dockerfile.
# ---------------------------------------------------------------------------
# LIBMBD_PREFIX_DIR=${INSTALL_DIR}/libmbd-${LIBMBD_VERSION}
#
# cd /tmp
# rm -rf libmbd-${LIBMBD_VERSION}
# wget -q https://github.com/libmbd/libmbd/releases/download/${LIBMBD_VERSION}/libmbd-${LIBMBD_VERSION}.tar.gz
# tar xzf libmbd-${LIBMBD_VERSION}.tar.gz
# cd libmbd-${LIBMBD_VERSION}

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
rm -rf /tmp/libmbd-*

echo "✓ libmbd installed to ${LIBMBD_PREFIX_DIR}"

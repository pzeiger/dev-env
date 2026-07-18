#!/bin/bash

set -euxo pipefail

# libMBD — many-body dispersion library (https://github.com/libmbd/libmbd).
# This is the compiled Fortran backend for the `pymbd` Python package: without
# it, `pip install pymbd` either fails or falls back to a pure-Python path
# (no pymbd.fortran). Built with CMake against the system OpenBLAS/LAPACK.

apt-get update && apt-get install -y -q \
    wget \
    build-essential gfortran \
    cmake

# ---------------------------------------------------------------------------
# versioned release build (current): official release tarball from GitHub,
# paired with `pip install pymbd==${LIBMBD_VERSION}` from PyPI. The release
# ships cmake/libMBDVersionTag.cmake, so CMake stamps the version without a .git
# checkout, and both libMBD and pymbd report the same clean release version
# (for a release, pymbd.fortran's assertion only checks major.minor).
# ---------------------------------------------------------------------------
LIBMBD_PREFIX_DIR=${INSTALL_DIR}/libmbd-${LIBMBD_VERSION}

cd /tmp
rm -rf libmbd-${LIBMBD_VERSION}
wget -q https://github.com/libmbd/libmbd/releases/download/${LIBMBD_VERSION}/libmbd-${LIBMBD_VERSION}.tar.gz
tar xzf libmbd-${LIBMBD_VERSION}.tar.gz
cd libmbd-${LIBMBD_VERSION}

# ---------------------------------------------------------------------------
# git build (kept for the future): to track upstream master instead of a
# release, comment out the release block above, uncomment this block, add `git`
# to the apt-get above, drop `ENV LIBMBD_VERSION` in the Dockerfile, and install
# pymbd from the same clone (not PyPI) so the versions match. LIBMBD_GIT_REF
# optionally pins a commit/tag (empty = default branch).
# ---------------------------------------------------------------------------
# LIBMBD_PREFIX_DIR=${INSTALL_DIR}/libmbd-git
# cd /tmp
# rm -rf libmbd-git
# git clone https://github.com/libmbd/libmbd.git libmbd-git
# cd libmbd-git
# if [ -n "${LIBMBD_GIT_REF:-}" ]; then git checkout "${LIBMBD_GIT_REF}"; fi

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

echo "✓ libmbd ${LIBMBD_VERSION} installed to ${LIBMBD_PREFIX_DIR}"

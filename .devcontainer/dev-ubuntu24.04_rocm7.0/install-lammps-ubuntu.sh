#!/usr/bin/env bash
# LAMMPS (stable) — CPU-only build for the dev box. gfx1151 (RDNA3.5) has no
# supported LAMMPS GPU backend (KOKKOS-HIP / GPU-package-HIP target CDNA), so
# this build uses KOKKOS with the OpenMP (CPU) backend and omits the GPU
# package. 24 packages; matches the live /workspaces/run build. GPU-accelerated
# LAMMPS lives in the CUDA container images (eelsfornax/idrobolab).
#
# Built against the container's OpenMPI + FFTW + HDF5 (apt) + auto-downloaded
# kim-api. ML-QUIP downloads and builds the libAtoms/QUIP library (Fortran +
# GAP, single-threaded — the slow part of this build; needs gfortran, present
# for the ELPA build). ML-IAP is built WITHOUT its optional Python coupling
# (that needs cython at configure time); the ML-IAP core still works. To enable
# the coupling, `uv pip install cython` before cmake and add -D MLIAP_ENABLE_PYTHON=on.
set -euo pipefail

# This script runs as root in the Dockerfile, but PKG_PYTHON/ML-IAP make cmake
# run the ubuntu-owned venv's python (find_package(Python ... NumPy) imports
# numpy). Writing .pyc would create root-owned __pycache__ dirs inside the venv,
# which later breaks `uv` (postCreateCommand, as ubuntu) with EACCES. Disable
# bytecode writes so the venv is never touched.
export PYTHONDONTWRITEBYTECODE=1

LAMMPS_BRANCH="${LAMMPS_BRANCH:-stable}"
INSTALL_DIR="${INSTALL_DIR:-/opt/software}"
SRC=/tmp/lammps-src

rm -rf "$SRC"
git clone --depth 1 -b "$LAMMPS_BRANCH" https://github.com/lammps/lammps.git "$SRC"
cd "$SRC"

cmake -S cmake -B build \
    -C cmake/presets/kokkos-openmp.cmake \
    -D CMAKE_INSTALL_PREFIX="${INSTALL_DIR}/lammps" \
    -D CMAKE_BUILD_TYPE=Release \
    -D BUILD_MPI=on -D BUILD_OMP=on -D BUILD_SHARED_LIBS=on -D LAMMPS_EXCEPTIONS=on \
    -D FFT=FFTW3 -D FFT_KOKKOS=FFTW3 \
    -D PKG_EXTRA-PAIR=on -D PKG_H5MD=on -D PKG_TALLY=on -D PKG_EXTRA-FIX=on \
    -D PKG_MISC=on -D PKG_SMTBQ=on -D PKG_REAXFF=on -D PKG_KIM=on -D DOWNLOAD_KIM=on \
    -D PKG_KSPACE=on -D PKG_MANYBODY=on -D PKG_ML-SNAP=on -D PKG_ML-IAP=on \
    -D PKG_ML-QUIP=on -D DOWNLOAD_QUIP=on -D PKG_MOLECULE=on \
    -D PKG_PYTHON=on -D PKG_INTERLAYER=on -D PKG_OPENMP=on -D PKG_QTB=on \
    -D PKG_OPT=on -D PKG_COMPRESS=on -D PKG_PLUGIN=on -D PKG_PHONON=on -D PKG_MEAM=on

cmake --build build -j"$(nproc)"
cmake --install build

# cmake --install does NOT copy DOWNLOAD_KIM's libkim-api into the prefix.
cp -a build/kim_build-prefix/lib/libkim-api.so* "${INSTALL_DIR}/lammps/lib/" 2>/dev/null || true

# LAMMPS python module (pure-python ctypes wrapper; dlopens liblammps.so via
# LD_LIBRARY_PATH). Installed under the prefix and exposed via PYTHONPATH (ENV
# in the Dockerfile) so it does not touch the ubuntu-owned venv.
mkdir -p "${INSTALL_DIR}/lammps/python"
cp -a python/lammps "${INSTALL_DIR}/lammps/python/lammps"

cd /
rm -rf "$SRC"

#!/usr/bin/env bash
# Quantum ESPRESSO (qe-7.6) — CPU build for the dev box, against the system
# gfortran + OpenMPI + FFTW3 + ScaLAPACK + OpenBLAS stack (the same libraries
# GPAW uses). CPU-only by design: QE's GPU backends are nvfortran (openacc/cuda)
# or OpenMP-offload / ROCm, none of which are viable on the gfx1151 (RDNA3.5)
# dev box. The CUDA container images (eelsfornax/idrobolab) build QE with GPU
# support via the NVIDIA HPC SDK. Recipe validated live under /workspaces/run
# (configures, compiles, `pw.x` runs: "Program PWSCF v.7.6").
set -euo pipefail

QE_VERSION="${QE_VERSION:-qe-7.6}"
INSTALL_DIR="${INSTALL_DIR:-/opt/software}"
SRC=/tmp/qe-src

rm -rf "$SRC"
git clone --depth 1 -b "$QE_VERSION" https://gitlab.com/QEF/q-e.git "$SRC"
cd "$SRC"

# System ScaLAPACK is the OpenMPI build (libscalapack-openmpi); point QE at it
# explicitly since its FindSCALAPACK does not guess that Debian name.
cmake -S . -B build \
    -D CMAKE_INSTALL_PREFIX="${INSTALL_DIR}/qe" \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_Fortran_COMPILER=mpif90 -D CMAKE_C_COMPILER=mpicc \
    -D QE_ENABLE_MPI=ON -D QE_ENABLE_OPENMP=ON \
    -D QE_ENABLE_SCALAPACK=ON \
    -D QE_FFTW_VENDOR=FFTW3 -D BLA_VENDOR=OpenBLAS \
    -D SCALAPACK_LIBRARIES=/usr/lib/x86_64-linux-gnu/libscalapack-openmpi.so

cmake --build build -j"$(nproc)"
cmake --install build

cd /
rm -rf "$SRC"

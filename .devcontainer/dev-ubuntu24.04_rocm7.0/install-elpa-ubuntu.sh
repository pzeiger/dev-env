#!/usr/bin/env bash
# ELPA (Eigenvalue SoLvers for Petaflop Applications) — a scalable dense
# eigensolver GPAW can use (elpa=True) as a better-scaling alternative to the
# ScaLAPACK diagonalisation. CPU build (AVX2 + OpenMP) against the container's
# OpenMPI + OpenBLAS + ScaLAPACK (apt: libscalapack-openmpi). Headers install
# under ${INSTALL_DIR}/elpa/include/elpa-${ELPA_VERSION}/ (the siteconfig globs
# for that versioned subdir).
set -euo pipefail

ELPA_VERSION="${ELPA_VERSION:-2024.05.001}"
INSTALL_DIR="${INSTALL_DIR:-/opt/software}"

# ELPA's configure may launch a small MPI probe; OpenMPI refuses to run as root
# without these (harmless under MPICH / non-root).
export OMPI_ALLOW_RUN_AS_ROOT=1 OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

cd /tmp
wget -q "https://elpa.mpcdf.mpg.de/software/tarball-archive/Releases/${ELPA_VERSION}/elpa-${ELPA_VERSION}.tar.gz"
tar xzf "elpa-${ELPA_VERSION}.tar.gz"
cd "elpa-${ELPA_VERSION}"
mkdir build && cd build
../configure \
    CC=mpicc FC=mpifort \
    CFLAGS="-O3 -march=x86-64-v3 -ftree-vectorize -funsafe-math-optimizations -fno-math-errno" \
    FCFLAGS="-O3 -march=x86-64-v3 -ftree-vectorize -funsafe-math-optimizations -fno-math-errno" \
    SCALAPACK_LDFLAGS="-lscalapack-openmpi -lopenblas" \
    SCALAPACK_FCFLAGS="" \
    --prefix="${INSTALL_DIR}/elpa-${ELPA_VERSION}" \
    --enable-openmp --disable-avx512
make -j "$(nproc)"
make install
ln -sfn "${INSTALL_DIR}/elpa-${ELPA_VERSION}" "${INSTALL_DIR}/elpa"
cd /tmp && rm -rf "elpa-${ELPA_VERSION}"*

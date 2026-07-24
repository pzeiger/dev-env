#!/usr/bin/env bash
# MAGMA (GPU dense linear algebra) for GPAW's GPU eigensolver (magma=True).
# hipMAGMA build for the AMD GPU.
#
# IMPORTANT: MAGMA's HIP backend officially targets CDNA (gfx90a/gfx908/gfx942).
# The dev box is a Strix Halo iGPU (RDNA 3.5, gfx1151), which MAGMA does NOT
# support, so this build is BEST-EFFORT and NON-FATAL: on failure the image
# build continues and GPAW is compiled WITHOUT MAGMA (the siteconfig only
# enables magma when /opt/software/magma exists — the GPU eigensolver then
# falls back to GPAW's built-in path). Kept for parity with the CUDA HPC
# containers and for bare-metal testing on supported AMD hardware.
set -uo pipefail   # intentionally NOT -e: a failed hipMAGMA build must not
                   # break the devcontainer image build.

MAGMA_VERSION="${MAGMA_VERSION:-2.7.2}"
INSTALL_DIR="${INSTALL_DIR:-/opt/software}"
ROCM_PATH="${ROCM_HOME:-/opt/rocm}"
GPU_ARCH="${GPAW_GPU_ARCH:-gfx1151}"

build_magma() {
    set -e
    cd /tmp
    wget -q "https://icl.utk.edu/projectsfiles/magma/downloads/magma-${MAGMA_VERSION}.tar.gz"
    tar xzf "magma-${MAGMA_VERSION}.tar.gz"
    cmake -S "magma-${MAGMA_VERSION}" -B /tmp/magma-build \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}/magma" \
        -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON \
        -DMAGMA_ENABLE_HIP=ON -DGPU_TARGET="${GPU_ARCH}" \
        -DCMAKE_HIP_COMPILER="${ROCM_PATH}/llvm/bin/clang++" \
        -DCMAKE_PREFIX_PATH="${ROCM_PATH}" \
        -DBLAS_LIBRARIES=/usr/lib/x86_64-linux-gnu/libopenblas.so \
        -DLAPACK_LIBRARIES=/usr/lib/x86_64-linux-gnu/libopenblas.so
    cmake --build /tmp/magma-build -j "$(nproc)"
    cmake --install /tmp/magma-build
}

if build_magma; then
    echo "hipMAGMA ${MAGMA_VERSION} installed for ${GPU_ARCH}."
else
    echo "WARNING: hipMAGMA build failed for ${GPU_ARCH} (RDNA/gfx1151 is not a"
    echo "         supported MAGMA arch). GPAW will build WITHOUT MAGMA."
    rm -rf "${INSTALL_DIR}/magma"   # avoid a half-installed tree
fi
cd /tmp && rm -rf /tmp/magma-build "magma-${MAGMA_VERSION}"* || true

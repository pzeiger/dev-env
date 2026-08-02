set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Install the whole Python stack in ONE resolution pass -------------------
# A single `uv pip install -r` solves over the union of all constraints, so an
# incompatibility (e.g. numpy<2 vs numpy>=2) fails loudly here instead of being
# silently decided by whichever install ran last. See requirements.txt.
#
# Build-time env vars (must be on the command line, not in the requirements file):
#   GPAW_BUILD_GPU=1              build gpaw with GPU (HIP/ROCm) support. The
#                     arch is set in siteconfig.py (GPAW_GPU_ARCH, default
#                     gfx1151); the runtime must report that same arch (i.e. the
#                     Dockerfile must NOT set HSA_OVERRIDE_GFX_VERSION) or GPU
#                     kernel launches segfault on the mismatch. GPU use stays
#                     opt-in at runtime (GPAW_USE_GPUS / parallel={'gpu': True});
#                     a GPU build still runs CPU/MPI workflows unchanged.
#   LIBMBD_PREFIX=${LIBMBD_HOME}  link pymbd (pymbd==0.14.1 from PyPI, in
#                     requirements.txt) against the libMBD 0.14.1 release
#                     compiled into the image (Dockerfile /
#                     install-libmbd-ubuntu.sh) so it gets the fast Fortran
#                     backend. Both are the 0.14.1 release, so their versions
#                     satisfy pymbd.fortran's assertion. NOTE: an empty
#                     LIBMBD_PREFIX makes pymbd skip the Fortran extension
#                     entirely (silent pure-Python fallback).
# GPAW_CONFIG is exported by postCreateCommand.
GPAW_BUILD_GPU=1 LIBMBD_PREFIX="${LIBMBD_HOME:?set by the Dockerfile}" \
    uv pip install --no-cache -r "$HERE/requirements.txt"

mkdir -p /home/ubuntu/.local/bin
cat > /home/ubuntu/.local/bin/gpaw << 'EOF'
#!/usr/bin/env python
from gpaw.cli.main import main
main()
EOF
chmod +x /home/ubuntu/.local/bin/gpaw

# --- Jupyter kernel: EELSfornax / JAX on the gfx1151 iGPU (presented as gfx1100)
# JAX-ROCm ships no linear-algebra kernels (LU / solve / eigh / transpose) for
# native gfx1151, so jnp.linalg.* fails (hipGetFuncBySymbol -> hipErrorInvalid-
# DeviceFunction, then segfault); those kernels DO exist for gfx1100. FFT /
# elementwise / matmul work natively. This kernel scopes
# HSA_OVERRIDE_GFX_VERSION=11.0.0 to JAX work ONLY -- it must NOT be global (see
# the GPAW note above: GPAW's GPU build is compiled for native gfx1151 and
# segfaults under the override). Use the default python3 kernel for GPAW; use
# this one for EELSfornax / JAX. Revisit on ROCm / jax-rocm upgrades: once
# native gfx1151 linalg kernels ship, drop this kernel and the override.
KDIR=/home/ubuntu/.local/share/jupyter/kernels/eelsfornax-gfx1100
mkdir -p "$KDIR"
PYBIN="$(command -v python)"
cat > "$KDIR/kernel.json" << EOF
{
  "argv": ["${PYBIN}", "-m", "ipykernel_launcher", "-f", "{connection_file}"],
  "display_name": "Python (EELSfornax · gfx1100)",
  "language": "python",
  "env": { "HSA_OVERRIDE_GFX_VERSION": "11.0.0" }
}
EOF

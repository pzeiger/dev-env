set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Build libMBD from the local repo (bind-mounted, runtime-only) -----------
# libMBD is the compiled Fortran backend for pymbd. It is built here rather than
# in the Dockerfile because /workspaces/code/libmbd is a bind mount that only
# exists at runtime (postCreateCommand). Building libMBD AND pymbd from the SAME
# working tree is deliberate: pymbd.fortran hard-asserts that libMBD's version
# matches pymbd's exactly (down to the git commit and `.dirty` flag). Both read
# their version from this tree's `git describe`, so they always agree — and the
# repo's .gitignore covers the editable-install artifacts, so the tree stays
# clean. pymbd itself is installed (editable) from the same path via
# requirements.txt.
LIBMBD_SRC=/workspaces/code/libmbd
LIBMBD_PREFIX=/home/ubuntu/.local/libmbd
LIBMBD_BUILD=/tmp/libmbd-build

if [ ! -e "$LIBMBD_SRC/CMakeLists.txt" ]; then
    echo "ERROR: $LIBMBD_SRC not mounted (no CMakeLists.txt). Check the bind" \
         "mount in devcontainer.json and that ../code/libmbd exists on the host." >&2
    exit 1
fi

# Serial build (ScaLAPACK/MPI off — pymbd here is single-process per rank). The
# cffi extension rpaths ${LIBMBD_PREFIX}/lib, so no LD_LIBRARY_PATH is needed.
rm -rf "$LIBMBD_BUILD"
cmake -S "$LIBMBD_SRC" -B "$LIBMBD_BUILD" \
    -DCMAKE_INSTALL_PREFIX="$LIBMBD_PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SCALAPACK_MPI=OFF
cmake --build "$LIBMBD_BUILD" -j "$(nproc)"
cmake --install "$LIBMBD_BUILD"
rm -rf "$LIBMBD_BUILD"

# --- Install the whole Python stack in ONE resolution pass -------------------
# A single `uv pip install -r` solves over the union of all constraints, so an
# incompatibility (e.g. numpy<2 vs numpy>=2) fails loudly here instead of being
# silently decided by whichever install ran last. See requirements.txt.
#
# Build-time env vars (must be on the command line, not in the requirements file):
#   GPAW_BUILD_GPU=0             build gpaw for CPU
#   LIBMBD_PREFIX=${LIBMBD_PREFIX}  link the editable pymbd (-e $LIBMBD_SRC in
#                     requirements.txt) against the libMBD just built above, so
#                     it gets the fast Fortran backend. NOTE: an empty
#                     LIBMBD_PREFIX makes pymbd skip the Fortran extension
#                     entirely (pure-Python fallback) — it must be a real path.
# GPAW_CONFIG is exported by postCreateCommand.
GPAW_BUILD_GPU=0 LIBMBD_PREFIX="$LIBMBD_PREFIX" uv pip install --no-cache \
    -r "$HERE/requirements.txt"

mkdir -p /home/ubuntu/.local/bin
cat > /home/ubuntu/.local/bin/gpaw << 'EOF'
#!/usr/bin/env python
from gpaw.cli.main import main
main()
EOF
chmod +x /home/ubuntu/.local/bin/gpaw

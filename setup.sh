set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Build libMBD + pymbd from the official upstream repo --------------------
# libMBD is the compiled Fortran backend for pymbd. We clone the official repo
# ONCE and build BOTH libMBD (below) and pymbd (editable, via requirements.txt)
# from that same clone. This is deliberate: pymbd.fortran hard-asserts that the
# compiled libMBD's version matches pymbd's exactly (git commit, and the .dirty
# flag). A fresh clone is clean and carries upstream's tags, so both `git
# describe` to the same version and the assertion holds; the repo's .gitignore
# covers the editable-install artifacts, so the tree stays clean.
#   Do NOT instead `pip install "pymbd @ git+<url>"`: uv builds that in its own
#   clone which ends up .dirty, mismatching a separately-built clean libMBD.
LIBMBD_GIT=${LIBMBD_GIT:-https://github.com/libmbd/libmbd.git}
LIBMBD_SRC=/home/ubuntu/.local/src/libmbd
LIBMBD_PREFIX=/home/ubuntu/.local/libmbd
LIBMBD_BUILD=/tmp/libmbd-build

# Fresh clone of the latest upstream (set LIBMBD_GIT to a fork/ref to override).
rm -rf "$LIBMBD_SRC"
git clone "$LIBMBD_GIT" "$LIBMBD_SRC"

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

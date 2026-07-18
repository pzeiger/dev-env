set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Install the whole Python stack in ONE resolution pass -------------------
# A single `uv pip install -r` solves over the union of all constraints, so an
# incompatibility (e.g. numpy<2 vs numpy>=2) fails loudly here instead of being
# silently decided by whichever install ran last. See requirements.txt.
#
# Build-time env vars (must be on the command line, not in the requirements file):
#   GPAW_BUILD_GPU=0              build gpaw for CPU
#   LIBMBD_PREFIX=${LIBMBD_HOME}  link pymbd (pymbd==0.14.1 from PyPI, in
#                     requirements.txt) against the libMBD 0.14.1 release
#                     compiled into the image (Dockerfile /
#                     install-libmbd-ubuntu.sh) so it gets the fast Fortran
#                     backend. Both are the 0.14.1 release, so their versions
#                     satisfy pymbd.fortran's assertion. NOTE: an empty
#                     LIBMBD_PREFIX makes pymbd skip the Fortran extension
#                     entirely (silent pure-Python fallback).
# GPAW_CONFIG is exported by postCreateCommand.
GPAW_BUILD_GPU=0 LIBMBD_PREFIX="${LIBMBD_HOME:?set by the Dockerfile}" \
    uv pip install --no-cache -r "$HERE/requirements.txt"

mkdir -p /home/ubuntu/.local/bin
cat > /home/ubuntu/.local/bin/gpaw << 'EOF'
#!/usr/bin/env python
from gpaw.cli.main import main
main()
EOF
chmod +x /home/ubuntu/.local/bin/gpaw

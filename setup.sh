# Install useful libraries
pip install "jax[rocm7-local]"
pip install sympy

# Install our repos
pip install --no-cache-dir -e /workspaces/code/abTEM
GPAW_BUILD_GPU=0 pip install --no-cache-dir -e /workspaces/code/gpaw
pip install --no-cache-dir -e /workspaces/code/gpaw-weaver
pip install --no-cache-dir -e /workspaces/code/EELSfornax[all]

mkdir -p /home/ubuntu/.local/bin
cat > /home/ubuntu/.local/bin/gpaw << 'EOF'
#!/usr/bin/env python
from gpaw.cli.main import main
main()
EOF
chmod +x /home/ubuntu/.local/bin/gpaw

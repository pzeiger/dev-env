# Install useful libraries
uv pip install --no-cache "jax[rocm7-local]"
uv pip install --no-cache ase h5py jupyterlab matplotlib notebook pypdf xarray
uv pip install --no-cache sympy spglib phonopy
#uv pip install --no-cache dftd3 tad-dftd3

# Install our repos
uv pip install --no-cache -e /workspaces/code/abTEM
GPAW_BUILD_GPU=0 uv pip install --no-cache -e /workspaces/code/gpaw
uv pip install --no-cache -e /workspaces/code/gpaw-weaver
uv pip install --no-cache -e /workspaces/code/EELSfornax[all]
uv pip install --no-cache -e /workspaces/code/PySlice[md]

mkdir -p /home/ubuntu/.local/bin
cat > /home/ubuntu/.local/bin/gpaw << 'EOF'
#!/usr/bin/env python
from gpaw.cli.main import main
main()
EOF
chmod +x /home/ubuntu/.local/bin/gpaw

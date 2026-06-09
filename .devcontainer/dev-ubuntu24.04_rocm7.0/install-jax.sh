#!/bin/bash

set -euxo pipefail

# libxc {version} module - DFT exchange-correlation functionals library

echo "$PATH"

#pip install jax==${JAX_VERSION}
#pip install jax-rocm7-pjrt==${JAX_VERSION}
#pip install jax-rocm7-plugin==${JAX_VERSION}
#pip install https://github.com/ROCm/rocm-jax/releases/download/rocm-jax-v${JAX_VERSION}/jaxlib-${JAX_VERSION}+rocm7-cp312-cp312-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl

pip install --upgrade "jax[rocm7-local]"

pip freeze | grep jax

python -c "import jax; print(jax.devices())"
python -c "import jax.numpy as jnp; x = jnp.arange(5); print(x)"


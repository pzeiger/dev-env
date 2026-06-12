#!/usr/bin/env bash

set -euxo pipefail

if [[ "${ROCM_VERSION}" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
  ROCM_VERSION_TMP="${ROCM_VERSION}.0"
else
  ROCM_VERSION_TMP="${ROCM_VERSION}"
fi

pip install fastrlock numpy
pip install amd-cupy --extra-index-url "https://pypi.amd.com/rocm-${ROCM_VERSION_TMP}/simple"

# Use ROCm build container on Ubuntu 24.04 as base
ARG ROCM_VERSION="7.2"
FROM rocm/dev-ubuntu-24.04:${ROCM_VERSION}-complete 
ARG ROCM_VERSION
ENV ROCM_VERSION="${ROCM_VERSION}"
ENV INSTALL_DIR=/opt/software
ENV BUILD_THREADS=16
ENV ROCM_HOME="/opt/rocm"

RUN echo "Starting build of dev container with ROCm ${ROCM_VERSION}"

# Ensure system packages are up to date and install global dependencies
RUN << 'EOF'
apt-get update
apt-get -y full-upgrade
apt-get install -y git \
    libfftw3-dev \
    libfftw3-mpi-dev \
    libopenblas-dev \
    libopenblas64-dev \
    openmpi-bin \
    libopenmpi-dev \
    libscalapack-openmpi-dev \
    libdw1

# install Claude CLI
apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && npm install -g @anthropic-ai/claude-code \
    && rm -rf /var/lib/apt/lists/*

# install github CLI
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
        && sudo mkdir -p -m 755 /etc/apt/keyrings \
        && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
        && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
        && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && sudo apt update \
        && sudo apt install gh -y

EOF


# Set up Python virtual environment and upgrade pip and setuptools
# Copy uv into image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

USER ubuntu
WORKDIR /home/ubuntu

# Ensure the installed binary is on the `PATH`
ENV PATH="/home/ubuntu/.local/bin/:$PATH"

ENV VIRTUAL_ENV="/home/ubuntu/venv"
RUN uv venv $VIRTUAL_ENV --python 3.12
ENV PATH="${VIRTUAL_ENV}/bin:$PATH"

RUN << 'EOF'
mv "${VIRTUAL_ENV}/bin/pip" "${VIRTUAL_ENV}/bin/pip-native"

cat > ${VIRTUAL_ENV}/bin/pip << 'PIP_WRAPPER'
#!/usr/bin/env bash
# Wrapper: redirect pip calls to uv pip for this venv

VENV_DIR="${VIRTUAL_ENV}"
exec uv pip --no-managed-python --no-cache "$@"
PIP_WRAPPER

chmod +x ${VIRTUAL_ENV}/bin/pip
EOF

RUN ls -ahl "${VIRTUAL_ENV}/bin"

COPY --chown=ubuntu:ubuntu install-cupy.sh /tmp/
RUN chmod +x /tmp/install-cupy.sh && /tmp/install-cupy.sh

USER root

# Get Libxc installed
ENV LIBXC_VERSION=7.0.0
COPY install-libxc-ubuntu.sh /tmp/
#RUN ls -la /tmp/install-libxc* && file /tmp/install-libxc-ubuntu.sh && head -5 /tmp/install-libxc-ubuntu.sh && bash -n /tmp/install-libxc-ubuntu.sh
#RUN set -x && /tmp/install-libxc-ubuntu.sh || { echo "Failed with exit $$?"; exit 1; }
RUN chmod +x /tmp/install-libxc-ubuntu.sh && /tmp/install-libxc-ubuntu.sh

ENV LIBXC_HOME=${INSTALL_DIR}/libxc
ENV LIBXC_INCLUDE=${INSTALL_DIR}/libxc/include
ENV LIBXC_LIBS=${INSTALL_DIR}/libxc/lib
ENV LD_LIBRARY_PATH=${LIBXC_LIBS}:${LD_LIBRARY_PATH:-}

# Install Libvdwxc
ENV LIBVDWXC_VERSION=0.5.0
COPY install-libvdwxc-ubuntu.sh /tmp/
RUN chmod +x /tmp/install-libvdwxc-ubuntu.sh && /tmp/install-libvdwxc-ubuntu.sh

ENV LIBVDWXC_HOME=${INSTALL_DIR}/libvdwxc
ENV LIBVDWXC_INCLUDE=${LIBVDWXC_HOME}/include
ENV LIBVDWXC_LIBS=${LIBVDWXC_HOME}/lib
ENV LD_LIBRARY_PATH=${LIBVDWXC_LIBS}:${LD_LIBRARY_PATH:-}


# Clean APT cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN echo 'ubuntu:ubuntu' | chpasswd
USER ubuntu

# Install python packages
RUN pip install --no-cache-dir ase h5py jupyterlab matplotlib notebook pypdf xarray

# Install JAX with ROCm support
ENV JAX_VERSION=0.10.0
COPY --chown=ubuntu:ubuntu install-jax.sh /tmp/
RUN chmod +x /tmp/install-jax.sh && /tmp/install-jax.sh
ENV LLVM_PATH="/opt/rocm/llvm"

COPY --chown=ubuntu:ubuntu siteconfig.py /home/ubuntu/
RUN ls -ahl ./* && GPAW_BUILD_GPU=0 GPAW_CONFIG='/home/ubuntu/siteconfig.py' pip install --no-cache-dir gpaw && rm siteconfig.py

# This is a supposed fix to help with gfx1151
# See: https://github.com/pytorch/pytorch/issues/164346
ENV HSA_OVERRIDE_GFX_VERSION="11.0.0"


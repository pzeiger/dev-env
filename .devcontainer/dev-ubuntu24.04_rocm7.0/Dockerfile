# Use ROCm build container on Ubuntu 24.04 as base
ARG ROCM_VERSION="7.2"
FROM rocm/dev-ubuntu-24.04:${ROCM_VERSION}-complete 
ARG ROCM_VERSION
ENV ROCM_VERSION="${ROCM_VERSION}"
ENV INSTALL_DIR=/opt/software
ENV BUILD_THREADS=16
ENV ROCM_HOME="/opt/rocm"

RUN echo "Starting build of dev container with ROCm ${ROCM_VERSION}"

# Set empy password for ubuntu user
RUN echo 'ubuntu:ubuntu' | chpasswd

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
apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && npm install -g @anthropic-ai/claude-code

# install github CLI
(type -p wget >/dev/null || sudo apt install wget -y) \
        && sudo mkdir -p -m 755 /etc/apt/keyrings \
        && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
        && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
        && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && sudo apt update \
        && sudo apt install gh -y

apt-get autoremove -y
EOF

# Install Apptainer from the official PPA (non-setuid installation), so
# container images (e.g. for NCSA Delta) can be built inside this devcontainer.
# Unprivileged/--fakeroot builds need subuid/subgid mappings for the ubuntu
# user and user namespaces (the devcontainer already runs with
# seccomp=unconfined); `apptainer exec` of .sif images additionally needs
# /dev/fuse (see runArgs in devcontainer.json).
RUN << 'EOF'
set -e
apt-get update
apt-get install -y software-properties-common
add-apt-repository -y ppa:apptainer/ppa
apt-get update
apt-get install -y apptainer
grep -q '^ubuntu:' /etc/subuid || echo 'ubuntu:100000:65536' >> /etc/subuid
grep -q '^ubuntu:' /etc/subgid || echo 'ubuntu:100000:65536' >> /etc/subgid
rm -rf /var/lib/apt/lists/*
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

# RUN << 'EOF'
# mv "${VIRTUAL_ENV}/bin/pip" "${VIRTUAL_ENV}/bin/pip-native"

# cat > ${VIRTUAL_ENV}/bin/pip << 'PIP_WRAPPER'
# #!/usr/bin/env bash
# # Wrapper: redirect pip calls to uv pip for this venv

# VENV_DIR="${VIRTUAL_ENV}"
# exec uv pip --no-managed-python --no-cache "$@"
# PIP_WRAPPER

# chmod +x ${VIRTUAL_ENV}/bin/pip
# EOF

RUN ls -ahl "${VIRTUAL_ENV}/bin"

COPY --chown=ubuntu:ubuntu install-cupy.sh /tmp/
RUN chmod +x /tmp/install-cupy.sh && /tmp/install-cupy.sh

USER root

# Get Libxc installed
ENV LIBXC_VERSION=7.0.0
COPY install-libxc-ubuntu.sh /tmp/
RUN chmod +x /tmp/install-libxc-ubuntu.sh && /tmp/install-libxc-ubuntu.sh
RUN chown -R ubuntu:ubuntu /tmp/libxc-${LIBXC_VERSION}

# --- Python bindings: ubuntu, into the venv ---
USER ubuntu
RUN uv pip install --no-cache --upgrade setuptools wheel numpy # build dependencies
RUN uv pip install --no-cache --no-build-isolation /tmp/libxc-${LIBXC_VERSION}

# --- cleanup ---
USER root
RUN rm -rf /tmp/libxc-${LIBXC_VERSION}*

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

# Install libMBD (many-body dispersion; compiled Fortran backend for pymbd).
# setup.sh links pymbd against this via LIBMBD_PREFIX=${LIBMBD_HOME}.
ENV LIBMBD_VERSION=0.14.0
COPY install-libmbd-ubuntu.sh /tmp/
RUN chmod +x /tmp/install-libmbd-ubuntu.sh && /tmp/install-libmbd-ubuntu.sh

ENV LIBMBD_HOME=${INSTALL_DIR}/libmbd
ENV LIBMBD_INCLUDE=${LIBMBD_HOME}/include
ENV LIBMBD_LIBS=${LIBMBD_HOME}/lib
ENV LD_LIBRARY_PATH=${LIBMBD_LIBS}:${LD_LIBRARY_PATH:-}

# LaTeX toolchain from Ubuntu package sources (pdflatex + latexmk), for
# building the theory/proposal documents inside the devcontainer.
# Coverage of the packages used in /workspaces/run and /workspaces/projects:
#   texlive-latex-base         pdflatex, amsmath, geometry
#   texlive-latex-recommended  hyperref, booktabs, microtype, amssymb/bm
#   texlive-latex-extra        enumitem, titlesec
#   texlive-science            physics.sty
# --no-install-recommends keeps the large -doc trees out of the image.
RUN << 'EOF'
set -e
apt-get update
apt-get install -y --no-install-recommends \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-science \
    latexmk
EOF

# Clean APT cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

USER ubuntu

# Install python packages
RUN uv pip install --no-cache torch torchvision --index-url https://download.pytorch.org/whl/rocm${ROCM_VERSION}

# Install JAX with ROCm support
#ENV JAX_VERSION=0.10.0
#COPY --chown=ubuntu:ubuntu install-jax.sh /tmp/
#RUN chmod +x /tmp/install-jax.sh && /tmp/install-jax.sh
#ENV LLVM_PATH="/opt/rocm/llvm"

#COPY --chown=ubuntu:ubuntu siteconfig.py /home/ubuntu/
#RUN ls -ahl ./* && GPAW_BUILD_GPU=0 GPAW_CONFIG='/home/ubuntu/siteconfig.py' uv pip install --no-cache gpaw && rm siteconfig.py

# This is a supposed fix to help with gfx1151
# See: https://github.com/pytorch/pytorch/issues/164346
ENV HSA_OVERRIDE_GFX_VERSION="11.0.0"


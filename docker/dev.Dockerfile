FROM python:3.11-bookworm

# Build args for customization
ARG YOLOBOX_PATH=.
ARG NODE_VERSION=22.20.0
ARG INSTALL_NODE=true
ARG INSTALL_AGENT_CLI=true
ARG CODEX_VERSION=latest
ARG CLAUDE_CODE_VERSION=latest
ARG EXTRA_PIP_PACKAGES="pytest ipython"

# System packages for scientific Python and OpenCV headless
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      build-essential \
      cmake \
      pkg-config \
      git \
      gnupg \
      curl \
      ca-certificates \
      tzdata \
      # OpenCV runtime libs (no GUI)
      libglib2.0-0 \
      libsm6 \
      libxext6 \
      libxrender1 \
      # OpenMP runtime for BLAS
      libgomp1; \
    # Install pinned Node.js binary from nodejs.org (conditional)
    if [ "$INSTALL_NODE" = "true" ]; then \
      ARCH="$(dpkg --print-architecture)"; \
      case "$ARCH" in \
        amd64) NODE_ARCH="x64" ;; \
        arm64) NODE_ARCH="arm64" ;; \
        *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;; \
      esac; \
      cd /tmp; \
      curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"; \
      curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt"; \
      grep " node-v${NODE_VERSION}-linux-${NODE_ARCH}\.tar\.xz$" SHASUMS256.txt | sha256sum -c -; \
      tar -xJf "node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -C /usr/local --strip-components=1 --no-same-owner; \
      ln -sf /usr/local/bin/node /usr/local/bin/nodejs; \
      rm -f "node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" SHASUMS256.txt; \
    fi; \
    # GitHub CLI
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg; \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg; \
    printf "deb [arch=%s signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n" "$(dpkg --print-architecture)" \
      > /etc/apt/sources.list.d/github-cli.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends gh; \
    rm -rf /var/lib/apt/lists/*

# Python env defaults
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    OPENCV_OPENCL_RUNTIME=disabled \
    OMP_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    MKL_NUM_THREADS=1 \
    NUMEXPR_NUM_THREADS=1

WORKDIR /workspace

# Install project requirements if provided via build context
# Usage: docker build --build-arg REQUIREMENTS_FILE=requirements.txt ...
ARG REQUIREMENTS_FILE=""
ARG REQUIREMENTS_FALLBACK=${YOLOBOX_PATH}/docker/.norequirements
COPY ${REQUIREMENTS_FILE:-${REQUIREMENTS_FALLBACK}} /tmp/requirements.txt*
RUN set -eux; \
    if [ -f /tmp/requirements.txt ] && [ -s /tmp/requirements.txt ] && [ "$(head -c 1 /tmp/requirements.txt)" != "#" ]; then \
      pip install --no-cache-dir -r /tmp/requirements.txt; \
    fi; \
    if [ -n "${EXTRA_PIP_PACKAGES}" ]; then \
      pip install --no-cache-dir ${EXTRA_PIP_PACKAGES}; \
    fi; \
    rm -f /tmp/requirements.txt*

# Optionally install coding agent CLIs globally
RUN if [ "$INSTALL_AGENT_CLI" = "true" ] && [ "$INSTALL_NODE" = "true" ]; then \
      npm i -g @openai/codex@${CODEX_VERSION} @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}; \
    fi

# Auto-scale thread env vars to CPU count in interactive shells
COPY ${YOLOBOX_PATH}/docker/threads.sh /etc/profile.d/threads.sh
COPY ${YOLOBOX_PATH}/docker/devprofile.sh /etc/profile.d/devprofile.sh
RUN install -d -m 0755 /etc/bash.bashrc.d \
    && cp /etc/profile.d/threads.sh /etc/bash.bashrc.d/threads.sh \
    && cp /etc/profile.d/devprofile.sh /etc/bash.bashrc.d/devprofile.sh \
    && chmod 0644 /etc/profile.d/threads.sh /etc/bash.bashrc.d/threads.sh /etc/profile.d/devprofile.sh /etc/bash.bashrc.d/devprofile.sh

# Keep container running for interactive dev
CMD ["bash", "-lc", "sleep infinity"]

# AI Tools Base Image - Dockerfile
# Provides common shell tools, Python, Node.js, and development utilities
# for AI coding assistants (Goose, Hermes, Copilot, etc.)
# Build with: podman build -t ai-base:latest .

FROM ubuntu:24.04

# Build arguments
ARG LOCAL_USERNAME=developer

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install sudo first (needed before creating user)
RUN apt-get update && apt-get install -y sudo && rm -rf /var/lib/apt/lists/*

# Create a container user with a FIXED, constant identity.
#
# Portability model: the image always ships user `developer` with UID/GID 1000.
# At *runtime* you map your (possibly different) host UID/GID onto this user with:
#   podman run --userns=keep-id:uid=1000,gid=1000 ...
# This decouples the image from your host UID, so a single image works on every
# machine and bind-mounted files (workspace, ~/.gnupg, ~/.ssh) line up correctly.
# Overriding these to match a specific host UID is possible but makes the image
# machine-specific — prefer keep-id instead.
ARG LOCAL_UID=1000
ARG LOCAL_GID=1000
ARG LOCAL_USERNAME=${LOCAL_USERNAME:-developer}

# Ubuntu 24.04's official image ships a pre-existing "ubuntu" user/group at
# UID/GID 1000, which collides with our fixed developer:1000 identity. Rename
# it in place (rather than deleting it) so we keep its existing homedir/skel
# setup, then reconcile its UID/GID/name with our LOCAL_* build args.
RUN if getent passwd ubuntu >/dev/null; then \
        usermod -l ${LOCAL_USERNAME} -d /home/${LOCAL_USERNAME} -m ubuntu && \
        groupmod -n ${LOCAL_USERNAME} ubuntu && \
        usermod -u ${LOCAL_UID} ${LOCAL_USERNAME} && \
        groupmod -g ${LOCAL_GID} ${LOCAL_USERNAME}; \
    fi

RUN if ! getent passwd ${LOCAL_USERNAME} >/dev/null; then \
        groupadd -g ${LOCAL_GID} ${LOCAL_USERNAME} && \
        useradd -m -u ${LOCAL_UID} -g ${LOCAL_GID} -s /bin/bash ${LOCAL_USERNAME}; \
    fi && \
    usermod -aG sudo ${LOCAL_USERNAME} && \
    echo "${LOCAL_USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo 'Defaults env_keep += "http_proxy https_proxy ftp_proxy no_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY NO_PROXY"' >> /etc/sudoers

# Keep LLVM prerequisites and installation ahead of frequently changed tools
# so additions to the general-purpose package list reuse the LLVM build cache.
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    clang-format-18 \
    && rm -rf /var/lib/apt/lists/*

# Install the latest stable LLVM/Clang toolchain from apt.llvm.org (llvm.sh adds
# the repo and installs clang, lld, lldb, clangd). Then expose unversioned names
# (clang, clang-tidy, ...) via update-alternatives. clang-format stays pinned to
# Ubuntu's version 18 because CI requires it.
RUN curl -fsSL https://apt.llvm.org/llvm.sh -o /tmp/llvm.sh && \
    chmod +x /tmp/llvm.sh && \
    LLVM_VERSION="$(sed -n 's/^CURRENT_LLVM_STABLE=\([0-9][0-9]*\).*/\1/p' /tmp/llvm.sh)" && \
    test -n "${LLVM_VERSION}" && \
    /tmp/llvm.sh "${LLVM_VERSION}" && \
    apt-get install -y --no-install-recommends \
        clang-tidy-${LLVM_VERSION} \
        clang-tools-${LLVM_VERSION} && \
    for tool in clang clang++ clangd clang-tidy clang-apply-replacements \
                clang-scan-deps run-clang-tidy lld lldb lldb-server \
                llvm-config llvm-ar llvm-ranlib llvm-symbolizer; do \
        if [ -x "/usr/bin/${tool}-${LLVM_VERSION}" ]; then \
            update-alternatives --install "/usr/bin/${tool}" "${tool}" \
                "/usr/bin/${tool}-${LLVM_VERSION}" 100; \
        fi; \
    done && \
    update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-18 100 && \
    update-alternatives --install /usr/bin/git-clang-format git-clang-format /usr/bin/git-clang-format-18 100 && \
    rm -rf /tmp/llvm.sh /var/lib/apt/lists/* && \
    clang --version && clang-tidy --version && clang-format --version | grep -q 'version 18'

# Install essential tools that AI agents commonly use
RUN apt-get update && apt-get install -y \
    # Core utilities
    git \
    ssh \
    unzip \
    # Search and find tools (CRITICAL for AI agents)
    ripgrep \
    fd-find \
    # Text processing
    jq \
    vim \
    nano \
    poppler-utils \
    pandoc \
    # Build tools (often needed)
    build-essential \
    cmake \
    make \
    gcc \
    g++ \
    # Debugging and profiling (native Linux): gdb for live/core debugging,
    # valgrind (memcheck/massif) and heaptrack for heap analysis, strace and
    # ltrace for syscall/library call tracing
    gdb \
    valgrind \
    heaptrack \
    strace \
    ltrace \
    # Python (AI agents often need this)
    python3 \
    python3-pip \
    python3-venv \
    # Python network analysis packages
    python3-scapy \
    python3-dpkt \
    # Shell
    bash \
    fish \
    zsh \
    # X11/GUI libraries (for keyring support)
    libxcb1 \
    # Other useful tools
    htop \
    tree \
    less \
    man-db \
    # Network tools
    tshark \
    wireshark \
    tcpdump \
    nmap \
    # QNX console and AOSP diagnostics
    picocom \
    adb \
    policycoreutils-python-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm (provides npx)
# Using NodeSource repository for latest LTS version
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Configure npm security settings to protect against supply chain attacks
# Create global .npmrc that applies to all npm operations (build-time and runtime)
# min-release-age=7: Only allow packages published 7+ days ago (reduces "golden hour" attack window)
# audit=true: Enable security audits by default
RUN echo "min-release-age=7" > /etc/npmrc && \
    echo "audit=true" >> /etc/npmrc

# Run npm audit to check for known vulnerabilities in installed packages
RUN npm audit --audit-level=high || echo "Warning: npm audit found vulnerabilities"

# Install GitHub CLI
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Install JFrog CLI (jf) - single static binary, installed system-wide
RUN curl -fL https://install-cli.jfrog.io | sh && \
    chmod 755 /usr/local/bin/jf

# Optional: Install latest CMake from Kitware's official repository
# Uncomment the following lines to get the newest CMake version instead of Ubuntu's default
# RUN apt-get update && apt-get install -y software-properties-common lsb-release && \
#     wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | \
#     gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
#     echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" | \
#     tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
#     apt-get update && \
#     apt-get install -y cmake && \
#     rm -rf /var/lib/apt/lists/*

# Create symbolic links for fd (Ubuntu ships it as fdfind)
RUN ln -s $(which fdfind) /usr/local/bin/fd

# Install Python packages not available via apt (using venv approach)
ARG PYTHON_ICS_VERSION=1!26.3.9
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir \
    pyshark \
    python-can \
    "python-ics==${PYTHON_ICS_VERSION}" \
    cantools \
    pyyaml \
    jinja2 \
    pypdf \
    pdfplumber \
    pymupdf \
    pdfminer.six \
    yamllint \
    odfpy

# Authenticate to Ford JFrog using a build-only netrc secret.
ARG TAT_INDEX_URL=https://jfrog.ford.com/artifactory/api/pypi/test-pypi-prod-local/simple
RUN --mount=type=secret,id=netrc,target=/run/secrets/netrc \
    if [ -n "${TAT_INDEX_URL}" ]; then \
        NETRC=/run/secrets/netrc /opt/venv/bin/pip install --no-cache-dir --no-input \
            --index-url "${TAT_INDEX_URL}" \
            tat-cli "python-ics==${PYTHON_ICS_VERSION}" && \
        /opt/venv/bin/pip check && \
        /opt/venv/bin/tat --help; \
    else \
        echo "Skipping private tat-cli install (TAT_INDEX_URL is empty)"; \
    fi

# Add venv to PATH so packages are available system-wide
ENV PATH="/opt/venv/bin:$PATH"

# Install uv (Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv && \
    mv /root/.local/bin/uvx /usr/local/bin/uvx

# Create common directories
# .ssh/tmp is for ControlPath sockets (ssh ControlMaster/ControlPersist) -
# harmless if unused, but required to exist beforehand if something tries to use it
RUN mkdir -p \
    /home/${LOCAL_USERNAME}/.config \
    /home/${LOCAL_USERNAME}/.ssh/tmp \
    /run/host-services && \
    chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} /home/${LOCAL_USERNAME} && \
    chmod 700 /home/${LOCAL_USERNAME}/.ssh && \
    chmod 700 /home/${LOCAL_USERNAME}/.ssh/tmp

# Create standard user directories (XDG Base Directory Specification)
# These are common across all Linux applications and make mounting cleaner
RUN mkdir -p /home/${LOCAL_USERNAME}/.config && \
    mkdir -p /home/${LOCAL_USERNAME}/.local/bin && \
    mkdir -p /home/${LOCAL_USERNAME}/.local/share && \
    mkdir -p /home/${LOCAL_USERNAME}/.cache && \
    chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} /home/${LOCAL_USERNAME}/.config && \
    chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} /home/${LOCAL_USERNAME}/.local && \
    chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} /home/${LOCAL_USERNAME}/.cache

# Add ~/.local/bin to PATH for user-installed binaries
ENV PATH="/home/${LOCAL_USERNAME}/.local/bin:${PATH}"

# Switch to user
USER ${LOCAL_USERNAME}
WORKDIR /home/${LOCAL_USERNAME}

# Default command
CMD ["/bin/bash"]

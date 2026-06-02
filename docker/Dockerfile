# AI Tools Podman Image - Dockerfile
# Multi-purpose container for AI coding assistants: Goose, GitHub Copilot, etc.
# Build with: podman build -t ai-ubuntu:latest .
# Or use build.sh which includes the necessary flags

FROM ubuntu:24.04

# Build arguments
ARG LOCAL_USERNAME=developer

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install sudo first (needed before creating user)
RUN apt-get update && apt-get install -y sudo && rm -rf /var/lib/apt/lists/*

# Create user matching host (adjust UID/GID as needed)
ARG LOCAL_UID=1001
ARG LOCAL_GID=1001
ARG LOCAL_USERNAME=${LOCAL_USERNAME:-developer}

RUN groupadd -g ${LOCAL_GID} ${LOCAL_USERNAME} && \
    useradd -m -u ${LOCAL_UID} -g ${LOCAL_GID} -s /bin/bash ${LOCAL_USERNAME} && \
    usermod -aG sudo ${LOCAL_USERNAME} && \
    echo "${LOCAL_USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install essential tools that goose commonly uses
RUN apt-get update && apt-get install -y \
    # Core utilities
    curl \
    wget \
    git \
    ssh \
    ca-certificates \
    gnupg \
    unzip \
    # Search and find tools (CRITICAL for goose)
    ripgrep \
    fd-find \
    # Text processing
    jq \
    vim \
    nano \
    poppler-utils \
    # Build tools (often needed)
    build-essential \
    cmake \
    make \
    gcc \
    g++ \
    # Clang format (provides git-clang-format)
    clang-format-18 \
    # Python (goose often needs this)
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
    # X11/GUI libraries (for goose keyring support)
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
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm (provides npx)
# Using NodeSource repository for latest LTS version
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Configure npm security settings to protect against supply chain attacks (Shai-hulud)
# Create global .npmrc that applies to all npm operations (build-time and runtime)
# min-release-age=7: Only allow packages published 7+ days ago (reduces "golden hour" attack window)
# audit=true: Enable security audits by default
RUN echo "min-release-age=7" > /etc/npmrc && \
    echo "audit=true" >> /etc/npmrc

# Install mcp-atlassian globally for goose extension (avoids npx download delay on startup)
RUN npm install -g mcp-atlassian@2.0.0

# Install GitHub Copilot CLI globally
RUN npm install -g @github/copilot

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

# Set up alternatives for clang-format to use version 18 as default
RUN update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-18 100 && \
    update-alternatives --install /usr/bin/git-clang-format git-clang-format /usr/bin/git-clang-format-18 100

# Install Homebrew (required for copilot-cli)
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/${LOCAL_USERNAME}/.bashrc && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/${LOCAL_USERNAME}/.profile

# Add brew to PATH for subsequent RUN commands
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# Install goose (Rust-based CLI)
# Download and install the latest stable release
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        GOOSE_ARCH="x86_64-unknown-linux-gnu"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        GOOSE_ARCH="aarch64-unknown-linux-gnu"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    GOOSE_VERSION=$(curl -Ls https://api.github.com/repos/block/goose/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/') && \
    curl -Ls "https://github.com/block/goose/releases/download/${GOOSE_VERSION}/goose-${GOOSE_ARCH}.tar.bz2" -o /tmp/goose.tar.bz2 && \
    tar -xjf /tmp/goose.tar.bz2 -C /usr/local/bin && \
    chmod +x /usr/local/bin/goose && \
    rm /tmp/goose.tar.bz2 && \
    echo "Installed goose ${GOOSE_VERSION} (${GOOSE_ARCH})"

# Create common directories
RUN mkdir -p /home/${LOCAL_USERNAME}/.config/goose \
    /home/${LOCAL_USERNAME}/.ssh \
    /run/host-services && \
    chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} /home/${LOCAL_USERNAME}

# Install Python packages not available via apt (using venv approach)
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir \
    pyshark \
    python-can \
    cantools \
    pyyaml \
    jinja2 \
    pypdf \
    pdfplumber \
    pymupdf \
    pdfminer.six \
    yamllint

# Add venv to PATH so packages are available system-wide
ENV PATH="/opt/venv/bin:$PATH"

# Install uv (Python package manager) for building diag-dl
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv && \
    mv /root/.local/bin/uvx /usr/local/bin/uvx

# Optional: Install additional tools via build hook
# Place a build-local.sh script next to Dockerfile for custom installations
# This file is gitignored and won't be in the public repo
COPY build-local.sh* /tmp/
RUN --mount=type=secret,id=gitconfig,target=/run/secrets/gitconfig \
    --mount=type=secret,id=netrc,target=/root/.netrc \
    if [ -f /tmp/build-local.sh ]; then \
      echo "Running local build customizations..." && \
      chmod +x /tmp/build-local.sh && \
      bash /tmp/build-local.sh && \
      rm /tmp/build-local.sh; \
    else \
      echo "No local build customizations found (this is normal for public builds)"; \
    fi

# Create common directories
RUN mkdir -p \
    /home/${LOCAL_USERNAME}/.ssh \
    /run/host-services && \
    chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} /home/${LOCAL_USERNAME}

# Switch to user
USER ${LOCAL_USERNAME}
WORKDIR /home/${LOCAL_USERNAME}

# Default command
CMD ["goose", "session"]

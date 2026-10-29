# Goose AI Assistant - Dockerfile
# Built on top of ai-base image with goose-specific tools
# Build with: podman build -t ai-goose:latest .
# Or use build.sh which includes the necessary flags

ARG BASE_IMAGE=ai-base:latest
FROM ${BASE_IMAGE}

# Switch to root for installations
USER root

# Install mcp-atlassian globally for goose extension (avoids npx download delay on startup)
RUN npm install -g mcp-atlassian@2.0.0

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

# Create goose-specific config directory (parent .config already exists from base)
ARG LOCAL_USERNAME=developer
RUN mkdir -p /home/${LOCAL_USERNAME}/.config/goose && \
    chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} /home/${LOCAL_USERNAME}/.config/goose

# Optional: Install additional tools via build hook
# Place a build-local.sh script next to Dockerfile for custom installations
# This file is gitignored and won't be in the public repo
RUN --mount=type=secret,id=gitconfig,target=/run/secrets/gitconfig \
    --mount=type=secret,id=netrc,target=/root/.netrc \
    --mount=type=secret,id=build-local,target=/run/secrets/build-local.sh \
    if [ -f /run/secrets/build-local.sh ]; then \
      echo "Running local build customizations..." && \
      bash /run/secrets/build-local.sh; \
    else \
      echo "No local build customizations found (this is normal for public builds)"; \
    fi

# Switch back to user
USER ${LOCAL_USERNAME}
WORKDIR /home/${LOCAL_USERNAME}

# Default command - start goose session
CMD ["goose", "session"]

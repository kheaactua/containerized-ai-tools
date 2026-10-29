# GitHub Copilot CLI - Dockerfile
# Built on top of ai-base image with GitHub Copilot CLI
# Build with: podman build -t ai-copilot:latest .

ARG BASE_IMAGE=ai-base:latest
FROM ${BASE_IMAGE}

# Switch to root for installations
USER root

# Install bubblewrap (bwrap) - required for Copilot CLI's optional command
# sandboxing feature (MXC bubblewrap backend on Linux needs bwrap 0.5.0+;
# Ubuntu 24.04 ships 0.9.0).
RUN apt-get update && \
    apt-get install -y --no-install-recommends bubblewrap && \
    rm -rf /var/lib/apt/lists/*

# Install GitHub Copilot CLI globally (current official package)
RUN npm install -g @github/copilot

# Create copilot-specific config directory (parent .config already exists from base)
ARG LOCAL_USERNAME=developer
RUN mkdir -p /home/${LOCAL_USERNAME}/.config/github-copilot && \
    chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} /home/${LOCAL_USERNAME}/.config/github-copilot

# Switch back to user
USER ${LOCAL_USERNAME}
WORKDIR /home/${LOCAL_USERNAME}

# Default command - start bash (copilot is invoked via 'gh copilot' commands)
CMD ["/bin/bash"]

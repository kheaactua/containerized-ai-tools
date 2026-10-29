# Hermes AI Agent - Dockerfile
# Built on top of ai-base image with Hermes AI agent
# Build with: podman build -t ai-hermes:latest .
# Installation: https://hermes-agent.nousresearch.com/

ARG BASE_IMAGE=ai-base:latest
FROM ${BASE_IMAGE}

# Switch to root for installations
USER root

# Install Hermes via the official install script
# The script installs to ~/.local/bin by default for non-root users
# We'll install as developer user to match our container setup
ARG LOCAL_USERNAME=developer

# Create hermes-specific data directory (uses ~/.hermes, not XDG standard)
ARG LOCAL_USERNAME=developer
RUN mkdir -p /home/${LOCAL_USERNAME}/.hermes && \
    chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} /home/${LOCAL_USERNAME}/.hermes

# Switch to user for installation (Hermes installer expects non-root)
USER ${LOCAL_USERNAME}
WORKDIR /home/${LOCAL_USERNAME}

# Install Hermes using official install script
# The script downloads and installs the binary to ~/.local/bin (which is already in PATH from base)
RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# Default command - start bash (hermes requires configuration first)
CMD ["bash"]

# To run hermes:
# hermes [OPTIONS]
# For help: hermes --help

# OpenCode (Ford build) - Dockerfile
# Built on top of ai-base image with the Ford-distributed opencode binary.
# Build with build.sh (stages the binary into ./bin/ first):
#   ./build.sh
#
# Binary source (for now, a manually downloaded release):
#   https://github.com/ford-innersource/Mach1MLTools-opencode-ford/releases
# build.sh copies it to ./bin/opencode (gitignored) so it's in the build context.

ARG BASE_IMAGE=ai-base:latest
FROM ${BASE_IMAGE}

# Switch to root for installations
USER root

# Install the opencode binary (self-contained Bun executable, only needs glibc)
COPY bin/opencode /usr/local/bin/opencode
RUN chmod 755 /usr/local/bin/opencode && opencode --version

# Ford-mandated settings (share disabled, no autoupdate, provider allowlist).
# /etc/opencode is opencode's "managed config" directory on Linux, so these
# apply no matter which directory opencode is launched from, and take priority
# over the user's ~/.config/opencode config.
COPY opencode.jsonc /etc/opencode/opencode.jsonc
RUN chmod 644 /etc/opencode/opencode.jsonc

# Belt-and-braces: the binary is pinned by the image, never self-update.
ENV OPENCODE_DISABLE_AUTOUPDATE=1

# Create opencode XDG directories (parents already exist from base).
# These are normally bind-mounted from the host to share config/auth/sessions.
ARG LOCAL_USERNAME=developer
RUN mkdir -p \
        /home/${LOCAL_USERNAME}/.config/opencode \
        /home/${LOCAL_USERNAME}/.local/share/opencode \
        /home/${LOCAL_USERNAME}/.local/state/opencode \
        /home/${LOCAL_USERNAME}/.cache/opencode && \
    chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} \
        /home/${LOCAL_USERNAME}/.config/opencode \
        /home/${LOCAL_USERNAME}/.local \
        /home/${LOCAL_USERNAME}/.cache/opencode

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

# Default command - start the opencode TUI
CMD ["opencode"]

# GitHub Copilot Instructions for Containerized AI Tools

## Project Overview

This project provides container images (Docker/Podman) for running AI coding assistants (Goose, GitHub Copilot CLI) in isolated, reproducible environments with essential development tools.

**Core Goals:**

- **Isolation**: AI agents run in containers, keeping host systems clean
- **Security**: Controlled access, read-only credential mounts
- **Reproducibility**: Same environment across machines and teams
- **Extensibility**: Build hooks for organization-specific tools

## Technology Stack

### Primary Technologies

- **Podman/Docker**: Container engines (Podman preferred for daemonless, rootless)
- **Ubuntu 24.04**: Base container image
- **Bash**: Build scripts and container entrypoint
- **Python 3.12+**: Virtual environment for Python tools
- **Node.js 20+**: For JavaScript-based tools

### Key Container Patterns

- **User namespace mapping**: `--userns=keep-id` to preserve UID/GID
- **Build-time secrets**: `--secret` for git credentials during build
- **Multi-stage builds**: Efficient layer caching
- **Non-root user**: All tools run as regular user, not root

## Code Structure

```
containerized-ai-tools/
├── README.md                    # Main documentation
├── LICENSE                      # MIT license
├── .github/
│   └── copilot-instructions.md # This file
└── docker/                      # Container image definitions
    ├── Dockerfile              # Multi-stage build with dev tools
    ├── build.sh                # Build wrapper with UID/GID detection
    ├── build-local.sh.example  # Template for customizations
    └── BUILD_HOOKS.md          # Hook system documentation
```

## Code Patterns and Conventions

### Dockerfile Structure

#### User Creation Pattern

```dockerfile
ARG LOCAL_UID=1001
ARG LOCAL_GID=1001
ARG LOCAL_USERNAME=developer

# Create user with matching UID/GID
RUN groupadd -g ${LOCAL_GID} ${LOCAL_USERNAME} && \
    useradd -m -u ${LOCAL_UID} -g ${LOCAL_GID} -s /bin/bash ${LOCAL_USERNAME}
```

#### Python Virtual Environment Pattern

```dockerfile
# Create venv as root, transfer ownership
RUN python3 -m venv /opt/venv
RUN chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} /opt/venv

# Install tools in venv
USER ${LOCAL_USERNAME}
RUN /opt/venv/bin/pip install --no-cache-dir goose-ai
```

#### Build Secrets Pattern

```dockerfile
# Mount secrets during build (never stored in layers)
RUN --mount=type=secret,id=gitconfig,target=/run/secrets/gitconfig \
    if [ -f /run/secrets/gitconfig ]; then \
        export GIT_CONFIG_GLOBAL=/run/secrets/gitconfig; \
        git clone https://internal.example.com/private-tool.git; \
    fi
```

### Build Script Pattern

The `build.sh` script should:

1. Auto-detect user's UID/GID/username
2. Pass as build args
3. Support optional secrets (like git credentials)
4. Tag consistently

```bash
#!/bin/bash
set -e

LOCAL_UID=$(id -u)
LOCAL_GID=$(id -g)
LOCAL_USERNAME=$(whoami)

SECRET_ARGS=()
if [ -f "$HOME/.gitconfig" ]; then
    SECRET_ARGS+=(--secret "id=gitconfig,src=$HOME/.gitconfig")
fi

podman build \
    --build-arg LOCAL_UID="$LOCAL_UID" \
    --build-arg LOCAL_GID="$LOCAL_GID" \
    --build-arg LOCAL_USERNAME="$LOCAL_USERNAME" \
    "${SECRET_ARGS[@]}" \
    -t ai-ubuntu:latest \
    -f Dockerfile \
    .
```

### Build Hooks Pattern

Optional `build-local.sh` for organization-specific customizations:

```bash
#!/bin/bash
set -e

# Check for mounted secrets
if [ -f /run/secrets/gitconfig ]; then
    export GIT_CONFIG_GLOBAL=/run/secrets/gitconfig
fi

# Install private tools
cd /tmp
git clone https://github.com/your-org/private-tool.git
cd private-tool
/opt/venv/bin/pip install --no-cache-dir .
cd /tmp && rm -rf private-tool
```

**Important**:

- This file should be `.gitignore`d
- Provide `.example` template
- Document in BUILD_HOOKS.md

## Security Requirements

### Critical: Build-Time Secrets

**NEVER** use `COPY` for credentials:

```dockerfile
# ❌ WRONG - Credentials stored in image layer
COPY ~/.gitconfig /tmp/gitconfig

# ✅ CORRECT - Credentials only available during RUN, not stored
RUN --mount=type=secret,id=gitconfig,target=/run/secrets/gitconfig \
    git clone https://...
```

### User Permissions

**Always** create a non-root user:

```dockerfile
# ✅ CORRECT - Run as regular user
USER ${LOCAL_USERNAME}
RUN goose --version

# ❌ WRONG - Running as root is a security risk
RUN goose --version  # (when still USER root)
```

### File Ownership

**Always** transfer ownership when creating resources as root:

```dockerfile
# Create as root
RUN python3 -m venv /opt/venv

# ✅ Transfer ownership before switching users
RUN chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} /opt/venv

USER ${LOCAL_USERNAME}
```

## Testing Approach

### Manual Testing Required

1. **Build Test**

   ```bash
   cd docker
   ./build.sh
   # Should succeed without errors
   ```

2. **Image Inspection**

   ```bash
   podman run --rm -it ai-ubuntu:latest bash
   # Inside container:
   id            # Check UID/GID match host
   goose --version
   gh copilot --version
   which python3
   python3 -c "import sys; print(sys.prefix)"  # Should be /opt/venv
   ```

3. **Permission Test**

   ```bash
   # On host, in a test directory:
   podman run --rm -it \
     --userns=keep-id \
     -v "$(pwd):/workspace" \
     -w /workspace \
     ai-ubuntu:latest bash

   # Inside container:
   touch test-file.txt
   # Exit and check on host:
   ls -la test-file.txt  # Should be owned by your user, not root
   ```

4. **Build Hook Test**

   ```bash
   cd docker
   cp build-local.sh.example build-local.sh
   # Edit to add test customization
   ./build.sh
   # Verify custom tool installed
   ```

## Common Pitfalls

### 1. UID/GID Mismatch

**Problem**: Files created in container owned by wrong user on host

**Wrong**:

```dockerfile
# Hardcoded UID/GID
RUN useradd -u 1000 -g 1000 developer
```

**Correct**:

```dockerfile
ARG LOCAL_UID=1001
ARG LOCAL_GID=1001
RUN useradd -u ${LOCAL_UID} -g ${LOCAL_GID} developer
```

### 2. Secrets in Layers

**Problem**: Credentials stored in image

**Wrong**:

```dockerfile
COPY build-local.sh /tmp/
RUN bash /tmp/build-local.sh  # If this uses credentials, they're in the layer
```

**Correct**:

```dockerfile
COPY build-local.sh /tmp/
RUN --mount=type=secret,id=gitconfig,target=/run/secrets/gitconfig \
    bash /tmp/build-local.sh
```

### 3. Python Package Location

**Problem**: Installing packages without venv

**Wrong**:

```bash
pip install goose-ai  # Goes to system Python
```

**Correct**:

```bash
/opt/venv/bin/pip install goose-ai  # Goes to venv
# Ensure /opt/venv/bin is in PATH
```

### 4. PATH Configuration

**Problem**: Installed tools not found

**Correct**:

```dockerfile
ENV PATH="/opt/venv/bin:$PATH"
```

### 5. Build Context Issues

**Problem**: COPY fails to find files

```dockerfile
# Build context is docker/, not parent directory
# ✅ Files must be relative to docker/
COPY build-local.sh /tmp/

# ❌ This won't work from docker/ subdirectory
COPY ../fish/some-file.fish /tmp/
```

### 6. Apt-get Best Practices

**Wrong**:

```dockerfile
RUN apt-get install git
```

**Correct**:

```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*
```

### 7. Layer Caching

Install stable dependencies early, volatile ones late:

```dockerfile
# ✅ System packages (rarely change) - early
RUN apt-get update && apt-get install -y build-essential

# ✅ AI tools (update frequently) - late
RUN /opt/venv/bin/pip install goose-ai

# ✅ Local customizations (change often) - last
COPY build-local.sh* /tmp/
RUN [ -f /tmp/build-local.sh ] && bash /tmp/build-local.sh || true
```

### 8. Optional Files in Dockerfile

**Problem**: COPY fails when optional file missing

**Wrong**:

```dockerfile
COPY build-local.sh /tmp/  # Fails if file doesn't exist
```

**Correct**:

```dockerfile
COPY build-local.sh* /tmp/  # Wildcard makes it optional
RUN if [ -f /tmp/build-local.sh ]; then bash /tmp/build-local.sh; fi
```

## Contribution Guidelines

### Adding New Tools

1. **Install in virtual environment** when possible
2. **Use official installation methods** (pip, npm, cargo)
3. **Pin versions** for reproducibility or use latest
4. **Update README** with tool name and purpose
5. **Test in container** before committing

Example:

```dockerfile
# Add to Dockerfile
RUN /opt/venv/bin/pip install --no-cache-dir \
    new-ai-tool==1.2.3 \
    another-tool
```

### Modifying Build Scripts

- **Preserve UID/GID detection** - critical for permissions
- **Keep secrets pattern** - maintain security
- **Test with and without** build-local.sh
- **Update documentation** if behavior changes

### Documentation

- **README.md**: User-facing docs (how to use)
- **BUILD_HOOKS.md**: Developer-facing (how to extend)
- **This file**: AI assistant guidance (patterns and conventions)

## Integration with Shell Plugins

This repo provides **only the container images**. Shell integration lives in separate repos:

- [fish-ai-container](<https://github.com/kheaactua/fish-ai-container>) - Fish shell launcher
- ZSH plugin - Coming soon

The shell plugins should:

1. Mount credentials read-only
2. Use `--userns=keep-id` for permission matching
3. Detect git repositories and mount the root
4. Pass through SSH_AUTH_SOCK for agent forwarding
5. Support custom work-specific hooks

## AI Assistant Guidance

When working on this codebase:

1. **Prioritize security**: Always use `--secret` for credentials, never `COPY`
2. **Test permissions**: Check UID/GID matching between host and container
3. **Respect separation**: This repo = images only, not shell integration
4. **Document changes**: Update relevant README files
5. **Follow patterns**: Use existing patterns for consistency

When suggesting changes:

- Explain security implications
- Show before/after examples
- Consider cross-platform compatibility (Linux, macOS, WSL)
- Test that UID/GID handling still works

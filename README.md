# Containerized AI Tools

Container images for running AI coding assistants like [Goose](https://github.com/block/goose) and GitHub Copilot in isolated, reproducible environments.

## Overview

This repository provides Docker/Podman container images with:

- **Pre-installed AI tools**: Goose, GitHub Copilot CLI
- **Essential dev tools**: git, ripgrep, fd, jq, python3, node, build tools
- **Network analysis**: wireshark, tshark, tcpdump, nmap, scapy
- **Customizable builds**: Hook system for organization-specific tools
- **User namespace support**: Proper UID/GID mapping for file permissions

## Why Use This

- **Isolation**: Keep AI agents and their dependencies separated from your host
- **Reproducibility**: Same environment across machines and teams
- **Security**: Control access via mounts, read-only credentials
- **Shareability**: Easy to distribute working setups
- **Extensibility**: Build hooks for private/custom tools

## Quick Start

### Prerequisites

Install Podman or Docker:

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install podman

# Fedora
sudo dnf install podman

# macOS
brew install podman

# Or use Docker instead
```

### Build the Image

```bash
cd docker
./build.sh
```

The build script automatically:

- Detects your UID/GID for proper permissions
- Tags as `ai-ubuntu:latest`
- Supports optional local customizations (see Build Hooks below)

**Manual build:**

```bash
podman build \
  --build-arg LOCAL_UID=$(id -u) \
  --build-arg LOCAL_GID=$(id -g) \
  --build-arg LOCAL_USERNAME=$(whoami) \
  -t ai-ubuntu:latest \
  docker/
```

## What's Inside

The container image includes:

### AI Tools

- **Goose** - Latest stable release
- **GitHub Copilot CLI** - `gh copilot` commands

### Development Tools

- **Languages**: Python 3.12+, Node.js 20+, build-essential
- **Search**: ripgrep, fd-find, fzf
- **Git**: Full git with credential helpers
- **Editors**: vim, nano
- **Shell**: bash, zsh, fish
- **Utilities**: curl, wget, jq, yq, tree, htop

### Network Analysis

- wireshark/tshark
- tcpdump
- nmap
- scapy (Python library)

## Usage

### Shell Integration

For convenient usage, pair this with a shell plugin that handles mounting, permissions, and environment:

**Fish Shell**: [fish-ai-container](https://github.com/kheaactua/fish-ai-container)

```fish
fisher install kheaactua/fish-ai-container
goose-container      # Launch Goose in container
copilot-container    # Launch Copilot in container
```

**ZSH**: Might implement one day

### Manual Usage

Run the container directly:

```bash
# Interactive Goose session
podman run --rm -it \
  --userns=keep-id \
  --network=host \
  -v "$HOME/.config/goose:/home/$(whoami)/.config/goose" \
  -v "$HOME/.gitconfig:/home/$(whoami)/.gitconfig:ro" \
  -v "$HOME/.ssh:/home/$(whoami)/.ssh:ro" \
  -v "$SSH_AUTH_SOCK:/run/host-services/ssh-auth.sock" \
  -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock \
  -v "$(pwd):/workspace" \
  -w /workspace \
  ai-ubuntu:latest \
  goose

# GitHub Copilot
podman run --rm -it \
  --userns=keep-id \
  --network=host \
  -v "$HOME/.config/gh:/home/$(whoami)/.config/gh:ro" \
  -v "$(pwd):/workspace" \
  -w /workspace \
  ai-ubuntu:latest \
  gh copilot suggest "write a unit test"
```

### Drop into Shell

Debug or explore the container:

```bash
podman run --rm -it \
  --userns=keep-id \
  -v "$(pwd):/workspace" \
  -w /workspace \
  ai-ubuntu:latest \
  bash
```

## Build Hooks

Customize the image for your organization's needs using `docker/build-local.sh`:

```bash
cd docker
cp build-local.sh.example build-local.sh
# Edit build-local.sh to add your custom tools
./build.sh  # Automatically runs build-local.sh if present
```

**Example use cases:**

- Install private packages from internal registries
- Clone and install internal tools from git
- Add organization-specific certificates
- Install proprietary debugging tools

See [docker/BUILD_HOOKS.md](docker/BUILD_HOOKS.md) for details.

### Installing from Private Git Repos

The build script supports mounting git credentials as a secret:

```bash
#!/bin/bash
# docker/build-local.sh

# Git credentials are available at /run/secrets/gitconfig during build
if [ -f /run/secrets/gitconfig ]; then
    export GIT_CONFIG_GLOBAL=/run/secrets/gitconfig
fi

cd /tmp
git clone https://github.com/your-org/your-private-tool.git
cd your-private-tool
/opt/venv/bin/pip install --no-cache-dir .
cd /tmp && rm -rf your-private-tool
```

## Security Considerations

### Built-in Security

- ✅ User namespace mapping preserves UID/GID
- ✅ No root/daemon required (Podman)
- ✅ Credentials can be mounted read-only
- ✅ Isolated environment per container

### Recommendations

- Mount SSH keys and git config read-only (`:ro`)
- Use SSH agent forwarding instead of key copying
- Enable host networking only when needed
- Review build-local.sh for secrets before committing
- Use `--secret` for build-time credentials (never `COPY`)

## Troubleshooting

### Permission Issues

**Problem**: Files created by container have wrong ownership

**Solution**: Rebuild with your UID/GID:

```bash
cd docker
./build.sh  # Automatically detects and uses your IDs
```

### Goose Not Found

**Problem**: `goose: command not found`

**Solution**: The build installs Goose to `/opt/venv/bin/`. Ensure the container's PATH includes it:

```bash
# Inside container
echo $PATH
# Should include /opt/venv/bin
```

### Network Issues

**Problem**: API calls fail or git clone doesn't work

**Solution**: Use `--network=host` when running:

```bash
podman run --network=host ...
```

### Proxy Configuration

If behind a corporate proxy, set during build:

```bash
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
cd docker
./build.sh
```

## Project Structure

```
containerized-ai-tools/
├── README.md                    # This file
├── LICENSE                      # MIT License
└── docker/                      # Container image
    ├── Dockerfile              # Multi-stage Ubuntu 24.04 image
    ├── build.sh                # Build wrapper with UID/GID detection
    ├── build-local.sh.example  # Template for customizations
    ├── BUILD_HOOKS.md          # Hook system documentation
    └── README.md               # Docker-specific docs
```

## Related Projects

**Shell Integration:**

- [fish-ai-container](https://github.com/kheaactua/fish-ai-container) - Fish shell plugin for launching these containers

**AI Tools:**

- [Goose](https://github.com/block/goose) - AI coding agent by Block
- [GitHub Copilot CLI](https://githubnext.com/projects/copilot-cli/) - AI pair programmer

**Container Technology:**

- [Podman](https://podman.io/) - Daemonless container engine
- [Docker](https://www.docker.com/) - Container platform

## Development

### Pre-commit Hooks

This repository uses pre-commit hooks for code quality:

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run manually on all files
pre-commit run --all-files
```

**Hooks enabled:**

- **shellcheck** - Shell script linting
- **shfmt** - Shell script formatting
- **hadolint** - Dockerfile linting
- **markdownlint** - Markdown formatting
- **gitleaks** - Secret scanning
- **detect-secrets** - Additional secret detection

### Updating Secrets Baseline

If you intentionally add content that looks like a secret (example tokens, test data):

```bash
detect-secrets scan > .secrets.baseline
git add .secrets.baseline
```

## Contributing

Contributions welcome! Areas of interest:

- Additional AI tools integration
- Performance optimizations
- Security enhancements
- Documentation improvements

Please ensure:

- Pre-commit hooks pass
- Dockerfile builds successfully
- Documentation is updated

## License

MIT License - See [LICENSE](LICENSE) file for details.

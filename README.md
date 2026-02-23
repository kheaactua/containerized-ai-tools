# Goose in Podman - Containerized AI Agents

Run AI coding assistants like [Goose](https://github.com/block/goose) and GitHub Copilot in isolated Podman containers with automatic mounting of your workspace, git config, SSH keys, and API credentials.

## Why Use This?

- **Isolation**: AI agents run in containers, keeping your host system clean
- **Reproducibility**: Same environment across machines and teams
- **Security**: Control exactly what the agent can access via mounts
- **Shareability**: Easy to share working setups with colleagues
- **Multi-tool**: One container setup works for Goose, Copilot, and custom tools

## Features

- 🔒 **Secure by default**: SSH keys and credentials mounted read-only
- 🔄 **Git integration**: Automatic git root detection and mounting
- 🌐 **Network access**: Host networking for API calls and git operations
- 📦 **Work hooks**: Easy customization for organization-specific mounts and env vars
- 🐚 **Shell support**: Fish plugin (included), ZSH plugin (planned)

## Quick Start

### 1. Prerequisites

Install Podman:
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install podman

# Fedora
sudo dnf install podman

# macOS
brew install podman
```

### 2. Build the Container Image

```bash
cd docker
./build.sh
# or manually: podman build -t ai-ubuntu:latest .
```

The image includes:
- Goose (latest stable release)
- GitHub Copilot CLI
- Essential dev tools (git, rg, fd, jq, python3, etc.)
- Network analysis tools (wireshark, tshark, scapy, etc.)

### 3. Install the Shell Plugin

#### Fish Shell

**Option A: Fisher (recommended)**
```fish
fisher install /path/to/goose-in-podman-example/fish
```

**Option B: Manual**
```fish
# Symlink or copy the config file
ln -s ~/goose-in-podman-example/fish/conf.d/container-launcher.fish \
      ~/.config/fish/conf.d/container-launcher.fish

# Reload fish config
source ~/.config/fish/config.fish
```

See [fish/README.md](fish/README.md) for detailed Fish installation and usage.

#### ZSH (Coming Soon)

See [zsh/README.md](zsh/README.md)

### 4. Run It!

```fish
# Start interactive Goose session
goose-container

# Run with arguments
goose-container --help
goose-container session --profile dev

# GitHub Copilot
copilot-container

# Drop into bash for debugging
goose-container bash
```

## How It Works

### Container Launcher

The generic `__container_launcher` function handles:

1. **Environment Variables**: Automatically passes through API keys, proxy settings, SSH agent
2. **Volume Mounts**:
   - Config directories (`~/.config/goose`, `~/.config/github-copilot`)
   - Git credentials (`~/.gitconfig`, `~/.netrc`, etc.) - read-only
   - SSH config and keys - read-only
   - Current working directory or git root
   - Custom work-specific mounts (via hooks)
3. **User Mapping**: `--userns=keep-id` preserves file ownership
4. **Networking**: Host network mode for API access
5. **Temporary Files**: Unique tmpdir per container session

### Tool Wrappers

Pre-configured functions for common tools:
- `goose-container` - Run Goose
- `copilot-container` - Run GitHub Copilot CLI


### Work-Specific Hooks

Add custom functions in your fish config to extend the launcher:

```fish
# ~/.config/fish/config.fish

function container-work-env-vars
    # Return additional env vars to pass
    echo "JFROG_TOKEN=$JFROG_TOKEN"
    echo "INTERNAL_API_URL=$INTERNAL_API_URL"
end

function container-work-mounts
    # Return additional mounts (host:container[:ro])
    echo "$HOME/work/certs:/certs:ro"
    echo "$HOME/work/tools:/opt/tools"
end
```

## Customization

### Adding New Tools

Copy the template in `fish/conf.d/container-launcher.fish`:

```fish
function my-tool-container --description "Run my-tool in container"
    # Set tool-specific environment
    set -x MY_TOOL_CONFIG "$HOME/.config/my-tool"

    __container_launcher "ai-ubuntu:latest" "my-tool" $argv

    # Clean up
    set -e MY_TOOL_CONFIG
end
```

### Modifying the Image

Edit `docker/Dockerfile` to add packages or tools, then rebuild:

```bash
cd docker
podman build -t ai-ubuntu:latest .
```

## Security Considerations

- ✅ SSH keys mounted read-only (agent can use but not modify)
- ✅ Git credentials mounted read-only
- ✅ User namespace keeps UID/GID matching
- ✅ Each container gets unique tmpdir (no session collisions)
- ⚠️ Workspace directories mounted read-write (agent can modify files)
- ⚠️ Host network mode gives full network access

## Troubleshooting

### SSH Agent Not Working

Ensure `$SSH_AUTH_SOCK` is set:
```fish
echo $SSH_AUTH_SOCK
# If empty, start ssh-agent
eval (ssh-agent -c)
ssh-add ~/.ssh/id_ed25519
```

### Permission Issues

Check UID/GID match between host and container:
```bash
id -u  # Should match LOCAL_UID in Dockerfile (default: 1001)
id -g  # Should match LOCAL_GID in Dockerfile (default: 1001)
```

If they don't match, rebuild with:
```bash
cd docker
podman build \
  --build-arg LOCAL_UID=$(id -u) \
  --build-arg LOCAL_GID=$(id -g) \
  --build-arg LOCAL_USERNAME=$(whoami) \
  -t ai-ubuntu:latest .
```

### Mount Not Working

Enable verbose output to see what's being mounted:
```fish
set -x CONTAINER_VERBOSE 1
goose-container bash
```

### Git Not Finding Repository

The launcher auto-detects git repositories and mounts the root. If you're not seeing your repo:
1. Ensure you're inside a git repo: `git rev-parse --show-toplevel`
2. Check if an explicit mount is overriding it
3. Enable verbose mode to see mount paths

## Examples

### Interactive Goose Session
```fish
cd ~/my-project
goose-container
# Goose can see entire git repo and use your git config
```

### One-off Command
```fish
goose-container run "analyze this codebase"
```

### Debugging Container
```fish
# Drop into bash to inspect environment
goose-container bash

# Inside container:
goose@container$ pwd
goose@container$ ls -la ~/.config/goose
goose@container$ ssh-add -l
goose@container$ git config --list
```

### GitHub Copilot
```fish
copilot-container explain "what does this function do?"
copilot-container suggest "write a unit test"
```

## Project Structure

```
goose-in-podman-example/
├── README.md              # This file
├── docker/               # Container image
│   ├── Dockerfile
│   ├── build.sh
│   └── patch_langfuse.py
├── fish/                 # Fish shell plugin
│   ├── README.md
│   └── conf.d/
│       └── container-launcher.fish
└── zsh/                  # ZSH plugin (planned)
    └── README.md
```

## Contributing

Contributions welcome! Areas of interest:
- ZSH plugin implementation
- Additional tool wrappers
- Documentation improvements
- Security enhancements

## License

MIT License - See LICENSE file for details

## Related Projects

- [Goose](https://github.com/block/goose) - AI coding agent
- [Podman](https://podman.io/) - Daemonless container engine
- [GitHub Copilot CLI](https://githubnext.com/projects/copilot-cli/) - AI pair programmer

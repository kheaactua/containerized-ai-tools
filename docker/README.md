t Goose + Podman Setup Guide

## Quick Start

### 1. Install Podman
```bash
sudo apt update
sudo apt install podman
```

### 2. Build the Container Image

```bash
cd docker/
./build.sh
```

This creates the `goose-ai:latest` image with all necessary tools.

### 3. Update the Fish Function
Edit `/home/matt/.config/fish/conf.d/goose-podman.fish` and change the IMAGE variable:
```fish
set -l IMAGE "goose-ubuntu:latest"  # Or "ubuntu:22.04"
```

### 4. Reload Fish Config
```bash
source ~/.config/fish/config.fish
# Or just start a new terminal
```

### 5. Run Goose!
```bash
goose-container
```

## Customization

### Adding New Environment Variables
Edit the Fish plugin and add:
```fish
test -n "$MY_NEW_VAR" && set -a cmd -e MY_NEW_VAR
```

### Adding New Mounts
```fish
# Read-write mount
set -a cmd -v /host/path:/container/path

# Read-only mount
test -e /host/file && set -a cmd -v /host/file:/container/file:ro

# Conditional mount (only if exists)
test -d /host/optional && set -a cmd -v /host/optional:/container/optional
```

### Creating a New Environment
Copy and modify the template in the fish file:
```fish
function goose-myproject --description "Run goose for my project"
    set -l IMAGE "goose-ubuntu:latest"
    set -l WORK_DIR "/path/to/project"
    # ... rest of setup
end
```

## Tools Goose Commonly Uses

**Critical:**
- `rg` (ripgrep) - Code search, goose uses this heavily
- `fd` - File finding
- `git` - Version control
- `curl`/`wget` - Downloads

**Very Common:**
- `python3` - Many code analysis tasks
- `jq` - JSON processing
- `vim`/`nano` - Text editing
- Build tools (`gcc`, `make`, `cmake`)

**Nice to Have:**
- `sd` - Search and replace (like sed but better)
- `bat` - Better cat with syntax highlighting
- `delta` - Better git diffs

## Security Notes

1. **SSH Keys:** Mounted read-only (`:ro`) - goose can use but not modify
2. **Git Credentials:** Mounted read-only - goose can authenticate but not change creds
3. **Workspace:** Mounted read-write - goose can modify project files
4. **Sudo:** Enabled inside container but contained to podman user namespace

## Troubleshooting

### SSH Agent Not Working
Check that `$SSH_AUTH_SOCK` is set on your host:
```bash
echo $SSH_AUTH_SOCK
```

If not, start ssh-agent:
```bash
eval $(ssh-agent)
ssh-add ~/.ssh/id_ed25519
```

### Permission Issues
Ensure UID/GID in Dockerfile matches your host user:
```bash
id -u  # Should match LOCAL_UID in Dockerfile
id -g  # Should match LOCAL_GID in Dockerfile
```

### Mount Not Working
Check if path exists and you have permissions:
```bash
ls -la /path/to/mount
```

### Testing Without Goose
Drop into a shell to test the environment:
```bash
goose-container bash
```

## Usage Examples

```bash
# Start interactive goose session (default)
goose-container

# Pass arguments to goose
goose-container --help
goose-container session --profile coding

# Drop into bash for debugging
goose-container bash

# Run a one-off command
goose-container rg "TODO" /workspace/myproject
```

## Next Steps

1. Build or pull the image
2. Test the function: `goose-container bash`
3. Verify mounts: `ls /workspace/myproject`
4. Verify SSH: `ssh-add -l`
5. Run goose: `goose-container`

## Adding More Environments

Copy the function template and modify for different projects:
- `goose-web` - Web development with node, npm
- `goose-data` - Data science with jupyter, pandas
- `goose-scratch` - Experimental/throwaway work

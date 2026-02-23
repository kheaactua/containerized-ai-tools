# Fish Shell Plugin - Goose in Podman

This Fish shell plugin provides commands to run AI coding assistants like Goose and GitHub Copilot in isolated Podman containers.

## Installation

### Option 1: Fisher (Recommended)

If you use [Fisher](https://github.com/jorgebucaran/fisher):

```fish
# Local installation (works for private repos):
fisher install ~/tmp/goose-in-podman-example

# Once repo is public:
# fisher install ford-personal/mruss100.goose-in-podman-example
```

### Option 2: Oh My Fish

```fish
omf install ~/goose-in-podman-example/fish
```

### Option 3: Manual Installation

Copy or symlink the configuration file:

```fish
# Create symlink (recommended - updates automatically)
ln -s ~/goose-in-podman-example/fish/conf.d/container-launcher.fish \
      ~/.config/fish/conf.d/container-launcher.fish

# Or copy the file
cp ~/goose-in-podman-example/fish/conf.d/container-launcher.fish \
   ~/.config/fish/conf.d/

# Reload fish config
source ~/.config/fish/config.fish
```

## Available Functions

### Main Commands

- **`goose-container [args...]`** - Run Goose in a container
  - No args: Start interactive session
  - With args: Pass through to goose
  - Special: Use `bash` to drop into a shell

- **`copilot-container [args...]`** - Run GitHub Copilot CLI in a container


### Helper Functions (Advanced)

These are internal functions you typically won't call directly, but can use to build custom wrappers:

- **`__container_launcher IMAGE TOOL_CMD [args...]`** - Generic container launcher
- **`__container_print_verbose [message...]`** - Print debug messages if `CONTAINER_VERBOSE` is set
- **`__container_mount_files [mounts...]`** - Mount files conditionally
- **`__container_mount_directories [mounts...]`** - Mount directories and track paths
- **`__container_mount_workdir WORK_DIR [explicit_mounts...]`** - Mount working directory or git root
- **`__container_build_command IMAGE WORK_DIR TOOL_CMD [args...]`** - Build final command array

## Usage Examples

### Basic Goose Usage

```fish
# Start interactive session in current directory
goose-container

# Pass arguments to goose
goose-container --help
goose-container session --profile coding

# Drop into bash shell for debugging
goose-container bash
```

### GitHub Copilot

```fish
# Interactive mode
copilot-container

# Ask a question
copilot-container explain "what does this function do?"

# Get suggestions
copilot-container suggest "write a unit test"
```

### Debugging

Enable verbose output to see what's happening:

```fish
set -x CONTAINER_VERBOSE 1
goose-container bash
```

You'll see:
- Container configuration
- Mounted volumes
- Environment variables being set
- Full podman command

### Working with Git Repositories

The launcher automatically detects if you're in a git repository and mounts the entire repo root:

```fish
cd ~/my-project/src/subdir
goose-container

# Inside container, goose can access entire git repo
# - /home/matt/my-project is mounted
# - .git directory is accessible
# - git commands work normally
```

## Customization

### Work-Specific Hooks

Add custom environment variables and mounts in your `~/.config/fish/config.fish`:

```fish
# Add custom environment variables
function container-work-env-vars
    echo "JFROG_TOKEN=$JFROG_TOKEN"
    echo "COMPANY_API_KEY=$COMPANY_API_KEY"
    echo "INTERNAL_REGISTRY=registry.company.com"
end

# Add custom volume mounts
function container-work-mounts
    # Mount company certificates
    echo "$HOME/work/certs:/etc/ssl/company-certs:ro"

    # Mount internal tools
    echo "$HOME/work/tools:/opt/company-tools"

    # Mount shared workspace
    echo "/mnt/shared-workspace:/shared:ro"
end
```

### Creating Custom Tool Wrappers

Add new tools by following the template in `conf.d/container-launcher.fish`:

```fish
# Add to your ~/.config/fish/config.fish
function my-tool-container --description "Run my-tool in container"
    # Set tool-specific environment
    set -x MY_TOOL_CONFIG "$HOME/.config/my-tool"
    set -x MY_TOOL_LOG_LEVEL "debug"

    __container_launcher "ai-ubuntu:latest" "my-tool" $argv

    # Clean up exported variables
    set -e MY_TOOL_CONFIG
    set -e MY_TOOL_LOG_LEVEL
end
```

### Modifying Mounts and Environment

If you need to modify the default behavior, you can either:

1. **Edit the plugin file** (not recommended - makes updates harder)
2. **Override functions** in your config (recommended)

Example override:

```fish
# Override in ~/.config/fish/config.fish
function goose-container --description "My custom goose-container"
    # Add your custom env vars
    set -x CUSTOM_VAR "value"

    # Call the original launcher
    __container_launcher "ai-ubuntu:latest" "goose" $argv

    set -e CUSTOM_VAR
end
```

## Configuration

### Environment Variables

The plugin automatically passes through these environment variables if they're set:

**API Keys:**
- `OPENAI_API_KEY`, `OPENAI_API_BASE`, `OPENAI_HOST`
- `ANTHROPIC_API_KEY`
- `ATLASSIAN_API_TOKEN`, `ATLASSIAN_EMAIL`, `ATLASSIAN_BASE_URL`
- `GITHUB_TOKEN`, `WORK_GITHUB_TOKEN`

**Proxy Settings:**
- `http_proxy`, `https_proxy`, `no_proxy`, `ftp_proxy`
- `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`, `FTP_PROXY`

**SSH & Shell:**
- `SSH_AUTH_SOCK` (mapped to `/run/host-services/ssh-auth.sock`)
- `TERM`
- `GPG_TTY`

**Custom (from hooks):**
- Any returned by `container-work-env-vars` function

### Volume Mounts

**Always Mounted:**
- `~/.config/goose` - Goose configuration and sessions
- `~/.config/github-copilot` - Copilot configuration
- `~/.copilot` - Copilot data
- `~/tmp` - Your home tmp directory
- Current directory or git root
- Container-specific tmpdir (unique per session)

**Conditionally Mounted (if they exist):**
- `~/.ssh/config` (read-only)
- `~/.ssh/known_hosts` (read-only)
- `~/.gitconfig` (read-only)
- `~/.gitconfig-*` (read-only) - includes work, dev, proxy variants
- `~/.netrc`, `~/.gitcookies`, `~/.git-credentials` (read-only)
- `~/.config/gh` - GitHub CLI configuration
- SSH auth socket
- Custom mounts from `container-work-mounts` function

## Troubleshooting

### Plugin Not Loading

```fish
# Check if file is in conf.d
ls -la ~/.config/fish/conf.d/container-launcher.fish

# Reload fish config
source ~/.config/fish/config.fish

# Or restart fish shell
exec fish
```

### Functions Not Available

```fish
# List loaded functions
functions | grep container

# If missing, check for errors
fish -c "source ~/.config/fish/conf.d/container-launcher.fish"
```

### SSH Agent Not Working

```fish
# Check if SSH_AUTH_SOCK is set
echo $SSH_AUTH_SOCK

# If empty, start agent
eval (ssh-agent -c)
ssh-add ~/.ssh/id_ed25519

# Verify keys are loaded
ssh-add -l
```

### Git Credentials Not Working

```fish
# Verify git config is readable
cat ~/.gitconfig

# Check if container can see it
goose-container bash
# Inside container:
git config --list
```

### Verbose Debugging

```fish
# Enable verbose output
set -x CONTAINER_VERBOSE 1

# Run command - you'll see all mounts and config
goose-container bash

# Inside container, verify mounts
ls -la ~/.config/goose
ls -la ~/.ssh
mount | grep -E "(home|config|ssh)"

# Check environment
env | sort

# Test git
git rev-parse --show-toplevel
```

## Uninstallation

### Fisher
```fish
# If installed via Fisher from local directory
fisher remove goose-in-podman-example

# Or if installed from public GitHub:
# fisher remove ford-personal/mruss100.goose-in-podman-example
```

### Manual
```fish
rm ~/.config/fish/conf.d/container-launcher.fish
source ~/.config/fish/config.fish
```

## Advanced: Creating Multiple Environments

You can create multiple specialized environments for different projects:

```fish
# In ~/.config/fish/config.fish

function goose-web --description "Goose for web development"
    set -x NODE_ENV "development"
    set -x GOOSE_PROFILE "web"
    __container_launcher "ai-ubuntu:latest" "goose" $argv
    set -e NODE_ENV GOOSE_PROFILE
end

function goose-data --description "Goose for data science"
    set -x JUPYTER_CONFIG_DIR "$HOME/.jupyter"
    set -x GOOSE_PROFILE "data"
    __container_launcher "ai-ubuntu:latest" "goose" $argv
    set -e JUPYTER_CONFIG_DIR GOOSE_PROFILE
end

function goose-scratch --description "Goose in isolated throwaway environment"
    # Override mount functions to limit what's accessible
    set -x TMPDIR "/tmp/goose-scratch-"(date +%s)
    __container_launcher "ai-ubuntu:latest" "goose" $argv
    set -e TMPDIR
end
```

## Further Reading

- [Fish Shell Documentation](https://fishshell.com/docs/current/)
- [Podman Documentation](https://docs.podman.io/)
- [Goose Documentation](https://github.com/block/goose)

## Support

For issues specific to the Fish plugin, please open an issue on the main repository with the `fish` label.

# GitHub Copilot Instructions for Goose in Podman

## Project Overview

This project provides a containerized environment for running AI coding assistants (Goose, GitHub Copilot CLI) in isolated Podman containers with automatic mounting of workspaces, git config, SSH keys, and API credentials.

**Core Goals:**
- **Isolation**: AI agents run in containers, keeping host systems clean
- **Security**: Credentials and keys mounted read-only; controlled access
- **Reproducibility**: Same environment across machines and teams
- **Extensibility**: Easy to add new tools and custom configurations

## Technology Stack

### Primary Technologies
- **Podman** (NOT Docker): Daemonless container engine with rootless capabilities
- **Fish Shell**: Primary shell plugin implementation (ZSH planned)
- **Ubuntu 24.04**: Base container image
- **Bash**: Container entrypoint and scripting

### Key Container Patterns
- **User namespace mapping**: `--userns=keep-id` to preserve UID/GID
- **Host networking**: `--network=host` for API access
- **Read-only mounts**: All credentials and config files
- **SSH agent forwarding**: Via socket mounting
- **Unique tmpdirs**: Per-session isolation

## Code Structure

```
goose-in-podman-example/
├── docker/                    # Container image definitions
│   ├── Dockerfile            # Multi-stage build with dev tools
│   ├── build.sh              # Build wrapper with UID/GID detection
│   ├── build-local.sh        # Optional local customizations (gitignored)
│   └── BUILD_HOOKS.md        # Hook system documentation
├── fish/                      # Fish shell plugin
│   ├── conf.d/
│   │   └── container-launcher.fish  # Core launcher implementation
│   └── README.md
└── zsh/                       # Future ZSH plugin
```

## Code Patterns and Conventions

### Fish Shell Functions

#### Naming Convention
- **Public commands**: `{tool}-container` (e.g., `goose-container`, `copilot-container`)
- **Internal helpers**: `__container_{function}` (double underscore prefix)
- **Hook functions**: `container-work-{category}` (e.g., `container-work-env-vars`)

#### Function Template for New Tools
```fish
function mytool-container --description "Run mytool in container"
    # 1. Set tool-specific environment variables
    set -x MYTOOL_CONFIG "$HOME/.config/mytool"
    set -x MYTOOL_CACHE_DIR "$HOME/.cache/mytool"

    # 2. Call generic launcher with image, command, and args
    __container_launcher "ai-ubuntu:latest" "mytool" $argv

    # 3. Clean up exported variables
    set -e MYTOOL_CONFIG
    set -e MYTOOL_CACHE_DIR
end
```

#### Internal Helper Functions
- **`__container_print_verbose`**: Debug output (checks `CONTAINER_VERBOSE`)
- **`__container_mount_files`**: Conditionally mount files if they exist
- **`__container_mount_directories`**: Mount dirs and track explicit mounts
- **`__container_mount_workdir`**: Mount CWD or git root (with deduplication)
- **`__container_build_command`**: Assemble final podman command array
- **`__container_launcher`**: Core launcher logic

### Dockerfile Patterns

#### User Creation
```dockerfile
ARG LOCAL_UID=1001
ARG LOCAL_GID=1001
ARG LOCAL_USERNAME=developer

RUN groupadd -g ${LOCAL_GID} ${LOCAL_USERNAME} && \
    useradd -m -u ${LOCAL_UID} -g ${LOCAL_GID} -s /bin/bash ${LOCAL_USERNAME}
```

**Why**: Ensures container user matches host user for file ownership

#### Build Hook System
```dockerfile
# Copy and run build-local.sh if it exists
COPY build-local.sh* /tmp/
RUN if [ -f /tmp/build-local.sh ]; then \
        chmod +x /tmp/build-local.sh && \
        /tmp/build-local.sh; \
    fi
```

**Why**: Allows local customizations without modifying tracked Dockerfile

#### Essential Tools for AI Agents
Must-have packages:
- **ripgrep** (`rg`): Fast code search - CRITICAL for AI assistants
- **fd-find**: Fast file finder
- **git**: Version control
- **jq**: JSON processing
- **python3**: Often needed by AI tools
- **build-essential**: Compilation tools

### Build Scripts

#### build.sh Pattern
```bash
# Auto-detect host UID/GID
podman build \
  --build-arg LOCAL_UID=$(id -u) \
  --build-arg LOCAL_GID=$(id -g) \
  --build-arg LOCAL_USERNAME=$(whoami) \
  -t ai-ubuntu:latest .
```

**Why**: Automatic user namespace matching without manual configuration

## Security Requirements

### CRITICAL: Read-Only Mounts

**ALWAYS mount credentials and config files as read-only:**

```fish
# CORRECT
echo "$HOME/.ssh/config:/home/$USER/.ssh/config:ro"
echo "$HOME/.gitconfig:/home/$USER/.gitconfig:ro"
echo "$HOME/.netrc:/home/$USER/.netrc:ro"

# WRONG - never do this
echo "$HOME/.ssh:/home/$USER/.ssh"  # Missing :ro
```

**Why**: Prevents AI agents from accidentally or maliciously modifying SSH keys, git credentials, or sensitive config files.

### SSH Agent Forwarding

```fish
# Correct pattern: mount socket read-only
-v "$SSH_AUTH_SOCK:/run/host-services/ssh-auth.sock:ro"
-e SSH_AUTH_SOCK="/run/host-services/ssh-auth.sock"
```

**Why**: Allows SSH key usage without exposing private keys to the container filesystem.

### Workspace Mounts

**Workspaces are mounted read-write** because agents need to modify code:

```fish
# This is intentional
-v "$git_root:$git_root"  # No :ro
```

**Security considerations:**
- Agents can modify any file in the mounted workspace
- Container runs with user's UID/GID (not root)
- Use git for recovery if agent makes unwanted changes
- Consider backup strategies for critical work

### User Namespace Mapping

**Always use `--userns=keep-id`:**

```fish
podman run --userns=keep-id ...
```

**Why**: Preserves host UID/GID so files created in container have correct ownership on host.

### Tmpdir Isolation

**Each container session gets unique tmpdir:**

```fish
set -l container_tmpdir "/tmp/goose-container-"(date +%s%N | string sub -l 16)
-v "$container_tmpdir:$container_tmpdir"
-e TMPDIR="$container_tmpdir"
```

**Why**: Prevents session collisions and data leakage between concurrent containers.

## Testing Approach

### Manual Testing Workflow

1. **Build the container:**
   ```bash
   cd docker
   ./build.sh
   ```

2. **Test basic invocation:**
   ```fish
   goose-container bash
   # Inside container, verify:
   whoami  # Should match host username
   id      # UID/GID should match host
   pwd     # Should be in git root or CWD
   ```

3. **Test mounts:**
   ```fish
   set -x CONTAINER_VERBOSE 1
   goose-container bash
   # Verify output shows correct mounts
   
   # Inside container:
   ls -la ~/.config/goose
   ls -la ~/.ssh
   cat ~/.gitconfig
   ssh-add -l  # Should show host SSH keys
   ```

4. **Test git integration:**
   ```fish
   cd ~/some-repo/subdir
   goose-container bash
   # Inside container:
   git rev-parse --show-toplevel  # Should work
   git status                      # Should see real repo status
   ```

5. **Test with actual tool:**
   ```fish
   goose-container --version
   goose-container session list
   ```

### Testing New Tool Wrappers

When adding a new tool wrapper:

1. **Verify minimal invocation:**
   ```fish
   mytool-container --help
   mytool-container --version
   ```

2. **Test with verbose output:**
   ```fish
   set -x CONTAINER_VERBOSE 1
   mytool-container some-command
   ```

3. **Verify environment variables:**
   ```fish
   mytool-container bash
   # Inside container:
   env | grep MYTOOL
   ```

4. **Test config file access:**
   ```fish
   mytool-container bash
   # Inside container:
   ls -la ~/.config/mytool
   cat ~/.config/mytool/config.toml
   ```

### Dockerfile Testing

After modifying Dockerfile:

1. **Clean rebuild:**
   ```bash
   podman rmi ai-ubuntu:latest
   cd docker
   ./build.sh
   ```

2. **Verify essential tools:**
   ```fish
   goose-container bash
   # Inside container:
   rg --version    # Must have ripgrep
   fd --version    # Must have fd-find
   git --version
   python3 --version
   jq --version
   ```

3. **Check user setup:**
   ```fish
   goose-container bash
   # Inside container:
   whoami          # Should match host
   sudo echo hi    # Should work without password
   ```

## Common Pitfalls

### 1. Using Docker Instead of Podman

❌ **Wrong:**
```bash
docker build -t ai-ubuntu:latest .
alias goose="docker run ..."
```

✅ **Correct:**
```bash
podman build -t ai-ubuntu:latest .
# Use podman everywhere
```

**Why**: This project is designed for Podman's rootless and daemonless features.

### 2. Forgetting Read-Only on Credentials

❌ **Wrong:**
```fish
echo "$HOME/.ssh:/home/$USER/.ssh"
echo "$HOME/.gitconfig:/home/$USER/.gitconfig"
```

✅ **Correct:**
```fish
echo "$HOME/.ssh/config:/home/$USER/.ssh/config:ro"
echo "$HOME/.gitconfig:/home/$USER/.gitconfig:ro"
```

### 3. UID/GID Mismatch

**Problem**: Files created in container have wrong ownership on host.

**Symptoms:**
```bash
ls -la
# Shows files owned by wrong user or numeric UID
```

**Solution:**
```bash
cd docker
# Rebuild with your UID/GID
podman build \
  --build-arg LOCAL_UID=$(id -u) \
  --build-arg LOCAL_GID=$(id -g) \
  --build-arg LOCAL_USERNAME=$(whoami) \
  -t ai-ubuntu:latest .
```

Or use the `build.sh` script which does this automatically.

### 4. Not Mounting Git Root

**Problem**: Agent can't see `.git` directory or full repository.

❌ **Wrong:**
```fish
# Just mounting CWD when in a subdirectory
-v "$PWD:$PWD"
```

✅ **Correct:**
```fish
# Auto-detect and mount git root
set -l git_root (git rev-parse --show-toplevel 2>/dev/null)
if test -n "$git_root"
    -v "$git_root:$git_root"
end
```

The `__container_mount_workdir` helper does this automatically.

### 5. SSH Agent Not Available

**Problem**: `ssh-add -l` fails inside container.

**Check:**
```fish
echo $SSH_AUTH_SOCK  # Must be set on host
```

**Solution:**
```fish
# Start SSH agent if not running
eval (ssh-agent -c)
ssh-add ~/.ssh/id_ed25519
```

### 6. Hardcoding Paths

❌ **Wrong:**
```fish
-v "/home/john/.config/goose:/home/john/.config/goose"
```

✅ **Correct:**
```fish
-v "$HOME/.config/goose:$HOME/.config/goose"
# or
-v "$HOME/.config/goose:/home/$USER/.config/goose"
```

### 7. Not Cleaning Up Environment Variables

❌ **Wrong:**
```fish
function mytool-container
    set -x MYTOOL_CONFIG "$HOME/.config/mytool"
    __container_launcher "ai-ubuntu:latest" "mytool" $argv
    # Missing cleanup!
end
```

✅ **Correct:**
```fish
function mytool-container
    set -x MYTOOL_CONFIG "$HOME/.config/mytool"
    __container_launcher "ai-ubuntu:latest" "mytool" $argv
    set -e MYTOOL_CONFIG  # Clean up
end
```

### 8. Installing Packages Without Cleanup

❌ **Wrong (Dockerfile):**
```dockerfile
RUN apt-get update && apt-get install -y package1 package2
```

✅ **Correct:**
```dockerfile
RUN apt-get update && apt-get install -y \
    package1 \
    package2 \
    && rm -rf /var/lib/apt/lists/*
```

**Why**: Reduces image size by removing apt cache.

## Contribution Guidelines

### Adding New Tools

1. **Update Dockerfile** to install the tool
2. **Create wrapper function** in `fish/conf.d/container-launcher.fish`:
   ```fish
   function newtool-container --description "Run newtool in container"
       set -x NEWTOOL_CONFIG "$HOME/.config/newtool"
       __container_launcher "ai-ubuntu:latest" "newtool" $argv
       set -e NEWTOOL_CONFIG
   end
   ```
3. **Test thoroughly** (see Testing Approach above)
4. **Update documentation** (README.md, fish/README.md)

### Modifying Core Launcher

**⚠️ Be extremely careful** when modifying `__container_launcher` or helper functions.

**Before modifying:**
- Understand the security implications
- Test with multiple tools (goose, copilot, bash)
- Verify git root detection still works
- Check that mounts remain read-only where needed

**Testing checklist:**
- [ ] Works in git repo root
- [ ] Works in git repo subdirectory
- [ ] Works outside git repos
- [ ] SSH agent forwarding still works
- [ ] Git credentials still accessible
- [ ] Work hooks still function
- [ ] Verbose output is clear

### Code Style

#### Fish Shell
- Use descriptive function names
- Add `--description` to all public functions
- Use `test` instead of `[ ]`
- Prefer `string` functions over external tools
- Check existence before mounting: `test -e $path`
- Use verbose output for debugging: `__container_print_verbose`

#### Bash/Shell Scripts
- Use `#!/usr/bin/env bash` shebang
- Set error handling: `set -euo pipefail`
- Quote variables: `"$variable"`
- Use `$(command)` instead of backticks
- Add comments for non-obvious logic

#### Dockerfile
- Group related `RUN` commands
- Always clean up apt cache: `rm -rf /var/lib/apt/lists/*`
- Use build args for customization
- Comment WHY, not WHAT
- Sort package lists alphabetically for readability

### Documentation

When making changes, update:
- **README.md**: High-level overview and quick start
- **fish/README.md**: Fish-specific usage and troubleshooting
- **docker/BUILD_HOOKS.md**: If modifying build system
- **This file**: If changing patterns or adding common pitfalls

### Commit Messages

Follow conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(fish): add support for custom tmpdir per tool

- Allow tools to specify unique tmpdir patterns
- Update __container_launcher to accept tmpdir_pattern param
- Maintain backward compatibility with default behavior

Closes #42
```

```
fix(dockerfile): ensure ripgrep is installed

ripgrep (rg) is critical for AI assistants to search code.
The package was accidentally removed in cleanup.

Fixes #38
```

```
docs(security): clarify read-only mount requirements

Add examples of correct and incorrect patterns for mounting
credentials. Emphasize the security implications.
```

## AI Assistant Guidance

When GitHub Copilot (or similar AI) is helping with this codebase:

### Understand the Context
- This is a **Podman** project, not Docker
- Security is **critical**: credentials must be read-only
- The launcher pattern is **generic**: changes affect all tools
- Users may have **custom hooks**: don't break extensibility

### Suggest Secure Defaults
- Always suggest `:ro` for credentials and config files
- Use `--userns=keep-id` for user namespace mapping
- Mount SSH agent socket, don't copy keys
- Suggest unique tmpdirs for isolation

### Respect Patterns
- Follow the `{tool}-container` naming convention
- Use helper functions (`__container_*`) for common operations
- Clean up environment variables after use
- Use verbose output for debugging

### Test Suggestions
When suggesting code changes:
1. Consider impact on existing tools
2. Suggest testing steps
3. Note potential security implications
4. Recommend documentation updates

## Questions or Issues?

When encountering issues:

1. **Enable verbose mode**: `set -x CONTAINER_VERBOSE 1`
2. **Check mounts**: Look for read-only flags and correct paths
3. **Verify UID/GID**: Ensure container user matches host
4. **Test in bash**: Use `goose-container bash` to inspect environment
5. **Review security**: Credentials should be read-only
6. **Check git root**: Should mount full repo, not just CWD

For bugs or feature requests, open an issue with:
- Clear description of the problem
- Steps to reproduce
- Output of verbose mode (if applicable)
- Your environment (OS, Podman version, Fish version)

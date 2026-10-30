# AI Tools Container Images

Multi-layered container setup for AI coding assistants with shared base tools.

## Architecture

```
ai-base:latest (foundation)
├── ai-goose:latest (Goose AI assistant)
├── ai-hermes:latest (Hermes AI agent)
├── ai-copilot:latest (GitHub Copilot CLI)
├── ai-opencode:latest (OpenCode, Ford build)
└── ai-fordllm-proxy:latest (Ford LLM OAuth → OpenAI-compatible proxy)
```

**Base Image** (`ai-base`) provides:
- Shell tools: ripgrep, fd, jq, git, etc.
- Python 3 + venv with common packages
- Node.js + npm with security configs
- Build tools: gcc, make, cmake, clang-format
- Network analysis: tshark, tcpdump, nmap
- User setup matching host UID/GID

**Agent Images** add specific AI tools on top of the base.

## Quick Start

### 1. Install Podman

```bash
sudo apt update
sudo apt install podman
```

### 2. Build All Images

```bash
./build-all.sh
```

Or build individually:

```bash
# Build base first (required)
cd base && ./build.sh && cd ..

# Then build specific agents
cd goose && ./build.sh && cd ..
cd hermes && ./build.sh && cd ..
cd copilot && ./build.sh && cd ..
cd opencode && ./build.sh && cd ..
```

### 3. Update Fish Functions

Update your fish function to use the new image names:

```fish
# For Goose
set -l IMAGE "ai-goose:latest"

# For Hermes
set -l IMAGE "ai-hermes:latest"

# For Copilot
set -l IMAGE "ai-copilot:latest"

# For OpenCode
set -l IMAGE "ai-opencode:latest"
```

### 4. Run

```bash
goose-container      # or whatever your fish function is named
```

## Build Options

### Base Image

```bash
cd base
./build.sh --help

Options:
  --tag TAG          Image tag (default: latest)
  --username NAME    Username inside container (default: developer)
  --uid UID          User ID (default: 1000; prefer keep-id at runtime)
  --gid GID          Group ID (default: 1000; prefer keep-id at runtime)
```

> **Portable by default:** images ship a fixed `developer` user (UID/GID `1000`).
> You align ownership with your host at *runtime* via `--userns=keep-id` — you do
> not need to rebuild per machine. See
> [Portable user identity & file ownership](#portable-user-identity--file-ownership-userns-keep-id).

### Agent Images

```bash
cd goose  # or hermes, copilot
./build.sh --help

Options:
  --tag TAG          Image tag (default: latest)
  --base IMAGE       Base image to use (default: ai-base:latest)
  --username NAME    Username inside container (default: developer)
```

### Build All

```bash
./build-all.sh --help

Options:
  --skip-base        Skip building the base image
  --only AGENTS      Only build specified agents (comma-separated)
                     Example: --only goose,hermes
```

Examples:

```bash
# Rebuild just one agent (after base is built)
./build-all.sh --skip-base --only goose

# Rebuild only specific agents
./build-all.sh --only goose,copilot

# Full rebuild
./build-all.sh
```

## Directory Structure

```
.
├── base/
│   ├── Dockerfile       # Base image with all common tools
│   └── build.sh         # Build script for base
├── goose/
│   ├── Dockerfile       # Goose-specific additions
│   ├── build.sh         # Build script for goose
│   └── build-local.sh   # Optional: local customizations (gitignored)
├── hermes/
│   ├── Dockerfile       # Hermes-specific additions (TODO: complete)
│   └── build.sh         # Build script for hermes
├── copilot/
│   ├── Dockerfile       # GitHub Copilot CLI
│   └── build.sh         # Build script for copilot
├── opencode/
│   ├── Dockerfile       # OpenCode (Ford build) from a local binary
│   ├── build.sh         # Build script (--binary PATH to choose the binary)
│   └── opencode.jsonc   # Ford managed config -> /etc/opencode/opencode.jsonc
├── fordllm-proxy/
│   ├── Dockerfile       # Ford LLM OAuth → OpenAI-compatible proxy
│   └── build.sh         # Build script for the proxy (needs Ford VPN)
├── build-all.sh         # Build everything in order
├── Dockerfile           # Legacy monolithic (kept for reference)
└── README.md            # This file
```

## Migration from Monolithic Dockerfile

The original `Dockerfile` is still present for reference. Key changes:

**Before:**
```bash
podman build -t ai-ubuntu:latest .
```

**After:**
```bash
./build-all.sh
# Creates: ai-base:latest, ai-goose:latest, ai-hermes:latest, ai-copilot:latest
```

**Fish Function Updates:**

Change from:
```fish
set -l IMAGE "goose-ubuntu:latest"
```

To:
```fish
set -l IMAGE "ai-goose:latest"
```

## Customization

### Adding Tools to Base Image

Edit `base/Dockerfile` to add tools that **all** agents should have:

```dockerfile
RUN apt-get update && apt-get install -y \
    your-new-tool \
    && rm -rf /var/lib/apt/lists/*
```

Then rebuild:
```bash
cd base && ./build.sh && cd ..
./build-all.sh --skip-base  # Rebuild agents with new base
```

### Adding Agent-Specific Tools

Edit the specific agent's `Dockerfile` (e.g., `goose/Dockerfile`):

```dockerfile
RUN npm install -g some-goose-specific-tool
```

Then rebuild just that agent:
```bash
cd goose && ./build.sh && cd ..
```

### Build Hooks (Private Customizations)

Create `goose/build-local.sh` for private/secret installations:

```bash
#!/bin/bash
# Install proprietary tools, private packages, etc.
pip install my-private-package
```

Add to `.gitignore` to keep it private. The build script will automatically use it if present.

## Tools Included

### Base Image Tools

**Critical for AI Agents:**
- `ripgrep` (rg) - Fast code search
- `fd` - Fast file finding
- `git` - Version control
- `jq` - JSON processing

**Development:**
- Python 3 + pip + venv
- Node.js + npm
- Build tools (gcc, make, cmake)
- clang-format + git-clang-format

**Network Analysis:**
- tshark, tcpdump, nmap
- Python: scapy, dpkt, pyshark

**Python Packages:**
- Document processing: pypdf, pdfplumber, pymupdf
- Data: pyyaml, jinja2
- Network: python-can, cantools
- Linting: yamllint

### Goose Image Additions
- Goose binary (latest release)
- mcp-atlassian npm package

### Hermes Image Additions
- TODO: Add Hermes installation instructions
- Visit: https://hermes-agent.nousresearch.com/

### Copilot Image Additions
- GitHub Copilot CLI (@githubnext/github-copilot-cli)

### OpenCode Image Additions (`ai-opencode`)
- Ford build of `opencode` at `/usr/local/bin/opencode`, from a manually downloaded
  release (https://github.com/ford-innersource/Mach1MLTools-opencode-ford/releases).
  The binary is gitignored; `build.sh` stages it into `opencode/bin/`:
  ```bash
  cd opencode
  ./build.sh                                   # default: ./opencode-v1.19.3-ford-r15-linux-amd64/opencode
  ./build.sh --binary /path/to/newer/opencode  # use a different binary
  ```
- `opencode/opencode.jsonc` installed as **managed config** at
  `/etc/opencode/opencode.jsonc` (share disabled, autoupdate off, provider
  allowlist). It applies from any directory and overrides user config.
- Runtime: the `opencode-container` fish function mounts the host's
  `~/.config/opencode`, `~/.local/share/opencode` (auth + sessions DB),
  `~/.local/state/opencode` and `~/.cache/opencode`, so the container shares host
  login and sessions. Don't run host and container opencode against the same DB
  at the same time.

### Ford LLM Proxy Additions (`ai-fordllm-proxy`)
- [`fordllm_proxy`](https://github.com/ford-innersource/fordllm_proxy) cloned to
  `/opt/fordllm_proxy`, dependencies installed via `uv sync`
- Exposes an OpenAI-compatible endpoint on port `5050`, bound to `0.0.0.0`

See [Using Ford LLM models (glm, GPT, etc.)](#using-ford-llm-models-glm-gpt-etc)
for how to build, run, and connect an agent to it.

## Using Ford LLM models (glm, GPT, etc.)

Ford's coding assistants don't talk to the model API directly. As Ford's docs
state, *"for automation/cli tools, use the `fordllm_proxy`."* The proxy performs
Ford's OAuth2 `client_credentials` flow and exposes a **standard
OpenAI-compatible** endpoint. Any CLI that supports a custom OpenAI base URL
(Copilot CLI, Hermes, OpenCode, …) can use it.

**One proxy serves all models at once.** You do not run one proxy per model —
a single running proxy forwards the `model` field of each request to the Ford
LLM API, so you pick the model by its ID (e.g. a `glm` slug) per session/request.

> Requires the **Ford network / VPN** and **Ford LLM API credentials**
> (`FORDLLM_CLIENT_ID` + `FORDLLM_CLIENT_SECRET`) for both build and run.
> Available model IDs are listed on Ford's models-features page and by
> `curl http://127.0.0.1:5050/v1/models`.

### 1. Build the proxy image

```bash
cd fordllm-proxy && ./build.sh && cd ..
# or:
./build-all.sh --skip-base --only fordllm-proxy
```

`build.sh` mounts your `~/.gitconfig` / `~/.netrc` as build secrets so it can
clone the private proxy repo. Ensure git can authenticate to github.com.

### 2. Run the proxy

Put your credentials in an env file (keep it out of git), e.g.
`~/.config/fordllm/.env`:

```bash
FORDLLM_CLIENT_ID=your-client-id
FORDLLM_CLIENT_SECRET=your-client-secret
```

Start it on a shared podman network so agent containers can reach it by name:

```bash
podman network create ai-net 2>/dev/null || true
podman run -d --rm --name fordllm-proxy \
  --network ai-net \
  --env-file ~/.config/fordllm/.env \
  -p 127.0.0.1:5050:5050 \
  ai-fordllm-proxy:latest

# Verify + discover valid model IDs (find the glm slug here):
curl http://127.0.0.1:5050/v1/models
```

### 3. Point an agent container at it

Run the agent on the **same** `--network ai-net`; the proxy is reachable at the
container name `fordllm-proxy`. For Copilot CLI (BYOK env vars):

```bash
podman run -it --rm \
  --network ai-net \
  --userns=keep-id:uid=1000,gid=1000 \
  -e COPILOT_PROVIDER_BASE_URL=http://fordllm-proxy:5050/v1 \
  -e COPILOT_PROVIDER_API_KEY=dummy \
  -e COPILOT_MODEL=<glm-slug-from-/v1/models> \
  -e COPILOT_PROVIDER_MAX_PROMPT_TOKENS=256000 \
  -e COPILOT_PROVIDER_MAX_OUTPUT_TOKENS=65536 \
  ai-copilot:latest
```

Hermes (or any OpenAI-compatible CLI) uses the same base URL
(`http://fordllm-proxy:5050/v1`), API key `dummy`, and a model ID of your choice
— switch models just by changing the model ID.

> **Networking note:** the proxy binds to `0.0.0.0` inside the image on purpose.
> If instead you publish it to the host and *don't* share a network, agent
> containers reach it via `http://host.containers.internal:5050/v1`, not
> `127.0.0.1` (which is the agent container itself).

### Base image not found

```bash
Error: Base image 'ai-base:latest' not found!
```

Solution: Build the base image first:
```bash
cd base && ./build.sh && cd ..
```

### Rebuild after changing base

If you modify `base/Dockerfile`, rebuild everything:
```bash
cd base && ./build.sh && cd ..
./build-all.sh --skip-base  # Rebuilds all agents
```

Or rebuild individual agents:
```bash
cd goose && ./build.sh && cd ..
```

### Image size concerns

Check image sizes:
```bash
podman images | grep ai-
```

The base image should be largest (~2-3GB). Agent images add minimal overhead (~50-200MB each).

### UID/GID mismatch — files owned by `root` (or wrong user) inside the container

With **rootless podman**, if you *don't* pass `--userns=keep-id`, your host user
is mapped to container **root** — so bind-mounted files you own on the host show
up as `root:root` inside the container (even though the host ownership is fine).
This breaks tools like `gpg` that require the running user to own their config
directory.

**Fix:** run with keep-id so your host UID/GID map onto the container's
`developer` user (UID/GID 1000):

```bash
podman run --userns=keep-id:uid=1000,gid=1000 ... ai-copilot:latest
```

See [Portable user identity & file ownership](#portable-user-identity--file-ownership-userns-keep-id)
for the full explanation.

## Portable user identity & file ownership (`--userns=keep-id`)

These images ship a **fixed** user — `developer`, UID/GID **1000** — instead of
baking your host UID at build time. This makes a single image portable across
machines where your host UID differs (e.g. `1000` on one box, `1001` or `501`
elsewhere). You reconcile the difference at **runtime**, not build time.

**How rootless podman maps UIDs:**

| Run flags | Host `you` (e.g. 1001) maps to… | Mounted files you own appear as… |
| --- | --- | --- |
| *(none)* | container `root` (0) | `root:root` ❌ (breaks gpg, confusing) |
| `--userns=keep-id` | same number inside (1001) | `1001` — but no matching user → `I have no name!` if it ≠ 1000 |
| `--userns=keep-id:uid=1000,gid=1000` | container `developer` (1000) | `developer` ✅ everything lines up |

**Always run with:**

```bash
podman run --userns=keep-id:uid=1000,gid=1000 \
  -v "$PWD:/home/developer/workspace" -w /home/developer/workspace \
  ai-copilot:latest
```

Notes:
- `keep-id:uid=,gid=` needs **podman ≥ 4.3**. On older podman use plain
  `--userns=keep-id` *and* build the image with `--uid $(id -u) --gid $(id -g)`.
- Mount into `/home/developer/...` (the fixed home), regardless of your host
  username.
- **Rootful Docker / `sudo podman`:** no keep-id — use `--user $(id -u):$(id -g)`
  (and daemon `userns-remap` if needed). **Docker Desktop (macOS/Windows)** maps
  ownership via its VM and generally "just works" without keep-id.

### `~/.gnupg` shows as `root` / gpg refuses to use it

Two things must both be true:

1. On the host, `~/.gnupg` must be owned by you and mode `700`
   (gpg refuses otherwise):
   ```bash
   chmod 700 ~/.gnupg && find ~/.gnupg -type f -exec chmod 600 {} +
   ```
   Stow symlinks are fine — podman follows the symlink and mounts the real
   target.
2. Run with `--userns=keep-id:uid=1000,gid=1000` so the mounted dir appears
   owned by the container user gpg runs as. Mount it at `/home/developer/.gnupg`.

## Adding New Agents

To add a new AI agent (e.g., "aider"):

1. Create directory:
```bash
mkdir aider
```

2. Create `aider/Dockerfile`:
```dockerfile
ARG BASE_IMAGE=ai-base:latest
FROM ${BASE_IMAGE}

USER root
# Install aider
RUN pip install aider-chat

ARG LOCAL_USERNAME=developer
USER ${LOCAL_USERNAME}
WORKDIR /home/${LOCAL_USERNAME}

CMD ["aider"]
```

3. Create `aider/build.sh` (copy from another agent, change names)

4. Update `build-all.sh` to include "aider" in `AGENTS_TO_BUILD`

5. Build:
```bash
cd aider && ./build.sh && cd ..
```

## Security Notes

- **File ownership:** Run with `--userns=keep-id:uid=1000,gid=1000` so bind
  mounts are owned by the container `developer` user (see
  [Portable user identity & file ownership](#portable-user-identity--file-ownership-userns-keep-id)).
- **SSH Keys:** Mount read-only (`:ro`) - agents can use but not modify
- **Git Credentials:** Mount read-only
- **GPG (`~/.gnupg`):** Must be `700` and owned by you on the host, mounted at
  `/home/developer/.gnupg` with keep-id, or gpg will refuse it
- **Workspace:** Mount read-write - agents can modify project files
- **npm Security:** Base image includes supply chain protection
  - `min-release-age=7` - Only packages published 7+ days ago
  - `audit=true` - Enable security audits
- **Sudo:** Enabled but contained to podman user namespace

## Performance

**Build Times (approximate):**
- Base image: 5-10 minutes (first time)
- Agent images: 1-2 minutes each
- Subsequent builds: Faster due to layer caching

**Disk Usage:**
- Base image: ~2-3 GB
- Each agent: +50-200 MB
- Total for all: ~3-4 GB

## Next Steps

1. ✓ Build images: `./build-all.sh`
2. Update fish functions to use new image names
3. Test each agent: `podman run -it --rm ai-goose:latest`
4. Set up fish functions with proper mounts (see original README)
5. Complete Hermes installation in `hermes/Dockerfile`

## Original Monolithic Setup

The original single `Dockerfile` is preserved for reference. It built everything into one large image (`ai-ubuntu:latest`).

**Advantages of Split Architecture:**
- ✓ Smaller per-agent images
- ✓ Faster rebuilds (only rebuild what changed)
- ✓ Easier to maintain (separation of concerns)
- ✓ Can run multiple agents simultaneously
- ✓ Add new agents without rebuilding everything

**Disadvantages:**
- Need to manage multiple images
- Base image must be built first
- Slightly more complex build process

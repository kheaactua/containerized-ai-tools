#!/usr/bin/env bash
# Build script for goose-in-podman container image
# Builds a multi-purpose AI tools container with Goose, development tools, etc.

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building goose-in-podman container image..."

# Prepare secret mount for git credentials if they exist
SECRET_ARGS=()
if [ -f "$HOME/.gitconfig" ]; then
    echo "📝 Mounting git credentials as build secret..."
    SECRET_ARGS+=(--secret "id=gitconfig,src=$HOME/.gitconfig")
fi

# Build with your current UID/GID so permissions match inside the container
podman build \
    --build-arg LOCAL_UID="$(id -u)" \
    --build-arg LOCAL_GID="$(id -g)" \
    --build-arg LOCAL_USERNAME="$(whoami)" \
    "${SECRET_ARGS[@]}" \
    -f Dockerfile \
    -t ai-ubuntu:latest \
    . ||
    {
        echo "❌ Build failed!"
        exit 1
    }

echo ""
echo "✅ Build complete!"
echo ""
echo "Test it with:"
echo "  podman run -it --rm ai-ubuntu:latest bash"
echo ""
echo "Or use the Fish plugin functions:"
echo "  goose-container"
echo "  copilot-container"

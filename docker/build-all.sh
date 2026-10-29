#!/bin/bash
# Build all AI tool images in the correct order
# 1. Base image (foundation)
# 2. Agent images (goose, hermes, etc.)

set -e

echo "========================================="
echo "Building AI Tools - Complete Suite"
echo "========================================="
echo ""

# Parse command line arguments
SKIP_BASE=false
AGENTS_TO_BUILD=("goose" "hermes" "copilot")

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-base)
            SKIP_BASE=true
            shift
            ;;
        --only)
            IFS=',' read -ra AGENTS_TO_BUILD <<< "$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --skip-base        Skip building the base image"
            echo "  --only AGENTS      Only build specified agents (comma-separated)"
            echo "                     Example: --only goose,hermes"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Build base image first (unless skipped)
if [ "$SKIP_BASE" = false ]; then
    echo "Step 1/2: Building base image..."
    echo "-----------------------------------------"
    (cd base && ./build.sh)
    echo ""
else
    echo "Skipping base image build (--skip-base)"
    echo ""
fi

# Build agent images
echo "Step 2/2: Building agent images..."
echo "-----------------------------------------"

for agent in "${AGENTS_TO_BUILD[@]}"; do
    if [ -d "$agent" ] && [ -f "$agent/build.sh" ]; then
        echo ""
        echo "Building $agent..."
        (cd "$agent" && ./build.sh)
    else
        echo "Warning: Agent '$agent' not found or has no build.sh"
    fi
done

echo ""
echo "========================================="
echo "✓ Build complete!"
echo "========================================="
echo ""
echo "Available images:"
podman images | grep -E "^(ai-base|ai-goose|ai-hermes|ai-copilot)" || echo "  (none found - check for errors above)"
echo ""
echo "Next steps:"
echo "  1. Test an image: podman run -it --rm ai-goose:latest"
echo "  2. Update your fish functions to use the new image names"
echo "  3. See README.md for usage details"

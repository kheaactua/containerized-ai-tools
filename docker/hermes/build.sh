#!/bin/bash
# Build script for Hermes AI agent image
# Requires ai-base image to be built first

set -e

# Default values
IMAGE_NAME="ai-hermes"
IMAGE_TAG="latest"
BASE_IMAGE="ai-base:latest"
LOCAL_USERNAME="developer"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --base)
            BASE_IMAGE="$2"
            shift 2
            ;;
        --username)
            LOCAL_USERNAME="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --tag TAG          Image tag (default: latest)"
            echo "  --base IMAGE       Base image to use (default: ai-base:latest)"
            echo "  --username NAME    Username inside container (default: developer)"
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

# Check if base image exists
if ! podman image exists "${BASE_IMAGE}"; then
    echo "Error: Base image '${BASE_IMAGE}' not found!"
    echo "Please build the base image first:"
    echo "  cd ../base && ./build.sh"
    exit 1
fi

echo "Building ${IMAGE_NAME}:${IMAGE_TAG}..."
echo "  Base image: ${BASE_IMAGE}"
echo "  Username: ${LOCAL_USERNAME}"

# Build the hermes image
podman build \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    --build-arg LOCAL_USERNAME="${LOCAL_USERNAME}" \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    .

echo ""
echo "✓ Hermes image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "Run with (map your host UID/GID onto the container user):"
echo "  podman run -it --rm --userns=keep-id:uid=1000,gid=1000 ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "To configure Hermes, you'll need to:"
echo "  1. Set up API keys for your LLM provider(s)"
echo "  2. Configure your Hermes profile"
echo "Visit: https://hermes-agent.nousresearch.com/docs for details"

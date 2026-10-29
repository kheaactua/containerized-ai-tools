#!/bin/bash
# Build script for AI base image
# This creates the foundation image that other AI agents build upon

set -e

# Default values
# Fixed identity for a portable image (see base/Dockerfile). At runtime, map your
# host UID/GID onto this user with: --userns=keep-id:uid=1000,gid=1000
IMAGE_NAME="ai-base"
IMAGE_TAG="latest"
LOCAL_USERNAME="developer"
LOCAL_UID=1000
LOCAL_GID=1000

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  --tag)
    IMAGE_TAG="$2"
    shift 2
    ;;
  --username)
    LOCAL_USERNAME="$2"
    shift 2
    ;;
  --uid)
    LOCAL_UID="$2"
    shift 2
    ;;
  --gid)
    LOCAL_GID="$2"
    shift 2
    ;;
  --help)
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --tag TAG    Image tag (default: latest)"
    echo "  --username NAME  Username inside container (default: developer)"
    echo "  --uid UID    User ID (default: 1000; prefer keep-id at runtime)"
    echo "  --gid GID    Group ID (default: 1000; prefer keep-id at runtime)"
    echo "  --help     Show this help message"
    exit 0
    ;;
  *)
    echo "Unknown option: $1"
    echo "Use --help for usage information"
    exit 1
    ;;
  esac
done

echo "Building ${IMAGE_NAME}:${IMAGE_TAG}..."
echo "  Username: ${LOCAL_USERNAME}"
echo "  UID: ${LOCAL_UID}"
echo "  GID: ${LOCAL_GID}"

# Build the base image
podman build \
  --build-arg LOCAL_USERNAME="${LOCAL_USERNAME}" \
  --build-arg LOCAL_UID="${LOCAL_UID}" \
  --build-arg LOCAL_GID="${LOCAL_GID}" \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  .

echo ""
echo "✓ Base image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "Tip: run agent containers with matching host ownership via:"
echo "  --userns=keep-id:uid=${LOCAL_UID},gid=${LOCAL_GID}"
echo ""
echo "Next steps:"
echo "  1. Build agent images: cd ../goose && ./build.sh"
echo "  2. Or build all: cd .. && ./build-all.sh"

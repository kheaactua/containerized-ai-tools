#!/bin/bash
# Build script for OpenCode (Ford build) image
# Requires ai-base image to be built first
#
# The opencode binary is not committed. Point --binary at a downloaded/extracted
# release binary; it is staged into ./bin/opencode (gitignored) for the build.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Default values
IMAGE_NAME="ai-opencode"
IMAGE_TAG="latest"
BASE_IMAGE="ai-base:latest"
LOCAL_USERNAME="developer"
# TODO: replace with a proper download/pinning step once sourcing is sorted out.
OPENCODE_BINARY="${SCRIPT_DIR}/opencode-v1.19.3-ford-r15-linux-amd64/opencode"

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
        --binary)
            OPENCODE_BINARY="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --tag TAG          Image tag (default: latest)"
            echo "  --base IMAGE       Base image to use (default: ai-base:latest)"
            echo "  --username NAME    Username inside container (default: developer)"
            echo "  --binary PATH      opencode binary to install"
            echo "                     (default: ./opencode-v1.19.3-ford-r15-linux-amd64/opencode)"
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

# Check the binary exists
if [ ! -f "${OPENCODE_BINARY}" ]; then
    echo "Error: opencode binary not found at '${OPENCODE_BINARY}'"
    echo "Download a release from:"
    echo "  https://github.com/ford-innersource/Mach1MLTools-opencode-ford/releases"
    echo "then pass it with: $0 --binary /path/to/opencode"
    exit 1
fi

# Stage the binary into the build context
mkdir -p bin
cp "${OPENCODE_BINARY}" bin/opencode
chmod 755 bin/opencode
OPENCODE_VERSION="$(bin/opencode --version 2>/dev/null || echo unknown)"

echo "Building ${IMAGE_NAME}:${IMAGE_TAG}..."
echo "  Base image: ${BASE_IMAGE}"
echo "  Username:   ${LOCAL_USERNAME}"
echo "  Binary:     ${OPENCODE_BINARY} (${OPENCODE_VERSION})"

# Prepare build secrets if they exist
BUILD_ARGS=""

if [ -f "./build-local.sh" ]; then
    BUILD_ARGS="${BUILD_ARGS} --secret id=build-local,src=./build-local.sh"
    echo "  Using: build-local.sh"
fi

if [ -f "${HOME}/.gitconfig" ]; then
    BUILD_ARGS="${BUILD_ARGS} --secret id=gitconfig,src=${HOME}/.gitconfig"
    echo "  Using: ~/.gitconfig"
fi

if [ -f "${HOME}/.netrc" ]; then
    BUILD_ARGS="${BUILD_ARGS} --secret id=netrc,src=${HOME}/.netrc"
    echo "  Using: ~/.netrc"
fi

# Build the opencode image
podman build \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    --build-arg LOCAL_USERNAME="${LOCAL_USERNAME}" \
    --label "opencode.version=${OPENCODE_VERSION}" \
    ${BUILD_ARGS} \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    .

echo ""
echo "✓ OpenCode image built successfully: ${IMAGE_NAME}:${IMAGE_TAG} (opencode ${OPENCODE_VERSION})"
echo ""
echo "Run with (map your host UID/GID onto the container user):"
echo "  podman run -it --rm --userns=keep-id:uid=1000,gid=1000 ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "Or use the fish function: opencode-container"

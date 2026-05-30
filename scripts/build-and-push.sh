#!/bin/bash

################################################################################
# Warrior LiveKit Agent - Docker Build & Push to GHCR
#
# Builds the agent + frontend images and pushes them to the GitHub Container
# Registry (GHCR), then makes both packages public so Akash can pull them
# anonymously.
#
# NOTE: This script must run on a host with a working Docker daemon (the
#       ability to build images). It auto-reads the GitHub token from
#       /home/ubuntu/.config/abacusai_auth_secrets.json when present, or takes
#       --token / GITHUB_TOKEN.
#
# Usage:
#   ./scripts/build-and-push.sh [OPTIONS]
#
# Options:
#   --tag VERSION       Extra version tag in addition to 'latest' (default: none)
#   --username USER     GitHub username/owner (default: princekoya-multiverse)
#   --token TOKEN       GitHub token with write:packages (default: from secrets file / env)
#   --no-push           Build only, don't push to registry
#   --no-public         Skip making the packages public
#   --help              Show this help message
################################################################################

set -euo pipefail

# Color codes for output
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[0;33m'
NC=$'\033[0m' # No Color

# Configuration
REGISTRY="ghcr.io"
NAMESPACE="princekoya-multiverse"
AGENT_IMAGE_NAME="warrior-agent"
FRONTEND_IMAGE_NAME="warrior-frontend"
AGENT_DOCKERFILE="docker/Dockerfile.agent"
FRONTEND_DOCKERFILE="docker/Dockerfile.frontend"
EXTRA_TAG=""
SHOULD_PUSH=true
SHOULD_MAKE_PUBLIC=true
GITHUB_USERNAME="princekoya-multiverse"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
SECRETS_FILE="/home/ubuntu/.config/abacusai_auth_secrets.json"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

################################################################################
# Helpers
################################################################################
print_header()  { echo -e "\n${BLUE}========================================${NC}\n${BLUE}$1${NC}\n${BLUE}========================================${NC}\n"; }
print_success() { echo -e "${GREEN}\xE2\x9C\x93 $1${NC}"; }
print_error()   { echo -e "${RED}\xE2\x9C\x97 $1${NC}"; }
print_info()    { echo -e "${BLUE}\xE2\x84\xB9 $1${NC}"; }
print_warning() { echo -e "${YELLOW}\xE2\x9A\xA0 $1${NC}"; }

show_help() { sed -n '3,30p' "$0"; }

load_token_from_secrets() {
    if [ -z "$GITHUB_TOKEN" ] && [ -f "$SECRETS_FILE" ]; then
        GITHUB_TOKEN="$(python3 -c "import json,sys; print(json.load(open('$SECRETS_FILE'))['githubuser']['secrets']['access_token']['value'])" 2>/dev/null || true)"
        [ -n "$GITHUB_TOKEN" ] && print_info "Loaded GitHub token from secrets file"
    fi
}

validate_docker() {
    print_info "Checking Docker installation..."
    command -v docker &> /dev/null || { print_error "Docker not found. Install Docker first."; exit 1; }
    docker info &> /dev/null || { print_error "Docker daemon is not running / not accessible."; exit 1; }
    print_success "Docker is ready"
}

login_ghcr() {
    print_info "Logging in to GitHub Container Registry..."
    if echo "$GITHUB_TOKEN" | docker login "$REGISTRY" -u "$GITHUB_USERNAME" --password-stdin &> /dev/null; then
        print_success "Authenticated with GHCR"
    else
        print_error "Failed to authenticate with GHCR. The token needs the 'write:packages' scope."
        exit 1
    fi
}

build_image() {
    local dockerfile=$1 image_name=$2
    local latest_tag="$REGISTRY/$NAMESPACE/$image_name:latest"
    print_info "Building: $latest_tag  (from $dockerfile)"
    local tags=(-t "$latest_tag")
    [ -n "$EXTRA_TAG" ] && tags+=(-t "$REGISTRY/$NAMESPACE/$image_name:$EXTRA_TAG")
    docker build -f "$PROJECT_ROOT/$dockerfile" "${tags[@]}" "$PROJECT_ROOT"
    print_success "Built: $image_name"
}

push_image() {
    local image_name=$1
    print_info "Pushing: $REGISTRY/$NAMESPACE/$image_name:latest"
    docker push "$REGISTRY/$NAMESPACE/$image_name:latest"
    if [ -n "$EXTRA_TAG" ]; then
        docker push "$REGISTRY/$NAMESPACE/$image_name:$EXTRA_TAG"
    fi
    print_success "Pushed: $image_name"
}

# Make a user-owned container package public via the GitHub REST API.
make_public() {
    local image_name=$1
    print_info "Setting package public: $image_name"
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/user/packages/container/$image_name/visibility" \
        -d '{"visibility":"public"}' || echo "000")
    if [ "$code" = "204" ] || [ "$code" = "200" ]; then
        print_success "Package is public: $image_name"
    else
        print_warning "Could not auto-set visibility (HTTP $code). Set it manually at:"
        print_warning "  https://github.com/users/$GITHUB_USERNAME/packages/container/$image_name/settings"
    fi
}

print_summary() {
    print_header "Summary"
    echo "Images:"
    echo "  \xE2\x80\xA2 $REGISTRY/$NAMESPACE/$AGENT_IMAGE_NAME:latest"
    echo "  \xE2\x80\xA2 $REGISTRY/$NAMESPACE/$FRONTEND_IMAGE_NAME:latest"
    echo ""
    echo "deploy.yaml image references:"
    echo "  agent:    image: $REGISTRY/$NAMESPACE/$AGENT_IMAGE_NAME:latest"
    echo "  frontend: image: $REGISTRY/$NAMESPACE/$FRONTEND_IMAGE_NAME:latest"
    echo ""
}

################################################################################
# Parse Arguments
################################################################################
while [[ $# -gt 0 ]]; do
    case $1 in
        --tag)       EXTRA_TAG="$2"; shift 2;;
        --username)  GITHUB_USERNAME="$2"; shift 2;;
        --token)     GITHUB_TOKEN="$2"; shift 2;;
        --no-push)   SHOULD_PUSH=false; shift;;
        --no-public) SHOULD_MAKE_PUBLIC=false; shift;;
        --help)      show_help; exit 0;;
        *)           print_error "Unknown option: $1"; show_help; exit 1;;
    esac
done

################################################################################
# Main
################################################################################
print_header "Warrior LiveKit Agent - Docker Build & Push"

validate_docker

if [ "$SHOULD_PUSH" = true ]; then
    load_token_from_secrets
    [ -z "$GITHUB_TOKEN" ] && { print_error "No GitHub token. Use --token or set GITHUB_TOKEN."; exit 1; }
    login_ghcr
fi

print_header "Building Docker Images"
build_image "$AGENT_DOCKERFILE"    "$AGENT_IMAGE_NAME"
build_image "$FRONTEND_DOCKERFILE" "$FRONTEND_IMAGE_NAME"

if [ "$SHOULD_PUSH" = true ]; then
    print_header "Pushing to GHCR"
    push_image "$AGENT_IMAGE_NAME"
    push_image "$FRONTEND_IMAGE_NAME"

    if [ "$SHOULD_MAKE_PUBLIC" = true ]; then
        print_header "Setting Image Visibility (public)"
        make_public "$AGENT_IMAGE_NAME"
        make_public "$FRONTEND_IMAGE_NAME"
    fi
else
    print_info "Skipping push (--no-push set)"
fi

print_summary
print_success "Done."

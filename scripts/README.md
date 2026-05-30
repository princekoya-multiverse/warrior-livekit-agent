# Deployment Scripts

Helper scripts for deploying Warrior LiveKit Agent to Akash Network.

## Available Scripts

### `build-and-push.sh`
Automates Docker image building and pushing to GitHub Container Registry (GHCR).

**Usage:**
```bash
./build-and-push.sh [OPTIONS]

Options:
  --tag VERSION       Docker image tag version (default: v1.0.0)
  --username USER     GitHub username
  --token TOKEN       GitHub PAT token
  --no-push           Build only, don't push
  --help              Show help
```

**Example:**
```bash
./build-and-push.sh --tag v1.0.0 --username your-username --token your-pat
```

The script:
1. ✓ Validates Docker installation
2. ✓ Authenticates with GHCR
3. ✓ Builds agent image
4. ✓ Builds frontend image
5. ✓ Pushes both to GHCR
6. ✓ Optionally makes images public (requires GitHub CLI)

**Requirements:**
- Docker installed and running
- GitHub Personal Access Token with `write:packages` scope
- Docker images successfully build

---

## Quick Start

```bash
# 1. Set your GitHub token
export GITHUB_TOKEN="your_github_pat"

# 2. Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# 3. Run the build script
./build-and-push.sh --tag v1.0.0 --username YOUR_USERNAME --token $GITHUB_TOKEN

# 4. Verify images are available
docker images | grep princekoya-multiverse
```

---

## Troubleshooting

**Docker not running:**
```bash
# Start Docker daemon
sudo systemctl start docker
# or on macOS: Open Docker Desktop
```

**GHCR authentication fails:**
```bash
# Verify PAT has correct scopes (write:packages)
# Regenerate token if needed: https://github.com/settings/tokens
```

**Build fails:**
```bash
# Check Dockerfile paths are correct
ls docker/Dockerfile.agent
ls docker/Dockerfile.frontend

# Try manual build for debugging
docker build -f docker/Dockerfile.agent -t test:latest .
```

---

## Manual Build & Push

If you prefer to run manually instead of using the script:

```bash
cd /home/ubuntu/warrior-livekit-agent

# Build agent
docker build -f docker/Dockerfile.agent \
  -t ghcr.io/princekoya-multiverse/warrior-agent:latest .

# Build frontend
docker build -f docker/Dockerfile.frontend \
  -t ghcr.io/princekoya-multiverse/warrior-frontend:latest .

# Push agent
docker push ghcr.io/princekoya-multiverse/warrior-agent:latest

# Push frontend
docker push ghcr.io/princekoya-multiverse/warrior-frontend:latest

# Make images public on GitHub UI:
# https://github.com/princekoya-multiverse?tab=packages
```

---

*Part of Warrior LiveKit Agent Akash Deployment Suite*

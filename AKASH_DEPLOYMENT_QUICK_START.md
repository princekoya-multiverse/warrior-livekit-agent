# Akash Deployment Quick Start: Warrior LiveKit Agent

> **Status:** Ready to deploy | **Credits:** ~$175 AKT available | **Domain:** warriorworld.life

---

## 1. Pre-Deployment Checklist

Before starting the deployment process, verify you have:

### Required Tools
- [ ] **Akash CLI** installed and configured
  ```bash
  akash version  # Should return version info
  ```
- [ ] **Docker** installed and running
  ```bash
  docker --version
  docker ps  # Should work without errors
  ```
- [ ] **GitHub CLI** (optional but recommended for registry auth)
  ```bash
  gh auth status  # Check authentication
  ```

### Required Access & Credentials
- [ ] **GitHub Personal Access Token (PAT)** with `write:packages` scope
  - Create at: https://github.com/settings/tokens
  - Used for pushing to GHCR
  - Store securely: `export GITHUB_TOKEN=<your-token>`

- [ ] **API Keys** available (will be added to deploy.yaml):
  - [ ] `LIVEKIT_URL` - Your LiveKit server endpoint
  - [ ] `LIVEKIT_API_KEY` - LiveKit API key
  - [ ] `LIVEKIT_API_SECRET` - LiveKit API secret
  - [ ] `DEEPGRAM_API_KEY` - Deepgram speech-to-text key
  - [ ] `OPENAI_API_KEY` - OpenAI API key (for Abacus AI integration)

### Akash Setup
- [ ] Akash account configured with available AKT credits
  ```bash
  akash query bank balances $(akash keys list --output json | jq -r '.[0].address')
  ```
- [ ] Current network configured (mainnet or testnet)
  ```bash
  echo $AKASH_CHAIN_ID  # Should show mainnet/testnet identifier
  ```

---

## 2. Docker Image Build & Push

### Step 1: Authenticate with GitHub Container Registry

```bash
# Export your GitHub PAT
export GITHUB_TOKEN="your_github_personal_access_token"

# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# Verify login
docker images | head -1  # Should not show authentication errors
```

### Step 2: Build Docker Images

Navigate to the project directory:
```bash
cd /home/ubuntu/warrior-livekit-agent
```

**Build the Agent Image:**
```bash
docker build \
  -f docker/agent.Dockerfile \
  -t ghcr.io/princekoya-multiverse/warrior-livekit-agent:latest \
  -t ghcr.io/princekoya-multiverse/warrior-livekit-agent:v1.0.0 \
  .
```

**Build the Frontend Image:**
```bash
docker build \
  -f docker/frontend.Dockerfile \
  -t ghcr.io/princekoya-multiverse/warrior-livekit-frontend:latest \
  -t ghcr.io/princekoya-multiverse/warrior-livekit-frontend:v1.0.0 \
  .
```

**Verify builds:**
```bash
docker images | grep princekoya-multiverse
```

### Step 3: Push Images to GHCR

**Push Agent Image:**
```bash
docker push ghcr.io/princekoya-multiverse/warrior-livekit-agent:latest
docker push ghcr.io/princekoya-multiverse/warrior-livekit-agent:v1.0.0
```

**Push Frontend Image:**
```bash
docker push ghcr.io/princekoya-multiverse/warrior-livekit-frontend:latest
docker push ghcr.io/princekoya-multiverse/warrior-livekit-frontend:v1.0.0
```

### Step 4: Make Images Public (Important!)

Go to GitHub and make both images public:

1. Navigate to: https://github.com/princekoya-multiverse?tab=packages
2. For each image:
   - Click the package name
   - Go to **Package settings** (gear icon)
   - Change visibility to **Public**
   - Save changes

**Verify public access:**
```bash
# These should work without authentication
docker pull ghcr.io/princekoya-multiverse/warrior-livekit-agent:latest
docker pull ghcr.io/princekoya-multiverse/warrior-livekit-frontend:latest
```

> **Tip:** Use the automated build script instead:
> ```bash
> bash scripts/build-and-push.sh
> ```

---

## 3. Akash Deployment Commands

### Step 1: Update deploy.yaml with Image Tags

Edit `deploy.yaml` and update all image references:

```yaml
services:
  agent:
    image: ghcr.io/princekoya-multiverse/warrior-livekit-agent:v1.0.0  # Update this
    
  frontend:
    image: ghcr.io/princekoya-multiverse/warrior-livekit-frontend:v1.0.0  # Update this
```

### Step 2: Create Akash Deployment

**Export Akash environment variables:**
```bash
# Set these based on your Akash configuration
export AKASH_NODE="https://rpc.mainnet.akash.network:443"  # or testnet
export AKASH_CHAIN_ID="akashnet-2"  # or testnet chain ID
export AKASH_KEYRING_BACKEND="os"
export AKASH_ACCOUNT_ADDRESS=$(akash keys list --output json | jq -r '.[0].address')
export AKASH_FROM="your-key-name"  # Your Akash key name
```

**Create the deployment:**
```bash
# 1. Get deployment price
akash tx deployment create deploy.yaml --from $AKASH_FROM --node $AKASH_NODE

# 2. Approve the transaction when prompted
# Should return deployment ID in the response
```

**Monitor deployment creation:**
```bash
# List your deployments
akash query deployment list --node $AKASH_NODE

# Get detailed deployment status
export DEPLOYMENT_ID="<deployment-id-from-response>"
akash query deployment get $DEPLOYMENT_ID --node $AKASH_NODE
```

### Step 3: Accept Provider Bid

Akash providers will bid on your deployment. Accept the best bid:

```bash
# List bids for your deployment
akash query market bid list --node $AKASH_NODE \
  --filters="dseq=$DEPLOYMENT_ID"

# Accept a bid (choose the provider with best specs/price)
export PROVIDER="<provider-address>"
akash tx market bid-close \
  --owner=$AKASH_ACCOUNT_ADDRESS \
  --dseq=$DEPLOYMENT_ID \
  --gseq=1 \
  --oseq=1 \
  --provider=$PROVIDER \
  --from=$AKASH_FROM \
  --node=$AKASH_NODE
```

### Step 4: Get Deployment URL/IP

```bash
# Get lease details
akash query market lease list --node $AKASH_NODE \
  --filters="dseq=$DEPLOYMENT_ID"

# Get deployment logs and access info
akash provider lease-logs $DEPLOYMENT_ID 1 1 $PROVIDER \
  --node=$AKASH_NODE

# Typical output will show:
# http://<deployment-id>.<provider-domain>
```

### Step 5: Check Deployment Status

```bash
# Real-time logs
akash provider lease-logs $DEPLOYMENT_ID 1 1 $PROVIDER \
  --follow \
  --node=$AKASH_NODE

# Services running
akash provider lease-status $DEPLOYMENT_ID 1 1 $PROVIDER \
  --node=$AKASH_NODE
```

---

## 4. Environment Variables Setup

All environment variables must be configured in `deploy.yaml` under the services section. Update these values before deployment:

### Required Environment Variables

```yaml
env:
  # LiveKit Configuration
  - name: LIVEKIT_URL
    value: "https://your-livekit-instance.example.com"
  
  - name: LIVEKIT_API_KEY
    value: "your-livekit-api-key"
  
  - name: LIVEKIT_API_SECRET
    value: "your-livekit-api-secret"
  
  # Deepgram Configuration (Speech-to-Text)
  - name: DEEPGRAM_API_KEY
    value: "your-deepgram-api-key"
  
  # OpenAI Configuration (for Abacus AI)
  - name: OPENAI_API_KEY
    value: "your-openai-api-key"
  
  # Optional: Node Environment
  - name: NODE_ENV
    value: "production"
  
  # Optional: Frontend Configuration
  - name: VITE_API_URL
    value: "https://your-deployment-url"
```

### Securing Sensitive Data

For production deployments, consider using Akash secrets (advanced):

```bash
# Create secret (Akash Enterprise feature)
akash tx cert create-client-cert \
  --from=$AKASH_FROM \
  --node=$AKASH_NODE
```

> **Note:** For now, use environment variables directly in deploy.yaml. In production, use a secrets manager or environment file approach.

---

## 5. Post-Deployment

### Access Your Deployment

Once deployment is live:

1. **Get the deployment URL:**
   ```bash
   # Usually formatted as: http://deployment-id.provider-domain
   akash provider lease-status $DEPLOYMENT_ID 1 1 $PROVIDER \
     --node=$AKASH_NODE | grep -i "port\|url"
   ```

2. **Access the application:**
   ```bash
   # Browser: https://your-deployment-url
   # Or: curl https://your-deployment-url
   ```

### Monitor Logs

**Streaming logs:**
```bash
akash provider lease-logs $DEPLOYMENT_ID 1 1 $PROVIDER \
  --tail=100 \
  --follow \
  --node=$AKASH_NODE
```

**Check specific service:**
```bash
akash provider lease-logs $DEPLOYMENT_ID 1 1 $PROVIDER \
  --tail=50 \
  --node=$AKASH_NODE
```

### Update Deployment

To update your deployment (new Docker image, config changes):

1. **Update deploy.yaml** with new image tags
2. **Create new deployment:**
   ```bash
   akash tx deployment create deploy.yaml --from $AKASH_FROM --node $AKASH_NODE
   ```
3. **Close old deployment (optional):**
   ```bash
   akash tx deployment close \
     --owner=$AKASH_ACCOUNT_ADDRESS \
     --dseq=$OLD_DEPLOYMENT_ID \
     --from=$AKASH_FROM \
     --node=$AKASH_NODE
   ```

### Configure Custom Domain

Next steps: Point `warriorworld.life` to your Akash deployment:

1. Get the deployment IP/URL from Akash
2. Update DNS records at freename.com:
   - Add CNAME or A record pointing to your deployment
   - Wait for DNS propagation (~5-15 minutes)
3. Update environment variables in deploy.yaml:
   ```yaml
   - name: FRONTEND_URL
     value: "https://warriorworld.life"
   ```
4. Redeploy if needed

---

## Quick Command Reference

```bash
# Full deployment workflow (copy-paste friendly)
export AKASH_NODE="https://rpc.mainnet.akash.network:443"
export AKASH_CHAIN_ID="akashnet-2"
export AKASH_FROM="your-key-name"
export AKASH_ACCOUNT_ADDRESS=$(akash keys list --output json | jq -r '.[0].address')

# 1. Check balance
akash query bank balances $AKASH_ACCOUNT_ADDRESS --node $AKASH_NODE

# 2. Create deployment
akash tx deployment create deploy.yaml --from $AKASH_FROM --node $AKASH_NODE

# 3. Accept bid (after reviewing bids)
akash tx market bid-close \
  --owner=$AKASH_ACCOUNT_ADDRESS \
  --dseq=<DEPLOYMENT_ID> \
  --gseq=1 --oseq=1 \
  --provider=<PROVIDER_ADDRESS> \
  --from=$AKASH_FROM \
  --node=$AKASH_NODE

# 4. Check logs
akash provider lease-logs <DEPLOYMENT_ID> 1 1 <PROVIDER_ADDRESS> \
  --follow \
  --node=$AKASH_NODE
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **GHCR push fails** | Verify GitHub PAT has `write:packages` scope; re-authenticate |
| **Bid not accepted** | Check if provider has capacity; wait for more bids |
| **Deployment not starting** | Check logs for environment variable errors |
| **High AKT cost** | Review specs in deploy.yaml; 3.5 vCPU / 4.5 GB is optimal |
| **Domain not resolving** | Wait for DNS propagation; verify freename.com settings |

---

## Resources

- **Akash Docs:** https://docs.akash.network/
- **Akash CLI Reference:** https://docs.akash.network/cli
- **GitHub Container Registry:** https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- **LiveKit Docs:** https://docs.livekit.io/
- **Project Repo:** https://github.com/princekoya-multiverse/warrior-livekit-agent

---

**Last Updated:** 2025  
**Maintenance:** Update image tags and environment variables as needed

# Akash Deployment Cheat Sheet

**Quick reference for Warrior LiveKit Agent deployment to Akash Network**

---

## 1️⃣ Pre-Flight Check (2 min)

```bash
# Verify Akash setup
akash version
echo $AKASH_CHAIN_ID  # Should show: akashnet-2

# Check balance
akash query bank balances $(akash keys list --output json | jq -r '.[0].address')
# Should show ~$175 AKT available
```

---

## 2️⃣ Build & Push Images (5-10 min)

### Option A: Automated Script (Recommended)
```bash
cd /home/ubuntu/warrior-livekit-agent

# Login to GHCR first
export GITHUB_TOKEN="your_pat_token"
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Run build script
bash scripts/build-and-push.sh --tag v1.0.0 --username YOUR_USERNAME --token $GITHUB_TOKEN
```

### Option B: Manual Commands
```bash
cd /home/ubuntu/warrior-livekit-agent

# Build
docker build -f docker/agent.Dockerfile \
  -t ghcr.io/princekoya-multiverse/warrior-livekit-agent:v1.0.0 .
docker build -f docker/frontend.Dockerfile \
  -t ghcr.io/princekoya-multiverse/warrior-livekit-frontend:v1.0.0 .

# Push
docker push ghcr.io/princekoya-multiverse/warrior-livekit-agent:v1.0.0
docker push ghcr.io/princekoya-multiverse/warrior-livekit-frontend:v1.0.0

# Make public on GitHub: https://github.com/princekoya-multiverse?tab=packages
```

---

## 3️⃣ Update Configuration (3 min)

**Edit deploy.yaml:**
```yaml
# Update these image tags:
services:
  agent:
    image: ghcr.io/princekoya-multiverse/warrior-livekit-agent:v1.0.0
  
  frontend:
    image: ghcr.io/princekoya-multiverse/warrior-livekit-frontend:v1.0.0

# Set environment variables:
env:
  - name: LIVEKIT_URL
    value: "your_livekit_url"
  - name: LIVEKIT_API_KEY
    value: "your_key"
  - name: LIVEKIT_API_SECRET
    value: "your_secret"
  - name: DEEPGRAM_API_KEY
    value: "your_key"
  - name: OPENAI_API_KEY
    value: "your_key"
```

---

## 4️⃣ Deploy to Akash (5 min)

### Export Variables
```bash
export AKASH_NODE="https://rpc.mainnet.akash.network:443"
export AKASH_CHAIN_ID="akashnet-2"
export AKASH_KEYRING_BACKEND="os"
export AKASH_FROM="your-key-name"
export AKASH_ACCOUNT_ADDRESS=$(akash keys list --output json | jq -r '.[0].address')
```

### Create Deployment
```bash
# Create
akash tx deployment create deploy.yaml --from $AKASH_FROM --node $AKASH_NODE

# Get deployment ID from response
# Set: export DEPLOYMENT_ID="12345"
```

### Accept Bid
```bash
# View bids
akash query market bid list --node $AKASH_NODE --filters="dseq=$DEPLOYMENT_ID"

# Accept best bid (usually lowest price provider with good specs)
# Set: export PROVIDER="akash1..."

akash tx market bid-close \
  --owner=$AKASH_ACCOUNT_ADDRESS \
  --dseq=$DEPLOYMENT_ID \
  --gseq=1 --oseq=1 \
  --provider=$PROVIDER \
  --from=$AKASH_FROM \
  --node=$AKASH_NODE
```

---

## 5️⃣ Verify Deployment (2 min)

```bash
# Get deployment URL
akash query market lease list --node $AKASH_NODE --filters="dseq=$DEPLOYMENT_ID"

# Check logs (will show deployment URL)
akash provider lease-logs $DEPLOYMENT_ID 1 1 $PROVIDER \
  --follow --node=$AKASH_NODE

# Test access
curl https://<deployment-url>
```

---

## 6️⃣ Configure Domain (Optional)

1. Get deployment URL/IP from Akash
2. Go to **freename.com** → Domain Settings
3. Add CNAME record pointing to deployment URL
4. Wait 5-15 minutes for DNS propagation
5. Test: `curl https://warriorworld.life`

---

## 🚨 Quick Troubleshooting

| Problem | Fix |
|---------|-----|
| GHCR push fails | Verify PAT token has `write:packages` scope |
| No bids received | Wait a few minutes, check deploy.yaml specs |
| Deployment won't start | Check logs for env var errors |
| High cost | Review resources: 3.5 vCPU / 4.5 GB RAM is optimal |
| Domain not working | Check freename.com DNS, wait for propagation |

---

## 📊 Cost Estimate

- **Compute:** 3.5 vCPU / 4.5 GB RAM
- **Storage:** 10 GB persistent storage
- **Estimated:** $50-100/month USD (~0.8-1.5 AKT/day)
- **Your budget:** ~$175 AKT = ~3-4 months runway

---

## 📚 Key Commands Reference

```bash
# Get balance
akash query bank balances $AKASH_ACCOUNT_ADDRESS --node $AKASH_NODE

# List deployments
akash query deployment list --node $AKASH_NODE

# List bids
akash query market bid list --node $AKASH_NODE --filters="dseq=$DEPLOYMENT_ID"

# Check deployment status
akash query market lease list --node $AKASH_NODE --filters="dseq=$DEPLOYMENT_ID"

# Stream logs
akash provider lease-logs $DEPLOYMENT_ID 1 1 $PROVIDER --follow --node=$AKASH_NODE

# Close deployment
akash tx deployment close \
  --owner=$AKASH_ACCOUNT_ADDRESS \
  --dseq=$DEPLOYMENT_ID \
  --from=$AKASH_FROM \
  --node=$AKASH_NODE
```

---

## 💾 Environment Setup (Save This)

```bash
# ~/.bashrc or ~/.zshrc - Add these for permanent setup
export AKASH_NODE="https://rpc.mainnet.akash.network:443"
export AKASH_CHAIN_ID="akashnet-2"
export AKASH_KEYRING_BACKEND="os"
export AKASH_FROM="your-key-name"
export AKASH_ACCOUNT_ADDRESS=$(akash keys list --output json | jq -r '.[0].address')

# Or create ~/.akash_env and source it:
source ~/.akash_env
```

---

**Total time estimate:** 20-30 minutes end-to-end  
**Next:** Monitor deployment and configure domain

---

*For detailed info, see: `AKASH_DEPLOYMENT_QUICK_START.md`*

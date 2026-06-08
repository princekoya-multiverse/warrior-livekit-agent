#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────
# Warrior B.O.S.S. — Akash Deployment Script
#
# Mirrors the CI/CD pipeline for local/one-shot deployment.
#
# Prerequisites:
#   1. Images pushed to GHCR (run the Build & Push workflow or `docker push`)
#   2. Akash CLI installed (or Docker-based CLI via AKASH_CLI_IMAGE)
#   3. AKASH_MNEMONIC set in .env or exported
#
# Usage:
#   scripts/akash-deploy.sh                    # deploy everything
#   scripts/akash-deploy.sh --dry-run          # template + validate only
#   scripts/akash-deploy.sh close <dseq>       # close a deployment
# ──────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SCRIPT_DIR"

# ── Configuration ────────────────────────────────────────────────────────
AKASH_NET="${AKASH_NET:-https://raw.githubusercontent.com/akash-network/net/master/mainnet}"
AKASH_NODE="${AKASH_NODE:-https://akash-rpc.polkachu.com}"
AKASH_GAS="${AKASH_GAS:-auto}"
AKASH_GAS_ADJUSTMENT="${AKASH_GAS_ADJUSTMENT:-1.25}"
AKASH_GAS_PRICES="${AKASH_GAS_PRICES:-0.025uakt}"
AKASH_KEYRING_BACKEND="${AKASH_KEYRING_BACKEND:-test}"
AKASH_CLI_IMAGE="${AKASH_CLI_IMAGE:-ghcr.io/akash-network/akash-cli:latest}"
WALLET_NAME="${WALLET_NAME:-warrior-deployer}"

# ── Colors ───────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERR]${NC} $*" >&2; }

# ── Helpers ──────────────────────────────────────────────────────────────
CLI() {
  if command -v provider-services &>/dev/null; then
    provider-services "$@"
  elif command -v akash &>/dev/null; then
    akash "$@"
  else
    docker run --rm \
      -v "$SCRIPT_DIR:/workspace" -w /workspace \
      -e AKASH_KEYRING_BACKEND \
      "$AKASH_CLI_IMAGE" "$@"
  fi
}

resolve_chain() {
  if [ -z "${CHAIN_ID:-}" ]; then
    CHAIN_ID=$(curl -s "$AKASH_NET/chain-id.txt" | tr -d '[:space:]')
  fi
  if [ -z "${CLI_VERSION:-}" ]; then
    CLI_VERSION=$(curl -s "$AKASH_NET/version.txt" | tr -d '[:space:]')
  fi
  export CLI_VERSION CHAIN_ID
  info "Chain: $CHAIN_ID | CLI: $CLI_VERSION"
}

import_wallet() {
  if [ -z "${AKASH_MNEMONIC:-}" ]; then
    if [ -f .env ]; then
      AKASH_MNEMONIC=$(grep -E '^AKASH_MNEMONIC=' .env | cut -d= -f2-)
    fi
  fi
  if [ -z "${AKASH_MNEMONIC:-}" ]; then
    err "AKASH_MNEMONIC not set. Export it or add to .env"
    exit 1
  fi
  echo "$AKASH_MNEMONIC" | CLI keys add "$WALLET_NAME" \
    --recover --keyring-backend "$AKASH_KEYRING_BACKEND" -y 2>/dev/null || true
  WALLET_ADDR=$(CLI keys show "$WALLET_NAME" --address \
    --keyring-backend "$AKASH_KEYRING_BACKEND" 2>/dev/null)
  info "Wallet: $WALLET_ADDR"
}

render_deploy_yaml() {
  if [ ! -f deploy.example.yaml ]; then
    err "deploy.example.yaml not found"
    exit 1
  fi
  cp deploy.example.yaml deploy.yaml

  # Load .env if present
  [ -f .env ] && set -a && source .env && set +a

  : "${LIVEKIT_API_KEY:?Required}"
  : "${LIVEKIT_API_SECRET:?Required}"
  : "${ABACUS_API_KEY:?Required}"
  : "${DEEPGRAM_API_KEY:?Required}"

  sed -i "s|REPLACE_KEY: REPLACE_SECRET|$LIVEKIT_API_KEY: $LIVEKIT_API_SECRET|" deploy.yaml
  sed -i "s|LIVEKIT_API_KEY=REPLACE_KEY|LIVEKIT_API_KEY=$LIVEKIT_API_KEY|" deploy.yaml
  sed -i "s|LIVEKIT_API_SECRET=REPLACE_SECRET|LIVEKIT_API_SECRET=$LIVEKIT_API_SECRET|" deploy.yaml
  sed -i "s|ABACUS_API_KEY=REPLACE_ABACUS_KEY|ABACUS_API_KEY=$ABACUS_API_KEY|" deploy.yaml
  sed -i "s|DEEPGRAM_API_KEY=REPLACE_DEEPGRAM_KEY|DEEPGRAM_API_KEY=$DEEPGRAM_API_KEY|" deploy.yaml
  sed -i "s|LIVEKIT_PUBLIC_URL=.*|LIVEKIT_PUBLIC_URL=${LIVEKIT_PUBLIC_URL:-wss://livekit.warriorworld.life}|" deploy.yaml
  sed -i "s|TOKEN_SERVER_CORS=.*|TOKEN_SERVER_CORS=${TOKEN_SERVER_CORS:-https://warriorworld.life}|" deploy.yaml

  info "deploy.yaml rendered"
}

close_deployment() {
  local dseq="$1"
  resolve_chain
  import_wallet
  CLI tx deployment close \
    --from "$WALLET_NAME" \
    --owner "$WALLET_ADDR" \
    --dseq "$dseq" \
    --node "$AKASH_NODE" \
    --chain-id "$CHAIN_ID" \
    --keyring-backend "$AKASH_KEYRING_BACKEND" \
    --gas "$AKASH_GAS" \
    --gas-adjustment "$AKASH_GAS_ADJUSTMENT" \
    --gas-prices "$AKASH_GAS_PRICES" \
    --fees 5000uakt \
    -y
  info "Deployment $dseq closed"
}

do_deploy() {
  render_deploy_yaml
  resolve_chain
  import_wallet

  # Create deployment
  info "Creating deployment..."
  RESULT=$(CLI tx deployment create deploy.yaml \
    --from "$WALLET_NAME" \
    --node "$AKASH_NODE" \
    --chain-id "$CHAIN_ID" \
    --keyring-backend "$AKASH_KEYRING_BACKEND" \
    --gas "$AKASH_GAS" \
    --gas-adjustment "$AKASH_GAS_ADJUSTMENT" \
    --gas-prices "$AKASH_GAS_PRICES" \
    --fees 5000uakt \
    -y \
    --output json 2>&1)
  echo "$RESULT"

  # Parse dseq
  DSEQ=$(echo "$RESULT" | python3 -c "
import json, re, sys
try:
    raw=json.load(sys.stdin)
except: sys.exit(1)
log=raw.get('raw_log','')
m=re.search(r'dseq[^0-9]*(\d+)',str(log))
if m: print(m.group(1)); sys.exit(0)
for ev in raw.get('events',[]):
    for attr in ev.get('attributes',[]):
        if 'dseq' in attr.get('key',''): print(attr['value']); sys.exit(0)
print('UNKNOWN')" 2>/dev/null || echo "UNKNOWN")

  if [ "$DSEQ" = "UNKNOWN" ]; then
    err "Could not parse DSEQ from deployment result"
    warn "Check the output above manually"
    exit 1
  fi
  info "DSEQ: $DSEQ"

  # Poll for bids
  info "Waiting for bids..."
  for i in $(seq 1 40); do
    BIDS=$(CLI query market bid list \
      --owner "$WALLET_ADDR" --dseq "$DSEQ" \
      --node "$AKASH_NODE" -o json 2>/dev/null || echo '{}')

    PROVIDER=$(echo "$BIDS" | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except: sys.exit(0)
for b in d.get('bids',[]):
    bd=b.get('bid',b)
    if bd.get('state','').lower()=='active':
        print(bd.get('provider',''))
        break
")

    if [ -n "$PROVIDER" ]; then
      info "Active bid from: $PROVIDER"

      CLI tx market lease create \
        --from "$WALLET_NAME" \
        --owner "$WALLET_ADDR" \
        --dseq "$DSEQ" \
        --provider "$PROVIDER" \
        --node "$AKASH_NODE" \
        --chain-id "$CHAIN_ID" \
        --keyring-backend "$AKASH_KEYRING_BACKEND" \
        --gas "$AKASH_GAS" \
        --gas-adjustment "$AKASH_GAS_ADJUSTMENT" \
        --gas-prices "$AKASH_GAS_PRICES" \
        --fees 5000uakt \
        -y --output json 2>&1

      # Send manifest
      info "Sending manifest..."
      CLI provider send-manifest deploy.yaml \
        --node "$AKASH_NODE" \
        --dseq "$DSEQ" \
        --provider "$PROVIDER" \
        --from "$WALLET_NAME" \
        --keyring-backend "$AKASH_KEYRING_BACKEND" \
        -o json 2>&1

      info "Deployment complete! DSEQ=$DSEQ Provider=$PROVIDER"
      echo "DSEQ=$DSEQ" > .akash-deploy
      echo "PROVIDER=$PROVIDER" >> .akash-deploy
      exit 0
    fi
    sleep 30
  done

  err "No active bid within 20 minutes"
  exit 1
}

# ── Main ─────────────────────────────────────────────────────────────────
case "${1:-deploy}" in
  deploy)      do_deploy ;;
  --dry-run|-n)
    render_deploy_yaml
    info "Dry-run: deploy.yaml is ready for inspection"
    info "Run with no arguments to deploy"
    ;;
  close)       close_deployment "${2:?Usage: $0 close <dseq>}" ;;
  *)
    echo "Usage: $0 [deploy|--dry-run|close <dseq>]"
    exit 1
    ;;
esac

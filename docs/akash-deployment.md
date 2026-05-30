# Akash Deployment — Step by Step

Deploy Warrior B.O.S.S. to the decentralized Akash Network. Target budget:
**3.5 vCPU / 4.5 GB RAM**, ~**$15–20/month**.

---

## 0. Prerequisites

- An Akash wallet funded with **AKT** (you have ~$175 in credits).
- The Akash CLI / `provider-services` installed:
  https://akash.network/docs/deployments/akash-cli/installation/
- A container registry account (Docker Hub, GHCR, etc.) to host your images.
- Built images for the **agent** and **frontend** (LiveKit server image is
  public).

---

## 1. Generate production LiveKit keys

```bash
./livekit-server/generate-keys.sh > keys.env   # do NOT commit
cat keys.env
```

Note the `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, and `LIVEKIT_KEYS` values.

---

## 2. Build & push images

```bash
# Set your registry namespace
export REG=docker.io/yourname

# Agent (also serves the token server via a different command)
docker build -f docker/Dockerfile.agent -t $REG/warrior-agent:latest .
docker push $REG/warrior-agent:latest

# Frontend — bake the public token endpoint at build time
docker build -f docker/Dockerfile.frontend \
  --build-arg VITE_TOKEN_ENDPOINT=https://api.warriorworld.life/token \
  -t $REG/warrior-frontend:latest .
docker push $REG/warrior-frontend:latest
```

> Akash pulls images from public registries. For private images, configure
> registry credentials per the Akash docs.

---

## 3. Fill in `deploy.yaml`

Edit `deploy.yaml` and replace every `REPLACE_*` placeholder:

| Placeholder | Value |
|---|---|
| `REPLACE_REGISTRY/warrior-agent:latest` | your pushed agent image |
| `REPLACE_REGISTRY/warrior-frontend:latest` | your pushed frontend image |
| `REPLACE_KEY` / `REPLACE_SECRET` | LiveKit key/secret from step 1 |
| `REPLACE_ABACUS_KEY` | your Abacus AI API key |
| `REPLACE_DEEPGRAM_KEY` | your Deepgram key |
| `LIVEKIT_PUBLIC_URL` | `wss://livekit.warriorworld.life` (your domain) |

Also set the LiveKit server's `LIVEKIT_KEYS` env to `"<KEY>: <SECRET>"`.

---

## 4. Create the deployment

```bash
# Set your key + node
export AKASH_KEY_NAME=warrior
export AKASH_NODE=https://rpc.akashnet.net:443
export AKASH_CHAIN_ID=akashnet-2

# 1) Create deployment from the SDL
provider-services tx deployment create deploy.yaml \
  --from $AKASH_KEY_NAME --node $AKASH_NODE --chain-id $AKASH_CHAIN_ID \
  --gas auto --gas-adjustment 1.4 -y

# 2) Find the deployment sequence (DSEQ) from the tx output, then view bids
provider-services query market bid list --owner <your-address> --dseq <DSEQ>

# 3) Create a lease with a chosen provider
provider-services tx market lease create \
  --dseq <DSEQ> --gseq 1 --oseq 1 --provider <provider-address> \
  --from $AKASH_KEY_NAME -y

# 4) Send the manifest to the provider
provider-services send-manifest deploy.yaml \
  --dseq <DSEQ> --provider <provider-address> --from $AKASH_KEY_NAME

# 5) Get the assigned URIs / IPs
provider-services lease-status \
  --dseq <DSEQ> --provider <provider-address> --from $AKASH_KEY_NAME
```

`lease-status` returns the public host/port for each exposed service
(frontend :80, token-server :8080, livekit :7880/:7881 + UDP).

---

## 5. WebRTC / UDP on Akash — important

WebRTC needs media ports. Akash exposes ports individually, and **UDP support
varies by provider**. Two robust strategies:

1. **Prefer TCP fallback + TURN.** LiveKit's `tcp_port: 7881` and the built-in
   TURN server (`livekit.prod.yaml`) let clients connect even when UDP is
   restricted. This is the most reliable path on mixed providers.
2. **Choose a provider that supports your UDP range** and expose the media
   ports. Test early — see the risk register in the architecture doc.

Set `use_external_ip: true` (already in `livekit.prod.yaml`) so the SFU
advertises the provider's public IP.

---

## 6. Point the domain & TLS

See [`domain-setup.md`](domain-setup.md). In short:

- `warriorworld.life` → frontend service host
- `api.warriorworld.life` → token-server host
- `livekit.warriorworld.life` → livekit-server host (wss + TURN)

Use Cloudflare (or a small Caddy/Nginx TLS terminator container) for HTTPS/WSS.

---

## 7. Update / close

```bash
# Update after pushing new images / editing SDL
provider-services tx deployment update deploy.yaml \
  --dseq <DSEQ> --from $AKASH_KEY_NAME -y

# Close the deployment (stops billing)
provider-services tx deployment close \
  --dseq <DSEQ> --from $AKASH_KEY_NAME -y
```

> **Scale-to-zero for demos:** close the deployment when not presenting and
> redeploy on demand to stretch your credits.

---

## Cost sanity check

| Service | CPU | RAM | ~uakt/block |
|---|---|---|---|
| livekit-server | 1.5 | 1.5 Gi | 10000 |
| agent | 1.0 | 2 Gi | 10000 |
| token-server | 0.5 | 0.5 Gi | 5000 |
| frontend | 0.5 | 0.5 Gi | 5000 |
| **Total** | **3.5** | **4.5 Gi** | — |

Bids are competitive; expect ~$15–20/month. With $175 credits that is roughly
**9–11 months** of continuous operation.

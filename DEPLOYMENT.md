# 🚀 Warrior B.O.S.S. — Deployment Guide

> **Quick-reference deployment playbook.** For deep-dives see the individual
> guides in [`docs/`](docs/).

---

## 1. Quick Start (Local)

```bash
# 1 — Clone & configure
cp .env.example .env
# Edit .env → fill ABACUS_API_KEY, DEEPGRAM_API_KEY, and optionally OPENAI_API_KEY

# 2 — Generate LiveKit keys (or keep defaults for local dev)
cd livekit-server && bash generate-keys.sh && cd ..

# 3 — Launch everything
docker compose up --build
```

Open **http://localhost:3000** — you should see the animated avatar and be able
to start a voice session.

| Service        | Local URL                    |
|----------------|------------------------------|
| Frontend       | http://localhost:3000         |
| Token Server   | http://localhost:8080         |
| LiveKit Server | ws://localhost:7880           |

📖 *Full details:* [`docs/local-development.md`](docs/local-development.md)

---

## 2. Docker Build

Two images to build — the agent (Python) and the frontend (Nginx + React SPA):

```bash
# Agent image (also runs token-server)
docker build -f docker/Dockerfile.agent -t warrior-agent:latest .

# Frontend image
docker build -f docker/Dockerfile.frontend -t warrior-frontend:latest .
```

### Push to a registry (required for Akash)

```bash
REGISTRY=docker.io/YOUR_USERNAME  # or ghcr.io/YOUR_ORG

docker tag warrior-agent:latest   $REGISTRY/warrior-agent:latest
docker tag warrior-frontend:latest $REGISTRY/warrior-frontend:latest

docker push $REGISTRY/warrior-agent:latest
docker push $REGISTRY/warrior-frontend:latest
```

---

## 3. Akash Deployment

### Prerequisites
- [Akash CLI](https://docs.akash.network/guides/cli) or **Cloudmos** deploy UI
- AKT tokens funded in your wallet
- Images pushed to a public registry (step 2 above)

### Steps

```bash
# 1 — Update deploy.yaml
#     Replace all REPLACE_REGISTRY with your registry prefix
#     Replace all REPLACE_KEY / REPLACE_SECRET with real LiveKit credentials
#     Set ABACUS_API_KEY, DEEPGRAM_API_KEY in the agent env block

# 2 — Deploy via Akash CLI
akash tx deployment create deploy.yaml --from $AKASH_WALLET --chain-id akashnet-2

# 3 — Accept a bid
akash query market bid list --owner $AKASH_ACCOUNT
akash tx market lease create --bid-id <BID_ID> --from $AKASH_WALLET

# 4 — Check status
akash provider lease-status --from $AKASH_WALLET
```

Note the **provider-assigned URI** from lease status — you'll need it for domain setup.

### Resource Budget

| Service        | CPU   | RAM    | Role                          |
|----------------|-------|--------|-------------------------------|
| livekit-server | 1.0   | 1 GB   | WebRTC SFU                    |
| token-server   | 0.5   | 512 MB | Token minting API             |
| agent          | 1.5   | 2 GB   | Voice AI worker               |
| frontend       | 0.5   | 1 GB   | Nginx + React SPA             |
| **Total**      | **3.5** | **4.5 GB** | **~$15–20/month on Akash** |

📖 *Full details:* [`docs/akash-deployment.md`](docs/akash-deployment.md)

---

## 4. Domain Setup — warriorworld.life

Point your domain to the Akash deployment using DNS:

```
# A record (or CNAME) → Akash provider ingress
warriorworld.life        →  <PROVIDER_IP>

# Subdomain for LiveKit WebSocket
livekit.warriorworld.life →  <PROVIDER_IP>
```

### HTTPS/WSS

Use **Cloudflare** (recommended) as your DNS proxy:

1. Add domain to Cloudflare, update nameservers at your registrar
2. Create A/CNAME records above with **Proxy enabled** (orange cloud)
3. SSL/TLS → **Full (strict)**
4. Ensure WebSockets are enabled (Network → WebSockets: On)

After DNS propagates:
- Frontend: `https://warriorworld.life`
- LiveKit:  `wss://livekit.warriorworld.life`

📖 *Full details:* [`docs/domain-setup.md`](docs/domain-setup.md)

---

## 5. Verification

Run these checks bottom-up to isolate failures quickly:

```bash
# 1 — LiveKit server health
curl -s https://warriorworld.life:7880  # or use provider URI directly

# 2 — Token server
curl -s https://warriorworld.life/api/token \
  -H "Content-Type: application/json" \
  -d '{"identity":"test","room":"test-room"}'
# Expect: {"token":"eyJ..."}

# 3 — Frontend loads
curl -sI https://warriorworld.life | head -5
# Expect: HTTP/2 200

# 4 — End-to-end voice test
# Open https://warriorworld.life in Chrome
# Click "Start Session" → grant mic → speak → hear AI response
```

### Local verification (docker compose)

```bash
# Health checks
curl -s http://localhost:8080/api/token \
  -H "Content-Type: application/json" \
  -d '{"identity":"test","room":"test-room"}'

# Open http://localhost:3000 in browser
```

📖 *Full details:* [`docs/testing.md`](docs/testing.md) &
[`docs/troubleshooting.md`](docs/troubleshooting.md)

---

## Architecture Overview

```
┌─────────────┐   HTTPS   ┌──────────────┐
│   Browser   │◄─────────►│   Frontend   │ (Nginx + React SPA)
│  (Chrome)   │           │   :3000/443  │
└──────┬──────┘           └──────────────┘
       │ WSS
       ▼
┌──────────────┐  gRPC   ┌──────────────┐  LLM API  ┌─────────────┐
│ LiveKit SFU  │◄───────►│    Agent     │──────────►│  Abacus AI  │
│  :7880/7881  │         │  (Python)    │           │  RouteLLM   │
└──────────────┘         └──────┬───────┘           └─────────────┘
                                │
                         ┌──────┴───────┐
                         │ Token Server │
                         │    :8080     │
                         └──────────────┘
```

---

## Environment Variables Reference

| Variable             | Required | Description                        |
|----------------------|----------|------------------------------------|
| `LIVEKIT_API_KEY`    | ✅       | LiveKit API key                    |
| `LIVEKIT_API_SECRET` | ✅       | LiveKit API secret                 |
| `LIVEKIT_PUBLIC_URL` | ✅       | Public WebSocket URL for LiveKit   |
| `ABACUS_API_KEY`     | ✅       | Abacus AI API key                  |
| `DEEPGRAM_API_KEY`   | ✅       | Deepgram STT key                   |
| `OPENAI_API_KEY`     | —        | Optional fallback LLM              |
| `TTS_VOICE`          | —        | Edge TTS voice (default: `en-US-GuyNeural`) |

---

*For issues, see [`docs/troubleshooting.md`](docs/troubleshooting.md).*

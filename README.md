# Warrior B.O.S.S. — LiveKit AI Agent (Phase 1)

A real-time, voice-first AI advisor you can **talk to face-to-face in a browser**.
Powered by [LiveKit](https://livekit.io) for WebRTC media, [Abacus AI](https://abacus.ai)
for the LLM brain, free [Edge TTS](https://github.com/rany2/edge-tts) for voice, and
deployable to the decentralized [Akash Network](https://akash.network).

> **Standard: Proof over theory. Build it. Show it. Ship it.**

The agent embodies the **Prince Core OS / Warrior OS** persona — calm, authoritative
coaching across the chain: **Health → Clarity → Decisions → Wealth → Freedom → Purpose.**

---

## What's inside

```
warrior-livekit-agent/
├── frontend/         React + Vite + TS web app (LiveKit client, canvas avatar)
├── agent/            Python livekit-agents worker + token server
├── livekit-server/   LiveKit SFU config + API key generator
├── docker/           Dockerfiles for every component + Nginx config
├── docs/             Setup, testing, Akash deployment, domain, troubleshooting
├── docker-compose.yml   Local full-stack dev
└── deploy.yaml       Akash SDL (production manifest)
```

| Component | Tech | Role |
|---|---|---|
| Frontend | React 18 + Vite + TS, `@livekit/components-react` | Browser UI, canvas avatar w/ audio-driven lip-sync |
| Agent worker | Python 3.11, `livekit-agents` 1.x | STT → LLM → TTS pipeline, Warrior persona |
| Token server | FastAPI | Mints short-lived LiveKit join JWTs |
| LiveKit server | `livekit/livekit-server` | WebRTC SFU / media routing |
| LLM | Abacus AI RouteLLM (OpenAI-compatible) | The agent's brain |
| STT | Deepgram (default) or local Whisper | Speech → text |
| TTS | Edge TTS (free, no key) | Text → speech |

---

## Quick start (local, Docker)

```bash
# 1. Clone and enter the repo
cd warrior-livekit-agent

# 2. Generate LiveKit keys (optional for local — devkey/secret works)
./livekit-server/generate-keys.sh

# 3. Configure environment
cp .env.example .env
#   Edit .env — at minimum set ABACUS_API_KEY and DEEPGRAM_API_KEY
#   (TTS is free; LiveKit keys default to devkey/secret for local dev)

# 4. Launch the full stack
docker compose up --build

# 5. Open the app
#    http://localhost:3000  → click "Enter the Session" → allow mic → talk
```

> **Note:** When running on a remote VM, `localhost` refers to the VM, not your
> machine. See `docs/local-development.md` for tunneling/preview-URL guidance.

## Quick start (local, no Docker)

See [`docs/local-development.md`](docs/local-development.md) for running each
component natively (LiveKit binary, `python -m agent.main dev`, `npm run dev`).

---

## Deploy to Akash

Full step-by-step in [`docs/akash-deployment.md`](docs/akash-deployment.md):

1. Build & push the agent and frontend images to a registry.
2. Fill secrets + image refs in `deploy.yaml`.
3. `provider-services tx deployment create deploy.yaml` and accept a bid.
4. Point `warriorworld.life` DNS at the provider (see `docs/domain-setup.md`).

**Resource budget (fits the target 3.5 vCPU / 4.5 GB RAM):**

| Service | CPU | RAM |
|---|---|---|
| livekit-server | 1.5 | 1.5 Gi |
| agent | 1.0 | 2 Gi |
| token-server | 0.5 | 0.5 Gi |
| frontend | 0.5 | 0.5 Gi |
| **Total** | **3.5** | **4.5 Gi** |

Estimated cost on Akash: **~$15–20/month** (≈10 months on $175 credits).

---

## Documentation

- [Local development](docs/local-development.md) — run everything locally
- [Testing guide](docs/testing.md) — verify each layer end-to-end
- [Akash deployment](docs/akash-deployment.md) — production deploy, step by step
- [Domain setup](docs/domain-setup.md) — wire up `warriorworld.life` + TLS
- [Troubleshooting](docs/troubleshooting.md) — common issues & fixes

---

## Security notes

- Secrets live only in `.env` / Akash env injection — never in git.
- LiveKit tokens are short-lived JWTs (1h), minted server-side only.
- No user data is persisted in Phase 1 — conversations are ephemeral.
- CORS on the token server is restricted to your domain in production.

---

*Built for Warriors. Proof over theory. Ship it.*

# Warrior B.O.S.S. System — PROJECT LOG

> **Master Continuity Document**
> Any agent reading this file should be able to understand the full state of the project, what has been built, how it works, what decisions were made, and what to do next.

**Last Updated:** May 30, 2026
**Project Owner:** princekoya@warriorworld.life
**GitHub Account:** `princekoya-multiverse`
**Domain:** warriorworld.life

---

## 1. PROJECT OVERVIEW

### Mission Statement

Build a real-time AI agent with live voice that embodies the Warrior Operating System philosophy — deployed on Web3 infrastructure (Akash Network) — accessible to anyone through a browser. No chatbot text boxes. Real presence. Sovereign hosting. Proof over theory.

**B.O.S.S. = Build, Orchestrate, Scale, Serve.**

### Current Phase

**Phase 1: LiveKit AI Agent Demo** — ✅ CODE COMPLETE, awaiting deployment.

Phase 1 delivers exactly one thing: a browser-accessible AI agent that a user can talk to face-to-face in real time, powered by LiveKit for media, Abacus AI for intelligence, and Akash Network for sovereign hosting.

**Success criteria:** A stranger can visit a URL, click one button, and have a voice conversation with the Warrior agent.

### Warrior Doctrine Principles Guiding This Build

Every design decision maps to the Core OS chain:

```
Health → Clarity → Decisions → Wealth → Freedom → Purpose
```

| Principle | How Phase 1 Embodies It |
|---|---|
| **Tech frees humans** | Agent handles complexity; user gets clarity |
| **Proof over theory** | Working demo ships before documentation expands |
| **Systems over hustle** | Reproducible Docker containers, not manual setups |
| **Quiet enhancement** | Agent augments decisions, doesn't create dependency |
| **Calm authority** | Agent voice/personality: coaching, not selling |

---

## 2. CURRENT ARCHITECTURE

### System Components & Locations

```
/home/ubuntu/warrior-livekit-agent/          ← PROJECT ROOT
│
├── agent/                                    ← PYTHON AGENT WORKER
│   ├── agent/
│   │   ├── main.py                          ← Agent entrypoint (LiveKit Agents SDK)
│   │   ├── config.py                        ← Environment & settings
│   │   ├── edge_tts_plugin.py               ← Custom Edge TTS plugin for LiveKit
│   │   ├── token_server.py                  ← FastAPI token minting endpoint
│   │   └── __init__.py
│   ├── prompts/
│   │   ├── system_prompt.md                 ← Core personality prompt
│   │   ├── warrior_doctrine.md              ← Principles & philosophy
│   │   └── *.docx / *.pdf                   ← Exported formats
│   ├── requirements.txt                     ← Python dependencies
│   ├── .env.example                         ← Agent-specific env template
│   └── .venv/                               ← Local virtual environment (not committed)
│
├── frontend/                                 ← REACT/VITE WEB INTERFACE
│   ├── src/
│   │   ├── App.tsx                          ← Main application component
│   │   ├── main.tsx                         ← React entry point
│   │   ├── styles.css                       ← Global styles
│   │   ├── config/livekit.ts                ← LiveKit connection config
│   │   ├── components/
│   │   │   ├── AgentRoom.tsx                ← LiveKit room connection
│   │   │   ├── WarriorAvatar.tsx            ← Animated avatar with lip-sync
│   │   │   ├── AudioVisualizer.tsx          ← Voice activity visualizer
│   │   │   └── ControlBar.tsx               ← Mic toggle, disconnect
│   │   └── hooks/
│   │       └── useAudioAmplitude.ts         ← Audio amplitude hook for avatar sync
│   ├── public/warrior.svg                   ← Avatar asset
│   ├── dist/                                ← Built production files
│   ├── package.json                         ← Node dependencies
│   ├── vite.config.ts                       ← Vite build config
│   └── .env.example                         ← Frontend env template
│
├── livekit-server/                           ← LIVEKIT SERVER CONFIG
│   ├── livekit.yaml                         ← Local dev config
│   ├── livekit.prod.yaml                    ← Production config (Akash)
│   └── generate-keys.sh                     ← API key generation script
│
├── docker/                                   ← DOCKER BUILD FILES
│   ├── Dockerfile.agent                     ← Agent worker container
│   ├── Dockerfile.frontend                  ← Frontend Nginx container
│   └── nginx.conf                           ← Nginx reverse proxy config
│
├── docs/                                     ← DOCUMENTATION
│   ├── akash-deployment.md                  ← Akash deployment guide
│   ├── local-development.md                 ← Local dev setup guide
│   ├── domain-setup.md                      ← DNS configuration guide
│   ├── testing.md                           ← Testing procedures
│   ├── troubleshooting.md                   ← Common issues & fixes
│   └── *.docx / *.pdf                       ← Exported formats
│
├── docker-compose.yml                        ← Local development orchestration
├── deploy.yaml                               ← Akash SDL deployment manifest
├── .env.example                              ← Root env template
├── .gitignore                                ← Git ignore rules
├── README.md                                 ← Project README
└── PROJECT_LOG.md                            ← THIS FILE
```

### How Components Connect

```
┌──────────────────────────────────────────────────────────────────┐
│                     USER'S BROWSER                               │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │           React Frontend (Vite + TypeScript)               │   │
│  │  ┌─────────────┐ ┌────────────────┐ ┌────────────────┐    │   │
│  │  │ LiveKit SDK  │ │ WarriorAvatar  │ │ AudioVisualizer│    │   │
│  │  │ (WebRTC)     │ │ (lip-sync)     │ │                │    │   │
│  │  └──────┬───────┘ └──────┬─────────┘ └────────────────┘    │   │
│  └─────────┼────────────────┼─────────────────────────────────┘   │
└────────────┼────────────────┼────────────────────────────────────┘
             │ WebRTC          │
             │ audio           │ TTS amplitude drives avatar
             ▼                 ▼
┌──────────────────────────────────────────────────────────────────┐
│                 AKASH NETWORK CLUSTER                            │
│                                                                  │
│  ┌──────────────┐  ┌──────────────────────────────────────────┐  │
│  │ Nginx/Frontend│  │       LiveKit Server (v1.8)             │  │
│  │ (port 80)    │  │  • WebRTC SFU media routing              │  │
│  │ static SPA + │  │  • Room management (auto-create)         │  │
│  │ /api proxy   │  │  • TURN fallback (port 7881)             │  │
│  └──────────────┘  │  • UDP media (port 50000+)               │  │
│                    └─────────────┬────────────────────────────┘  │
│                                  │ LiveKit Agent Protocol        │
│  ┌───────────────┐               ▼                               │
│  │ Token Server  │  ┌──────────────────────────────────────────┐ │
│  │ (FastAPI:8080)│  │      Agent Worker (Python)               │ │
│  │ mints JWTs    │  │  ┌────────┐ ┌──────────┐ ┌───────────┐  │ │
│  └───────────────┘  │  │Silero  │→│ Deepgram │→│ Abacus AI │  │ │
│                     │  │VAD     │ │ STT      │ │ LLM       │  │ │
│                     │  └────────┘ └──────────┘ └─────┬─────┘  │ │
│                     │                                │         │ │
│                     │  ┌──────────┐                   │         │ │
│                     │  │ Edge TTS │←──────────────────┘         │ │
│                     │  │ (free)   │→ audio back to LiveKit      │ │
│                     │  └──────────┘                             │ │
│                     └──────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
             │
             │ HTTPS API calls
             ▼
┌──────────────────────────────────────────────────────────────────┐
│                   EXTERNAL SERVICES                              │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐  │
│  │ Abacus AI    │  │ Deepgram     │  │ warriorworld.life     │  │
│  │ RouteLLM API │  │ STT API      │  │ (DNS @ Freename)      │  │
│  └──────────────┘  └──────────────┘  └───────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

### Tech Stack Summary

| Layer | Technology | Version/Notes |
|---|---|---|
| **Frontend** | React + TypeScript + Vite | React 18.3, Vite 5.4 |
| **LiveKit Client** | `@livekit/components-react` | ^2.6.0 |
| **Agent Runtime** | Python 3.11 + `livekit-agents` | ~1.5 |
| **LLM** | Abacus AI RouteLLM | `route-llm` model via OpenAI-compatible API |
| **STT** | Deepgram | Nova-2 model |
| **TTS** | Edge TTS | `en-US-GuyNeural` voice (free, no API key) |
| **VAD** | Silero VAD | Voice activity detection |
| **Media Server** | LiveKit Server | v1.8 (self-hosted) |
| **Token Server** | FastAPI + Uvicorn | JWT minting for room access |
| **Reverse Proxy** | Nginx | TLS termination + SPA serving |
| **Containerization** | Docker + Docker Compose | Multi-stage builds |
| **Deployment** | Akash Network SDL | Decentralized compute |
| **Domain** | warriorworld.life | Registrar: Freename |

### Resource Requirements

| Service | CPU | RAM | Storage |
|---|---|---|---|
| LiveKit Server | 1.5 vCPU | 1.5 GB | 1 GB |
| Token Server | 0.5 vCPU | 512 MB | 512 MB |
| Agent Worker | 1.0 vCPU | 2 GB | 2 GB |
| Frontend/Nginx | 0.5 vCPU | 512 MB | 512 MB |
| **Total** | **3.5 vCPU** | **4.5 GB** | **4 GB** |

---

## 3. REPOSITORY INVENTORY

### GitHub Account

- **Account:** `princekoya-multiverse` (personal user account)
- **Organization:** None exists yet — recommended to create `warrior-world` org
- **GitHub App:** Abacus AI App installed on personal account only

### Existing Repositories

| Repository | Purpose | Stack | Visibility | URL |
|---|---|---|---|---|
| `warrior-command-backend` | NestJS backend — Warrior Command Center for Akash | TypeScript, Docker, NestJS | Public | [github.com/princekoya-multiverse/warrior-command-backend](https://github.com/princekoya-multiverse/warrior-command-backend) |
| `pemfwarriorshop` | Warrior World web app / storefront (PEMF Warrior Shop) | Vite, React, TS, shadcn/ui, Supabase | Private | [github.com/princekoya-multiverse/pemfwarriorshop](https://github.com/princekoya-multiverse/pemfwarriorshop) |

### New Repository (To Be Created & Pushed)

| Repository | Purpose | Stack | Status |
|---|---|---|---|
| `warrior-livekit-agent` | LiveKit AI agent — voice-interactive coaching agent | Python, React, LiveKit, Docker, Akash SDL | **Code complete, NOT yet pushed to GitHub** |

### How Repositories Relate

```
princekoya-multiverse/
│
├── pemfwarriorshop               ← Consumer storefront (Supabase backend)
│   └── Hermes helper/runner services embedded
│
├── warrior-command-backend        ← NestJS API server (Akash-deployed)
│   └── REST backend for Warrior ecosystem
│
└── warrior-livekit-agent          ← NEW: Real-time voice AI agent
    ├── Independently deployable on Akash
    ├── Connects to Abacus AI for intelligence
    └── Serves frontend for browser-based voice chat
```

**Key relationship:** Each repo is an independently deployable service with its own Docker images, scaling profile, and lifecycle. They share the `warriorworld.life` domain but are otherwise decoupled. The LiveKit agent is a real-time worker — completely separate from the REST backend and the storefront.

### Recommended: Create GitHub Organization

Before pushing, strongly consider creating a `warrior-world` GitHub Organization to:
1. Move/transfer existing repos into it
2. Create `warrior-livekit-agent` inside the org
3. Enable team-based access control and shared secrets
4. Authorize Abacus GitHub App on the org: https://github.com/apps/abacusai/installations/select_target

> ⚠️ Creating GitHub orgs cannot be done via the current agent permissions. The project owner must do this manually.

---

## 4. DEPLOYMENT STATUS

### Current State: **NOT YET DEPLOYED**

All code is built and tested locally. Nothing is live on the internet yet.

| Component | Status | Location |
|---|---|---|
| Agent worker code | ✅ Complete | `/home/ubuntu/warrior-livekit-agent/agent/` |
| Frontend code | ✅ Complete + built | `/home/ubuntu/warrior-livekit-agent/frontend/dist/` |
| Docker configs | ✅ Complete | `/home/ubuntu/warrior-livekit-agent/docker/` |
| Docker Compose (local) | ✅ Complete | `/home/ubuntu/warrior-livekit-agent/docker-compose.yml` |
| Akash SDL manifest | ✅ Complete | `/home/ubuntu/warrior-livekit-agent/deploy.yaml` |
| GitHub push | ❌ Not done | Needs repo creation first |
| Docker image registry | ❌ Not done | Images need to be built & pushed |
| Akash deployment | ❌ Not done | Requires images in registry first |
| Domain DNS config | ❌ Not done | Needs Akash deployment IP first |
| Live URL | ❌ Not available | Target: `warriorworld.life` |

### Akash Deployment Plan

- **Available credits:** ~$175 AKT
- **Estimated monthly cost:** ~$17/month
- **Runway at current estimate:** ~10 months of operation
- **Deployment manifest:** `deploy.yaml` (Akash SDL v2.0)

### Domain Configuration Status

- **Domain:** warriorworld.life
- **Registrar:** Freename
- **DNS configured:** No — pending Akash deployment to get provider IP
- **Planned subdomains:**
  - `warriorworld.life` → Frontend (Nginx, port 80)
  - `livekit.warriorworld.life` → LiveKit Server (WSS, port 7880)
  - `api.warriorworld.life` → Token Server (HTTPS, port 8080)

---

## 5. LIVEKIT INTEGRATION DETAILS

### Why Self-Hosting on Akash

| Factor | LiveKit Cloud | Self-Hosted on Akash |
|---|---|---|
| Cost (1000 min/mo) | ~$50–100/mo | ~$15–25/mo |
| Data sovereignty | Their servers | Your containers |
| Web3 alignment | Centralized SaaS | Decentralized compute |
| Customization | Limited | Full control |
| Vendor lock-in | High | Zero |
| Akash credits | N/A | $175 available now |

**Decision: Self-host. The math works, the philosophy aligns, and we have credits.**

### LiveKit Server Configuration

**Config file:** `livekit-server/livekit.yaml` (local) / `livekit.prod.yaml` (Akash)

Key settings:
- **Port 7880:** HTTP/WebSocket API
- **Port 7881:** TCP fallback for restrictive firewalls
- **Port 50000+:** UDP media ports
- **TURN enabled:** Built-in TURN server ensures connectivity through corporate firewalls
- **Auto-create rooms:** Simplifies Phase 1 — no room management API needed
- **Max participants:** 5 per room (Phase 1 is 1:1 agent conversations)

API keys are generated via `livekit-server/generate-keys.sh` and injected as environment variables. Never committed to source.

### Agent Worker Architecture

The agent is a Python process using `livekit-agents` SDK v1.5:

```
Voice Pipeline (per conversation turn):
─────────────────────────────────────────────────
1. User speaks → microphone → WebRTC → LiveKit Server
2. LiveKit routes audio → Agent Worker
3. Silero VAD detects speech boundaries
4. Deepgram STT converts speech → text
5. Text + history → Abacus AI RouteLLM → response text
6. Response text → Edge TTS → audio stream
7. Audio → LiveKit Server → WebRTC → user's browser
8. Browser plays audio + drives avatar lip-sync
─────────────────────────────────────────────────
Target round-trip: < 1.5 seconds
```

**Key implementation details:**
- `WarriorAgent` class extends `livekit.agents.Agent` with Warrior OS system prompt
- `AgentSession` handles VAD, STT, LLM, TTS pipeline orchestration
- Interruption handling enabled — user can cut the agent off mid-response (`min_interruption_duration=0.4s`)
- Metrics collection for usage/cost awareness
- Prewarm function loads Silero VAD model once per worker process
- Custom `EdgeTTS` plugin wraps Microsoft's free Edge TTS API

**Agent personality:** Calm, authoritative coaching tone. See `agent/prompts/system_prompt.md` for the full persona definition. Key traits: direct, no filler, proof-based, always ends with a next step or focusing question.

### Frontend Integration

The React frontend uses `@livekit/components-react` v2.6.0:

1. User lands on the page → sees animated Warrior avatar
2. User clicks "Connect" → frontend requests JWT from Token Server
3. Token Server mints a short-lived LiveKit JWT → returns it with server URL
4. Frontend connects to LiveKit room using the token
5. User's microphone is published to the room
6. Agent's audio is subscribed and played through speakers
7. `WarriorAvatar` component animates mouth/glow based on agent audio amplitude
8. `ControlBar` provides mic toggle and disconnect controls

**Design:** Dark theme, minimal UI. The agent is the focus. No clutter.

### Token Flow

```
Browser → POST /api/token → Token Server → LiveKit JWT
Browser → connect(token) → LiveKit Server → Room joined
Agent Worker → already in room → audio flows bidirectionally
```

---

## 6. DECISIONS LOG

### Key Architectural Decisions

| # | Decision | Choice | Rationale | Trade-offs |
|---|---|---|---|---|
| 1 | **Hosting platform** | Akash Network | Web3 alignment, $175 credits available, ~$17/mo vs ~$80+ managed | Less documentation, potential UDP port limitations |
| 2 | **Media server** | LiveKit (self-hosted v1.8) | Open-source, best WebRTC SFU, official agents SDK | Self-managed TURN; no managed scaling |
| 3 | **LLM provider** | Abacus AI RouteLLM | Already available via API, zero additional cost, OpenAI-compatible | Tied to Abacus availability; fallback to OpenAI configured |
| 4 | **TTS engine** | Edge TTS (`en-US-GuyNeural`) | Completely free, decent quality, no API key needed | Microsoft dependency; quality below ElevenLabs |
| 5 | **STT engine** | Deepgram (Nova-2) | Free tier: 12,000 min/year, fast and accurate | Cloud dependency; fallback to local Whisper possible |
| 6 | **Avatar approach** | Canvas/WebGL lip-sync from audio amplitude | No GPU required, ships fast, lightweight | Not photorealistic; upgrade path to SadTalker/Wav2Lip in Phase 2 |
| 7 | **Frontend framework** | React 18 + Vite + TypeScript | Fast builds, strong LiveKit SDK support | — |
| 8 | **Agent runtime** | Python + livekit-agents SDK | Official SDK, best plugin ecosystem, async-native | Heavier than Node for simple tasks |
| 9 | **Containerization** | Docker Compose → Akash SDL | Standard workflow, easy local dev → production parity | — |
| 10 | **Token minting** | Separate FastAPI service | Decouples token auth from agent logic; scales independently | Extra container; could be merged with agent |
| 11 | **Conversation memory** | In-memory (ephemeral) | No persistence needed for Phase 1 demo | No history across sessions; add Warrior Vault in Phase 2 |
| 12 | **Repo structure** | Standalone `warrior-livekit-agent` | Independently deployable, cleanly isolated from NestJS backend and storefront | — |

### Credit Optimization Strategies

1. **Edge TTS over ElevenLabs** — $0/month vs ~$5–22/month
2. **Deepgram free tier** — 12,000 min/year at zero cost
3. **Abacus AI RouteLLM** — already included, no per-call billing anxiety
4. **Conversation windowing** — last 10 turns, not full history (shorter context = faster + cheaper)
5. **Scale-to-zero option** — Akash deployments can be closed/redeployed on demand
6. **Combined Nginx** — frontend static files served by same container that proxies; saves one deployment

---

## 7. COMPLETED WORK

### Phase 1 Deliverables Checklist

| Deliverable | Status | Notes |
|---|---|---|
| LiveKit agent worker (Python) | ✅ Complete | `agent/agent/main.py` — full voice pipeline |
| Warrior personality & prompts | ✅ Complete | `agent/prompts/system_prompt.md` + `warrior_doctrine.md` |
| Custom Edge TTS plugin | ✅ Complete | `agent/agent/edge_tts_plugin.py` |
| Token minting server | ✅ Complete | `agent/agent/token_server.py` (FastAPI) |
| React frontend with avatar | ✅ Complete | `frontend/` — built, `dist/` ready |
| LiveKit server configuration | ✅ Complete | `livekit-server/livekit.yaml` + prod variant |
| Docker build files | ✅ Complete | `docker/Dockerfile.agent`, `Dockerfile.frontend`, `nginx.conf` |
| Docker Compose (local dev) | ✅ Complete | `docker-compose.yml` — 4 services |
| Akash SDL manifest | ✅ Complete | `deploy.yaml` — ready for deployment |
| Architecture document | ✅ Complete | `/home/ubuntu/warrior_boss_architecture_phase1.md` |
| GitHub inventory | ✅ Complete | `/home/ubuntu/warrior_github_inventory.md` |
| Deployment documentation | ✅ Complete | `docs/akash-deployment.md` |
| Local dev documentation | ✅ Complete | `docs/local-development.md` |
| Domain setup guide | ✅ Complete | `docs/domain-setup.md` |
| Testing documentation | ✅ Complete | `docs/testing.md` |
| Troubleshooting guide | ✅ Complete | `docs/troubleshooting.md` |
| Master continuity doc | ✅ Complete | `PROJECT_LOG.md` (this file) |
| GitHub push | ❌ Pending | Needs repo creation |
| Docker images built/pushed | ❌ Pending | Needs registry setup |
| Akash deployment | ❌ Pending | Needs images |
| Domain DNS configuration | ❌ Pending | Needs deployment IP |
| Live end-to-end test | ❌ Pending | Needs deployment |

### What's Working (Local)

- Agent worker boots and connects to LiveKit server
- Voice pipeline: STT → LLM → TTS chain is wired
- Frontend builds successfully (`npm run build` → `dist/`)
- Docker Compose defines all 4 services with correct networking
- Environment templates (`.env.example`) are documented
- All documentation is written and exported to multiple formats

### Documentation Created

| Document | Path | Format |
|---|---|---|
| Architecture (Phase 1) | `/home/ubuntu/warrior_boss_architecture_phase1.md` | MD |
| GitHub Inventory | `/home/ubuntu/warrior_github_inventory.md` | MD |
| Akash Deployment Guide | `docs/akash-deployment.md` | MD + DOCX + PDF |
| Local Development Guide | `docs/local-development.md` | MD + DOCX + PDF |
| Domain Setup Guide | `docs/domain-setup.md` | MD |
| Testing Guide | `docs/testing.md` | MD + DOCX + PDF |
| Troubleshooting Guide | `docs/troubleshooting.md` | MD + DOCX + PDF |
| System Prompt | `agent/prompts/system_prompt.md` | MD + DOCX + PDF |
| Warrior Doctrine | `agent/prompts/warrior_doctrine.md` | MD + DOCX + PDF |
| Project README | `README.md` | MD |
| **This continuity doc** | `PROJECT_LOG.md` | MD |

---

## 8. OUTSTANDING TASKS & ROADMAP

### Immediate Next Steps (Priority Order)

```
STEP 1 ─ Push to GitHub
  ├─ Option A (recommended): Create warrior-world GitHub org first
  │   ├─ Create org at github.com/organizations/new
  │   ├─ Install Abacus GitHub App on org
  │   └─ Create warrior-livekit-agent repo in org
  └─ Option B: Create warrior-livekit-agent under princekoya-multiverse
  Then:
  ├─ git init && git add && git commit
  └─ git push origin main

STEP 2 ─ Build & Push Docker Images
  ├─ Choose a container registry (GitHub Container Registry recommended)
  ├─ docker build -f docker/Dockerfile.agent -t ghcr.io/<owner>/warrior-agent:latest .
  ├─ docker build -f docker/Dockerfile.frontend -t ghcr.io/<owner>/warrior-frontend:latest .
  └─ docker push both images

STEP 3 ─ Deploy to Akash
  ├─ Update deploy.yaml with real image refs and secrets
  ├─ Install Akash CLI (or use Akash Console at console.akash.network)
  ├─ Fund deployment wallet (AKT tokens from existing ~$175 balance)
  ├─ Submit deployment → accept bid → services go live
  └─ Note the provider-assigned IP/hostname

STEP 4 ─ Configure Domain
  ├─ In Freename DNS for warriorworld.life:
  │   ├─ A record: @ → Akash provider IP (frontend)
  │   ├─ A record: livekit → Akash provider IP (LiveKit server)
  │   └─ A record: api → Akash provider IP (token server)
  ├─ Wait for DNS propagation
  └─ Verify HTTPS works (if not, configure TLS via Let's Encrypt in Nginx)

STEP 5 ─ End-to-End Test
  ├─ Visit warriorworld.life in Chrome/Firefox/Safari
  ├─ Click connect → grant microphone permission
  ├─ Speak → verify agent responds with voice
  ├─ Test interruption handling
  ├─ Verify avatar animates during agent speech
  └─ Measure round-trip latency (target: < 1.5s)
```

### Known Issues & Limitations

| Issue | Severity | Mitigation |
|---|---|---|
| Akash may limit UDP port range | Medium | TCP fallback via port 7881 + built-in TURN |
| Edge TTS quality is adequate but not premium | Low | Upgrade path to ElevenLabs when budget allows |
| No conversation persistence | Low | By design for Phase 1; Warrior Vault in Phase 2 |
| No user authentication | Low | Phase 1 is a public demo; auth in Phase 2 |
| Deepgram free tier has annual limit (12K min) | Low | Switch to local Whisper if exhausted |
| No HTTPS out of the box on Akash | Medium | Nginx + Let's Encrypt or Akash TLS support |

### Phase 2 Preview: Warrior Vault Integration (Weeks 5–10)

- **Warrior Vault:** Encrypted personal data store per user (health metrics, goals, journal entries)
- **RAG pipeline:** Agent references Warrior OS documentation via retrieval-augmented generation
- **User authentication:** Wallet-based login (Web3 native)
- **Session persistence:** Conversations carry across sessions
- **Enhanced avatar:** GPU-powered face generation on Akash (SadTalker/Wav2Lip)
- **Analytics dashboard:** Conversation metrics, user engagement, system health

### Phase 3 Preview: Multi-Agent B.O.S.S. Orchestration (Weeks 11–20)

```
                ┌──────────────────┐
                │   B.O.S.S.       │
                │   Orchestrator   │
                └────────┬─────────┘
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
 ┌────────────┐  ┌────────────┐  ┌────────────┐
 │  Health     │  │  Wealth    │  │  Life      │
 │  Agent      │  │  Agent     │  │  Agent     │
 └────────────┘  └────────────┘  └────────────┘
```

- **Specialized agents:** Health, Wealth, Life — each an expert in one domain
- **Orchestrator:** Routes queries to the right specialist
- **Cross-agent memory:** Shared context (health data informs wealth decisions)
- **Warrior Marketplace:** Third-party agents can join the ecosystem
- **Mobile app:** Native iOS/Android with always-on agent access

---

## 9. HANDOFF INSTRUCTIONS

### For Future Agents Continuing This Work

**Read these documents in order:**

1. **This file** (`PROJECT_LOG.md`) — you're reading it; it's the master state
2. **Architecture doc** (`/home/ubuntu/warrior_boss_architecture_phase1.md`) — deep technical details
3. **README.md** — quick-start for the project
4. **`docs/local-development.md`** — how to run locally
5. **`docs/akash-deployment.md`** — how to deploy to Akash

### Where to Find Everything

| What | Where |
|---|---|
| All project code | `/home/ubuntu/warrior-livekit-agent/` |
| Architecture document | `/home/ubuntu/warrior_boss_architecture_phase1.md` |
| GitHub inventory | `/home/ubuntu/warrior_github_inventory.md` |
| Agent source code | `/home/ubuntu/warrior-livekit-agent/agent/agent/` |
| Agent personality prompt | `/home/ubuntu/warrior-livekit-agent/agent/prompts/system_prompt.md` |
| Frontend source code | `/home/ubuntu/warrior-livekit-agent/frontend/src/` |
| Docker build files | `/home/ubuntu/warrior-livekit-agent/docker/` |
| Akash manifest | `/home/ubuntu/warrior-livekit-agent/deploy.yaml` |
| All documentation | `/home/ubuntu/warrior-livekit-agent/docs/` |
| Environment templates | `.env.example` (root, agent, frontend) |

### How to Extend the System

**Adding a new knowledge domain:**
1. Create a new prompt file in `agent/prompts/` (e.g., `fitness_domain.md`)
2. Update `agent/agent/config.py` to include it in the system prompt builder
3. Test with `docker compose up` locally

**Changing the agent's voice:**
1. Edit `TTS_VOICE` in `.env` — valid Edge TTS voices: `en-US-GuyNeural`, `en-US-JennyNeural`, etc.
2. Adjust `TTS_RATE` and `TTS_PITCH` for speed/tone

**Upgrading TTS to ElevenLabs:**
1. Add `livekit-plugins-elevenlabs` to `requirements.txt`
2. Replace `EdgeTTS` with ElevenLabs plugin in `main.py`
3. Add `ELEVENLABS_API_KEY` to environment

**Switching STT to local Whisper:**
1. Set `STT_PROVIDER=whisper` in environment
2. Agent will use the OpenAI Whisper plugin (heavier on CPU)

**Adding user authentication (Phase 2):**
1. Implement wallet connect in the frontend
2. Add auth middleware to the token server
3. Include user identity in the LiveKit token metadata

### Who to Contact for Access

- **Project Owner:** princekoya@warriorworld.life
- **GitHub Account:** `princekoya-multiverse`
- **Domain Registrar:** Freename (for warriorworld.life DNS)
- **Akash Account:** Owner manages AKT wallet and deployments
- **Abacus AI:** API key managed by project owner
- **Deepgram:** API key managed by project owner

---

## 10. RESOURCE TRACKING

### Akash Credits

| Metric | Value |
|---|---|
| **Available credits** | ~$175 AKT |
| **Estimated monthly cost** | ~$17/month |
| **Projected runway** | ~10 months |
| **Credits used so far** | $0 (not yet deployed) |

### Monthly Cost Breakdown (Estimated)

| Service | Est. Cost/Month |
|---|---|
| LiveKit Server (1.5 CPU, 1.5GB RAM) | ~$8 |
| Agent Worker (1 CPU, 2GB RAM) | ~$6 |
| Token Server (0.5 CPU, 512MB RAM) | ~$2 |
| Frontend/Nginx (0.5 CPU, 512MB RAM) | ~$1 |
| **Total Akash** | **~$17** |
| Deepgram STT | $0 (free tier: 12,000 min/yr) |
| Edge TTS | $0 (free) |
| Abacus AI LLM | $0 (included) |
| Domain (warriorworld.life) | Already owned |
| **Grand Total** | **~$17/month** |

### Cost Comparison (Why Akash)

| Approach | Monthly Cost |
|---|---|
| **Akash (our plan)** | **~$17** |
| AWS EC2 (t3.medium) | ~$35+ |
| LiveKit Cloud + AWS | ~$80–150 |
| Fly.io | ~$25 |
| Railway | ~$30 |

### Budget Alerts

- **At $17/mo, $175 covers ~10 months.** No urgency, but track actual usage after deployment.
- **Deepgram free tier:** 12,000 minutes/year. At ~30 minutes of demo use per day, that's ~1,000 minutes/month = 12 months. Comfortable, but monitor.
- **Scale-to-zero:** If budget gets tight, close deployment when not demoing and redeploy on demand.

---

## APPENDIX: Quick Reference Commands

### Local Development

```bash
# Clone and setup
cd /home/ubuntu/warrior-livekit-agent
cp .env.example .env                    # Fill in API keys
cp agent/.env.example agent/.env        # Fill in agent keys

# Run locally
docker compose up --build               # All 4 services

# Frontend only (dev mode)
cd frontend && npm run dev

# Agent only (dev mode)
cd agent && source .venv/bin/activate && python -m agent.main dev
```

### Deployment

```bash
# Build images
docker build -f docker/Dockerfile.agent -t <registry>/warrior-agent:latest .
docker build -f docker/Dockerfile.frontend -t <registry>/warrior-frontend:latest .
docker push <registry>/warrior-agent:latest
docker push <registry>/warrior-frontend:latest

# Deploy to Akash (via CLI)
akash tx deployment create deploy.yaml --from <wallet> --node <node> --chain-id <chain>
```

### Generate LiveKit Keys

```bash
cd livekit-server && bash generate-keys.sh
```

---

*Built for Warriors. Proof over theory. Ship it.*

*This document is the single source of truth for the Warrior B.O.S.S. System. Update it whenever the project state changes.*

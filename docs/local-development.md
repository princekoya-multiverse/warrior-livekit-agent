# Local Development

Two ways to run the stack locally: **Docker (recommended)** or **native** (run
each process directly for fast iteration / hot-reload).

---

## Prerequisites

- Docker + Docker Compose (for the Docker path)
- Node.js 20+ and npm (for the native frontend)
- Python 3.11+ (for the native agent)
- An **Abacus AI API key** (LLM) — set as `ABACUS_API_KEY`
- A **Deepgram API key** (STT) — free tier at https://deepgram.com
  - Or set `STT_PROVIDER=whisper` to run STT locally (heavier CPU)
- TTS uses **Edge TTS** — free, no key required

---

## Option A — Docker (full stack)

```bash
cp .env.example .env
# Edit .env: set ABACUS_API_KEY and DEEPGRAM_API_KEY (LiveKit keys can stay devkey/secret)

docker compose up --build
```

Services started:

| Service | URL / Port |
|---|---|
| Frontend | http://localhost:3000 |
| Token server | http://localhost:8080 |
| LiveKit server | ws://localhost:7880 |
| Agent worker | (background, connects to LiveKit) |

Open **http://localhost:3000**, click **Enter the Session**, allow microphone
access, and start talking.

> Running on a remote VM? `localhost` is the VM, not your laptop. Use the VM's
> preview URL for the frontend, and set `LIVEKIT_PUBLIC_URL` to a URL your
> browser can actually reach (a public ws/wss endpoint or tunnel).

---

## Option B — Native (per-process, hot reload)

Open four terminals.

### 1. LiveKit server

Using Docker for just the server (simplest):

```bash
docker run --rm -p 7880:7880 -p 7881:7881 -p 50000-50200:50000-50200/udp \
  -v "$PWD/livekit-server/livekit.yaml:/etc/livekit.yaml" \
  livekit/livekit-server:v1.8 --config /etc/livekit.yaml
```

Or install the binary: https://docs.livekit.io/home/self-hosting/local/

### 2. Agent worker

```bash
cd agent
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env        # set ABACUS_API_KEY, DEEPGRAM_API_KEY
export $(grep -v '^#' .env | xargs)   # load env (or use a dotenv runner)

# Download VAD / turn-detector models once:
python -m agent.main download-files

# Run the worker (dev = auto-reload on file changes):
python -m agent.main dev
```

### 3. Token server

```bash
cd agent && source .venv/bin/activate
export LIVEKIT_API_KEY=devkey LIVEKIT_API_SECRET=secret
export LIVEKIT_PUBLIC_URL=ws://localhost:7880
uvicorn agent.token_server:app --host 0.0.0.0 --port 8080 --reload
```

Test it:

```bash
curl -s http://localhost:8080/healthz
curl -s -X POST http://localhost:8080/token | jq .
```

### 4. Frontend

```bash
cd frontend
npm install
npm run dev        # http://localhost:3000 (Vite proxies /api -> :8080)
```

---

## How a conversation flows

```
mic → browser (WebRTC) → LiveKit server → agent worker
agent: STT → Abacus LLM → Edge TTS → audio → LiveKit → browser → avatar lip-sync
```

The avatar mouth + visualizer are driven client-side by the agent audio
amplitude (`useAudioAmplitude` hook) — no GPU, no extra services.

---

## Switching STT to local Whisper

If you don't want a Deepgram key:

```bash
# in .env
STT_PROVIDER=whisper
```

See `agent/agent/main.py` `_build_stt()` — the local Whisper path is a stub you
can wire to `faster-whisper`. Deepgram is recommended for Phase 1 latency.

## Changing the voice

Edge TTS offers many voices. Set `TTS_VOICE`, e.g.:

- `en-US-GuyNeural` (default — calm male)
- `en-US-ChristopherNeural`
- `en-GB-RyanNeural`

List all: `edge-tts --list-voices`.

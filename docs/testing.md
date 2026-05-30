# Testing Guide

Verify each layer independently, then end-to-end. Work bottom-up so a failure
points at the right component.

---

## 1. Token server

```bash
# Health
curl -s http://localhost:8080/healthz
# -> {"status":"ok"}

# Mint a token
curl -s -X POST http://localhost:8080/token \
  -H 'Content-Type: application/json' -d '{}' | jq .
# -> { "token": "...", "url": "ws://localhost:7880", "room": "warrior-session-...", ... }
```

Decode the JWT at https://jwt.io — confirm it has `video.roomJoin: true` and a
`room` grant, and that `exp` is ~1 hour out.

---

## 2. LiveKit server

```bash
# The HTTP port should respond (validates the SFU is up)
curl -s http://localhost:7880 | head -c 80
# LiveKit returns "OK" on the root health path
```

Check logs for `starting LiveKit server` and the RTC port range.

---

## 3. Agent worker

On startup the worker logs:

```
LLM: Abacus AI RouteLLM (route-llm)
STT: Deepgram (nova-2-general)
registered worker ...
```

Common config warnings (printed, non-fatal):
- `No LLM key found` → set `ABACUS_API_KEY`
- `STT_PROVIDER=deepgram but DEEPGRAM_API_KEY is not set`

### Quick TTS sanity check (no LiveKit needed)

```bash
cd agent && source .venv/bin/activate
python - <<'PY'
import asyncio, edge_tts
async def go():
    c = edge_tts.Communicate("Welcome, Warrior.", voice="en-US-GuyNeural")
    n = 0
    async for ch in c.stream():
        if ch["type"] == "audio":
            n += len(ch.get("data", b""))
    print("edge-tts audio bytes:", n)
asyncio.run(go())
PY
# -> edge-tts audio bytes: >0
```

### Quick LLM sanity check

```bash
python - <<'PY'
import os
from openai import OpenAI
c = OpenAI(api_key=os.environ["ABACUS_API_KEY"], base_url="https://routellm.abacus.ai/v1")
r = c.chat.completions.create(model="route-llm",
    messages=[{"role":"user","content":"Reply OK."}], max_tokens=5)
print(r.choices[0].message.content)
PY
```

If you see `no remaining credits`, top up your Abacus account — the integration
itself is working (auth + routing succeeded).

---

## 4. Frontend

```bash
cd frontend
npm run build      # must finish with no TypeScript errors
npm run dev        # open http://localhost:3000
```

Checklist in the browser:
- [ ] Join screen renders with warrior branding
- [ ] "Enter the Session" requests microphone permission
- [ ] Status moves: Connecting → Waking the Warrior → Listening
- [ ] Agent greets you with the welcome line (audio plays)
- [ ] Avatar mouth + visualizer move while the agent speaks
- [ ] "Mic On/Muted" toggle works; "End Session" returns to join screen

---

## 5. End-to-end conversation test

1. `docker compose up --build`
2. Open http://localhost:3000, enter the session, allow mic.
3. Say: *"What's the Warrior OS?"*
4. Expect a calm, concise spoken answer referencing the Health→…→Purpose chain.
5. Interrupt mid-answer by speaking — the agent should stop and listen.

**Latency target:** < 1.5s round trip. If slower, see troubleshooting
(STT/TTS streaming, region, CPU).

---

## Automated smoke checks

```bash
# Agent package imports + token mint (run from repo root)
cd agent && source .venv/bin/activate
LIVEKIT_API_KEY=devkey LIVEKIT_API_SECRET=secret python -c "
import agent.main, agent.token_server, agent.edge_tts_plugin
from agent.token_server import _mint
assert _mint(None,None,None)['token']
print('agent smoke OK')
"

# Frontend type-check + build
cd ../frontend && npm run build && echo "frontend build OK"
```

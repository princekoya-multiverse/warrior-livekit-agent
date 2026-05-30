# Troubleshooting

Common issues, ordered by where they usually surface.

---

## Connection / WebRTC

### "Enter the Session" spins, never connects
- **Token server down/unreachable.** `curl http://localhost:8080/healthz`.
  Check the Vite proxy (`/api`) target in `vite.config.ts`.
- **Wrong `LIVEKIT_PUBLIC_URL`.** The browser must reach this URL. On a remote
  VM, `ws://localhost:7880` won't work from your laptop — use a public ws/wss
  URL or a tunnel.

### Connects but no audio / "Waking the Warrior…" forever
- **Agent worker not running** or failed to register. Check agent logs for
  `registered worker`. Verify `LIVEKIT_URL`, key, and secret match the server.
- **Key mismatch.** The agent/token-server `LIVEKIT_API_KEY`/`SECRET` must match
  a pair in the server's `keys:` (or `LIVEKIT_KEYS`).

### Audio one-way / drops on some networks
- **UDP blocked.** Enable TCP fallback (`tcp_port: 7881`) and TURN
  (`livekit.prod.yaml`). On Akash, prefer providers with UDP or rely on TURN.
- **`use_external_ip` not set.** Required so the SFU advertises a reachable IP.

### Microphone permission never prompts
- Browsers require **HTTPS** (or `localhost`). Serve the frontend over TLS in
  production — see `domain-setup.md`.

---

## LLM (Abacus AI)

### `no remaining credits to use the LLM apis`
- Auth + routing are working; your Abacus account is out of credits. Top up, or
  set `OPENAI_API_KEY` to use the OpenAI fallback temporarily.

### `401 / unauthorized`
- `ABACUS_API_KEY` is wrong/expired. Re-copy it. Confirm `ABACUS_BASE_URL` is
  `https://routellm.abacus.ai/v1`.

### Responses are slow
- Keep the system prompt concise and history short (`MAX_HISTORY_TURNS`).
- Choose a faster routed model via `ABACUS_MODEL`.

---

## STT (Deepgram / Whisper)

### `DEEPGRAM_API_KEY is not set`
- Set the key, or switch `STT_PROVIDER=whisper` for local STT (more CPU).

### Agent doesn't react when you speak
- VAD threshold / mic level. Speak clearly; check the browser is actually
  publishing (mic toggle shows "Mic On").
- Confirm Deepgram key has quota.

---

## TTS (Edge TTS)

### No agent voice / `APIConnectionError` from TTS
- Edge TTS needs outbound internet to Microsoft's endpoint. Check egress.
- `ffmpeg` must be installed in the agent image (it is, in `Dockerfile.agent`).
  Natively: `apt-get install ffmpeg`.

### Robotic / wrong accent
- Change `TTS_VOICE` (e.g. `en-US-ChristopherNeural`). List voices:
  `edge-tts --list-voices`.

---

## Avatar / frontend

### Avatar doesn't move while agent speaks
- Lip-sync is driven by the **agent's** audio track amplitude. If you only hear
  audio but see no movement, the track may be playing via a different element.
  Confirm `RoomAudioRenderer` is mounted and the agent is the remote
  participant.

### `npm run build` fails on types
- Run `npm install` first. The project is strict-typed; fix the reported file.

---

## Docker / Compose

### `docker compose up` build fails on agent image
- The agent image installs `livekit-agents` + models; ensure internet access
  during build. `download-files` is wrapped in `|| true` so it won't hard-fail.

### Ports already in use
- 3000 / 7880 / 7881 / 8080 may be taken. Stop conflicting processes or remap
  the host ports in `docker-compose.yml`.

> **Reminder:** ports 1000 and 2200 are reserved on the dev VM — do not use.

---

## Akash

### No bids received
- Raise the `pricing.amount` in `deploy.yaml`, or relax resource requests.

### Lease active but service unreachable
- Run `provider-services lease-status` to get the real assigned host/port; the
  external port is usually **not** the same as the container port.
- Check provider UDP support for WebRTC (see akash-deployment.md §5).

---

## Still stuck?

Collect: agent logs, token-server logs, LiveKit server logs, and the browser
console. Most issues are a **key mismatch** or an **unreachable
`LIVEKIT_PUBLIC_URL`** — verify those two first.

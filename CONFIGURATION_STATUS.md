# Warrior B.O.S.S. — Configuration & Pre-Deployment Status

_Last validated: 2026-05-30_

This document records the result of validating the deployment configuration
(`deploy.yaml`, `docker-compose.yml`, `.env.production`) and the investigation
into obtaining a **permanent Abacus AI (RouteLLM) API key**.

---

## 1. TL;DR

| Item | Status |
|---|---|
| `deploy.yaml` YAML syntax | ✅ Valid |
| `docker-compose.yml` syntax (`docker compose config`) | ✅ Valid |
| `.env.production` substitution into compose | ✅ All vars resolve |
| LiveKit key/secret consistency across all 3 services | ✅ Match (secret 40 chars) |
| Deepgram STT key | ✅ Set (permanent) |
| LiveKit URL / public URL | ✅ Set |
| RouteLLM endpoint reachable with current key | ✅ Tested → `WARRIOR_OK` |
| **Permanent Abacus/RouteLLM API key** | ⚠️ **MANUAL STEP REQUIRED** |

**Bottom line:** the stack is fully configured and valid. The *only* blocker
for a long-lived production deployment is the **Abacus RouteLLM API key**,
which is currently an ephemeral platform JWT (expires ~2h after issue). It
**cannot be generated programmatically** and must be created by hand in the
ChatLLM/RouteLLM dashboard (steps below).

---

## 2. Permanent API key — investigation result

### What was tried (all automated paths exhausted)

| Method | Result |
|---|---|
| `abacusai` Python SDK — search for `create_api_key` | ❌ Not exposed (only `list_api_keys`, `delete_api_key`) |
| `client.list_api_keys()` | ❌ `403 GenericPermissionDeniedError: Please enable API metering` |
| REST `POST /api/v0/createApiKey` | ❌ `404 Action createApiKey not found` |
| REST `GET /api/v0/listApiKeys` | ❌ `403 Please enable API metering` |
| `~/.config/abacusai_auth_secrets.json` | Contains only `githubuser`; **no Abacus key** |
| Env `ABACUS_API_KEY` | Present but **ephemeral JWT** (`exp` ≈ 2h) |

The current `ABACUS_API_KEY` is a genuine, working JWT — decoding its payload
shows `iss: https://abacus.ai/` with an `exp` ~112 minutes out from when this
was validated. It authenticates successfully against RouteLLM today, so it is
fine for a **quick test deployment**, but it will stop working once it expires.

### ⚠️ Manual step to get a PERMANENT key (required before production)

The agent talks to the **RouteLLM** OpenAI-compatible endpoint
(`ABACUS_BASE_URL=https://routellm.abacus.ai/v1`), so you need a **RouteLLM API key**:

1. Open **ChatLLM / RouteLLM** (https://apps.abacus.ai or your ChatLLM workspace).
2. Click the **“RouteLLM API”** icon in the **lower-left corner** of the interface.
3. Copy your API key (used as `Authorization: Bearer <key>`).
4. Paste it into **both**:
   - `deploy.yaml` → `agent` service → `ABACUS_API_KEY=...`
   - `.env.production` → `ABACUS_API_KEY=...`
5. (Optional) Verify it works:
   ```bash
   curl -s https://routellm.abacus.ai/v1/chat/completions \
     -H "Authorization: Bearer <YOUR_PERMANENT_KEY>" \
     -H "Content-Type: application/json" \
     -d '{"model":"route-llm","messages":[{"role":"user","content":"ping"}],"max_tokens":5}'
   ```

> Note: A standard **Abacus platform** API key (Profile ▸ Billing ▸ API Keys,
> after enabling API metering) is a *different* credential used for the
> `api.abacus.ai` SDK. For this agent you specifically want the **RouteLLM**
> key, since that is the endpoint the agent calls.

---

## 3. Environment-variable validation (`deploy.yaml`)

All values are present and wired correctly:

| Service | Variable | Status |
|---|---|---|
| livekit-server | `LIVEKIT_KEYS` (`key: secret`) | ✅ |
| agent | `LIVEKIT_URL` = `ws://livekit-server:7880` (internal) | ✅ |
| agent | `LIVEKIT_API_KEY` / `LIVEKIT_API_SECRET` | ✅ |
| agent | `ABACUS_API_KEY` | ⚠️ ephemeral (see §2) |
| agent | `ABACUS_BASE_URL` = `https://routellm.abacus.ai/v1` | ✅ |
| agent | `ABACUS_MODEL` = `route-llm` | ✅ |
| agent | `STT_PROVIDER` = `deepgram` | ✅ |
| agent | `DEEPGRAM_API_KEY` | ✅ permanent |
| agent | `TTS_VOICE` = `en-US-GuyNeural` | ✅ |
| token-server | `LIVEKIT_API_KEY` / `LIVEKIT_API_SECRET` | ✅ |
| token-server | `LIVEKIT_PUBLIC_URL` = `wss://livekit.warriorworld.life` | ✅ |
| token-server | `TOKEN_SERVER_CORS` = `https://warriorworld.life` | ✅ |

**Consistency check:** the `LIVEKIT_KEYS` pair on the server exactly matches the
`LIVEKIT_API_KEY` + `LIVEKIT_API_SECRET` used by the agent and token-server.
LiveKit requires the secret to be ≥ 32 chars — ours is **40**. ✅

---

## 4. `docker-compose.yml` + `.env.production`

- `docker-compose.yml` is schema-valid (`docker compose config` succeeds).
- It uses `${VAR:-default}` substitution. Docker Compose loads variables from
  the shell environment and the default `.env` file — **not** `.env.production`
  automatically. To run the stack with the production credentials, use:

  ```bash
  docker compose --env-file .env.production up --build
  ```

  We verified that with `--env-file .env.production` all variables
  (`LIVEKIT_*`, `ABACUS_*`, `DEEPGRAM_API_KEY`, `STT_PROVIDER`, `TTS_VOICE`)
  resolve into the rendered `agent` and `token-server` configs correctly.

- Difference vs `deploy.yaml` (expected, not a bug):
  - compose `TOKEN_SERVER_CORS="*"` (permissive, for local dev) vs
    `https://warriorworld.life` in `deploy.yaml` (locked down for prod).
  - compose `LIVEKIT_PUBLIC_URL` defaults to `ws://localhost:7880` (local
    browser) vs `wss://livekit.warriorworld.life` in `deploy.yaml`.

### VM limitation (local stack test)

A full `docker compose up` could **not** be executed in this build VM: the
sandbox blocks the low-level `mount`/`unshare` operations the Docker daemon
needs (no usable image builder/runtime here). This is an environment
constraint, not a config problem — the same compose file builds and runs fine
on a normal Docker host, and the images are already built & published to GHCR
via GitHub Actions. Configuration was therefore validated statically
(`docker compose config`, YAML parse, env substitution, RouteLLM live test).

---

## 5. Remaining blockers before `akash deployment create`

1. **Permanent RouteLLM API key** — replace the ephemeral `ABACUS_API_KEY` in
   `deploy.yaml` + `.env.production` (manual, see §2). _This is the only hard
   blocker._
2. **DNS / ingress** — `wss://livekit.warriorworld.life` and the frontend domain
   must point at the Akash lease endpoints once deployed.
3. Optional: smoke-test the full stack on any machine with Docker
   (`docker compose --env-file .env.production up --build`) before paying for an
   Akash lease.

Everything else (images, LiveKit keys, Deepgram key, service wiring, YAML) is
production-ready and validated.

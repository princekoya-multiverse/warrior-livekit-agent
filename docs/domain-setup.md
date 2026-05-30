# Domain Setup — warriorworld.life

Wire your domain to the Akash deployment and serve everything over HTTPS/WSS.

---

## Subdomain plan

| Subdomain | Points to | Purpose |
|---|---|---|
| `warriorworld.life` | frontend service (:80) | The web app |
| `api.warriorworld.life` | token-server (:8080) | LiveKit token API |
| `livekit.warriorworld.life` | livekit-server (:7880/:7881) | WebRTC SFU + TURN |

---

## 1. Get your Akash hosts

After `lease-status` (see akash-deployment.md), note the public host/IP and
ports assigned to each service.

---

## 2. DNS records

In your DNS provider (the domain is registered via Freename per the
architecture doc; use its DNS panel or delegate to Cloudflare):

```
# A or CNAME records pointing to the Akash provider host
warriorworld.life        ->  <frontend-host>
api.warriorworld.life    ->  <token-server-host>
livekit.warriorworld.life->  <livekit-host>
```

If Akash gives you a hostname, use CNAME; if an IP, use A records.

---

## 3. TLS / HTTPS (required for WebRTC mic access)

Browsers only grant microphone access on **HTTPS** (or `localhost`). You need
TLS on at least the frontend and the LiveKit endpoint (WSS).

### Option A — Cloudflare proxy (easiest)

1. Add `warriorworld.life` to Cloudflare, set nameservers.
2. Proxy (orange cloud) the `warriorworld.life` and `api` records.
3. SSL/TLS mode: **Full**. Cloudflare terminates HTTPS for you.
4. For `livekit.warriorworld.life`, WebSocket is supported by Cloudflare, but
   the **UDP media + TURN** still needs direct reachability — keep that record
   **DNS-only (grey cloud)** and rely on LiveKit's TLS/TURN config.

### Option B — Caddy TLS terminator (self-contained)

Add a small Caddy container in front that auto-provisions Let's Encrypt certs:

```
warriorworld.life {
    reverse_proxy frontend:80
}
api.warriorworld.life {
    reverse_proxy token-server:8080
}
livekit.warriorworld.life {
    reverse_proxy livekit-server:7880
}
```

Caddy fetches certs automatically on first request (ports 80/443 must be
exposed on the Akash lease).

---

## 4. Update app config to use the domain

- **Frontend build arg:** `VITE_TOKEN_ENDPOINT=https://api.warriorworld.life/token`
- **Token server env:** `LIVEKIT_PUBLIC_URL=wss://livekit.warriorworld.life`
- **Token server CORS:** `TOKEN_SERVER_CORS=https://warriorworld.life`
- **LiveKit prod config:** `turn.domain: livekit.warriorworld.life`

Rebuild/push the frontend image after changing `VITE_TOKEN_ENDPOINT` (it is
baked at build time), then `provider-services tx deployment update`.

---

## 5. Verify

```bash
# Frontend over HTTPS
curl -sI https://warriorworld.life | head -n1

# Token API over HTTPS
curl -s https://api.warriorworld.life/healthz

# LiveKit WSS handshake (should upgrade)
curl -sI https://livekit.warriorworld.life | head -n1
```

Then open https://warriorworld.life in a browser — mic permission should be
offered (proof TLS is working).

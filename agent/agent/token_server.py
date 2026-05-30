"""
LiveKit token server.

A tiny FastAPI service that mints short-lived LiveKit access tokens so the
browser can join a room. The LiveKit API secret never leaves the server.

Endpoints:
    GET  /healthz                      -> {"status": "ok"}
    POST /token  {room?, identity?}    -> {"token", "url", "room", "identity"}
    GET  /token?room=&identity=        -> same (convenience for quick testing)

Run:
    uvicorn agent.token_server:app --host 0.0.0.0 --port 8080
"""

from __future__ import annotations

import datetime
import os
import time
import uuid

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from livekit import api
from pydantic import BaseModel

from . import config

# Comma-separated list of allowed origins; "*" by default for easy local dev.
_ALLOWED_ORIGINS = os.environ.get("TOKEN_SERVER_CORS", "*").split(",")
# Public ws/wss URL the browser should connect to (may differ from agent URL).
_PUBLIC_LIVEKIT_URL = os.environ.get("LIVEKIT_PUBLIC_URL", config.LIVEKIT_URL)
_TOKEN_TTL_SECONDS = int(os.environ.get("TOKEN_TTL_SECONDS", "3600"))

app = FastAPI(title="Warrior B.O.S.S. Token Server", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in _ALLOWED_ORIGINS if o.strip()],
    allow_methods=["*"],
    allow_headers=["*"],
)


class TokenRequest(BaseModel):
    room: str | None = None
    identity: str | None = None
    name: str | None = None


def _mint(room: str | None, identity: str | None, name: str | None) -> dict:
    room = room or f"warrior-session-{uuid.uuid4().hex[:8]}"
    identity = identity or f"warrior-{uuid.uuid4().hex[:8]}"

    grants = api.VideoGrants(
        room_join=True,
        room=room,
        can_publish=True,
        can_subscribe=True,
        can_publish_data=True,
    )
    token = (
        api.AccessToken(config.LIVEKIT_API_KEY, config.LIVEKIT_API_SECRET)
        .with_identity(identity)
        .with_name(name or identity)
        .with_ttl(datetime.timedelta(seconds=_TOKEN_TTL_SECONDS))
        .with_grants(grants)
    )
    return {
        "token": token.to_jwt(),
        "url": _PUBLIC_LIVEKIT_URL,
        "room": room,
        "identity": identity,
        "expires_at": int(time.time()) + _TOKEN_TTL_SECONDS,
    }


@app.get("/healthz")
def healthz() -> dict:
    return {"status": "ok"}


@app.post("/token")
def create_token(req: TokenRequest) -> dict:
    return _mint(req.room, req.identity, req.name)


@app.get("/token")
def create_token_get(
    room: str | None = None,
    identity: str | None = None,
    name: str | None = None,
) -> dict:
    return _mint(room, identity, name)

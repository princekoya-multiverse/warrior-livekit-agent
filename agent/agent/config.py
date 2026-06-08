"""
Central configuration for the Warrior B.O.S.S. agent worker.

All secrets and tunables are read from environment variables so nothing
sensitive ever lives in source control. See `.env.example` for the full list.
"""

from __future__ import annotations

import json
import os
from pathlib import Path

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_PROMPTS_DIR = Path(__file__).resolve().parent.parent / "prompts"
_ABACUS_SECRETS_PATH = Path.home() / ".config" / "abacusai_auth_secrets.json"


def _read_abacus_key_from_secrets() -> str | None:
    """Best-effort load of an Abacus AI key from the local secrets file.

    Environment variables always take precedence; this is only a convenience
    fallback for local development.
    """
    try:
        if _ABACUS_SECRETS_PATH.exists():
            data = json.loads(_ABACUS_SECRETS_PATH.read_text())
            # Common shapes we may encounter.
            for svc in ("abacusai", "abacus", "abacusAI"):
                node = data.get(svc, {})
                secrets = node.get("secrets", {})
                for key in ("api_key", "access_token"):
                    val = secrets.get(key, {}).get("value")
                    if val:
                        return val
    except Exception:
        pass
    return None


def _env(name: str, default: str | None = None) -> str | None:
    val = os.environ.get(name)
    return val if val not in (None, "") else default


# ---------------------------------------------------------------------------
# LiveKit connection
# ---------------------------------------------------------------------------

LIVEKIT_URL = _env("LIVEKIT_URL", "ws://localhost:7880")
LIVEKIT_API_KEY = _env("LIVEKIT_API_KEY", "devkey")
LIVEKIT_API_SECRET = _env("LIVEKIT_API_SECRET", "devsecret_change_me_0123456789abcdef")

# ---------------------------------------------------------------------------
# LLM — Abacus AI (OpenAI-compatible RouteLLM endpoint)
# ---------------------------------------------------------------------------

# Abacus AI exposes an OpenAI-compatible chat completions API.
ABACUS_BASE_URL = _env("ABACUS_BASE_URL", "https://routellm.abacus.ai/v1")
ABACUS_API_KEY = _env("ABACUS_API_KEY") or _read_abacus_key_from_secrets()
# RouteLLM model alias. "route-llm" auto-routes to a strong general model.
ABACUS_MODEL = _env("ABACUS_MODEL", "route-llm")

# Optional DeepSeek (free for us, OpenAI-compatible).
DEEPSEEK_API_KEY = _env("DEEPSEEK_API_KEY")
DEEPSEEK_BASE_URL = _env("DEEPSEEK_BASE_URL", "https://api.deepseek.com")
DEEPSEEK_MODEL = _env("DEEPSEEK_MODEL", "deepseek-chat")

# Optional OpenAI fallback (only used if explicitly configured).
OPENAI_API_KEY = _env("OPENAI_API_KEY")

# ---------------------------------------------------------------------------
# Speech-to-Text
# ---------------------------------------------------------------------------

# "deepgram" (needs DEEPGRAM_API_KEY) or "whisper" (local, CPU-heavy).
STT_PROVIDER = _env("STT_PROVIDER", "deepgram").lower()
DEEPGRAM_API_KEY = _env("DEEPGRAM_API_KEY")
DEEPGRAM_MODEL = _env("DEEPGRAM_MODEL", "nova-2-general")

# ---------------------------------------------------------------------------
# Text-to-Speech (Edge TTS — free, no key)
# ---------------------------------------------------------------------------

TTS_VOICE = _env("TTS_VOICE", "en-US-GuyNeural")
TTS_RATE = _env("TTS_RATE", "+0%")
TTS_PITCH = _env("TTS_PITCH", "+0Hz")

# ---------------------------------------------------------------------------
# Conversation behaviour
# ---------------------------------------------------------------------------

GREETING = _env(
    "AGENT_GREETING",
    "Welcome, Warrior. I'm here to help you optimize your health, wealth, "
    "and life. What would you like to discuss today?",
)

# Keep only the last N turns to control context size, latency and cost.
MAX_HISTORY_TURNS = int(_env("MAX_HISTORY_TURNS", "10"))


# ---------------------------------------------------------------------------
# Prompt loading
# ---------------------------------------------------------------------------

def load_prompt(name: str) -> str:
    path = _PROMPTS_DIR / name
    if path.exists():
        return path.read_text(encoding="utf-8").strip()
    return ""


def build_system_prompt() -> str:
    """Compose the full system prompt from the personality + doctrine files."""
    system = load_prompt("system_prompt.md")
    doctrine = load_prompt("warrior_doctrine.md")
    parts = [p for p in (system, doctrine) if p]
    return "\n\n---\n\n".join(parts)


def validate() -> list[str]:
    """Return a list of human-readable configuration problems (empty == ok)."""
    problems: list[str] = []
    if not ABACUS_API_KEY and not OPENAI_API_KEY and not DEEPSEEK_API_KEY:
        problems.append(
            "No LLM key found: set ABACUS_API_KEY, OPENAI_API_KEY, or DEEPSEEK_API_KEY."
        )
    if STT_PROVIDER == "deepgram" and not DEEPGRAM_API_KEY:
        problems.append(
            "STT_PROVIDER=deepgram but DEEPGRAM_API_KEY is not set. "
            "Set the key or switch STT_PROVIDER=whisper."
        )
    return problems

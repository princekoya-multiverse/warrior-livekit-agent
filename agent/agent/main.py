"""
Warrior B.O.S.S. — LiveKit Agent Worker

A real-time voice agent that joins a LiveKit room and runs the pipeline:

    user speech --> STT --> Abacus AI LLM --> Edge TTS --> agent speech

The agent embodies the Prince Core OS / Warrior OS personality (calm,
authoritative coaching, proof over hype).

Run locally:
    python -m agent.main dev        # connects to LIVEKIT_URL, hot-reload
    python -m agent.main start      # production worker

Environment is documented in `.env.example`.
"""

from __future__ import annotations

import logging

from livekit.agents import (
    Agent,
    AgentSession,
    JobContext,
    JobProcess,
    RoomInputOptions,
    WorkerOptions,
    cli,
    metrics,
)
from livekit.plugins import deepgram, openai, silero

from . import config
from .edge_tts_plugin import EdgeTTS

logger = logging.getLogger("warrior-agent")
logging.basicConfig(level=logging.INFO)


class WarriorAgent(Agent):
    """The Warrior B.O.S.S. coaching persona."""

    def __init__(self) -> None:
        super().__init__(instructions=config.build_system_prompt())


def _build_llm() -> openai.LLM:
    """Construct an OpenAI-compatible LLM client.

    Priority: DeepSeek > Abacus AI > OpenAI.
    All three expose OpenAI-compatible chat completions APIs.
    """
    if config.DEEPSEEK_API_KEY:
        logger.info("LLM: DeepSeek (%s)", config.DEEPSEEK_MODEL)
        return openai.LLM(
            model=config.DEEPSEEK_MODEL,
            api_key=config.DEEPSEEK_API_KEY,
            base_url=config.DEEPSEEK_BASE_URL,
        )
    if config.ABACUS_API_KEY:
        logger.info("LLM: Abacus AI RouteLLM (%s)", config.ABACUS_MODEL)
        return openai.LLM(
            model=config.ABACUS_MODEL,
            api_key=config.ABACUS_API_KEY,
            base_url=config.ABACUS_BASE_URL,
        )
    if config.OPENAI_API_KEY:
        logger.info("LLM: OpenAI fallback")
        return openai.LLM(model="gpt-4o-mini", api_key=config.OPENAI_API_KEY)
    raise RuntimeError("No LLM key configured.")


def _build_stt():
    """Speech-to-text provider. Deepgram (cloud) or Whisper (local)."""
    if config.STT_PROVIDER == "whisper":
        # Local Whisper via the OpenAI-compatible plugin running faster-whisper
        # is heavier on CPU; Deepgram is the recommended default for Phase 1.
        logger.info("STT: local Whisper")
        return openai.STT()  # placeholder; see docs for local whisper setup
    logger.info("STT: Deepgram (%s)", config.DEEPGRAM_MODEL)
    return deepgram.STT(
        model=config.DEEPGRAM_MODEL,
        api_key=config.DEEPGRAM_API_KEY,
        language="en-US",
    )


def prewarm(proc: JobProcess) -> None:
    """Load heavy models once per worker process (VAD)."""
    proc.userdata["vad"] = silero.VAD.load()


async def entrypoint(ctx: JobContext) -> None:
    problems = config.validate()
    for p in problems:
        logger.warning("CONFIG: %s", p)

    await ctx.connect()
    logger.info("Connected to room: %s", ctx.room.name)

    session: AgentSession = AgentSession(
        vad=ctx.proc.userdata.get("vad") or silero.VAD.load(),
        stt=_build_stt(),
        llm=_build_llm(),
        tts=EdgeTTS(
            voice=config.TTS_VOICE,
            rate=config.TTS_RATE,
            pitch=config.TTS_PITCH,
        ),
        # Graceful interruption handling — the user can cut the agent off.
        allow_interruptions=True,
        min_interruption_duration=0.4,
    )

    # Lightweight usage logging (tokens / audio) for cost awareness.
    usage = metrics.UsageCollector()

    @session.on("metrics_collected")
    def _on_metrics(ev) -> None:  # noqa: ANN001
        metrics.log_metrics(ev.metrics)
        usage.collect(ev.metrics)

    await session.start(
        agent=WarriorAgent(),
        room=ctx.room,
        room_input_options=RoomInputOptions(),
    )

    # Greet the user once on join.
    await session.generate_reply(instructions=f"Greet the user verbatim: {config.GREETING}")


if __name__ == "__main__":
    cli.run_app(
        WorkerOptions(
            entrypoint_fnc=entrypoint,
            prewarm_fnc=prewarm,
            ws_url=config.LIVEKIT_URL,
            api_key=config.LIVEKIT_API_KEY,
            api_secret=config.LIVEKIT_API_SECRET,
        )
    )

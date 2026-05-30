"""
Free Text-to-Speech plugin for LiveKit Agents backed by Microsoft Edge TTS.

`edge-tts` uses the public Microsoft Edge read-aloud service. It requires no API
key and no GPU, which makes it ideal for a cost-optimized Phase 1 deployment.

The plugin emits MP3 chunks; LiveKit's AudioEmitter decodes them internally, so
we only have to forward the raw bytes as they stream in.
"""

from __future__ import annotations

from dataclasses import dataclass

import edge_tts
from livekit.agents import (
    DEFAULT_API_CONNECT_OPTIONS,
    APIConnectionError,
    APIConnectOptions,
    tts,
    utils,
)

# Edge TTS streams MP3 at 24 kHz, mono.
SAMPLE_RATE = 24000
NUM_CHANNELS = 1

# A calm, grounded male voice that fits the Warrior coaching persona.
DEFAULT_VOICE = "en-US-GuyNeural"


@dataclass
class _Opts:
    voice: str
    rate: str
    volume: str
    pitch: str


class EdgeTTS(tts.TTS):
    """LiveKit TTS implementation using the free Microsoft Edge TTS service."""

    def __init__(
        self,
        *,
        voice: str = DEFAULT_VOICE,
        rate: str = "+0%",
        volume: str = "+0%",
        pitch: str = "+0Hz",
    ) -> None:
        super().__init__(
            capabilities=tts.TTSCapabilities(streaming=False),
            sample_rate=SAMPLE_RATE,
            num_channels=NUM_CHANNELS,
        )
        self._opts = _Opts(voice=voice, rate=rate, volume=volume, pitch=pitch)

    def update_options(
        self,
        *,
        voice: str | None = None,
        rate: str | None = None,
        volume: str | None = None,
        pitch: str | None = None,
    ) -> None:
        if voice is not None:
            self._opts.voice = voice
        if rate is not None:
            self._opts.rate = rate
        if volume is not None:
            self._opts.volume = volume
        if pitch is not None:
            self._opts.pitch = pitch

    def synthesize(
        self,
        text: str,
        *,
        conn_options: APIConnectOptions = DEFAULT_API_CONNECT_OPTIONS,
    ) -> "ChunkedStream":
        return ChunkedStream(tts=self, input_text=text, conn_options=conn_options)


class ChunkedStream(tts.ChunkedStream):
    def __init__(
        self,
        *,
        tts: EdgeTTS,
        input_text: str,
        conn_options: APIConnectOptions,
    ) -> None:
        super().__init__(tts=tts, input_text=input_text, conn_options=conn_options)
        self._tts: EdgeTTS = tts
        self._opts = tts._opts

    async def _run(self, output_emitter: tts.AudioEmitter) -> None:
        request_id = utils.shortuuid()
        try:
            communicate = edge_tts.Communicate(
                self.input_text,
                voice=self._opts.voice,
                rate=self._opts.rate,
                volume=self._opts.volume,
                pitch=self._opts.pitch,
            )

            output_emitter.initialize(
                request_id=request_id,
                sample_rate=SAMPLE_RATE,
                num_channels=NUM_CHANNELS,
                mime_type="audio/mp3",
            )

            async for chunk in communicate.stream():
                if chunk["type"] == "audio" and chunk.get("data"):
                    output_emitter.push(chunk["data"])

            output_emitter.flush()
        except Exception as e:  # noqa: BLE001
            raise APIConnectionError() from e

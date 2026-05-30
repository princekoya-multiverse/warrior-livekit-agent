import { useEffect, useRef, useState } from "react";

/**
 * useAudioAmplitude
 *
 * Given a live MediaStreamTrack (typically the agent's published audio),
 * returns a smoothed amplitude value in the range [0, 1] using the Web Audio
 * AnalyserNode. This drives the avatar's lip-sync animation — no GPU and no
 * external dependency required.
 */
export function useAudioAmplitude(track?: MediaStreamTrack | null): number {
  const [amplitude, setAmplitude] = useState(0);
  const rafRef = useRef<number | null>(null);
  const ctxRef = useRef<AudioContext | null>(null);

  useEffect(() => {
    if (!track) {
      setAmplitude(0);
      return;
    }

    const AudioCtx =
      window.AudioContext ||
      (window as unknown as { webkitAudioContext: typeof AudioContext })
        .webkitAudioContext;
    const ctx = new AudioCtx();
    ctxRef.current = ctx;

    const stream = new MediaStream([track]);
    const source = ctx.createMediaStreamSource(stream);
    const analyser = ctx.createAnalyser();
    analyser.fftSize = 512;
    analyser.smoothingTimeConstant = 0.6;
    source.connect(analyser);

    const data = new Uint8Array(analyser.frequencyBinCount);
    let smoothed = 0;

    const tick = () => {
      analyser.getByteFrequencyData(data);
      // Root-mean-square of the spectrum -> perceived loudness.
      let sum = 0;
      for (let i = 0; i < data.length; i++) {
        const v = data[i] / 255;
        sum += v * v;
      }
      const rms = Math.sqrt(sum / data.length);
      // Emphasise speech dynamics and clamp.
      const target = Math.min(1, rms * 2.2);
      smoothed = smoothed * 0.7 + target * 0.3;
      setAmplitude(smoothed);
      rafRef.current = requestAnimationFrame(tick);
    };
    tick();

    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
      try {
        source.disconnect();
      } catch {
        /* noop */
      }
      ctx.close().catch(() => undefined);
    };
  }, [track]);

  return amplitude;
}

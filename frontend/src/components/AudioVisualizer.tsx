import { useEffect, useRef } from "react";

interface AudioVisualizerProps {
  amplitude: number;
  bars?: number;
}

/**
 * A minimal horizontal bar visualizer driven by the agent's audio amplitude.
 * Purely decorative; reinforces "the agent is speaking" feedback.
 */
export function AudioVisualizer({ amplitude, bars = 24 }: AudioVisualizerProps) {
  const ampRef = useRef(0);
  useEffect(() => {
    ampRef.current = amplitude;
  }, [amplitude]);

  return (
    <div className="visualizer" aria-hidden>
      {Array.from({ length: bars }).map((_, i) => {
        // Center bars react more strongly than edges.
        const dist = Math.abs(i - (bars - 1) / 2) / (bars / 2);
        const weight = 1 - dist * 0.7;
        const h = 6 + amplitude * 46 * weight * (0.6 + Math.random() * 0.8);
        return (
          <span
            key={i}
            className="visualizer-bar"
            style={{ height: `${Math.max(4, h)}px` }}
          />
        );
      })}
    </div>
  );
}

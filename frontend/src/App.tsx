import { LiveKitRoom } from "@livekit/components-react";
import "@livekit/components-styles";
import { useCallback, useState } from "react";
import { AgentRoom } from "./components/AgentRoom";
import { fetchJoinToken } from "./config/livekit";

type Phase = "idle" | "connecting" | "connected" | "error";

export default function App() {
  const [phase, setPhase] = useState<Phase>("idle");
  const [token, setToken] = useState<string>("");
  const [serverUrl, setServerUrl] = useState<string>("");
  const [error, setError] = useState<string>("");

  const join = useCallback(async () => {
    setPhase("connecting");
    setError("");
    try {
      const data = await fetchJoinToken();
      setToken(data.token);
      setServerUrl(data.url);
      setPhase("connected");
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
      setPhase("error");
    }
  }, []);

  const leave = useCallback(() => {
    setPhase("idle");
    setToken("");
    setServerUrl("");
  }, []);

  if (phase === "connected" && token && serverUrl) {
    return (
      <div className="app">
        <LiveKitRoom
          token={token}
          serverUrl={serverUrl}
          connect
          audio
          video={false}
          onDisconnected={leave}
          className="lk-room"
        >
          <AgentRoom onDisconnect={leave} />
        </LiveKitRoom>
      </div>
    );
  }

  return (
    <div className="app">
      <div className="join-screen">
        <div className="brand">
          <img src="/warrior.svg" alt="Warrior" className="brand-mark" />
          <h1 className="brand-title">WARRIOR B.O.S.S.</h1>
          <p className="brand-sub">
            Real-time AI advisor · Health · Wealth · Life
          </p>
        </div>

        <div className="join-card">
          <p className="join-copy">
            Speak with the Warrior. Proof over hype — clear answers, one next
            step at a time.
          </p>
          <button
            className="join-btn"
            onClick={join}
            disabled={phase === "connecting"}
          >
            {phase === "connecting" ? "Connecting…" : "Enter the Session"}
          </button>
          {phase === "error" && (
            <p className="join-error">⚠ {error}</p>
          )}
          <p className="join-hint">
            Microphone access is required for voice conversation.
          </p>
        </div>

        <footer className="join-footer">
          Health → Clarity → Decisions → Wealth → Freedom → Purpose
        </footer>
      </div>
    </div>
  );
}

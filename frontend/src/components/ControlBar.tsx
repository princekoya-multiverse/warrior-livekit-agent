import { useLocalParticipant } from "@livekit/components-react";
import { useEffect, useState } from "react";

interface ControlBarProps {
  onDisconnect: () => void;
}

/**
 * Bottom control bar: microphone mute toggle + leave button.
 */
export function ControlBar({ onDisconnect }: ControlBarProps) {
  const { localParticipant } = useLocalParticipant();
  const [micOn, setMicOn] = useState(true);

  // Keep mic enabled on mount so the user is heard immediately.
  useEffect(() => {
    localParticipant?.setMicrophoneEnabled(true).catch(() => undefined);
  }, [localParticipant]);

  const toggleMic = async () => {
    const next = !micOn;
    setMicOn(next);
    await localParticipant?.setMicrophoneEnabled(next).catch(() => undefined);
  };

  return (
    <div className="control-bar">
      <button
        className={`ctrl-btn ${micOn ? "ctrl-on" : "ctrl-off"}`}
        onClick={toggleMic}
        title={micOn ? "Mute microphone" : "Unmute microphone"}
      >
        {micOn ? "🎙️ Mic On" : "🔇 Muted"}
      </button>
      <button className="ctrl-btn ctrl-leave" onClick={onDisconnect}>
        ✕ End Session
      </button>
    </div>
  );
}

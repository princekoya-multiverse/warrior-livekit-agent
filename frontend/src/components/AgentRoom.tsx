import {
  RoomAudioRenderer,
  useConnectionState,
  useTracks,
} from "@livekit/components-react";
import { ConnectionState, Track } from "livekit-client";
import { useMemo } from "react";
import { useAudioAmplitude } from "../hooks/useAudioAmplitude";
import { AudioVisualizer } from "./AudioVisualizer";
import { ControlBar } from "./ControlBar";
import { WarriorAvatar } from "./WarriorAvatar";

interface AgentRoomProps {
  onDisconnect: () => void;
}

/**
 * The in-room experience. Renders the warrior avatar driven by the agent's
 * audio, a visualizer, status text and the control bar. Must be rendered as a
 * child of <LiveKitRoom>.
 */
export function AgentRoom({ onDisconnect }: AgentRoomProps) {
  const connState = useConnectionState();

  // All microphone tracks in the room; the agent is the remote participant.
  const tracks = useTracks([Track.Source.Microphone], {
    onlySubscribed: true,
  });

  const agentTrack = useMemo(() => {
    const remote = tracks.find((t) => !t.participant.isLocal);
    return remote?.publication.track?.mediaStreamTrack ?? null;
  }, [tracks]);

  const amplitude = useAudioAmplitude(agentTrack);
  const connected = connState === ConnectionState.Connected;
  const agentPresent = !!agentTrack;

  const status = !connected
    ? "Connecting…"
    : !agentPresent
    ? "Waking the Warrior…"
    : amplitude > 0.08
    ? "Speaking"
    : "Listening";

  return (
    <div className="agent-stage">
      {/* Plays all subscribed audio (the agent's voice). */}
      <RoomAudioRenderer />

      <div className="avatar-wrap">
        <WarriorAvatar amplitude={amplitude} active={agentPresent} />
      </div>

      <div className="status-row">
        <span className={`status-dot ${agentPresent ? "live" : "wait"}`} />
        <span className="status-text">{status}</span>
      </div>

      <AudioVisualizer amplitude={amplitude} />

      <ControlBar onDisconnect={onDisconnect} />
    </div>
  );
}

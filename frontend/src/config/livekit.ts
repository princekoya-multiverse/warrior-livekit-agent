// LiveKit / token-server configuration for the frontend.

// The endpoint the browser calls to mint a LiveKit join token.
// Defaults to "/api/token" which Vite proxies to the token server in dev.
export const TOKEN_ENDPOINT: string =
  import.meta.env.VITE_TOKEN_ENDPOINT || "/api/token";

export interface JoinTokenResponse {
  token: string;
  url: string;
  room: string;
  identity: string;
  expires_at?: number;
}

/**
 * Request a LiveKit access token + server URL from the token server.
 */
export async function fetchJoinToken(params?: {
  room?: string;
  identity?: string;
  name?: string;
}): Promise<JoinTokenResponse> {
  const res = await fetch(TOKEN_ENDPOINT, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(params ?? {}),
  });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(
      `Token request failed (${res.status}). ${text || "Is the token server running?"}`
    );
  }
  return (await res.json()) as JoinTokenResponse;
}

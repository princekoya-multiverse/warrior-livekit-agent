#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# Generate a LiveKit API key + secret pair.
#
# Usage:
#   ./generate-keys.sh                 # prints key, secret, and env snippets
#   ./generate-keys.sh > keys.env      # save to a file (do NOT commit)
#
# The output is suitable for:
#   - LIVEKIT_KEYS  (server)   ->  "<key>: <secret>"
#   - LIVEKIT_API_KEY / LIVEKIT_API_SECRET  (agent + token server)
# ─────────────────────────────────────────────────────────────────────────
set -euo pipefail

rand() {
  # URL-safe base64 random string of N bytes.
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 "$1" | tr -d '\n/+=' | cut -c1-"$2"
  else
    head -c "$1" /dev/urandom | base64 | tr -d '\n/+=' | cut -c1-"$2"
  fi
}

API_KEY="API$(rand 24 16)"
API_SECRET="$(rand 48 40)"

cat <<EOF
# ── LiveKit credentials (generated $(date -u +%Y-%m-%dT%H:%M:%SZ)) ──
# Server (livekit.yaml keys / LIVEKIT_KEYS env):
LIVEKIT_KEYS=${API_KEY}: ${API_SECRET}

# Agent worker + token server:
LIVEKIT_API_KEY=${API_KEY}
LIVEKIT_API_SECRET=${API_SECRET}

# Reminder: keep these secret. Never commit them to git.
EOF

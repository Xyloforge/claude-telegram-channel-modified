#!/usr/bin/env bash
# Wrapper script that keeps Claude Code running with the Telegram channel.
# When the session ends (e.g. via /new from Telegram), it auto-restarts.
#
# Usage:
#   chmod +x claude-telegram.sh
#   ./claude-telegram.sh
#
# To stop permanently: Ctrl+C or send SIGTERM to this wrapper.

set -euo pipefail

STATE_DIR="${TELEGRAM_STATE_DIR:-$HOME/.claude/channels/telegram}"
RESTART_FLAG="$STATE_DIR/restart-requested"
CLAUDE_CMD="${CLAUDE_CMD:-claude}"

# Pass any extra flags through, e.g.:
#   ./claude-telegram.sh --model opus
EXTRA_FLAGS=("$@")

cleanup() {
  rm -f "$RESTART_FLAG"
  echo "[claude-telegram] wrapper stopped."
  exit 0
}
trap cleanup SIGINT SIGTERM

echo "[claude-telegram] starting Claude Code with Telegram channel..."
echo "[claude-telegram] press Ctrl+C to stop permanently."
echo ""

while true; do
  rm -f "$RESTART_FLAG"

  # Run Claude Code with the Telegram channel plugin.
  "$CLAUDE_CMD" --channels plugin:telegram@claude-plugins-official "${EXTRA_FLAGS[@]+"${EXTRA_FLAGS[@]}"}" || true

  # Check if the exit was a deliberate /new restart or a natural exit.
  if [[ -f "$RESTART_FLAG" ]]; then
    echo ""
    echo "[claude-telegram] /new requested — restarting in 2s..."
    sleep 2
    continue
  fi

  # Natural exit (user typed /exit, Ctrl+C in Claude, etc.) — stop the loop.
  echo ""
  echo "[claude-telegram] session ended normally. Exiting wrapper."
  break
done

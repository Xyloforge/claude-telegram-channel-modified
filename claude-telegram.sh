#!/usr/bin/env bash
# Wrapper script that keeps Claude Code running with the Telegram channel.
# When the session ends (e.g. via /new from Telegram), it auto-restarts.
# Also handles first-time setup for new users.
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_CACHE="$HOME/.claude/plugins/cache/claude-plugins-official/telegram"
ENV_FILE="$STATE_DIR/.env"

# Pass any extra flags through, e.g.:
#   ./claude-telegram.sh --model opus
EXTRA_FLAGS=("$@")

cleanup() {
  rm -f "$RESTART_FLAG"
  echo "[claude-telegram] wrapper stopped."
  exit 0
}
trap cleanup SIGINT SIGTERM

# ── Step 1: Check claude is available ────────────────────────────────────────
if ! command -v "$CLAUDE_CMD" &>/dev/null; then
  echo "[claude-telegram] ERROR: 'claude' CLI not found."
  echo "  Install Claude Code: https://claude.ai/download"
  exit 1
fi

# ── Step 2: Install telegram plugin if missing ────────────────────────────────
if [[ ! -d "$PLUGIN_CACHE" ]]; then
  echo "[claude-telegram] Telegram plugin not installed. Installing now..."
  "$CLAUDE_CMD" plugin install telegram@claude-plugins-official
  echo ""
  # Re-check after install
  if [[ ! -d "$PLUGIN_CACHE" ]]; then
    echo "[claude-telegram] ERROR: plugin install failed. Try manually:"
    echo "  claude plugin install telegram@claude-plugins-official"
    exit 1
  fi
fi

# ── Step 3: Deploy dev server.ts to all installed plugin versions ─────────────
deploy_server() {
  local deployed=0
  for version_dir in "$PLUGIN_CACHE"/*/; do
    if [[ -f "$version_dir/server.ts" ]]; then
      cp "$SCRIPT_DIR/server.ts" "$version_dir/server.ts"
      echo "[claude-telegram] deployed server.ts → $version_dir"
      deployed=$((deployed + 1))
    fi
  done
  if [[ $deployed -eq 0 ]]; then
    echo "[claude-telegram] warning: no server.ts found in plugin cache versions"
  fi
}

# ── Step 4: Check for bot token ───────────────────────────────────────────────
if [[ ! -f "$ENV_FILE" ]] || ! grep -q "TELEGRAM_BOT_TOKEN=" "$ENV_FILE" 2>/dev/null; then
  echo ""
  echo "[claude-telegram] ── First-time setup ──────────────────────────────"
  echo "  No bot token found. You need a Telegram bot token."
  echo ""
  echo "  1. Open Telegram and message @BotFather"
  echo "  2. Send /newbot and follow the prompts"
  echo "  3. Copy the token it gives you, then paste it below."
  echo ""
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR"
  read -r -p "  Paste your TELEGRAM_BOT_TOKEN: " token
  if [[ -z "$token" ]]; then
    echo "[claude-telegram] ERROR: no token provided. Exiting."
    exit 1
  fi
  printf 'TELEGRAM_BOT_TOKEN=%s\n' "$token" > "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  echo "[claude-telegram] token saved to $ENV_FILE"
  echo ""
fi

echo "[claude-telegram] starting Claude Code with Telegram channel..."
echo "[claude-telegram] press Ctrl+C to stop permanently."
echo ""

while true; do
  rm -f "$RESTART_FLAG"

  deploy_server

  # Run Claude Code with the Telegram channel plugin.
  "$CLAUDE_CMD" --channels plugin:telegram@claude-plugins-official "${EXTRA_FLAGS[@]+"${EXTRA_FLAGS[@]}"}" || true

  # Check if the exit was a deliberate /new or /compact restart or a natural exit.
  if [[ -f "$RESTART_FLAG" ]]; then
    echo ""
    echo "[claude-telegram] restarting in 2s..."
    sleep 2
    continue
  fi

  # Natural exit (user typed /exit, Ctrl+C in Claude, etc.) — stop the loop.
  echo ""
  echo "[claude-telegram] session ended normally. Exiting wrapper."
  break
done

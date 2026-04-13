#!/usr/bin/env bash
set -euo pipefail

# ─── Config ───────────────────────────────────────────────────────────────────
REPO_URL="https://github.com/GITHUB_USER/GITHUB_REPO"   # ← update before sharing
PLUGIN_NAME="telegram-custom"
REGISTRY="local"
VERSION="0.0.5"
INSTALL_DIR="$HOME/.claude/plugins/cache/$REGISTRY/$PLUGIN_NAME/$VERSION"
OFFICIAL_CACHE="$HOME/.claude/plugins/cache/claude-plugins-official/telegram/0.0.5"
SETTINGS_FILE="$HOME/.claude/settings.json"
INSTALLED_FILE="$HOME/.claude/plugins/installed_plugins.json"
STATE_DIR="$HOME/.claude/channels/telegram"
ENV_FILE="$STATE_DIR/.env"

# ─── Helpers ──────────────────────────────────────────────────────────────────
info()    { printf '\033[0;34m[info]\033[0m %s\n' "$*"; }
success() { printf '\033[0;32m[done]\033[0m %s\n' "$*"; }
warn()    { printf '\033[0;33m[warn]\033[0m %s\n' "$*"; }
die()     { printf '\033[0;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

# ─── Sync mode: deploy server.ts to the official plugin cache ─────────────────
# Usage: ./install.sh sync
if [[ "${1:-}" == "sync" ]]; then
  if [ ! -d "$OFFICIAL_CACHE" ]; then
    die "Official telegram plugin not installed at $OFFICIAL_CACHE. Install it first via Claude Code."
  fi
  cp "$(dirname "$0")/server.ts" "$OFFICIAL_CACHE/server.ts"
  success "Deployed server.ts → $OFFICIAL_CACHE/server.ts"
  echo ""
  echo "  Restart Claude Code or run ./claude-telegram.sh to pick up changes."
  exit 0
fi

# ─── Prerequisites ────────────────────────────────────────────────────────────
command -v bun  &>/dev/null || die "bun is required. Install: curl -fsSL https://bun.sh/install | bash"
command -v git  &>/dev/null || die "git is required."
command -v python3 &>/dev/null || die "python3 is required."

# ─── Clone / update ───────────────────────────────────────────────────────────
if [ -d "$INSTALL_DIR/.git" ]; then
  info "Updating existing installation at $INSTALL_DIR ..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  info "Cloning plugin to $INSTALL_DIR ..."
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

# ─── Install dependencies ─────────────────────────────────────────────────────
info "Installing dependencies ..."
(cd "$INSTALL_DIR" && bun install --no-summary)

# ─── Bot token setup ──────────────────────────────────────────────────────────
mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"

if grep -q "TELEGRAM_BOT_TOKEN" "$ENV_FILE" 2>/dev/null; then
  info "Bot token already configured (${ENV_FILE})."
else
  echo ""
  echo "  Create a bot with @BotFather on Telegram and paste the token below."
  echo "  Format: 123456789:AAHfiqksKZ8..."
  echo ""
  read -rp "  Telegram bot token: " BOT_TOKEN
  [ -z "$BOT_TOKEN" ] && die "No token entered. Run the installer again when you have one."
  printf 'TELEGRAM_BOT_TOKEN=%s\n' "$BOT_TOKEN" > "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  success "Token saved to $ENV_FILE"
fi

# ─── Register in installed_plugins.json ───────────────────────────────────────
info "Registering plugin ..."
python3 - "$INSTALLED_FILE" "$PLUGIN_NAME" "$REGISTRY" "$INSTALL_DIR" "$VERSION" << 'PY'
import json, sys, os
from datetime import datetime, timezone

path, name, registry, install_path, version = sys.argv[1:]
key = f"{name}@{registry}"
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")
entry = {
    "scope": "user",
    "installPath": install_path,
    "version": version,
    "installedAt": now,
    "lastUpdated": now,
}

try:
    with open(path) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {"version": 2, "plugins": {}}

data.setdefault("version", 2)
data.setdefault("plugins", {})
data["plugins"][key] = [entry]

os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"  registered {key}")
PY

# ─── Enable in settings.json ──────────────────────────────────────────────────
info "Enabling plugin in settings.json ..."
python3 - "$SETTINGS_FILE" "$PLUGIN_NAME" "$REGISTRY" << 'PY'
import json, sys, os

path, name, registry = sys.argv[1:]
key = f"{name}@{registry}"

try:
    with open(path) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {}

data.setdefault("enabledPlugins", {})
data["enabledPlugins"][key] = True

with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"  enabled {key}")
PY

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
success "Plugin installed!"
echo ""
echo "  Next steps:"
echo "  1. Restart Claude Code (or run /reload-plugins)"
echo "  2. Run /telegram:access to manage who can message Claude"
echo "  3. Message your bot on Telegram — it will reply with a pairing code"
echo ""
echo "  Bot commands available:"
echo "  /status  — check pairing state"
echo "  /model   — view or change the AI model"
echo "  /new     — restart the Claude Code session"
echo ""

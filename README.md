# Telegram for Claude Code (Extended)

A modified version of the official [telegram@claude-plugins-official](https://github.com/anthropics/claude-plugins-official) plugin with a full suite of extra bot commands for managing Claude Code remotely from your phone.

## Prerequisites

- [Bun](https://bun.sh) — `curl -fsSL https://bun.sh/install | bash`
- A Telegram bot token from [@BotFather](https://t.me/BotFather)
- [tmux](https://github.com/tmux/tmux) — optional, required for `/console` only (`brew install tmux`)

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/GITHUB_USER/GITHUB_REPO/main/install.sh | bash
```

Then run `./claude-telegram.sh` (or restart Claude Code) and run `/telegram:access` to pair your Telegram account.

## Usage

1. Message your bot on Telegram — it replies with a 6-char pairing code
2. In Claude Code: `/telegram:access pair <code>`
3. Your Telegram messages now reach Claude, and Claude can reply back

---

## Commands

### Session control

| Command | Description |
|---------|-------------|
| `/new` | Restart the Claude Code session |
| `/compact` | Ask Claude to save a context summary, then restart |

### Model & performance

| Command | Description |
|---------|-------------|
| `/model` | Show current model |
| `/model <name>` | Change model for next session (`sonnet`, `opus`, `haiku`, or full ID) |
| `/effort` | Show current thinking budget |
| `/effort <level>` | Set thinking budget: `off`, `low`, `medium`, `high`, `max`, or a token count |
| `/stats` | Show model, effort, context window, uptime, and message count |

### Permissions & tools

| Command | Description |
|---------|-------------|
| `/cmdlist` | List tools that are auto-approved (no permission prompt) |
| `/cmdremove <tool>` | Remove a tool from the auto-approved list |
| `/deny` | List denied tools |
| `/deny add <pattern>` | Block Claude from using a tool (e.g. `Bash`, `Write`) |
| `/deny remove <pattern>` | Unblock a tool |

### Settings

| Command | Description |
|---------|-------------|
| `/context` | View the persistent context summary injected at session start |
| `/context <text>` | Replace the context summary with new text |
| `/context clear` | Clear the context summary |
| `/dirs` | List allowed directories (`permissions.additionalDirectories`) |
| `/dirs add <path>` | Add a directory Claude can access |
| `/dirs remove <path>` | Remove a directory |
| `/plugins` | List enabled/disabled plugins with status |
| `/plugins toggle <name>` | Enable or disable a plugin |

> Settings commands write to `~/.claude/settings.json`. Changes take effect on the next session — use `/new` to restart immediately.

### System & monitoring

| Command | Description |
|---------|-------------|
| `/shell <cmd>` | *(disabled — uncomment in server.ts to enable)* Run a shell command and get output |
| `/logs [n]` | Show last N bash commands Claude ran (default 20, max 50) |
| `/console` | List tmux sessions with a live preview of each pane *(requires tmux)* |
| `/console <session>` | Dump the full terminal output of a tmux session *(requires tmux)* |
| `/cost` | Show estimated API cost — today and all-time |

#### `/shell` safety blocklist

The `/shell` command blocks dangerous patterns to prevent accidents:

- `sudo` — privilege escalation
- `rm -rf /`, `rm -rf ~` — recursive deletion of root or home
- `dd of=/dev/...` — writing directly to disk devices
- `mkfs` — format a filesystem
- `shutdown`, `reboot`, `poweroff`, `halt` — system shutdown
- Fork bombs (`:(){ :|:& };:`)
- Writing to device files (`> /dev/sdX`)
- Pipe-to-shell patterns (`curl ... | bash`, `wget ... | sh`)

#### `/console` — reading your terminal

`/console` uses `tmux capture-pane` to dump the actual terminal screen of a running session — the same output you see in your terminal. If only one tmux session exists it dumps it automatically. If there are multiple it shows a 2-line preview of each so you can identify the right one.

Requires tmux (`brew install tmux`). If not installed, the command will tell you.

---

## Access control

Run `/telegram:configure` or `/telegram:access` in Claude Code to manage who can reach you. See [ACCESS.md](ACCESS.md) for details.

## Updating

Re-run the install script — it does `git pull` if the plugin is already installed.

```bash
curl -fsSL https://raw.githubusercontent.com/GITHUB_USER/GITHUB_REPO/main/install.sh | bash
```

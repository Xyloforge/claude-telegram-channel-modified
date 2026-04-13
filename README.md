# Telegram for Claude Code (Extended)

A modified version of the official [telegram@claude-plugins-official](https://github.com/anthropics/claude-plugins-official) plugin, adding two extra Telegram bot commands:

| Command | Description |
|---------|-------------|
| `/model` | View or change the AI model for the next session |
| `/new` | Restart the Claude Code session |

Everything else (pairing, access control, permission relay, `/status`) is identical to the official plugin.

## Prerequisites

- [Bun](https://bun.sh) — `curl -fsSL https://bun.sh/install | bash`
- A Telegram bot token from [@BotFather](https://t.me/BotFather)

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/GITHUB_USER/GITHUB_REPO/main/install.sh | bash
```

Then run `./claude-telegram.sh` (or restart Claude Code) and run `/telegram:access` to pair your Telegram account.

## Usage

1. Message your bot on Telegram — it replies with a 6-char pairing code
2. In Claude Code: `/telegram:access pair <code>`
3. Now your Telegram messages reach Claude

### Switching models from Telegram

```
/model              # show current model
/model sonnet       # switch to Sonnet
/model opus         # switch to Opus
/model haiku        # switch to Haiku
```

Takes effect on the next session. Use `/new` to restart immediately.

## Access control

Run `/telegram:configure` or `/telegram:access` in Claude Code to manage who can reach you.

## Updating

Re-run the install script — it does `git pull` if the plugin is already installed.

```bash
curl -fsSL https://raw.githubusercontent.com/GITHUB_USER/GITHUB_REPO/main/install.sh | bash
```

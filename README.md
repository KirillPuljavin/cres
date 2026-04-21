# cres

Claude RESume. Drop-in replacement for the broken `/resume` picker in Claude Code. Reads raw JSONL session history, runs `claude -r <id>` for you. About 60 lines of bash. Works on Linux and macOS.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/KirillPuljavin/cres/main/install.sh | bash
```

Detects your package manager (apt, dnf, pacman, zypper, apk, brew) and pulls in `jq` and `fzf` if missing. Works on Linux and macOS.

Or via Homebrew:

```bash
brew install kirillpuljavin/cres/cres
```

<details>
<summary>Manual install</summary>

Install `jq` and `fzf` yourself, then:

```bash
curl -fsSL https://raw.githubusercontent.com/KirillPuljavin/cres/main/cres -o /usr/local/bin/cres
chmod +x /usr/local/bin/cres
```
</details>

## Usage

```
$ cres
resume ▸
↑↓ select · enter resume · esc cancel
  just now   │ check cres                                    │ 1f3fa5f2-…
  15m ago    │ debugging the auth middleware                 │ ec5a0f24-…
  5h ago     │ read session_2026-04-19_enod.md               │ 49d6ed11-…
```

Pick a session, hit enter, you're back in.

## Configuration

Default list size is 20 sessions. Override with `CRES_LIMIT`:

```bash
CRES_LIMIT=100 cres      # one-off
export CRES_LIMIT=100    # add to .bashrc/.zshrc to persist
```

Non-integer or zero values fall back to 20 silently.

## Why

Claude Code's `/resume` picker has a cluster of open bugs right now. It's not one broken thing, it's a family of fragile heuristics in the picker's session-validation layer. Hitting any of them makes sessions invisible or unselectable:

- [#49128](https://github.com/anthropics/claude-code/issues/49128): `/resume` shows "No conversations found" even with sessions on disk.
- [#51392](https://github.com/anthropics/claude-code/issues/51392): Picker sort order, UUID search, and older-format sessions fail to open (affects 2.1.81, 2.1.105, 2.1.114).
- [#41946](https://github.com/anthropics/claude-code/issues/41946): Picker doesn't show a valid, recently completed session.
- [#39658](https://github.com/anthropics/claude-code/issues/39658): Sessions created after `/clear` are invisible because their first JSONL record is malformed.
- [#46522](https://github.com/anthropics/claude-code/issues/46522): Picker hides sessions with mixed `cwd` history (e.g. after a project directory rename).
- [#48513](https://github.com/anthropics/claude-code/issues/48513): Picker shows the last message as the preview instead of the first, which is almost always less useful for identifying a session.
- [#42311](https://github.com/anthropics/claude-code/issues/42311): `--resume` picker behavior for `claude -p` and SDK sessions is undocumented.

Common thread: the picker trusts its own validation heuristics layered on top of the session files. The files on disk are always fine. Every bug above is a different way the picker's logic can misinterpret or reject them.

`cres` sidesteps the picker entirely. It reads the raw JSONL session journal, filters and labels sessions with explicit rules, and invokes `claude -r <id>` directly. None of the picker code runs.

## How it works

Claude Code stores session history as JSONL files at `~/.claude/projects/<cwd-slug>/`. Each file is one full session: user turns, assistant turns, tool calls, permission state, file snapshots.

`cres` does this:

1. Lists `.jsonl` files in your project dir, sorted by mtime.
2. Keeps only interactive sessions (first-line record type is `permission-mode` or `file-history-snapshot`).
3. Extracts a title via `jq` (prefers `ai-title`, falls back to `custom-title`, then the first user message).
4. Pipes into `fzf`.
5. Runs `exec claude -r <selected-id>`.

No config, no state, no daemon.

## The first-line filter

If you run headless `claude -p` in the same workspace (MCP servers, background agents, cron tasks, any automation), those sessions end up in the same project directory as your TTY ones. Without filtering they bleed into the resume list.

The filter is structural. CC CLI writes a different first JSONL record depending on launch mode: TTY launches start with a permission-state record, headless print runs start with an auto-generated title. `cres` checks line 1 of each file and keeps only TTY-flavored ones.

This behavior is undocumented upstream ([#42311](https://github.com/anthropics/claude-code/issues/42311)), so the filter is `cres`'s take on how the picker should behave here.

## Why bypass instead of wait for fixes

The bugs above are in the picker's validation and rendering layer, not in the session files themselves. Patching one bug doesn't protect you from the next. Reading the journal directly does.

`cres` stays useful as long as the picker has validation heuristics separate from the raw session data. If Anthropic unifies that, swap back.

## Uninstall

```bash
sudo rm /usr/local/bin/cres
```

## License

MIT. See [LICENSE](LICENSE).

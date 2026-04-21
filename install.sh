#!/usr/bin/env bash
set -euo pipefail

REPO="KirillPuljavin/cres"
SCRIPT_URL="https://raw.githubusercontent.com/${REPO}/main/cres"
INSTALL_PATH="/usr/local/bin/cres"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m  %s\n' "$*" >&2; exit 1; }

if   command -v brew    >/dev/null 2>&1; then PM="brew";   INSTALL="brew install"
elif command -v apt-get >/dev/null 2>&1; then PM="apt";    INSTALL="sudo apt-get install -y"
elif command -v dnf     >/dev/null 2>&1; then PM="dnf";    INSTALL="sudo dnf install -y"
elif command -v pacman  >/dev/null 2>&1; then PM="pacman"; INSTALL="sudo pacman -S --noconfirm"
elif command -v zypper  >/dev/null 2>&1; then PM="zypper"; INSTALL="sudo zypper install -y"
elif command -v apk     >/dev/null 2>&1; then PM="apk";    INSTALL="sudo apk add"
else die "No supported package manager found. Install jq and fzf manually then rerun."
fi

say "package manager: $PM"

missing=()
for dep in jq fzf; do
  command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
done

if (( ${#missing[@]} > 0 )); then
  say "installing: ${missing[*]}"
  [ "$PM" = "apt" ] && sudo apt-get update -qq
  $INSTALL "${missing[@]}"
else
  say "jq and fzf already installed"
fi

command -v claude >/dev/null 2>&1 || warn "claude not on PATH. Install Claude Code from https://claude.com/claude-code"

say "installing cres to $INSTALL_PATH"
if [ -w /usr/local/bin ] || [ "$(id -u)" = "0" ]; then
  curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH"
  chmod +x "$INSTALL_PATH"
else
  sudo curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH"
  sudo chmod +x "$INSTALL_PATH"
fi

say "done. run 'cres' in any Claude Code project directory."

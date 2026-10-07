#!/usr/bin/env bash
# Re-apply the sidebar chat look (bubbles, quiet headers, hover controls) after an end-4 update
# (./setup install overwrites ~/.config/quickshell). Safe to run twice: already-applied = skip.
set -e
cd "$HOME/.config/quickshell/ii"
p="$(dirname "$(readlink -f "$0")")/chat-style.patch"
if patch -p1 --dry-run -R -s -f < "$p" >/dev/null 2>&1; then
    echo "chat-style patch already applied"
else
    patch -p1 -N < "$p"
fi

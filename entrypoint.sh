#!/bin/bash
set -e

# Bootstrap GSD into ~/.claude volume on first run (or if volume was recreated)
if [ ! -f "/home/claude/.claude/commands/gsd-help.md" ]; then
    su - claude -c 'npx get-shit-done-cc@latest --claude --global --portable-hooks'
fi

exec /usr/sbin/sshd -D

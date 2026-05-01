#!/bin/bash
set -e

# Bootstrap GSD into ~/.claude volume on first run (or if volume was recreated)
if [ ! -f "/home/claude/.claude/commands/gsd-help.md" ]; then
    su - claude -c 'export NVM_DIR=/home/claude/.nvm && . "$NVM_DIR/nvm.sh" && npx get-shit-done-cc@latest --claude --global --portable-hooks' || echo "[entrypoint] GSD bootstrap failed — container will still start"
fi

exec /usr/sbin/sshd -D

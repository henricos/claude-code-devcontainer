#!/bin/bash
set -e

# Bootstrap GSD into ~/.claude volume on first run (or if volume was recreated)
if [ ! -f "/home/claude/.claude/skills/gsd-help/SKILL.md" ] && [ ! -f "/home/claude/.claude/commands/gsd-help.md" ]; then
    su - claude -c 'export NVM_DIR=/home/claude/.nvm && export CLAUDE_CONFIG_DIR=/home/claude/.claude && . "$NVM_DIR/nvm.sh" && get-shit-done-cc --claude --global --portable-hooks' || echo "[entrypoint] GSD bootstrap failed — container will still start"
fi

exec /usr/sbin/sshd -D

#!/bin/bash
set -e

# Fix ownership of SSH volume so sshd can read authorized_keys
# regardless of the UID that owns the mounted host directory
if [ -d /home/claude/.ssh ]; then
    chown -R claude:claude /home/claude/.ssh
    chmod 700 /home/claude/.ssh
    [ -f /home/claude/.ssh/authorized_keys ] && chmod 600 /home/claude/.ssh/authorized_keys
fi

exec /usr/sbin/sshd -D

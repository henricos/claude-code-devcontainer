FROM ubuntu:24.04

ARG IMAGE_VERSION=dev
ARG BUILD_DATE

ENV DEBIAN_FRONTEND=noninteractive \
    NVM_DIR=/home/claude/.nvm

# System packages — changes rarely, kept first for cache efficiency
RUN apt-get update && apt-get install -y \
    curl wget git ca-certificates gnupg \
    openssh-server \
    python3 python3-pip python3-venv \
    tmux htop nano jq build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# yq — YAML processor
RUN wget -qO /usr/local/bin/yq \
    https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq

# uv + yt-dlp via pip (--break-system-packages required on Ubuntu 24.04 / PEP 668)
RUN pip3 install uv yt-dlp --break-system-packages

# Docker CLI — connects to host daemon via socket volume mount
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /usr/share/keyrings/docker.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu noble stable" \
    > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y docker-ce-cli \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# gh CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli.gpg] \
    https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Non-root user — rename the ubuntu user (UID 1000) to claude so it aligns with typical host UIDs
RUN usermod -l claude ubuntu && \
    usermod -d /home/claude -m claude && \
    groupmod -n claude ubuntu

# Switch to claude for nvm + Node + global npm packages
USER claude
WORKDIR /home/claude

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install 22 \
    && nvm alias default 22 \
    && npm install -g @anthropic-ai/claude-code playwright

# Make nvm available in login shells (SSH sessions source .profile)
RUN echo '. "$NVM_DIR/nvm.sh"' >> /home/claude/.profile

# SSH setup requires root
USER root
RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && mkdir -p /home/claude/.ssh \
    && chmod 700 /home/claude/.ssh \
    && chown claude:claude /home/claude/.ssh

LABEL org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://github.com/henricos/claude-code-devcontainer"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]

Projeto: claude-workstation

1. Objetivo
Criar uma Estação de Trabalho IA (Workstation) persistente e isolada para rodar o Claude Code (CLI oficial da Anthropic) dentro de um homelab. O projeto visa centralizar as ferramentas de desenvolvimento (Node, Python, Git) em uma imagem Docker customizada, permitindo que o agente de IA manipule repositórios locais com persistência de sessão e acesso remoto via SSH.

2. Arquitetura e Fluxo
- Build: Automatizado via GitHub Actions (CI/CD).
- Registry: Imagem pública hospedada no GHCR (GitHub Container Registry).
- Deployment: Docker Compose via Portainer no Homelab.
- Acesso: SSH direto ao container (Porta 2222) para desenvolvimento remoto (VS Code Remote, Tmux).
- Persistência: Volumes mapeados para manter o login OAuth do Claude e as chaves SSH do usuário.

3. Sugestão de DockerfileFROM ubuntu:24.04
```
# Configurações de ambiente
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /work

# Instalação de pacotes essenciais e SSH
RUN apt-get update && apt-get install -y \
    curl git python3 python3-pip python3-venv openssh-server \
    tmux vim htop ca-certificates \
    && curl -fsSL [https://deb.nodesource.com/setup_22.x](https://deb.nodesource.com/setup_22.x) | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalação global do Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Configuração do daemon de SSH para aceitar apenas chaves públicas
RUN mkdir /var/run/sshd \
    && sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && mkdir -p /root/.ssh && chmod 700 /root/.ssh

# Script de inicialização (entrypoint)
RUN echo '#!/bin/bash\n/usr/sbin/sshd -D &\necho "Claude Code Agent pronto na porta 2222"\ntail -f /dev/null' > /entrypoint.sh \
    && chmod +x /entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
```

4. Sugestão de .github/workflows/publish.ymlname: Build and Publish Claude Agent
```
on:
  push:
    branches: ['main']

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and Push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
```

5. Sugestão de compose.example (Portainer)
```
services:
  claude-workstation:
    image: ghcr.io/SEU_USUARIO/claude-workstation:latest
    container_name: claude-workstation
    restart: unless-stopped
    ports:
      - "2222:22" # Acesso SSH local via porta alternativa
    volumes:
      # Dados de configuração e login (OAuth) do Claude
      - /dados/disco1/containers/volumes/claudebox/data:/root/.claude
      # Chaves SSH públicas para permitir seu acesso
      - /dados/disco1/containers/volumes/claudebox/ssh:/root/.ssh:ro
      # Seus repositórios de código
      - /home/servico/github:/work
    networks:
      - claude_internal

networks:
  claude_internal:
    driver: bridge
```

6. Checklist de Implementação
- Criar o repositório claude-workstation no GitHub.
- Subir o Dockerfile e o .github/workflows/publish.yml.
- No seu servidor, garanta que o arquivo /dados/disco1/containers/volumes/claudebox/ssh/authorized_keys contenha sua chave pública.
- Execute o deploy via Portainer.
- Acesse via ssh -p 2222 root@<ip-do-servidor>.
- Rode o comando claude para realizar o login inicial.

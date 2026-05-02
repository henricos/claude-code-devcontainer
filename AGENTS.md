# Agent Context: claude-workstation

## What this repository is

A Docker image that packages Claude Code (Anthropic CLI) with a full development toolchain into a persistent, SSH-accessible workstation. The image is designed to run 24/7 in a homelab environment and is published to GHCR via GitHub Actions.

## Repository structure

```
.
├── Dockerfile              # Image definition
├── entrypoint.sh           # Container startup (starts sshd)
├── compose.example.yml     # Deployment reference for Portainer / Docker Compose
├── VERSION                 # Single source of truth for the image version
├── .github/
│   └── workflows/
│       └── release-ghcr.yml  # CI/CD: build and publish on tag push
├── CLAUDE.md               # Loads this file via @AGENTS.md
└── AGENTS.md               # This file
```

## What's installed in the image

| Category | Tools |
|---|---|
| Shell & system | bash, tmux, htop, nano/pico |
| Version control | git, gh (GitHub CLI) |
| Node.js | nvm (default: Node 22), npm, npx |
| Python | python3, pip, venv, uv |
| Data tools | jq, yq |
| Containers | docker CLI (no daemon — connects via socket volume) |
| Media | yt-dlp |
| Browser automation | playwright (npm global) |
| AI | Claude Code (`claude` CLI), GSD installer (`get-shit-done-cc`) |

## Local build

```bash
docker build -t claude-workstation .
```

## Release workflow

To publish a new image version:

1. Update `VERSION` with the new semver (e.g. `1.1.0`)
2. Commit, tag, and push:

```bash
git commit -am "chore: bump version to 1.1.0"
git tag v1.1.0
git push && git push --tags
```

GitHub Actions validates that `VERSION` matches the tag, then builds and pushes:
- `ghcr.io/henricos/claude-workstation:v1.1.0`
- `ghcr.io/henricos/claude-workstation:latest`

## Fechar uma versão (guia para o agente)

Este guia define o fluxo canônico que o agente deve seguir quando o usuário pedir para fechar uma versão, soltar uma release, criar uma tag ou publicar uma nova imagem.

**Regras invioláveis:**
- Nunca prossiga se a branch atual não for `main`.
- Nunca prossiga se `main` local não estiver alinhada com `origin/main`.
- Nunca prossiga se a working tree não estiver limpa.
- Nunca faça commit, stash ou reset automático para "destravar" a release.

### Passo 1 — Verificar pré-condições

```bash
git branch --show-current
git fetch origin
git rev-parse HEAD
git rev-parse origin/main
git diff --quiet && git diff --cached --quiet
```

Aborte com mensagem clara se qualquer condição não for atendida.

### Passo 2 — Determinar a próxima versão

Leia a versão atual do arquivo `VERSION` e calcule as três opções canônicas. Pergunte ao usuário qual bump aplicar antes de continuar:

- `patch` — correções e ajustes menores
- `minor` — novas funcionalidades sem quebra de compatibilidade
- `major` — mudanças que alteram o comportamento de forma significativa

Confirme a versão escolhida antes de executar qualquer comando.

### Passo 3 — Gate local

Execute o build local para garantir que a imagem constrói sem erros antes de criar a tag:

```bash
docker build -t claude-workstation:release-gate .
```

Se o build falhar, **aborte**. Não crie tag sobre código que não builda.

### Passo 4 — Aplicar o bump

Atualize o arquivo `VERSION`, faça o commit e crie a tag:

```bash
echo "X.Y.Z" > VERSION
git add VERSION
git commit -m "chore: bump version to X.Y.Z"
git tag vX.Y.Z
```

### Passo 5 — Publicar

```bash
git push && git push --tags
```

Se o push falhar, **aborte** e informe que a cadeia externa não foi disparada.

### Passo 6 — Validar a cadeia externa

Após o push, confirme:

1. **GitHub Actions** — existe uma run do workflow `Build and Release` para a tag; o job terminou com `success`.
2. **GHCR** — o pacote `ghcr.io/henricos/claude-workstation` tem as tags `vX.Y.Z` e `latest` publicadas e visibilidade `Public`.

Aguarde a conclusão do workflow antes de declarar sucesso. Se o workflow falhar, reporte e pare.

### Passo 7 — Resumo final

Apresente um resumo com: versão anterior, nova versão, tipo de bump, commit, tag, status do workflow e tags confirmadas no GHCR.

## Conventions

- The non-root user inside the container is `claude` (home: `/home/claude`)
- SSH port inside the container is `22`; mapped to `2222` externally in the compose example
- `~/.claude` is always a volume — never bake MCP or GSD config into the image
- All apt layers that change rarely come before nvm/npm layers to maximize cache hits
- The workflow triggers only on tag push (`v*.*.*`) — no CI runs on plain commits to main

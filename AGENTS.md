# Agent Context: claude-code-devcontainer

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
│       └── release-ghcr.yml  # CI/CD: build on main, publish on tag
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
| AI | Claude Code (`claude` CLI) |

## Local build

```bash
docker build -t claude-code-devcontainer .
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
- `ghcr.io/henricos/claude-code-devcontainer:v1.1.0`
- `ghcr.io/henricos/claude-code-devcontainer:latest`

Pushing to `main` without a tag triggers a build-only run (no publish) — useful for validating Dockerfile changes.

## Conventions

- The non-root user inside the container is `claude` (home: `/home/claude`)
- SSH port inside the container is `22`; mapped to `2222` externally in the compose example
- `~/.claude` is always a volume — never bake MCP or GSD config into the image
- All apt layers that change rarely come before nvm/npm layers to maximize cache hits
- One job in the workflow, two conditional paths (main vs tag) to keep the pipeline simple

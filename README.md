<div align="center">

# claude-workstation

Uma imagem Docker que executa o [Claude Code](https://claude.ai/code) como uma estação de trabalho de IA persistente.<br>Acesso via SSH, sessões tmux persistentes e um conjunto completo de ferramentas de desenvolvimento prontas para uso.

[![Build](https://github.com/henricos/claude-workstation/actions/workflows/release-ghcr.yml/badge.svg)](https://github.com/henricos/claude-workstation/actions/workflows/release-ghcr.yml)
[![Version](https://img.shields.io/github/v/release/henricos/claude-workstation)](https://github.com/henricos/claude-workstation/releases)
[![Image size](https://ghcr-badge.egpl.dev/henricos/claude-workstation/size)](https://github.com/henricos/claude-workstation/pkgs/container/claude-workstation)

</div>

## Ferramentas incluídas

| Categoria | Ferramentas |
|---|---|
| Shell e sistema | bash, tmux, htop, nano |
| Controle de versão | git, gh (GitHub CLI) |
| Node.js | nvm (Node 22 LTS) |
| Python | python3, pip, venv, uv |
| Ferramentas de dados | jq, yq |
| Containers | docker CLI |
| Mídia | yt-dlp |
| Automação de browser | playwright |
| IA | Claude Code CLI, GSD installer CLI |

O container roda como usuário não-root (`claude`, UID 1000) e expõe a porta 22 internamente — o mapeamento externo é definido no Compose. Nenhuma configuração do Claude ou de MCPs é embutida na imagem: tudo persiste em um volume montado em `/home/claude/.claude`.

## Configuração

O container é stateless por design — a imagem pode ser atualizada a qualquer momento sem perda de dados. Todo o estado persistente (sessão do Claude, chaves SSH, gitconfig e seus repositórios) vive em volumes no host. Antes de subir o container pela primeira vez é necessário preparar esses diretórios com as permissões corretas, especialmente o `.ssh`, que o daemon SSH recusa se as permissões estiverem abertas demais.

Consulte o [guia de configuração](docs/setup.md) para o passo a passo completo.

## Publicar uma nova versão da imagem

O fluxo de release usa o arquivo `VERSION` como fonte de verdade. O GitHub Actions valida que o conteúdo do arquivo bate com a tag antes de publicar — o workflow `Build and Release` é disparado pela criação de uma GitHub Release e publica no GHCR com a tag de versão e `latest`.

Consulte o [guia de release](docs/release.md) para o passo a passo completo, incluindo pré-condições, gate local de build e validação da cadeia externa.

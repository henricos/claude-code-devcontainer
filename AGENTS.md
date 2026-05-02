# Contexto do agente: claude-workstation

## O que é este repositório

Uma imagem Docker que empacota o Claude Code (CLI da Anthropic) com um conjunto completo de ferramentas de desenvolvimento em uma estação de trabalho persistente e acessível via SSH. A imagem foi pensada para rodar 24/7 em ambiente homelab e é publicada no GHCR via GitHub Actions.

## Idioma

Este repositório adota uma política de idioma híbrida:

- **Estrutura e código do projeto** (nomes de pastas, arquivos de código, configs, nomes de documentos técnicos, variáveis, comentários dentro de arquivos de código e comentários operacionais dentro de arquivos de configuração): **inglês**.
- **Conteúdo escrito para humanos** (documentação narrativa, commits, mensagens ao usuário, comunicação no chat, exemplos explicativos e comentários em blocos de documentação): **português do Brasil (`pt-BR`)**.

A única exceção admissível são jargões tecnológicos globais enraizados que soem puramente artificiais em português, como `build`, `entrypoint`, `workflow`, `tag`, `push`, `pipeline` ou trechos de código exatos. Referências externas podem ser capturadas no idioma original; metadados, títulos criados pela IA e textos autorais do sistema continuam em `pt-BR`.

## Estrutura do repositório

```
.
├── Dockerfile              # definição da imagem
├── entrypoint.sh           # inicialização do container (sobe o sshd)
├── compose.example.yml     # referência de deploy para Portainer / Docker Compose
├── VERSION                 # fonte única da versão da imagem
├── .github/
│   └── workflows/
│       └── release-ghcr.yml  # CI/CD: build e publicação em push de tag
├── CLAUDE.md               # carrega este arquivo via @AGENTS.md
└── AGENTS.md               # este arquivo
```

## O que está instalado na imagem

| Categoria | Ferramentas |
|---|---|
| Shell e sistema | bash, tmux, htop, nano/pico |
| Controle de versão | git, gh (GitHub CLI) |
| Node.js | nvm (default: Node 22), npm, npx |
| Python | python3, pip, venv, uv |
| Ferramentas de dados | jq, yq |
| Containers | docker CLI (sem daemon — conecta via volume do socket) |
| Mídia | yt-dlp |
| Automação de browser | playwright (npm global) |
| IA | Claude Code (`claude` CLI), instalador do GSD (`get-shit-done-cc`) |

## Build local

```bash
docker build -t claude-workstation .
```

## Fluxo de release

Para publicar uma nova versão da imagem:

1. Atualize `VERSION` com o novo semver (ex: `1.1.0`)
2. Faça commit, crie a tag e publique:

```bash
git commit -am "chore: bump version to 1.1.0"
git tag v1.1.0
git push && git push --tags
```

O GitHub Actions valida que `VERSION` corresponde à tag, depois constrói e publica:
- `ghcr.io/henricos/claude-workstation:v1.1.0`
- `ghcr.io/henricos/claude-workstation:latest`

## Commits

- Mensagens sempre em **pt-BR**.
- Formato **Conventional Commits**: `tipo: assunto conciso` (assunto até ~72 caracteres).
- Tipos válidos: `feat`, `fix`, `docs`, `refactor`, `chore`.
- A mensagem inteira deve usar **presente do indicativo na terceira pessoa do singular**, descrevendo o que o commit faz: `adiciona`, `corrige`, `atualiza`, `remove`, `refatora`, `documenta`.
- Não use imperativo na mensagem: evite `adicione`, `corrija`, `atualize`, `remova`, `refatore`, `documente`.
- Corpo obrigatório, com um parágrafo curto resumindo o objetivo da mudança e uma lista de bullets descrevendo as mudanças realizadas.
- Antes de executar `commit` ou `commit + push`, apresente a mensagem proposta e aguarde aprovação explícita do operador.
- Use arquivos explícitos no `git add`; não use staging amplo como `git add .`.

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

## Convenções

- O usuário não-root dentro do container é `claude` (home: `/home/claude`).
- A porta SSH dentro do container é `22`; no exemplo de Compose, ela é mapeada externamente para `2222`.
- `~/.claude` é sempre um volume — nunca embuta configuração de MCP ou GSD na imagem.
- Todas as camadas apt que mudam raramente vêm antes das camadas nvm/npm para maximizar cache.
- O workflow dispara apenas em push de tag (`v*.*.*`) — não há CI em commits simples para `main`.

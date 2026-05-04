# Contexto do agente: claude-workstation

## O que é este repositório

Uma imagem Docker que empacota o Claude Code (CLI da Anthropic) com um conjunto completo de ferramentas de desenvolvimento em uma estação de trabalho persistente e acessível via SSH. A imagem foi pensada para rodar 24/7 em ambiente homelab e é publicada no GHCR via GitHub Actions.

## Estratégia de IA agnóstica

Este repositório adota uma estratégia agnóstica de ferramenta para suportar múltiplas IAs sem duplicar instruções.

**Fontes de verdade editáveis:**

- `AGENTS.md` - regras operacionais comuns a qualquer agente.
- `.agents/skills/` - implementações padronizadas dos fluxos operacionais.

Arquivos de compatibilidade como `CLAUDE.md` e diretórios de ferramenta são apenas apontamentos para essas fontes de verdade. Nunca edite os apontamentos diretamente quando a intenção for mudar regras ou skills.

**Como cada ferramenta carrega as instruções e as skills:**

- **Claude Code** - carrega as regras por meio de `CLAUDE.md`, que inclui `@AGENTS.md`; skills via `.claude/skills`, que aponta para `.agents/skills`.
- **Cursor** - lê `AGENTS.md` como arquivo nativo de instruções; skills via `.cursor/skills`, que aponta para `.agents/skills`.
- **Codex CLI / outras ferramentas** - leem `AGENTS.md` diretamente; skills de `.agents/skills`.

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
├── claude-tmux-menu        # seletor de sessões tmux persistentes
├── compose.example.yml     # referência de deploy para Portainer / Docker Compose
├── VERSION                 # fonte única da versão da imagem
├── docs/
│   ├── setup.md            # guia de configuração e primeiro acesso
│   └── release.md          # guia de fechamento de versão (siga este ao fazer release)
├── .github/
│   └── workflows/
│       └── release-ghcr.yml  # CI/CD: build e publicação em push de tag
├── CLAUDE.md               # carrega este arquivo via @AGENTS.md
└── AGENTS.md               # este arquivo
```

## Fluxo de release

Quando o usuário pedir para fechar uma versão, soltar uma release, criar uma tag ou publicar uma nova imagem, siga **obrigatoriamente** o guia em [`docs/release.md`](docs/release.md). Não improvise nem abrevie os passos — o guia contém pré-condições e gates que evitam publicação de código quebrado.

## Commits

- Mensagens sempre em **pt-BR**.
- Formato **Conventional Commits**: `tipo: assunto conciso` (assunto até ~72 caracteres).
- Tipos válidos: `feat`, `fix`, `docs`, `refactor`, `chore`.
- A mensagem inteira deve usar **presente do indicativo na terceira pessoa do singular**, descrevendo o que o commit faz: `adiciona`, `corrige`, `atualiza`, `remove`, `refatora`, `documenta`.
- Não use imperativo na mensagem: evite `adicione`, `corrija`, `atualize`, `remova`, `refatore`, `documente`.
- Corpo obrigatório, com um parágrafo curto resumindo o objetivo da mudança e uma lista de bullets descrevendo as mudanças realizadas.
- Antes de executar `commit` ou `commit + push`, apresente a mensagem proposta e aguarde aprovação explícita do operador.
- Use arquivos explícitos no `git add`; não use staging amplo como `git add .`.


## Convenções

- O usuário não-root dentro do container é `claude` (home: `/home/claude`).
- A porta SSH dentro do container é `22`; no exemplo de Compose, ela é mapeada externamente para `2222`.
- `~/.claude` é sempre um volume — nunca embuta configuração de MCP ou GSD na imagem.
- Todas as camadas apt que mudam raramente vêm antes das camadas nvm/npm para maximizar cache.
- O workflow dispara apenas em push de tag (`v*.*.*`) — não há CI em commits simples para `main`.

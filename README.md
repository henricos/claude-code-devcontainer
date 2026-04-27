# claude-code-devcontainer

Uma imagem Docker que executa o [Claude Code](https://claude.ai/code) como uma estação de trabalho de IA persistente. Projetada para ambientes homelab onde você quer um agente de desenvolvimento sempre disponível e acessível via SSH.

## O que está incluído

| Categoria | Ferramentas |
|---|---|
| Shell e sistema | bash, tmux, htop, nano |
| Controle de versão | git, gh (GitHub CLI) |
| Node.js | nvm, Node 22 LTS |
| Python | python3, pip, venv, uv |
| Ferramentas de dados | jq, yq |
| Containers | docker CLI |
| Mídia | yt-dlp |
| Automação de browser | playwright |
| IA | Claude Code CLI |

O container roda como usuário não-root (`claude`) e expõe SSH na porta 22. Nenhuma configuração de MCP ou do Claude é embutida na imagem — tudo fica em um volume persistente montado em `/home/claude/.claude`.

## Início rápido

### 1. Preparar o diretório de dados do Claude

Crie o diretório que vai persistir as configurações, sessão OAuth e memória do Claude Code entre reinicializações do container.

```bash
mkdir -p /opt/claude-workstation/claude
```

### 2. Preparar o diretório SSH

O acesso ao container é feito exclusivamente por chave SSH. Crie um diretório dedicado para isso — não use seu `~/.ssh` pessoal diretamente, para evitar que o container tenha acesso às suas outras chaves privadas.

Você pode copiar uma chave pública existente ou gerar uma nova exclusivamente para o container:

Opção A — copiar uma chave existente:

```bash
mkdir -p /opt/claude-workstation/ssh
cp ~/.ssh/id_ed25519.pub /opt/claude-workstation/ssh/authorized_keys
```

Opção B — gerar uma chave nova dedicada:

```bash
mkdir -p /opt/claude-workstation/ssh
ssh-keygen -t ed25519 -f ~/.ssh/id_claude_workstation -C "claude-workstation"
cp ~/.ssh/id_claude_workstation.pub /opt/claude-workstation/ssh/authorized_keys
```

O entrypoint da imagem corrige automaticamente a propriedade do diretório SSH ao iniciar, portanto não é necessário nenhum `chown` manual.

### 3. Configurar o Compose

Copie o arquivo de exemplo para criar seu `compose.yml`:

```bash
cp compose.example.yml compose.yml
```

Abra o `compose.yml` e ajuste os valores conforme o seu ambiente. Os campos que precisam de atenção estão descritos na tabela abaixo.

```yaml
services:
  claude-code-devcontainer:
    image: ghcr.io/henricos/claude-code-devcontainer:latest
    container_name: claude-code-devcontainer
    volumes:
      - /opt/claude-workstation/claude:/home/claude/.claude
      - /opt/claude-workstation/ssh:/home/claude/.ssh
      - /opt/claude-workstation/gitconfig:/home/claude/.gitconfig:ro
      - /home/user/projects:/home/claude/work
      # - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - "2222:22"
    restart: unless-stopped
```

| Campo | O que ajustar |
|---|---|
| `image` | Substitua `YOUR_USERNAME` pelo seu usuário do GitHub |
| `/opt/claude-workstation/claude` | Caminho no host para os dados do Claude Code |
| `/opt/claude-workstation/ssh` | Caminho no host onde está o `authorized_keys` criado no passo 2 |
| `/opt/claude-workstation/gitconfig` | Caminho para o seu `.gitconfig` no host (usado pelo agente nos commits) |
| `/home/user/projects` | Caminho no host dos seus repositórios de código |
| `docker.sock` | Descomente se quiser que o agente possa executar builds Docker no host |

### 4. Subir o container

```bash
docker compose up -d
```

### 5. Conectar via SSH

```bash
ssh -p 2222 claude@<ip-do-seu-servidor>
```

No primeiro acesso, execute `claude` para autenticar com sua conta Anthropic. A sessão persiste entre reinicializações pelo volume `~/.claude`.

## Publicar uma nova versão da imagem

1. Atualize o arquivo `VERSION` com o novo semver
2. Faça o commit, crie a tag e envie:

```bash
git commit -am "chore: bump version to x.y.z"
git tag vx.y.z
git push && git push --tags
```

O GitHub Actions valida a versão, constrói a imagem e publica no GHCR com a tag de versão e `latest`.

Fazer push para `main` sem tag executa apenas a validação do build, sem publicar.

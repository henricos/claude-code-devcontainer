# claude-workstation

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
| IA | Claude Code CLI, GSD installer CLI |

O container roda como usuário não-root (`claude`, UID 1000) e expõe SSH na porta 22. Nenhuma configuração de MCP ou do Claude é embutida na imagem — tudo fica em um volume persistente montado em `/home/claude/.claude`.

## Início rápido

### 1. Preparar o diretório de dados do Claude

Crie o diretório que vai persistir as configurações, sessão OAuth e memória do Claude Code entre reinicializações do container. O usuário `claude` dentro do container tem UID 1000, então os diretórios de volume precisam pertencer a esse UID no host.

```bash
mkdir -p /opt/claude-workstation/claude
chown 1000:1000 /opt/claude-workstation/claude
```

### 2. Preparar o diretório SSH

O container usa o mesmo diretório `.ssh` para dois propósitos distintos: receber conexões SSH vindas de fora (SSH de entrada) e autenticar em serviços externos como o GitHub (SSH de saída).

#### 2a. SSH de entrada — quem pode acessar o container

O arquivo `authorized_keys` lista as chaves públicas autorizadas a fazer SSH no container. Você pode usar uma chave existente ou gerar uma dedicada.

Para copiar uma chave existente:

```bash
mkdir -p /opt/claude-workstation/ssh
cp ~/.ssh/id_ed25519.pub /opt/claude-workstation/ssh/authorized_keys
```

Para gerar uma chave nova dedicada ao container:

```bash
mkdir -p /opt/claude-workstation/ssh
ssh-keygen -t ed25519 -f ~/.ssh/id_claude_workstation -C "claude-workstation"
cp ~/.ssh/id_claude_workstation.pub /opt/claude-workstation/ssh/authorized_keys
```

#### 2b. SSH de saída — acesso do container ao GitHub

Para que o container possa clonar repositórios privados e fazer push, ele precisa de uma chave SSH própria registrada na sua conta do GitHub. Essa chave pode ser diferente da usada para entrar no container.

Gere a chave no host e salve-a no diretório de volume:

```bash
ssh-keygen -t ed25519 -f /opt/claude-workstation/ssh/id_github -C "claude-container-github"
```

Exiba a chave pública e adicione-a em [github.com/settings/keys](https://github.com/settings/keys):

```bash
cat /opt/claude-workstation/ssh/id_github.pub
```

Crie o arquivo de configuração SSH para que o container use essa chave ao se conectar ao GitHub:

```bash
cat > /opt/claude-workstation/ssh/config << 'EOF'
Host github.com
  IdentityFile ~/.ssh/id_github
  IdentitiesOnly yes
EOF
```

#### Permissões do diretório SSH

O SSH recusa conexões se as permissões do diretório e dos arquivos de chave estiverem abertas demais. O container não ajusta essas permissões — elas precisam estar corretas no host antes de subir o container.

```bash
chown -R 1000:1000 /opt/claude-workstation/ssh
chmod 700 /opt/claude-workstation/ssh
chmod 600 /opt/claude-workstation/ssh/authorized_keys
chmod 600 /opt/claude-workstation/ssh/id_github
chmod 600 /opt/claude-workstation/ssh/config
```

### 3. Configurar o Compose

Copie o arquivo de exemplo para criar seu `compose.yml`:

```bash
cp compose.example.yml compose.yml
```

Abra o `compose.yml` e ajuste os valores conforme o seu ambiente. Os campos que precisam de atenção estão descritos na tabela abaixo.

```yaml
services:
  claude-workstation:
    image: ghcr.io/henricos/claude-workstation:latest
    container_name: claude-workstation
    hostname: workstation
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
| `image` | Tag da imagem — use `latest` ou uma versão específica como `v1.0.0` |
| `/opt/claude-workstation/claude` | Caminho no host para os dados do Claude Code (deve pertencer a UID 1000) |
| `/opt/claude-workstation/ssh` | Caminho no host do diretório SSH — contém `authorized_keys` (entrada) e a chave do GitHub (saída) |
| `/opt/claude-workstation/gitconfig` | Caminho para o seu `.gitconfig` no host (usado pelo agente nos commits) |
| `/home/user/projects` | Caminho no host dos seus repositórios de código |
| `docker.sock` | Socket do Docker — leia a nota abaixo antes de descomentar |

O volume `docker.sock` dá ao container acesso direto ao daemon Docker do host, o que equivale a permissão de root na máquina. Qualquer `docker run -v /caminho:/destino` executado de dentro do container resolve `/caminho` no filesystem do host, não no container. Mantenha comentado a menos que você precise explicitamente que o agente construa ou execute containers.

### 4. Subir o container

```bash
docker compose up -d
```

### 5. Conectar via SSH

Conexão direta:

```bash
ssh -p 2222 claude@<ip-do-seu-servidor>
```

Para evitar digitar usuário, porta e IP a cada vez, adicione uma entrada no `~/.ssh/config` da sua máquina:

```
Host claude-workstation
    HostName <ip-do-seu-servidor>
    User claude
    Port 2222
    IdentityFile ~/.ssh/id_claude_workstation
```

Depois basta usar `ssh claude-workstation`. O prompt dentro do container será `claude@workstation`.

No primeiro acesso, execute `claude` para autenticar com sua conta Anthropic. A sessão persiste entre reinicializações pelo volume `~/.claude`.

### 6. Validar a configuração

Após entrar no container, execute os comandos abaixo para confirmar que tudo está funcionando. Cada um verifica uma parte independente da configuração.

Confirma que a chave SSH de saída está registrada corretamente no GitHub:

```bash
ssh -T git@github.com
```

Confirma que o volume do `.gitconfig` está montado e a identidade está configurada:

```bash
git config --global user.name
git config --global user.email
```

Confirma que os volumes do Claude Code e de projetos estão montados:

```bash
ls ~/.claude
ls ~/work
```

Confirma que o Claude Code está instalado e acessível:

```bash
claude --version
```

Confirma a autenticação do GitHub CLI (fluxo OAuth, independente da chave SSH):

```bash
gh auth status
```

Se o `docker.sock` estiver habilitado, confirma acesso ao daemon Docker do host:

```bash
docker ps
```

## Publicar uma nova versão da imagem

O fluxo de release usa o arquivo `VERSION` como fonte de verdade. O GitHub Actions valida que o conteúdo do arquivo bate com a tag Git antes de publicar.

Atualize o `VERSION`, faça o commit e crie a tag:

```bash
echo "x.y.z" > VERSION
git commit -am "chore: bump version to x.y.z"
git tag vx.y.z
```

Publique o commit e a tag:

```bash
git push && git push --tags
```

O workflow `Build and Release` é disparado apenas por push de tag — constrói a imagem e publica no GHCR com a tag de versão e `latest`.

O guia completo de fechamento de versão — incluindo pré-condições, gate local de build e validação da cadeia externa — está em `AGENTS.md`.

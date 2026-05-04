# Guia de configuração

## 1. Preparar o diretório de dados do Claude

Crie o diretório que vai persistir as configurações, sessão OAuth e memória do Claude Code entre reinicializações do container. O usuário `claude` dentro do container tem UID 1000, então os diretórios de volume precisam pertencer a esse UID no host.

> **Execute no servidor**

```bash
mkdir -p /opt/claude-workstation/.claude
chown 1000:1000 /opt/claude-workstation/.claude
```

## 2. Preparar o diretório SSH

O container usa o mesmo diretório `.ssh` para dois propósitos distintos: receber conexões SSH vindas de fora (SSH de entrada) e autenticar em serviços externos como o GitHub (SSH de saída).

### 2a. SSH de entrada — quem pode acessar o container

O arquivo `authorized_keys` lista as chaves públicas autorizadas a fazer SSH no container. Gere o par de chaves no servidor e copie a chave pública para o `authorized_keys`. A chave privada fica em `/tmp` temporariamente — você vai transferi-la para a sua máquina na seção 5.

> **Execute no servidor**

```bash
mkdir -p /opt/claude-workstation/.ssh
ssh-keygen -t ed25519 -f /tmp/id_claude_workstation -C "claude-workstation"
cp /tmp/id_claude_workstation.pub /opt/claude-workstation/.ssh/authorized_keys
```

### 2b. SSH de saída — acesso do container ao GitHub

Para que o container possa clonar repositórios privados e fazer push, ele precisa de uma chave SSH própria registrada na sua conta do GitHub. A chave é gerada diretamente no diretório de volume para que o container a encontre ao iniciar.

> **Execute no servidor**

```bash
ssh-keygen -t ed25519 -f /opt/claude-workstation/.ssh/id_github -C "claude-workstation-github"
```

Exiba a chave pública e adicione-a em [github.com/settings/keys](https://github.com/settings/keys):

> **Execute no servidor**

```bash
cat /opt/claude-workstation/.ssh/id_github.pub
```

Crie o arquivo de configuração SSH para que o container use essa chave ao se conectar ao GitHub:

> **Execute no servidor**

```bash
cat > /opt/claude-workstation/.ssh/config << 'EOF'
Host github.com
  IdentityFile ~/.ssh/id_github
  IdentitiesOnly yes
EOF
```

### Permissões do diretório SSH

O SSH recusa conexões se as permissões do diretório e dos arquivos de chave estiverem abertas demais. O container não ajusta essas permissões — elas precisam estar corretas no host antes de subir o container.

> **Execute no servidor**

```bash
chown -R 1000:1000 /opt/claude-workstation/.ssh
chmod 700 /opt/claude-workstation/.ssh
chmod 600 /opt/claude-workstation/.ssh/authorized_keys
chmod 600 /opt/claude-workstation/.ssh/id_github
chmod 600 /opt/claude-workstation/.ssh/config
```

## 3. Configurar o Compose

Copie o arquivo de exemplo para criar seu `compose.yml` e ajuste os caminhos conforme o seu ambiente:

> **Execute no servidor**

```bash
cp compose.example.yml compose.yml
```

```yaml
services:
  claude-workstation:
    image: ghcr.io/henricos/claude-workstation:latest
    container_name: claude-workstation
    hostname: workstation
    volumes:
      - /opt/claude-workstation/.claude:/home/claude/.claude
      - /opt/claude-workstation/.ssh:/home/claude/.ssh
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
| `/opt/claude-workstation/.claude` | Caminho no host para os dados do Claude Code (deve pertencer a UID 1000) |
| `/opt/claude-workstation/.ssh` | Caminho no host do diretório SSH — contém `authorized_keys` (entrada) e a chave do GitHub (saída) |
| `/opt/claude-workstation/gitconfig` | Caminho para o seu `.gitconfig` no host (usado pelo agente nos commits) |
| `/home/user/projects` | Caminho no host dos seus repositórios de código — o diretório precisa existir antes de subir o container |
| `docker.sock` | Socket do Docker — leia a nota abaixo antes de descomentar |

O volume `docker.sock` dá ao container acesso direto ao daemon Docker do host, o que equivale a permissão de root na máquina. Qualquer `docker run -v /caminho:/destino` executado de dentro do container resolve `/caminho` no filesystem do host, não no container. Mantenha comentado a menos que você precise explicitamente que o agente construa ou execute containers.

## 4. Subir o container

> **Execute no servidor**

```bash
docker compose up -d
```

## 5. Conectar via SSH

Antes de acessar pela primeira vez, transfira a chave privada gerada na seção 2a para a sua máquina:

> **Execute na sua máquina**

```bash
scp usuario@servidor:/tmp/id_claude_workstation ~/.ssh/id_claude_workstation
chmod 600 ~/.ssh/id_claude_workstation
```

Adicione uma entrada no `~/.ssh/config`:

> **Execute na sua máquina**

```
Host claude-workstation
    HostName <ip-do-servidor>
    User claude
    Port 2222
    IdentityFile ~/.ssh/id_claude_workstation
```

Com isso configurado, basta usar:

> **Execute na sua máquina**

```bash
ssh claude-workstation
```

O prompt dentro do container será `claude@workstation`.

Ao entrar por SSH, o container mostra um seletor com até cinco sessões tmux persistentes: `ws-1` a `ws-5`. Escolha uma sessão existente para continuar de onde parou ou escolha uma sessão disponível para criá-la. Pressionar Enter usa a primeira sessão disponível.

## 6. Validar a configuração

No primeiro acesso, autentique-se com sua conta Anthropic antes de validar os demais itens:

> **Execute no container**

```bash
claude
```

Confirma que a chave SSH de saída está registrada corretamente no GitHub:

> **Execute no container**

```bash
ssh -T git@github.com
```

Confirma que o volume do `.gitconfig` está montado e a identidade está configurada:

> **Execute no container**

```bash
git config --global user.name
git config --global user.email
```

Confirma que os volumes do Claude Code e de projetos estão montados:

> **Execute no container**

```bash
ls ~/.claude
ls ~/work
```

Confirma que o Claude Code está instalado e acessível:

> **Execute no container**

```bash
claude --version
```

Confirma a autenticação do GitHub CLI (fluxo OAuth, independente da chave SSH):

> **Execute no container**

```bash
gh auth status
```

Se o `docker.sock` estiver habilitado, confirma acesso ao daemon Docker do host:

> **Execute no container**

```bash
docker ps
```

# Guia de release

Este documento define o fluxo canônico para publicar uma nova versão da imagem. Siga os passos na ordem — cada um é pré-condição do seguinte.

## Passo 1 — Verificar pré-condições

A release só pode ser feita a partir de `main`, com o branch local alinhado com `origin/main` e a working tree limpa.

> **Execute no servidor de desenvolvimento**

```bash
git branch --show-current
git fetch origin
git rev-parse HEAD
git rev-parse origin/main
git diff --quiet && git diff --cached --quiet
```

Se qualquer condição não for atendida, **aborte**. Não faça commit, stash ou reset automático para destravar a release.

## Passo 2 — Determinar a próxima versão

Leia a versão atual:

> **Execute no servidor de desenvolvimento**

```bash
cat VERSION
```

Escolha o tipo de bump:

| Tipo | Quando usar |
|---|---|
| `patch` | Correções e ajustes menores |
| `minor` | Novas funcionalidades sem quebra de compatibilidade |
| `major` | Mudanças que alteram o comportamento de forma significativa |

Confirme a versão escolhida antes de continuar.

## Passo 3 — Gate local

Construa a imagem localmente para garantir que o código builda sem erros antes de criar a tag:

> **Execute no servidor de desenvolvimento**

```bash
docker build -t claude-workstation:release-gate .
```

Se o build falhar, **aborte**. Não crie tag sobre código que não builda.

## Passo 4 — Aplicar o bump

Atualize o arquivo `VERSION`, faça o commit e crie a tag:

> **Execute no servidor de desenvolvimento**

```bash
echo "X.Y.Z" > VERSION
git add VERSION
git commit -m "chore: bump version para X.Y.Z"
git tag vX.Y.Z
```

## Passo 5 — Publicar

> **Execute no servidor de desenvolvimento**

```bash
git push && git push --tags
```

Se o push falhar, **aborte** e investigue antes de tentar novamente.

## Passo 6 — Validar a cadeia externa

Após o push, confirme:

1. **GitHub Actions** — existe uma run do workflow `Build and Release` para a tag; o job terminou com `success`.
2. **GHCR** — o pacote `ghcr.io/henricos/claude-workstation` tem as tags `vX.Y.Z` e `latest` publicadas e visibilidade `Public`.

Aguarde a conclusão do workflow antes de declarar sucesso. Se o workflow falhar, reporte e investigue.

## Passo 7 — Resumo final

Confirme: versão anterior, nova versão, tipo de bump, commit, tag, status do workflow e tags publicadas no GHCR.

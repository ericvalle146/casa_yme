# 🔄 Como Atualizar a VPS

## ⚠️ Problema: Conflito no Git Pull

Se você receber o erro:
```
error: Your local changes to the following files would be overwritten by merge
```

## ✅ Solução Rápida

### Opção 1: Usar o Script Automático (Recomendado)

```bash
chmod +x resolver-conflito-git.sh
./resolver-conflito-git.sh
```

O script vai:
- Detectar mudanças locais
- Oferecer opções para resolver
- Fazer o pull automaticamente
- Verificar se os novos arquivos estão presentes

### Opção 2: Comandos Manuais

#### Se as mudanças locais NÃO são importantes:

```bash
# Descartar mudanças locais
git reset --hard HEAD
git clean -fd

# Fazer pull
git pull origin main
```

#### Se as mudanças locais SÃO importantes:

```bash
# Salvar mudanças em stash
git stash push -m "Mudanças locais antes do pull"

# Fazer pull
git pull origin main

# Recuperar mudanças (se necessário)
git stash pop
```

#### Se quiser fazer commit das mudanças:

```bash
# Adicionar e commitar mudanças
git add -A
git commit -m "chore: Mudanças locais antes do pull"

# Fazer pull (pode haver conflitos)
git pull origin main

# Se houver conflitos, resolva e depois:
git add .
git commit
```

## 📋 Após Atualizar

Verifique se os novos arquivos estão presentes:

```bash
ls -la | grep -E "(deploy-completo|verificar-traefik|configurar-traefik|DEPLOY-FINAL|COMO-USAR|SOLUCAO-DEPLOY)"
```

Você deve ver:
- ✅ `deploy-completo.sh`
- ✅ `verificar-traefik.sh`
- ✅ `configurar-traefik-acme.sh`
- ✅ `DEPLOY-FINAL.md`
- ✅ `COMO-USAR.md`
- ✅ `SOLUCAO-DEPLOY.md`

## 🚀 Próximos Passos

Após atualizar com sucesso:

1. **Execute o deploy:**
   ```bash
   chmod +x deploy-completo.sh
   ./deploy-completo.sh
   ```

2. **Ou verifique o Traefik:**
   ```bash
   chmod +x verificar-traefik.sh
   ./verificar-traefik.sh
   ```

## 💡 Dica

Se você não tem certeza se as mudanças locais são importantes, use a **Opção 1** (descartar mudanças). Os arquivos antigos foram removidos do repositório e substituídos por versões melhores.


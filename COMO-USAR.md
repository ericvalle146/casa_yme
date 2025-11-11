# 🚀 Como Usar - Deploy ImóvelPro

## ⚡ Início Rápido

### 1. Configure o Backend

```bash
cd server
cp env.example .env
nano .env  # Configure o N8N_WEBHOOK_URL
```

### 2. Execute o Deploy

```bash
chmod +x deploy-completo.sh
./deploy-completo.sh
```

**Pronto!** O script faz tudo automaticamente.

## 🔍 Se Der Erro de SSL

### Problema: `ERR_CERT_AUTHORITY_INVALID`

**Solução rápida:**

1. Verifique o Traefik:
   ```bash
   ./verificar-traefik.sh
   ```

2. Se o Traefik não tiver Let's Encrypt configurado:
   ```bash
   ./configurar-traefik-acme.sh
   ```
   Siga as instruções que aparecerem.

3. Reinicie o Traefik e aguarde alguns minutos.

## 📋 Scripts Disponíveis

| Script | O que faz |
|--------|-----------|
| `deploy-completo.sh` | Deploy completo automático |
| `verificar-traefik.sh` | Verifica configuração do Traefik |
| `configurar-traefik-acme.sh` | Ajuda a configurar Let's Encrypt no Traefik |

## ✅ Checklist Rápido

- [ ] Backend configurado (`server/.env` com `N8N_WEBHOOK_URL`)
- [ ] Traefik rodando
- [ ] Traefik com Let's Encrypt configurado
- [ ] Domínios apontando para o IP da VPS
- [ ] Execute `./deploy-completo.sh`

## 🆘 Ajuda

**Ver logs:**
```bash
docker compose logs -f
```

**Ver status:**
```bash
docker compose ps
```

**Verificar SSL:**
```bash
./verificar-traefik.sh
```

**Documentação completa:** Veja `DEPLOY-FINAL.md`


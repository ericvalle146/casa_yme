# 🚀 Deploy Completo - ImóvelPro

## 📋 Pré-requisitos

1. **Docker e Docker Compose** instalados
2. **Traefik** rodando na VPS (com Let's Encrypt configurado)
3. **Domínios** configurados:
   - Frontend: `imob.locusup.shop`
   - Backend: `apiapi.jyze.space`
4. **DNS** apontando para o IP da VPS (`147.93.5.243`)

## 🔧 Configuração Inicial

### 1. Configurar Backend

```bash
cd server
cp env.example .env
nano .env
```

**Configure obrigatoriamente:**
```env
PORT=4000
CORS_ORIGINS=https://imob.locusup.shop
N8N_WEBHOOK_URL=https://seu-servidor-n8n.com/webhook/endpoint
```

### 2. Verificar Traefik

Execute o script de verificação:

```bash
chmod +x verificar-traefik.sh
./verificar-traefik.sh
```

**Importante:** O Traefik precisa ter Let's Encrypt configurado. Se não tiver, você verá um aviso.

## 🚀 Deploy Automático

### Opção 1: Deploy Completo (Recomendado)

```bash
chmod +x deploy-completo.sh
./deploy-completo.sh
```

Este script:
- ✅ Verifica todas as dependências
- ✅ Detecta automaticamente a network do Traefik
- ✅ Constrói as imagens Docker
- ✅ Faz o deploy dos serviços
- ✅ Verifica a saúde dos serviços
- ✅ Verifica certificados SSL

### Opção 2: Deploy Manual

#### Com Docker Compose

```bash
docker-compose up -d --build
```

#### Com Docker Swarm

```bash
cd deploy
chmod +x deploy-swarm.sh
./deploy-swarm.sh
```

## 🔍 Verificação Pós-Deploy

### 1. Verificar Serviços

```bash
# Docker Compose
docker-compose ps

# Docker Swarm
docker service ls | grep imovelpro
```

### 2. Verificar Logs

```bash
# Docker Compose
docker-compose logs -f

# Docker Swarm
docker service logs -f imovelpro_frontend
docker service logs -f imovelpro_backend
```

### 3. Verificar SSL

```bash
# Verificar certificado do backend
echo | openssl s_client -connect apiapi.jyze.space:443 -servername apiapi.jyze.space 2>&1 | grep "CN ="

# Verificar certificado do frontend
echo | openssl s_client -connect imob.locusup.shop:443 -servername imob.locusup.shop 2>&1 | grep "CN ="
```

**Se aparecer "TRAEFIK DEFAULT CERT":**
- O Traefik não está gerando certificados do Let's Encrypt
- Verifique a configuração do Traefik
- Execute: `./verificar-traefik.sh`

### 4. Testar Endpoints

```bash
# Backend health
curl https://apiapi.jyze.space/health

# Frontend
curl -I https://imob.locusup.shop
```

## ⚠️ Problemas Comuns

### Erro: ERR_CERT_AUTHORITY_INVALID

**Causa:** Traefik usando certificado auto-assinado

**Solução:**
1. Verifique se o Traefik tem Let's Encrypt configurado:
   ```bash
   ./verificar-traefik.sh
   ```

2. Se não tiver, configure o Traefik com ACME:
   - Acesse a configuração do Traefik
   - Adicione certificadosResolvers com Let's Encrypt
   - Reinicie o Traefik

3. Aguarde alguns minutos para o Let's Encrypt gerar os certificados

### Erro: Network não encontrada

**Causa:** Network `vpsnet` não existe

**Solução:**
```bash
# Criar network
docker network create --driver bridge vpsnet

# Ou se estiver usando Swarm
docker network create --driver overlay --attachable vpsnet
```

### Erro: Containers não iniciam

**Verificar logs:**
```bash
docker-compose logs
# ou
docker service logs imovelpro_backend
```

**Verificar se as portas estão livres:**
```bash
sudo netstat -tulpn | grep -E ':(80|4000|3429)'
```

### Erro: Backend não responde

**Verificar:**
1. Se o arquivo `.env` está configurado corretamente
2. Se o `N8N_WEBHOOK_URL` está correto
3. Logs do backend: `docker-compose logs backend`

## 📝 Estrutura do Deploy

```
Prototipo_Mariana_Imobiliarias-main/
├── deploy-completo.sh          # Script principal de deploy
├── verificar-traefik.sh         # Script de verificação do Traefik
├── docker-compose.yml           # Configuração Docker Compose
├── deploy/
│   ├── docker-stack.yml         # Configuração Docker Swarm
│   └── deploy-swarm.sh          # Script de deploy Swarm
├── server/
│   ├── .env                     # Variáveis de ambiente (criar)
│   └── env.example              # Exemplo de variáveis
└── vite.config.ts               # Configuração do Vite
```

## 🔄 Atualizar Deploy

Para atualizar após mudanças no código:

```bash
./deploy-completo.sh
```

O script automaticamente:
- Para containers antigos
- Reconstrói as imagens
- Faz o deploy novamente

## 🗑️ Remover Deploy

### Docker Compose
```bash
docker-compose down
```

### Docker Swarm
```bash
docker stack rm imovelpro
```

## 📞 Suporte

Se encontrar problemas:

1. Execute `./verificar-traefik.sh` para diagnosticar
2. Verifique os logs: `docker-compose logs` ou `docker service logs`
3. Verifique se o Traefik está configurado corretamente
4. Verifique se os domínios estão apontando para o IP correto

## ✅ Checklist de Deploy

- [ ] Docker e Docker Compose instalados
- [ ] Traefik rodando com Let's Encrypt configurado
- [ ] Domínios configurados e DNS apontando corretamente
- [ ] Arquivo `server/.env` configurado com `N8N_WEBHOOK_URL`
- [ ] Network `vpsnet` existe (ou será criada automaticamente)
- [ ] Portas 80 e 443 abertas no firewall
- [ ] Deploy executado com sucesso
- [ ] Serviços rodando e saudáveis
- [ ] Certificados SSL válidos (não auto-assinados)
- [ ] Frontend acessível em `https://imob.locusup.shop`
- [ ] Backend acessível em `https://apiapi.jyze.space/health`


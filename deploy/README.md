# Deploy Docker Swarm - ImóvelPro

Este diretório contém os arquivos necessários para fazer deploy do ImóvelPro usando Docker Swarm Stack, seguindo o padrão usado no projeto saborpaulista.

## 🎯 Por Que Docker Swarm?

- ✅ **Integração nativa** com a network `vpsnet` (overlay do Swarm)
- ✅ **Sem downtime** - não requer parar outros serviços
- ✅ **Traefik detecta automaticamente** os serviços
- ✅ **Mesmo padrão** usado nos outros projetos (saborpaulista, etc.)

## 📋 Pré-requisitos

1. Docker Swarm ativo
2. Network `vpsnet` criada pelo Docker Swarm
3. Traefik rodando no Docker Swarm
4. Arquivo `server/.env` configurado

## 🚀 Deploy

### Opção 1: Script Automático (Recomendado)

```bash
cd ~/Prototipo_Mariana_Imobiliarias
./deploy/deploy-swarm.sh
```

### Opção 2: Manual

```bash
# 1. Build das imagens
docker build -t prototipo_mariana_imobiliarias-frontend:latest -f Dockerfile.frontend --build-arg VITE_API_BASE_URL=https://apiapi.jyze.space .
docker build -t prototipo_mariana_imobiliarias-backend:latest -f server/Dockerfile ./server

# 2. Exportar variáveis
export TRAEFIK_NETWORK=vpsnet
export FRONTEND_IMAGE=prototipo_mariana_imobiliarias-frontend:latest
export BACKEND_IMAGE=prototipo_mariana_imobiliarias-backend:latest
export PORT=4000
export CORS_ORIGINS=https://imob.locusup.shop
export NODE_ENV=production
export N8N_WEBHOOK_URL=https://seu-servidor-n8n.com/webhook/endpoint

# 3. Deploy da stack
docker stack deploy -c deploy/docker-stack.yml imovelpro
```

## 📝 Configuração

### Variáveis de Ambiente

O script `deploy-swarm.sh` carrega automaticamente as variáveis do arquivo `server/.env`:

```bash
PORT=4000
CORS_ORIGINS=https://imob.locusup.shop
NODE_ENV=production
N8N_WEBHOOK_URL=https://seu-servidor-n8n.com/webhook/endpoint
```

### Network do Traefik

O script detecta automaticamente a network do Traefik (prioriza `vpsnet`). Você pode forçar uma network específica:

```bash
export TRAEFIK_NETWORK=vpsnet
./deploy/deploy-swarm.sh
```

## 🔍 Verificação

### Verificar Serviços

```bash
# Listar serviços
docker service ls | grep imovelpro

# Ver status detalhado
docker service ps imovelpro_frontend
docker service ps imovelpro_backend

# Ver logs
docker service logs -f imovelpro_frontend
docker service logs -f imovelpro_backend
```

### Verificar Network

```bash
# Ver containers na network vpsnet
docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}'

# Deve incluir: imovelpro_frontend.1.xxx e imovelpro_backend.1.xxx
```

### Verificar Traefik

```bash
# Ver rotas do Traefik (se API habilitada)
curl -s http://localhost:8080/api/http/routers | jq '.[] | select(.name | contains("imovelpro"))'

# Testar domínios
curl -I https://imob.locusup.shop
curl -I https://apiapi.jyze.space/health
```

## 🛠️ Comandos Úteis

### Atualizar Stack

```bash
# Rebuild das imagens e redeploy
./deploy/deploy-swarm.sh
```

### Escalar Serviços

```bash
# Escalar frontend para 2 réplicas
docker service scale imovelpro_frontend=2

# Escalar backend para 2 réplicas
docker service scale imovelpro_backend=2
```

### Rollback

```bash
# Ver histórico de atualizações
docker service ps imovelpro_frontend --no-trunc

# Rollback para versão anterior
docker service rollback imovelpro_frontend
docker service rollback imovelpro_backend
```

### Remover Stack

```bash
# Remover stack completa
docker stack rm imovelpro

# Aguardar remoção completa
docker stack ps imovelpro
```

## 🔄 Migração de docker-compose para Swarm

Se você estava usando `docker-compose.yml`, execute:

```bash
# 1. Parar containers antigos
docker compose down

# 2. Remover containers e network
docker stop imovelpro-frontend imovelpro-backend 2>/dev/null || true
docker rm imovelpro-frontend imovelpro-backend 2>/dev/null || true
docker network rm prototipo_mariana_imobiliarias_imovelpro-network 2>/dev/null || true

# 3. Deploy com Swarm
./deploy/deploy-swarm.sh
```

## 📊 Diferenças: docker-compose vs Docker Swarm

| Aspecto | docker-compose | Docker Swarm Stack |
|---------|---------------|-------------------|
| Network overlay | ❌ Não pode conectar | ✅ Conecta automaticamente |
| Comando | `docker-compose up` | `docker stack deploy` |
| Formato | `docker-compose.yml` | `docker-stack.yml` |
| Labels Traefik | ✅ Mesmas | ✅ Mesmas |
| Variáveis de ambiente | `env_file` | `environment` (exportadas) |
| Health checks | ✅ Suportado | ✅ Suportado |
| Restart policy | `restart: unless-stopped` | `deploy.restart_policy` |
| Dependências | `depends_on` | Ordem de deploy |

## ⚠️ Troubleshooting

### Serviços não aparecem no Traefik

1. Verificar se estão na network `vpsnet`:
   ```bash
   docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}'
   ```

2. Verificar labels do Traefik:
   ```bash
   docker service inspect imovelpro_frontend --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | jq
   ```

3. Verificar logs do Traefik:
   ```bash
   docker service logs -f traefik_traefik
   ```

### Erro: "network vpsnet not found"

1. Verificar se a network existe:
   ```bash
   docker network ls | grep vpsnet
   ```

2. Verificar se é uma network overlay:
   ```bash
   docker network inspect vpsnet --format '{{.Driver}} {{.Scope}}'
   # Deve ser: overlay swarm
   ```

3. Forçar network específica:
   ```bash
   export TRAEFIK_NETWORK=vpsnet
   ./deploy/deploy-swarm.sh
   ```

### Serviços não iniciam

1. Ver logs dos serviços:
   ```bash
   docker service logs imovelpro_frontend
   docker service logs imovelpro_backend
   ```

2. Ver status detalhado:
   ```bash
   docker service ps imovelpro_frontend --no-trunc
   docker service ps imovelpro_backend --no-trunc
   ```

3. Verificar health checks:
   ```bash
   docker service inspect imovelpro_frontend --format '{{json .Spec.TaskTemplate.ContainerSpec.Healthcheck}}' | jq
   ```

## 📚 Referências

- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [Docker Stack Deploy](https://docs.docker.com/engine/reference/commandline/stack_deploy/)
- [Traefik Docker Provider](https://doc.traefik.io/traefik/providers/docker/)

## 🔗 Arquivos Relacionados

- `docker-stack.yml` - Configuração da stack Swarm
- `deploy-swarm.sh` - Script de deploy automático
- `../docker-compose.yml` - Configuração antiga (não funciona com Swarm)
- `../PROBLEMA-COMPLETO.md` - Documentação completa do problema




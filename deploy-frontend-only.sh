#!/usr/bin/env bash

set -euo pipefail

# Cores
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

# Configurações
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
DOMAIN_FRONTEND="imob.locusup.shop"
STACK_NAME="imovelpro"

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        DEPLOY APENAS FRONTEND - SEM BACKEND              ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar Docker
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker não encontrado${NC}"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker não está rodando${NC}"
    exit 1
fi

# Verificar Swarm
if ! docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active\|manager"; then
    echo -e "${RED}❌ Docker Swarm não está ativo${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker Swarm ativo${NC}"
echo ""

# Parar e remover stack antiga (incluindo backend se existir)
echo -e "${BLUE}[1] Removendo stack antiga completamente...${NC}"
docker stack rm "$STACK_NAME" 2>/dev/null || true
sleep 10

# Remover serviços individuais do backend se existirem
echo -e "${BLUE}   Removendo serviços do backend se existirem...${NC}"
docker service rm "${STACK_NAME}_backend" 2>/dev/null || true
docker service rm "imovelpro_backend" 2>/dev/null || true
sleep 5

echo -e "${GREEN}✅ Stack antiga removida${NC}"
echo ""

# Detectar network do Traefik
echo -e "${BLUE}[2] Detectando network do Traefik...${NC}"
TRAEFIK_NETWORK="vpsnet"

if ! docker network inspect "$TRAEFIK_NETWORK" >/dev/null 2>&1; then
    echo -e "${RED}❌ Network $TRAEFIK_NETWORK não encontrada${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Network encontrada: ${YELLOW}$TRAEFIK_NETWORK${NC}"
echo ""

# Detectar Traefik e certresolver
echo -e "${BLUE}[3] Detectando configuração do Traefik...${NC}"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)

if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Traefik não encontrado${NC}"
    exit 1
fi

TRAEFIK_SERVICE=$(echo "$TRAEFIK_CONTAINER" | cut -d'.' -f1-2)
TRAEFIK_ARGS=$(docker service inspect "$TRAEFIK_SERVICE" --format '{{range .Spec.TaskTemplate.ContainerSpec.Args}}{{.}}{{"\n"}}{{end}}' 2>/dev/null || echo "")

CERT_RESOLVER=$(echo "$TRAEFIK_ARGS" | grep -oP 'certificatesresolvers\.\K[^.]+' | head -1 || echo "letsencryptresolver")

if [ -z "$CERT_RESOLVER" ]; then
    CERT_RESOLVER=$(echo "$TRAEFIK_ARGS" | grep -oE 'certificatesresolvers\.[a-zA-Z0-9]+' | cut -d'.' -f2 | head -1 || echo "letsencryptresolver")
fi

echo -e "${GREEN}✅ Certresolver: ${YELLOW}$CERT_RESOLVER${NC}"
echo ""

# Garantir que docker-stack.yml está correto (sem backend)
echo -e "${BLUE}[4] Garantindo que docker-stack.yml está sem backend...${NC}"

# Criar docker-stack.yml temporário apenas com frontend
cat > "$PROJECT_ROOT/deploy/docker-stack-frontend-only.yml" << 'EOF'
networks:
  traefik:
    external: true
    name: ${TRAEFIK_NETWORK:-vpsnet}

services:
  frontend:
    image: ${FRONTEND_IMAGE:-prototipo_mariana_imobiliarias-frontend:latest}
    networks:
      - traefik
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first
        failure_action: rollback
      rollback_config:
        parallelism: 1
        order: stop-first
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.imovelpro-frontend.rule=Host(`imob.locusup.shop`)"
        - "traefik.http.routers.imovelpro-frontend.entrypoints=websecure"
        - "traefik.http.routers.imovelpro-frontend.tls.certresolver=${CERT_RESOLVER:-letsencryptresolver}"
        - "traefik.http.routers.imovelpro-frontend.tls=true"
        - "traefik.http.services.imovelpro-frontend.loadbalancer.server.port=80"
        - "traefik.docker.network=${TRAEFIK_NETWORK:-vpsnet}"
        - "traefik.http.routers.imovelpro-frontend-http.rule=Host(`imob.locusup.shop`)"
        - "traefik.http.routers.imovelpro-frontend-http.entrypoints=web"
        - "traefik.http.routers.imovelpro-frontend-http.middlewares=redirect-to-https-frontend"
        - "traefik.http.middlewares.redirect-to-https-frontend.redirectscheme.scheme=https"
        - "traefik.http.middlewares.redirect-to-https-frontend.redirectscheme.permanent=true"
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF

# Substituir certresolver no arquivo
sed -i "s/\${CERT_RESOLVER:-letsencryptresolver}/$CERT_RESOLVER/g" "$PROJECT_ROOT/deploy/docker-stack-frontend-only.yml"

echo -e "${GREEN}✅ Arquivo de configuração criado (apenas frontend)${NC}"
echo ""

# Build da imagem do frontend
echo -e "${BLUE}[5] Construindo imagem do frontend...${NC}"

# Permitir configurar webhook via variável de ambiente ou argumento
WEBHOOK_URL="${VITE_WEBHOOK_URL:-https://webhook.locusp.shop/webhook/mariana_imobiliaria}"

echo -e "${BLUE}   Webhook URL: ${YELLOW}$WEBHOOK_URL${NC}"
echo -e "${YELLOW}   (Para mudar, use: export VITE_WEBHOOK_URL=https://seu-webhook.com)${NC}"

docker build \
    --pull \
    --build-arg VITE_WEBHOOK_URL="$WEBHOOK_URL" \
    -t "imovelpro-frontend:latest" \
    -f "$PROJECT_ROOT/Dockerfile.frontend" \
    "$PROJECT_ROOT" || {
    echo -e "${RED}❌ Erro ao construir frontend${NC}"
    exit 1
}

echo -e "${GREEN}✅ Imagem construída${NC}"
echo ""

# Deploy da stack
echo -e "${BLUE}[6] Fazendo deploy (APENAS FRONTEND)...${NC}"

export TRAEFIK_NETWORK
export FRONTEND_IMAGE="imovelpro-frontend:latest"
export CERT_RESOLVER

docker stack deploy -c "$PROJECT_ROOT/deploy/docker-stack-frontend-only.yml" "$STACK_NAME" || {
    echo -e "${RED}❌ Erro ao fazer deploy${NC}"
    exit 1
}

echo -e "${GREEN}✅ Stack deploy iniciado${NC}"
echo ""

# Aguardar
echo -e "${BLUE}[7] Aguardando serviço iniciar...${NC}"
sleep 15

# Verificar serviços (deve ter APENAS frontend)
echo -e "${BLUE}[8] Verificando serviços...${NC}"
SERVICES=$(docker service ls | grep "$STACK_NAME" || echo "")

if echo "$SERVICES" | grep -q "backend"; then
    echo -e "${RED}❌ ERRO: Backend ainda está presente!${NC}"
    echo -e "${YELLOW}   Removendo backend manualmente...${NC}"
    docker service rm "${STACK_NAME}_backend" 2>/dev/null || true
    sleep 5
fi

docker service ls | grep "$STACK_NAME" || true
echo ""

# Verificar saúde
echo -e "${BLUE}[9] Verificando saúde do frontend...${NC}"
sleep 10

FRONTEND_STATUS=$(docker service ps "${STACK_NAME}_frontend" --format '{{.CurrentState}}' --no-trunc 2>/dev/null | head -1 || echo "")

if echo "$FRONTEND_STATUS" | grep -q "Running"; then
    echo -e "${GREEN}✅ Frontend está rodando${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend: $FRONTEND_STATUS${NC}"
fi

# Verificar se backend NÃO existe
if docker service inspect "${STACK_NAME}_backend" >/dev/null 2>&1; then
    echo -e "${RED}❌ Backend ainda existe! Removendo...${NC}"
    docker service rm "${STACK_NAME}_backend" 2>/dev/null || true
else
    echo -e "${GREEN}✅ Backend não existe (correto!)${NC}"
fi
echo ""

# Resumo final
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                  DEPLOY CONCLUÍDO!                        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ Deploy realizado com sucesso!${NC}"
echo ""
echo -e "${BLUE}📋 Informações:${NC}"
echo -e "   - Frontend: ${CYAN}https://${DOMAIN_FRONTEND}${NC}"
echo -e "   - Webhook: ${CYAN}https://webhook.locusp.shop/webhook/mariana_imobiliaria${NC}"
echo -e "   - Network:  ${YELLOW}${TRAEFIK_NETWORK}${NC}"
echo -e "   - Certresolver: ${YELLOW}${CERT_RESOLVER}${NC}"
echo ""
echo -e "${BLUE}💡 Comandos úteis:${NC}"
echo -e "   - Ver serviços: ${YELLOW}docker service ls | grep $STACK_NAME${NC}"
echo -e "   - Ver logs: ${YELLOW}docker service logs -f ${STACK_NAME}_frontend${NC}"
echo ""
echo -e "${YELLOW}⏱️  Aguarde 2-5 minutos para o Let's Encrypt gerar os certificados SSL${NC}"
echo ""


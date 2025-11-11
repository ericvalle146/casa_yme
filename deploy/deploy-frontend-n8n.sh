#!/usr/bin/env bash

set -euo pipefail

# cores
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

# configurações
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOMAIN_FRONTEND="imob.locusup.shop"
STACK_NAME="imovelpro"
TRAEFIK_NETWORK_DEFAULT="vpsnet"

WEBHOOK_DEFAULT="https://n8n.locusup.shop/webhook/mariana_imobiliaria"

echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  DEPLOY FRONTEND (webhook -> n8n)        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"

echo ""

# verificar docker
if ! command -v docker >/dev/null 2>&1; then
  echo -e "${RED}❌ Docker não encontrado${NC}"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo -e "${RED}❌ Docker não está rodando${NC}"
  exit 1
fi

# verificar swarm
if ! docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active\|manager"; then
  echo -e "${RED}❌ Docker Swarm não está ativo${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Docker Swarm ativo${NC}\n"

# detectar network do traefik (ou usar padrão)
TRAEFIK_NETWORK="${TRAEFIK_NETWORK:-$TRAEFIK_NETWORK_DEFAULT}"
if docker network inspect "$TRAEFIK_NETWORK" >/dev/null 2>&1; then
  echo -e "${GREEN}✅ Network Traefik encontrada: ${YELLOW}$TRAEFIK_NETWORK${NC}\n"
else
  echo -e "${YELLOW}⚠️  Network $TRAEFIK_NETWORK não encontrada, tentando network padrão: ${TRAEFIK_NETWORK_DEFAULT}${NC}"
  TRAEFIK_NETWORK="$TRAEFIK_NETWORK_DEFAULT"
  if ! docker network inspect "$TRAEFIK_NETWORK" >/dev/null 2>&1; then
    echo -e "${RED}❌ Network do Traefik não encontrada: $TRAEFIK_NETWORK${NC}"
    exit 1
  fi
fi

# detectar traefik service e certresolver
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1 || true)
if [ -z "$TRAEFIK_CONTAINER" ]; then
  echo -e "${YELLOW}⚠️  Traefik container não encontrado pelo nome 'traefik' - continuará com resolver padrão.${NC}"
  CERT_RESOLVER="letsencryptresolver"
else
  TRAEFIK_SERVICE=$(echo "$TRAEFIK_CONTAINER" | cut -d'.' -f1-2)
  TRAEFIK_ARGS=$(docker service inspect "$TRAEFIK_SERVICE" --format '{{range .Spec.TaskTemplate.ContainerSpec.Args}}{{.}}{{"\n"}}{{end}}' 2>/dev/null || echo "")
  CERT_RESOLVER=$(echo "$TRAEFIK_ARGS" | grep -oP 'certificatesresolvers\.\K[^.]+' | head -1 || echo "letsencryptresolver")
fi

echo -e "${GREEN}✅ Certresolver: ${YELLOW}${CERT_RESOLVER}${NC}\n"

# webhook (pode sobrescrever via env VITE_WEBHOOK_URL)
WEBHOOK_URL="${VITE_WEBHOOK_URL:-$WEBHOOK_DEFAULT}"

echo -e "${BLUE}Webhook configurado: ${YELLOW}$WEBHOOK_URL${NC}"
echo -e "${YELLOW}(para mudar, export VITE_WEBHOOK_URL=https://seu-webhook && ./deploy/deploy-frontend-n8n.sh)${NC}\n"

# criar docker-stack (frontend apenas)
STACK_FILE="$PROJECT_ROOT/deploy/docker-stack-frontend-n8n.yml"
cat > "$STACK_FILE" <<EOF
version: '3.7'

networks:
  traefik:
    external: true
    name: ${TRAEFIK_NETWORK}

services:
  frontend:
    image: ${FRONTEND_IMAGE:-imovelpro-frontend:latest}
    networks:
      - traefik
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first
      labels:
        - "traefik.enable=true"
        - "traefik.docker.network=${TRAEFIK_NETWORK}"
        - "traefik.http.routers.imovelpro-frontend.rule=Host(`$DOMAIN_FRONTEND`)"
        - "traefik.http.routers.imovelpro-frontend.entrypoints=websecure"
        - "traefik.http.routers.imovelpro-frontend.tls=true"
        - "traefik.http.routers.imovelpro-frontend.tls.certresolver=${CERT_RESOLVER}"
        - "traefik.http.services.imovelpro-frontend.loadbalancer.server.port=80"
        - "traefik.http.routers.imovelpro-frontend-http.rule=Host(`$DOMAIN_FRONTEND`)"
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

echo -e "${GREEN}✅ Arquivo de stack criado em: ${YELLOW}$STACK_FILE${NC}\n"

# build da imagem (passando o webhook como build-arg)
IMAGE_TAG="imovelpro-frontend:latest"

echo -e "${BLUE}Construindo imagem do frontend...${NC}"

docker build --pull --build-arg VITE_WEBHOOK_URL="$WEBHOOK_URL" -t "$IMAGE_TAG" -f "$PROJECT_ROOT/Dockerfile.frontend" "$PROJECT_ROOT" || {
  echo -e "${RED}❌ Erro ao construir a imagem do frontend${NC}"
  exit 1
}

echo -e "${GREEN}✅ Imagem construída: ${YELLOW}$IMAGE_TAG${NC}\n"

# deploy da stack
export FRONTEND_IMAGE="$IMAGE_TAG"

echo -e "${BLUE}Iniciando deploy da stack (apenas frontend)...${NC}"

docker stack deploy -c "$STACK_FILE" "$STACK_NAME" || {
  echo -e "${RED}❌ Erro ao fazer docker stack deploy${NC}"
  exit 1
}

echo -e "${GREEN}✅ Deploy iniciado (stack: $STACK_NAME). Verifique serviços com: docker service ls | grep $STACK_NAME${NC}\n"

echo -e "${CYAN}Resumo:${NC}"
echo -e " - Frontend: https://$DOMAIN_FRONTEND"
echo -e " - Webhook usado na build: ${YELLOW}$WEBHOOK_URL${NC}"
echo -e " - Stack file: ${YELLOW}$STACK_FILE${NC}\n"

echo -e "${YELLOW}Observação: se o Traefik estiver num nome de container/serviço diferente, ajuste a detecção de certresolver e a network.${NC}\n"

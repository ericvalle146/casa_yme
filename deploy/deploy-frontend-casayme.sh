#!/usr/bin/env bash

set -euo pipefail

# Cores
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STACK_NAME="${STACK_NAME:-casayme}"
DOMAIN_FRONTEND="${DOMAIN_FRONTEND:-casayme.com.br}"
API_BASE_URL="${VITE_API_BASE_URL:-https://apiapi.jyze.space}"

echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║ Deploy Frontend - casayme.com.br (Traefik) ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
echo ""

# Verificações básicas
if ! command -v docker >/dev/null 2>&1; then
  echo -e "${RED}❌ Docker não encontrado${NC}"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo -e "${RED}❌ Docker não está rodando${NC}"
  exit 1
fi

SWARM_STATE=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || echo "inactive")
if [ "$SWARM_STATE" != "active" ] && [ "$SWARM_STATE" != "manager" ]; then
  echo -e "${RED}❌ Docker Swarm não está ativo${NC}"
  echo -e "${YELLOW}   Ative com: docker swarm init${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Docker Swarm ativo${NC}"
echo ""

# Detectar network do Traefik
TRAEFIK_NETWORK=${TRAEFIK_NETWORK:-}
if [ -z "$TRAEFIK_NETWORK" ]; then
  CANDIDATES=$(docker network ls --format '{{.Name}} {{.Driver}} {{.Scope}}' | awk '$2=="overlay" && $3=="swarm" {print $1}' || echo "")
  for n in vpsnet traefik traefik-public proxy web JyzeCliente; do
    if echo "$CANDIDATES" | grep -Fxq "$n"; then
      TRAEFIK_NETWORK="$n"
      break
    fi
  done
fi
if [ -z "$TRAEFIK_NETWORK" ]; then
  TRAEFIK_NETWORK=$(docker network ls --format '{{.Name}} {{.Driver}} {{.Scope}}' | awk '$2=="overlay" && $3=="swarm" {print $1; exit}' || echo "")
fi
if [ -z "$TRAEFIK_NETWORK" ]; then
  echo -e "${RED}❌ Rede do Traefik não encontrada${NC}"
  echo -e "${YELLOW}   Exporte TRAEFIK_NETWORK=<rede> ou crie uma overlay (ex: vpsnet)${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Usando rede Traefik: ${YELLOW}${TRAEFIK_NETWORK}${NC}"
echo ""

# Detectar certresolver do Traefik
CERT_RESOLVER=${CERT_RESOLVER:-}
if [ -z "$CERT_RESOLVER" ]; then
  TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1 || true)
  if [ -n "$TRAEFIK_CONTAINER" ]; then
    TRAEFIK_SERVICE=$(echo "$TRAEFIK_CONTAINER" | cut -d'.' -f1-2)
    TRAEFIK_ARGS=$(docker service inspect "$TRAEFIK_SERVICE" --format '{{range .Spec.TaskTemplate.ContainerSpec.Args}}{{.}}{{"\n"}}{{end}}' 2>/dev/null || echo "")
    CERT_RESOLVER=$(echo "$TRAEFIK_ARGS" | grep -oP 'certificatesresolvers\.\K[^.]+' | head -1 || echo "")
  fi
fi
if [ -z "$CERT_RESOLVER" ]; then
  CERT_RESOLVER="letsencryptresolver"
fi
echo -e "${GREEN}✅ Certresolver: ${YELLOW}${CERT_RESOLVER}${NC}"
echo ""

# Build da imagem
TIMESTAMP_TAG=$(date +%Y%m%d-%H%M%S)
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "nogit")
IMAGE_TAG="${TIMESTAMP_TAG}-${GIT_SHA}"
FRONTEND_IMAGE="${FRONTEND_IMAGE:-casayme-frontend:${IMAGE_TAG}}"

echo -e "${BLUE}Construindo frontend (API: ${API_BASE_URL})...${NC}"
docker build \
  --pull \
  -t "$FRONTEND_IMAGE" \
  -t "casayme-frontend:latest" \
  -f "$PROJECT_ROOT/Dockerfile.frontend" \
  --build-arg VITE_API_BASE_URL="$API_BASE_URL" \
  "$PROJECT_ROOT"
echo -e "${GREEN}✅ Imagem construída: ${YELLOW}${FRONTEND_IMAGE}${NC}"
echo ""

# Deploy
export TRAEFIK_NETWORK
export FRONTEND_IMAGE
export DOMAIN_FRONTEND
export CERT_RESOLVER

echo -e "${BLUE}Fazendo deploy da stack (${STACK_NAME})...${NC}"
docker stack deploy -c "$PROJECT_ROOT/deploy/docker-stack.yml" "$STACK_NAME"

echo -e "${GREEN}✅ Deploy disparado${NC}"
sleep 8

FRONTEND_SERVICE="${STACK_NAME}_frontend"
STATUS=$(docker service ps "$FRONTEND_SERVICE" --format '{{.CurrentState}}' --no-trunc 2>/dev/null | head -1 || echo "")

if echo "$STATUS" | grep -q "Running"; then
  echo -e "${GREEN}✅ Frontend está rodando${NC}"
else
  echo -e "${YELLOW}⚠️  Status atual do frontend: ${STATUS}${NC}"
fi
echo ""

echo -e "${BLUE}Resumo:${NC}"
echo -e " - Domínio: https://${DOMAIN_FRONTEND}"
echo -e " - Stack: ${STACK_NAME}"
echo -e " - Rede Traefik: ${TRAEFIK_NETWORK}"
echo -e " - Certresolver: ${CERT_RESOLVER}"
echo -e " - Imagem: ${FRONTEND_IMAGE}"
echo ""
echo -e "${BLUE}Comandos úteis:${NC}"
echo -e " - docker service ls | grep ${STACK_NAME}"
echo -e " - docker service logs -f ${FRONTEND_SERVICE}"
echo -e " - docker stack rm ${STACK_NAME}"
echo ""




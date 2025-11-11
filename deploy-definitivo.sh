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
echo -e "${CYAN}║     DEPLOY DEFINITIVO - ImóvelPro (APENAS FRONTEND)     ║${NC}"
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
SWARM_MODE=false
if docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active\|manager"; then
    SWARM_MODE=true
    echo -e "${GREEN}✅ Docker Swarm ativo${NC}"
else
    echo -e "${RED}❌ Docker Swarm não está ativo${NC}"
    echo -e "${YELLOW}   Execute: docker swarm init${NC}"
    exit 1
fi

# Detectar network do Traefik
echo -e "${BLUE}[1] Detectando network do Traefik...${NC}"
TRAEFIK_NETWORK="vpsnet"

if ! docker network inspect "$TRAEFIK_NETWORK" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Network $TRAEFIK_NETWORK não encontrada${NC}"
    echo -e "${BLUE}   Tentando criar...${NC}"
    docker network create --driver overlay --attachable "$TRAEFIK_NETWORK" 2>/dev/null || true
    
    if docker network inspect "$TRAEFIK_NETWORK" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Network criada${NC}"
    else
        echo -e "${RED}❌ Não foi possível criar a network${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Network encontrada: ${YELLOW}$TRAEFIK_NETWORK${NC}"
fi
echo ""

# Detectar Traefik e certresolver
echo -e "${BLUE}[2] Detectando configuração do Traefik...${NC}"
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)

if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Traefik não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik encontrado: ${YELLOW}$TRAEFIK_CONTAINER${NC}"

# Detectar nome do certresolver
TRAEFIK_SERVICE=$(echo "$TRAEFIK_CONTAINER" | cut -d'.' -f1-2)
TRAEFIK_ARGS=$(docker service inspect "$TRAEFIK_SERVICE" --format '{{range .Spec.TaskTemplate.ContainerSpec.Args}}{{.}}{{"\n"}}{{end}}' 2>/dev/null || echo "")

CERT_RESOLVER=$(echo "$TRAEFIK_ARGS" | grep -oP 'certificatesresolvers\.\K[^.]+' | head -1 || echo "letsencryptresolver")

if [ -z "$CERT_RESOLVER" ] || [ "$CERT_RESOLVER" = "letsencryptresolver" ]; then
    # Tentar detectar de outra forma
    CERT_RESOLVER=$(echo "$TRAEFIK_ARGS" | grep -oE 'certificatesresolvers\.[a-zA-Z0-9]+' | cut -d'.' -f2 | head -1 || echo "letsencryptresolver")
fi

echo -e "${GREEN}✅ Certresolver detectado: ${YELLOW}$CERT_RESOLVER${NC}"
echo ""

# Atualizar docker-stack.yml com certresolver correto
echo -e "${BLUE}[3] Atualizando configuração com certresolver correto...${NC}"
sed -i "s/certresolver=letsencrypt/certresolver=$CERT_RESOLVER/g" "$PROJECT_ROOT/deploy/docker-stack.yml"
sed -i "s/certresolver=letsencryptresolver/certresolver=$CERT_RESOLVER/g" "$PROJECT_ROOT/deploy/docker-stack.yml"
echo -e "${GREEN}✅ Configuração atualizada${NC}"
echo ""

# Build da imagem do frontend
echo -e "${BLUE}[4] Construindo imagem do frontend...${NC}"

TIMESTAMP_TAG=$(date +%Y%m%d-%H%M%S)
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "nogit")
IMAGE_TAG="${TIMESTAMP_TAG}-${GIT_SHA}"

FRONTEND_IMAGE="imovelpro-frontend:${IMAGE_TAG}"

echo -e "${BLUE}   Building frontend...${NC}"
docker build \
    --pull \
    -t "$FRONTEND_IMAGE" \
    -t "imovelpro-frontend:latest" \
    -f "$PROJECT_ROOT/Dockerfile.frontend" \
    "$PROJECT_ROOT" || {
    echo -e "${RED}❌ Erro ao construir frontend${NC}"
    exit 1
}

echo -e "${GREEN}✅ Imagem construída${NC}"
echo ""

# Parar stack antiga
echo -e "${BLUE}[5] Parando stack antiga...${NC}"
docker stack rm "$STACK_NAME" 2>/dev/null || true
sleep 5
echo -e "${GREEN}✅ Stack antiga removida${NC}"
echo ""

# Deploy da stack
echo -e "${BLUE}[6] Fazendo deploy da stack...${NC}"

export TRAEFIK_NETWORK
export FRONTEND_IMAGE="imovelpro-frontend:latest"

docker stack deploy -c "$PROJECT_ROOT/deploy/docker-stack.yml" "$STACK_NAME" || {
    echo -e "${RED}❌ Erro ao fazer deploy${NC}"
    exit 1
}

echo -e "${GREEN}✅ Stack deploy iniciado${NC}"
echo ""

# Aguardar serviços
echo -e "${BLUE}[7] Aguardando serviço iniciar...${NC}"
sleep 15

# Verificar serviços
echo -e "${BLUE}[8] Verificando serviço...${NC}"
docker service ls | grep "$STACK_NAME" || true
echo ""

# Verificar saúde
echo -e "${BLUE}[9] Verificando saúde do serviço...${NC}"
sleep 10

FRONTEND_STATUS=$(docker service ps "${STACK_NAME}_frontend" --format '{{.CurrentState}}' --no-trunc 2>/dev/null | head -1 || echo "")

if echo "$FRONTEND_STATUS" | grep -q "Running"; then
    echo -e "${GREEN}✅ Frontend está rodando${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend: $FRONTEND_STATUS${NC}"
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
echo -e "   - Webhook: ${CYAN}https://webhook.locusup.shop/webhook/mariana_imobiliaria${NC}"
echo -e "   - Network:  ${YELLOW}${TRAEFIK_NETWORK}${NC}"
echo -e "   - Certresolver: ${YELLOW}${CERT_RESOLVER}${NC}"
echo ""
echo -e "${BLUE}💡 Comandos úteis:${NC}"
echo -e "   - Ver serviços: ${YELLOW}docker service ls | grep $STACK_NAME${NC}"
echo -e "   - Ver logs: ${YELLOW}docker service logs -f ${STACK_NAME}_frontend${NC}"
echo ""
echo -e "${YELLOW}⏱️  Aguarde 2-5 minutos para o Let's Encrypt gerar os certificados SSL${NC}"
echo -e "${YELLOW}   Verifique com: ${CYAN}echo | openssl s_client -connect ${DOMAIN_FRONTEND}:443 -servername ${DOMAIN_FRONTEND} 2>&1 | grep CN${NC}"
echo ""

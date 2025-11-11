#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🔧 Corrigindo labels do Traefik${NC}"
echo ""

# Atualizar código
echo -e "${BLUE}1) Atualizando código...${NC}"
git pull origin main

# Parar containers
echo -e "${BLUE}2) Parando containers...${NC}"
docker compose -f docker-compose.standalone.yml down

# Recriar containers com labels corretos
echo -e "${BLUE}3) Recriando containers com labels corretos...${NC}"
docker compose -f docker-compose.standalone.yml up -d

# Aguardar
sleep 10

# Verificar labels
echo -e "${BLUE}4) Verificando labels...${NC}"
FRONTEND_NETWORK=$(docker inspect imovelpro-frontend --format '{{index .Config.Labels "traefik.docker.network"}}' 2>/dev/null || echo "")
BACKEND_NETWORK=$(docker inspect imovelpro-backend --format '{{index .Config.Labels "traefik.docker.network"}}' 2>/dev/null || echo "")

echo -e "${BLUE}   Frontend network label: ${FRONTEND_NETWORK}${NC}"
echo -e "${BLUE}   Backend network label: ${BACKEND_NETWORK}${NC}"

# Verificar network real
REAL_NETWORK=$(docker network ls | grep imovelpro | awk '{print $2}' | head -1)
echo -e "${BLUE}   Network real: ${REAL_NETWORK}${NC}"

# Reiniciar Traefik
echo -e "${BLUE}5) Reiniciando Traefik...${NC}"
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    docker restart "$TRAEFIK_CONTAINER" 2>/dev/null || true
    sleep 10
    echo -e "${GREEN}✅ Traefik reiniciado${NC}"
fi

echo ""
echo -e "${GREEN}✅ Processo concluído!${NC}"
echo -e "${BLUE}   Aguarde alguns segundos e teste os domínios${NC}"


#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔗 Tentando conectar containers à network vpsnet${NC}"
echo ""

# Verificar se vpsnet existe
if ! docker network inspect vpsnet >/dev/null 2>&1; then
    echo -e "${RED}❌ Network vpsnet não encontrada${NC}"
    exit 1
fi

# Verificar tipo da network
NETWORK_TYPE=$(docker network inspect vpsnet --format '{{.Driver}}' 2>/dev/null || echo "")
NETWORK_SCOPE=$(docker network inspect vpsnet --format '{{.Scope}}' 2>/dev/null || echo "")

echo -e "${BLUE}   Network vpsnet: ${NETWORK_TYPE} (${NETWORK_SCOPE})${NC}"

if [ "$NETWORK_TYPE" = "overlay" ] && [ "$NETWORK_SCOPE" = "swarm" ]; then
    echo -e "${YELLOW}⚠️  Network vpsnet é overlay do Swarm${NC}"
    echo -e "${YELLOW}   Containers externos não podem se conectar diretamente${NC}"
    echo ""
    echo -e "${BLUE}💡 Solução: Usar IP do host no Traefik${NC}"
    echo -e "${BLUE}   Ou modificar configuração do Traefik para escutar em múltiplas networks${NC}"
    exit 1
fi

# Tentar conectar frontend
echo -e "${BLUE}1) Conectando frontend...${NC}"
if docker network connect vpsnet imovelpro-frontend 2>&1; then
    echo -e "${GREEN}✅ Frontend conectado à vpsnet${NC}"
else
    ERROR=$(docker network connect vpsnet imovelpro-frontend 2>&1)
    if echo "$ERROR" | grep -q "already"; then
        echo -e "${GREEN}✅ Frontend já estava conectado${NC}"
    else
        echo -e "${RED}❌ Erro: ${ERROR}${NC}"
    fi
fi

# Tentar conectar backend
echo -e "${BLUE}2) Conectando backend...${NC}"
if docker network connect vpsnet imovelpro-backend 2>&1; then
    echo -e "${GREEN}✅ Backend conectado à vpsnet${NC}"
else
    ERROR=$(docker network connect vpsnet imovelpro-backend 2>&1)
    if echo "$ERROR" | grep -q "already"; then
        echo -e "${GREEN}✅ Backend já estava conectado${NC}"
    else
        echo -e "${RED}❌ Erro: ${ERROR}${NC}"
    fi
fi

# Atualizar labels para usar vpsnet
echo -e "${BLUE}3) Atualizando labels para usar vpsnet...${NC}"
docker update --label-add "traefik.docker.network=vpsnet" imovelpro-frontend 2>/dev/null || true
docker update --label-add "traefik.docker.network=vpsnet" imovelpro-backend 2>/dev/null || true

# Reiniciar Traefik
echo -e "${BLUE}4) Reiniciando Traefik...${NC}"
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    docker restart "$TRAEFIK_CONTAINER" 2>/dev/null || true
    sleep 10
    echo -e "${GREEN}✅ Traefik reiniciado${NC}"
fi

echo ""
echo -e "${GREEN}✅ Processo concluído!${NC}"
echo -e "${BLUE}   Aguarde alguns segundos e teste os domínios${NC}"


#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🎯 Solução Final - Conectar containers à vpsnet${NC}"
echo ""

# Verificar vpsnet
if ! docker network inspect vpsnet >/dev/null 2>&1; then
    echo -e "${RED}❌ Network vpsnet não encontrada${NC}"
    exit 1
fi

VPSNET_TYPE=$(docker network inspect vpsnet --format '{{.Driver}}' 2>/dev/null || echo "")
VPSNET_SCOPE=$(docker network inspect vpsnet --format '{{.Scope}}' 2>/dev/null || echo "")

echo -e "${BLUE}   vpsnet: ${VPSNET_TYPE} (${VPSNET_SCOPE})${NC}"

if [ "$VPSNET_TYPE" = "overlay" ] && [ "$VPSNET_SCOPE" = "swarm" ]; then
    echo -e "${RED}❌ vpsnet é overlay do Swarm${NC}"
    echo -e "${YELLOW}   Containers externos NÃO podem se conectar${NC}"
    echo ""
    echo -e "${BLUE}💡 SOLUÇÃO: Modificar Traefik para detectar em múltiplas networks${NC}"
    echo -e "${BLUE}   OU usar Docker Swarm Stack (deploy/deploy-swarm.sh)${NC}"
    exit 1
fi

# Tentar conectar containers
echo -e "${BLUE}1) Conectando frontend à vpsnet...${NC}"
if docker network connect vpsnet imovelpro-frontend 2>&1; then
    echo -e "${GREEN}✅ Frontend conectado${NC}"
else
    ERROR=$(docker network connect vpsnet imovelpro-frontend 2>&1)
    if echo "$ERROR" | grep -q "already"; then
        echo -e "${GREEN}✅ Frontend já estava conectado${NC}"
    else
        echo -e "${RED}❌ Erro: ${ERROR}${NC}"
    fi
fi

echo -e "${BLUE}2) Conectando backend à vpsnet...${NC}"
if docker network connect vpsnet imovelpro-backend 2>&1; then
    echo -e "${GREEN}✅ Backend conectado${NC}"
else
    ERROR=$(docker network connect vpsnet imovelpro-backend 2>&1)
    if echo "$ERROR" | grep -q "already"; then
        echo -e "${GREEN}✅ Backend já estava conectado${NC}"
    else
        echo -e "${RED}❌ Erro: ${ERROR}${NC}"
    fi
fi

# Atualizar labels para usar vpsnet
echo -e "${BLUE}3) Atualizando labels...${NC}"
docker update --label-add "traefik.docker.network=vpsnet" imovelpro-frontend 2>/dev/null || true
docker update --label-add "traefik.docker.network=vpsnet" imovelpro-backend 2>/dev/null || true

# Reiniciar Traefik
echo -e "${BLUE}4) Reiniciando Traefik...${NC}"
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    docker restart "$TRAEFIK_CONTAINER" 2>/dev/null || true
    sleep 15
    echo -e "${GREEN}✅ Traefik reiniciado${NC}"
fi

# Verificar
echo -e "${BLUE}5) Verificando...${NC}"
sleep 10

CONTAINERS_IN_VPSNET=$(docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")
if echo "$CONTAINERS_IN_VPSNET" | grep -q "imovelpro"; then
    echo -e "${GREEN}✅ Containers estão na vpsnet!${NC}"
    echo -e "${GREEN}   Containers: $(echo "$CONTAINERS_IN_VPSNET" | grep -o "imovelpro[^ ]*" | tr '\n' ' ')${NC}"
else
    echo -e "${YELLOW}⚠️  Containers não estão na vpsnet${NC}"
fi

echo ""
echo -e "${GREEN}✅ Processo concluído!${NC}"
echo -e "${BLUE}   Aguarde 30 segundos e teste os domínios${NC}"





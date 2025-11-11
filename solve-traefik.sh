#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Solução Final - Traefik${NC}"
echo ""

# Encontrar Traefik
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Traefik não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik: ${TRAEFIK_CONTAINER}${NC}"

# Network dos containers
NETWORK_NAME="prototipo_mariana_imobiliarias_imovelpro-network"

# Garantir que Traefik está na network
echo -e "${BLUE}1) Conectando Traefik à network dos containers...${NC}"
docker network connect "$NETWORK_NAME" "$TRAEFIK_CONTAINER" 2>/dev/null || true
sleep 2

# Verificar se está conectado
CONTAINERS_IN_NETWORK=$(docker network inspect "$NETWORK_NAME" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")
if echo "$CONTAINERS_IN_NETWORK" | grep -q "traefik"; then
    echo -e "${GREEN}✅ Traefik está na network${NC}"
else
    echo -e "${RED}❌ Traefik não está na network${NC}"
    exit 1
fi

# Verificar configuração do Traefik
echo -e "${BLUE}2) Verificando configuração do Traefik...${NC}"
TRAEFIK_CMD=$(docker inspect "$TRAEFIK_CONTAINER" --format '{{join .Args " "}}' 2>/dev/null || echo "")

# Verificar se tem providers.docker.network
if echo "$TRAEFIK_CMD" | grep -q "providers.docker.network"; then
    echo -e "${YELLOW}⚠️  Traefik está limitado a uma network específica${NC}"
    echo -e "${BLUE}   Tentando fazer containers também estarem na vpsnet...${NC}"
    
    # Tentar conectar containers à vpsnet
    if docker network inspect vpsnet >/dev/null 2>&1; then
        VPSNET_TYPE=$(docker network inspect vpsnet --format '{{.Driver}}' 2>/dev/null || echo "")
        if [ "$VPSNET_TYPE" != "overlay" ]; then
            echo -e "${BLUE}   vpsnet é ${VPSNET_TYPE} - tentando conectar containers...${NC}"
            docker network connect vpsnet imovelpro-frontend 2>/dev/null || true
            docker network connect vpsnet imovelpro-backend 2>/dev/null || true
            echo -e "${GREEN}✅ Containers conectados à vpsnet${NC}"
        else
            echo -e "${YELLOW}⚠️  vpsnet é overlay do Swarm - containers externos não podem se conectar${NC}"
            echo -e "${BLUE}   Solução: Modificar stack do Traefik para remover limitação de network${NC}"
        fi
    fi
else
    echo -e "${GREEN}✅ Traefik não tem limitação de network${NC}"
fi

# Reiniciar Traefik
echo -e "${BLUE}3) Reiniciando Traefik...${NC}"
docker restart "$TRAEFIK_CONTAINER" 2>/dev/null || true
sleep 20

# Verificar rotas
echo -e "${BLUE}4) Verificando rotas...${NC}"
sleep 10

ROUTES=$(curl -s http://localhost:8080/api/http/routers 2>/dev/null || echo "[]")
IMOVELPRO_ROUTES=$(echo "$ROUTES" | jq '.[] | select(.name | contains("imovelpro"))' 2>/dev/null || echo "")

if [ ! -z "$IMOVELPRO_ROUTES" ]; then
    echo -e "${GREEN}✅✅✅ ROTAS DETECTADAS!${NC}"
    echo "$IMOVELPRO_ROUTES" | jq -r '.name' 2>/dev/null
    echo ""
    echo -e "${GREEN}🎉 SUCESSO! Teste os domínios:${NC}"
    echo -e "   - https://imob.locusup.shop"
    echo -e "   - https://apiapi.jyze.space/health"
else
    echo -e "${YELLOW}⚠️  Rotas ainda não detectadas${NC}"
    echo ""
    echo -e "${BLUE}📋 Diagnóstico:${NC}"
    echo -e "   - Containers na network: $(echo "$CONTAINERS_IN_NETWORK" | wc -w)"
    echo -e "   - Traefik na network: $(echo "$CONTAINERS_IN_NETWORK" | grep -q "traefik" && echo "sim" || echo "não")"
    echo ""
    echo -e "${BLUE}💡 Próximos passos:${NC}"
    echo -e "   1. Ver logs: ${YELLOW}docker logs -f $TRAEFIK_CONTAINER | grep -i imovelpro${NC}"
    echo -e "   2. Verificar se Traefik detecta containers: ${YELLOW}docker logs $TRAEFIK_CONTAINER | grep -i docker${NC}"
    echo -e "   3. Testar acesso direto: ${YELLOW}curl -I http://localhost:3429${NC}"
fi


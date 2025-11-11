#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🔍 Verificando configuração do Traefik${NC}"
echo ""

# Verificar container do Traefik
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Traefik não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik: ${TRAEFIK_CONTAINER}${NC}"
echo ""

# Verificar labels dos containers
echo -e "${BLUE}1) Verificando labels do Frontend...${NC}"
FRONTEND_LABELS=$(docker inspect imovelpro-frontend --format '{{json .Config.Labels}}' 2>/dev/null || echo "{}")
echo "$FRONTEND_LABELS" | jq 'with_entries(select(.key | startswith("traefik")))' 2>/dev/null || echo "$FRONTEND_LABELS"
echo ""

echo -e "${BLUE}2) Verificando labels do Backend...${NC}"
BACKEND_LABELS=$(docker inspect imovelpro-backend --format '{{json .Config.Labels}}' 2>/dev/null || echo "{}")
echo "$BACKEND_LABELS" | jq 'with_entries(select(.key | startswith("traefik")))' 2>/dev/null || echo "$BACKEND_LABELS"
echo ""

# Verificar networks do Traefik
echo -e "${BLUE}3) Verificando networks do Traefik...${NC}"
TRAEFIK_NETWORKS=$(docker inspect "$TRAEFIK_CONTAINER" --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}' 2>/dev/null || echo "")
echo -e "${GREEN}   Networks: ${TRAEFIK_NETWORKS}${NC}"
echo ""

# Verificar containers na network
NETWORK_NAME="prototipo_mariana_imobiliarias_imovelpro-network"
echo -e "${BLUE}4) Verificando containers na network ${NETWORK_NAME}...${NC}"
CONTAINERS=$(docker network inspect "$NETWORK_NAME" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")
echo -e "${GREEN}   Containers: ${CONTAINERS}${NC}"
echo ""

# Verificar se Traefik tem Docker provider habilitado
echo -e "${BLUE}5) Verificando configuração do Traefik (Docker provider)...${NC}"
TRAEFIK_CMD=$(docker inspect "$TRAEFIK_CONTAINER" --format '{{join .Args " "}}' 2>/dev/null || echo "")
if echo "$TRAEFIK_CMD" | grep -q "providers.docker"; then
    echo -e "${GREEN}   ✅ Docker provider encontrado${NC}"
    # Verificar network do Docker provider
    if echo "$TRAEFIK_CMD" | grep -q "providers.docker.network"; then
        PROVIDER_NETWORK=$(echo "$TRAEFIK_CMD" | grep -oP 'providers.docker.network=\K[^\s]+' || echo "")
        echo -e "${BLUE}   Network do provider: ${PROVIDER_NETWORK}${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Network do provider não especificada (Traefik usa todas as networks)${NC}"
    fi
else
    echo -e "${YELLOW}   ⚠️  Docker provider pode não estar habilitado${NC}"
fi
echo ""

# Verificar rotas do Traefik
echo -e "${BLUE}6) Verificando rotas do Traefik...${NC}"
ROUTES=$(curl -s http://localhost:8080/api/http/routers 2>/dev/null || echo "[]")
if [ ! -z "$ROUTES" ] && [ "$ROUTES" != "[]" ]; then
    IMOVELPRO_ROUTES=$(echo "$ROUTES" | jq '.[] | select(.name | contains("imovelpro"))' 2>/dev/null || echo "")
    if [ ! -z "$IMOVELPRO_ROUTES" ]; then
        echo -e "${GREEN}   ✅ Rotas do imovelpro encontradas:${NC}"
        echo "$IMOVELPRO_ROUTES" | jq -r '.name' 2>/dev/null || echo "$IMOVELPRO_ROUTES"
    else
        echo -e "${YELLOW}   ⚠️  Nenhuma rota do imovelpro encontrada${NC}"
        echo -e "${BLUE}   Total de rotas: $(echo "$ROUTES" | jq 'length' 2>/dev/null || echo "0")${NC}"
    fi
else
    echo -e "${YELLOW}   ⚠️  Não foi possível acessar a API do Traefik${NC}"
    echo -e "${BLUE}   Verifique se a API está habilitada na porta 8080${NC}"
fi
echo ""

# Sugestões
echo -e "${BLUE}💡 Próximos passos:${NC}"
echo -e "   1. Aguarde alguns segundos para o Traefik detectar (pode levar até 30s)"
echo -e "   2. Verifique logs do Traefik: ${YELLOW}docker logs -f $TRAEFIK_CONTAINER${NC}"
echo -e "   3. Reinicie o Traefik: ${YELLOW}docker restart $TRAEFIK_CONTAINER${NC}"
echo -e "   4. Verifique se os containers têm os labels corretos (acima)"
echo ""


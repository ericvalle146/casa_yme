#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔧 Configuração Final do Traefik${NC}"
echo ""

# Encontrar Traefik
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Traefik não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik encontrado: ${TRAEFIK_CONTAINER}${NC}"
echo ""

# Network dos containers
NETWORK_NAME="prototipo_mariana_imobiliarias_imovelpro-network"

# Verificar se Traefik está na network
echo -e "${BLUE}1) Verificando se Traefik está na network dos containers...${NC}"
TRAEFIK_NETWORKS=$(docker inspect "$TRAEFIK_CONTAINER" --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}' 2>/dev/null || echo "")

if echo "$TRAEFIK_NETWORKS" | grep -q "$NETWORK_NAME\|imovelpro"; then
    echo -e "${GREEN}✅ Traefik já está na network${NC}"
else
    echo -e "${BLUE}   Conectando Traefik à network...${NC}"
    if docker network connect "$NETWORK_NAME" "$TRAEFIK_CONTAINER" 2>&1; then
        echo -e "${GREEN}✅ Traefik conectado${NC}"
    else
        ERROR_OUTPUT=$(docker network connect "$NETWORK_NAME" "$TRAEFIK_CONTAINER" 2>&1)
        if echo "$ERROR_OUTPUT" | grep -q "already"; then
            echo -e "${GREEN}✅ Traefik já estava conectado${NC}"
        else
            echo -e "${RED}❌ Erro ao conectar: ${ERROR_OUTPUT}${NC}"
        fi
    fi
fi

echo ""

# Verificar configuração do Traefik
echo -e "${BLUE}2) Verificando configuração do Traefik...${NC}"
TRAEFIK_CMD=$(docker inspect "$TRAEFIK_CONTAINER" --format '{{join .Args " "}}' 2>/dev/null || echo "")

# Verificar se tem limitação de network
if echo "$TRAEFIK_CMD" | grep -q "providers.docker.network"; then
    PROVIDER_NETWORK=$(echo "$TRAEFIK_CMD" | grep -oP 'providers.docker.network=\K[^\s]+' || echo "")
    echo -e "${YELLOW}⚠️  Traefik está limitado à network: ${PROVIDER_NETWORK}${NC}"
    echo -e "${YELLOW}   Isso impede detectar containers em outras networks${NC}"
    echo ""
    echo -e "${BLUE}💡 Solução:${NC}"
    echo -e "${BLUE}   Você precisa modificar o stack do Traefik para remover a limitação de network${NC}"
    echo -e "${BLUE}   OU fazer os containers estarem na mesma network (vpsnet)${NC}"
else
    echo -e "${GREEN}✅ Traefik não tem limitação de network${NC}"
    echo -e "${GREEN}   Deve detectar containers em todas as networks que está conectado${NC}"
fi

echo ""

# Verificar se containers estão na network
echo -e "${BLUE}3) Verificando containers na network...${NC}"
CONTAINERS=$(docker network inspect "$NETWORK_NAME" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")
echo -e "${GREEN}   Containers: ${CONTAINERS}${NC}"

# Verificar labels
echo ""
echo -e "${BLUE}4) Verificando labels dos containers...${NC}"
FRONTEND_LABELS=$(docker inspect imovelpro-frontend --format '{{index .Config.Labels "traefik.enable"}}' 2>/dev/null || echo "")
BACKEND_LABELS=$(docker inspect imovelpro-backend --format '{{index .Config.Labels "traefik.enable"}}' 2>/dev/null || echo "")

if [ "$FRONTEND_LABELS" = "true" ] && [ "$BACKEND_LABELS" = "true" ]; then
    echo -e "${GREEN}✅ Labels do Traefik configurados${NC}"
else
    echo -e "${YELLOW}⚠️  Labels podem estar incorretos${NC}"
fi

echo ""

# Reiniciar Traefik
echo -e "${BLUE}5) Reiniciando Traefik...${NC}"
docker restart "$TRAEFIK_CONTAINER" 2>/dev/null || true
sleep 15

echo ""

# Verificar rotas
echo -e "${BLUE}6) Verificando rotas do Traefik...${NC}"
sleep 5

# Tentar acessar API do Traefik
API_URL="http://localhost:8080/api/http/routers"
ROUTES=$(curl -s "$API_URL" 2>/dev/null || echo "[]")

if [ "$ROUTES" != "[]" ] && [ ! -z "$ROUTES" ]; then
    IMOVELPRO_ROUTES=$(echo "$ROUTES" | jq '.[] | select(.name | contains("imovelpro"))' 2>/dev/null || echo "")
    
    if [ ! -z "$IMOVELPRO_ROUTES" ]; then
        echo -e "${GREEN}✅ Rotas do imovelpro encontradas!${NC}"
        echo "$IMOVELPRO_ROUTES" | jq -r '.name' 2>/dev/null
    else
        echo -e "${YELLOW}⚠️  Rotas do imovelpro não encontradas${NC}"
        echo -e "${BLUE}   Total de rotas: $(echo "$ROUTES" | jq 'length' 2>/dev/null || echo "0")${NC}"
        
        # Mostrar algumas rotas para debug
        echo -e "${BLUE}   Algumas rotas encontradas:${NC}"
        echo "$ROUTES" | jq -r '.[].name' 2>/dev/null | head -5 || echo "   Nenhuma"
    fi
else
    echo -e "${YELLOW}⚠️  Não foi possível acessar a API do Traefik${NC}"
    echo -e "${BLUE}   Verifique se a API está habilitada${NC}"
fi

echo ""
echo -e "${GREEN}✅ Processo concluído!${NC}"
echo ""
echo -e "${BLUE}💡 Se as rotas não apareceram:${NC}"
echo -e "   1. Verifique logs do Traefik: ${YELLOW}docker logs -f $TRAEFIK_CONTAINER${NC}"
echo -e "   2. Verifique se o Traefik está na network: ${YELLOW}docker network inspect $NETWORK_NAME${NC}"
echo -e "   3. Teste os domínios diretamente:"
echo -e "      - ${YELLOW}curl -I https://imob.locusup.shop${NC}"
echo -e "      - ${YELLOW}curl -I https://apiapi.jyze.space/health${NC}"


#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔍 Verificando Traefik e Rotas${NC}"
echo ""

# Encontrar Traefik
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Traefik não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik: ${TRAEFIK_CONTAINER}${NC}"
echo ""

# Verificar se API está acessível
echo -e "${BLUE}1) Verificando API do Traefik...${NC}"
API_RESPONSE=$(curl -s http://localhost:8080/api/http/routers 2>&1 || echo "ERROR")

if echo "$API_RESPONSE" | grep -q "ERROR\|Failed\|Connection refused"; then
    echo -e "${YELLOW}⚠️  API do Traefik não está acessível na porta 8080${NC}"
    echo -e "${BLUE}   Verificando portas expostas do Traefik...${NC}"
    docker port "$TRAEFIK_CONTAINER" | grep 8080 || echo "   Porta 8080 não exposta"
else
    echo -e "${GREEN}✅ API do Traefik acessível${NC}"
    
    # Verificar rotas
    echo -e "${BLUE}2) Verificando rotas do imovelpro...${NC}"
    ROUTES=$(echo "$API_RESPONSE" | jq -r '.[].name' 2>/dev/null || echo "")
    
    if echo "$ROUTES" | grep -q "imovelpro"; then
        echo -e "${GREEN}✅ Rotas do imovelpro encontradas:${NC}"
        echo "$ROUTES" | grep "imovelpro" | while read route; do
            echo -e "   - ${route}"
        done
    else
        echo -e "${YELLOW}⚠️  Rotas do imovelpro NÃO encontradas${NC}"
        echo -e "${BLUE}   Rotas disponíveis:${NC}"
        echo "$ROUTES" | head -10
    fi
fi

echo ""

# Verificar serviços do Swarm
echo -e "${BLUE}3) Verificando serviços do Swarm...${NC}"
SERVICES=$(docker service ls --format "{{.Name}}" | grep imovelpro || echo "")
if [ ! -z "$SERVICES" ]; then
    echo -e "${GREEN}✅ Serviços encontrados:${NC}"
    echo "$SERVICES" | while read service; do
        echo -e "   - ${service}"
    done
else
    echo -e "${RED}❌ Serviços não encontrados${NC}"
fi

echo ""

# Verificar network vpsnet
echo -e "${BLUE}4) Verificando network vpsnet...${NC}"
CONTAINERS_IN_VPSNET=$(docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")
if echo "$CONTAINERS_IN_VPSNET" | grep -q "imovelpro"; then
    echo -e "${GREEN}✅ Serviços estão na network vpsnet${NC}"
    echo "$CONTAINERS_IN_VPSNET" | tr ' ' '\n' | grep "imovelpro" | while read container; do
        echo -e "   - ${container}"
    done
else
    echo -e "${YELLOW}⚠️  Serviços NÃO estão na network vpsnet${NC}"
fi

echo ""

# Verificar logs do Traefik
echo -e "${BLUE}5) Verificando logs do Traefik (últimas 50 linhas)...${NC}"
docker logs "$TRAEFIK_CONTAINER" --tail 50 2>&1 | grep -i "imovelpro\|error\|certificate\|tls" || echo "   Nenhum log relevante encontrado"

echo ""
echo -e "${BLUE}💡 Próximos passos:${NC}"
echo -e "   - Se as rotas não aparecerem, aguarde alguns minutos (Traefik pode levar tempo para detectar)"
echo -e "   - Verifique certificados: ${YELLOW}docker logs $TRAEFIK_CONTAINER | grep -i cert${NC}"
echo -e "   - Teste acesso direto: ${YELLOW}curl -I http://localhost:3429${NC}"


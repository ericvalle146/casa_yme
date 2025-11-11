#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}⏳ Aguardando Traefik detectar serviços...${NC}"
echo ""

MAX_WAIT=120
WAITED=0
INTERVAL=10

while [ $WAITED -lt $MAX_WAIT ]; do
    # Tentar acessar API do Traefik
    ROUTES=$(curl -s http://localhost:8080/api/http/routers 2>/dev/null || echo "[]")
    
    if [ "$ROUTES" != "[]" ]; then
        IMOVELPRO_ROUTES=$(echo "$ROUTES" | jq -r '.[].name' 2>/dev/null | grep "imovelpro" || echo "")
        
        if [ ! -z "$IMOVELPRO_ROUTES" ]; then
            echo -e "${GREEN}✅ Rotas detectadas!${NC}"
            echo "$IMOVELPRO_ROUTES" | while read route; do
                echo -e "   - ${route}"
            done
            echo ""
            echo -e "${GREEN}✅ Traefik está detectando os serviços${NC}"
            exit 0
        fi
    fi
    
    echo -e "${BLUE}   Aguardando... (${WAITED}s/${MAX_WAIT}s)${NC}"
    sleep $INTERVAL
    WAITED=$((WAITED + INTERVAL))
done

echo -e "${YELLOW}⚠️  Rotas não foram detectadas após ${MAX_WAIT} segundos${NC}"
echo -e "${BLUE}   Verifique manualmente:${NC}"
echo -e "${BLUE}   ${YELLOW}curl -s http://localhost:8080/api/http/routers | jq '.[].name'${NC}"


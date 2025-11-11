#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🔄 Forçando detecção do Traefik${NC}"
echo ""

TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")

if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${YELLOW}⚠️  Traefik não encontrado${NC}"
    exit 1
fi

echo -e "${BLUE}1) Reiniciando containers para forçar detecção...${NC}"
docker restart imovelpro-frontend imovelpro-backend 2>/dev/null || true
sleep 5

echo -e "${BLUE}2) Reiniciando Traefik...${NC}"
docker restart "$TRAEFIK_CONTAINER" 2>/dev/null || true
sleep 10

echo -e "${BLUE}3) Verificando rotas...${NC}"
sleep 5

ROUTES=$(curl -s http://localhost:8080/api/http/routers 2>/dev/null || echo "[]")
IMOVELPRO_ROUTES=$(echo "$ROUTES" | jq '.[] | select(.name | contains("imovelpro"))' 2>/dev/null || echo "")

if [ ! -z "$IMOVELPRO_ROUTES" ]; then
    echo -e "${GREEN}✅ Rotas detectadas!${NC}"
    echo "$IMOVELPRO_ROUTES" | jq -r '.name' 2>/dev/null
else
    echo -e "${YELLOW}⚠️  Rotas ainda não detectadas${NC}"
    echo -e "${BLUE}   Verifique os logs: ${YELLOW}docker logs -f $TRAEFIK_CONTAINER${NC}"
    echo -e "${BLUE}   Verifique labels: ${YELLOW}docker inspect imovelpro-frontend --format '{{json .Config.Labels}}' | jq${NC}"
fi

echo ""
echo -e "${BLUE}💡 Teste os domínios:${NC}"
echo -e "   - https://imob.locusup.shop"
echo -e "   - https://apiapi.jyze.space/health"


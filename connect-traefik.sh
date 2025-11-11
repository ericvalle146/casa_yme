#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🔗 Conectando Traefik à network imovelpro-network${NC}"
echo ""

# Encontrar container do Traefik
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")

if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${YELLOW}⚠️  Traefik não encontrado${NC}"
    echo -e "${BLUE}   Containers estão rodando em:${NC}"
    echo -e "   - Frontend: http://localhost:3429"
    echo -e "   - Backend: http://localhost:4000"
    echo ""
    echo -e "${BLUE}   Para conectar manualmente:${NC}"
    echo -e "   ${YELLOW}docker network connect imovelpro-network <traefik-container>${NC}"
    exit 0
fi

echo -e "${GREEN}✅ Traefik encontrado: ${TRAEFIK_CONTAINER}${NC}"

# Conectar à network
if docker network connect imovelpro-network "$TRAEFIK_CONTAINER" 2>/dev/null; then
    echo -e "${GREEN}✅ Traefik conectado à network imovelpro-network${NC}"
    
    # Reiniciar Traefik para detectar novos containers
    echo -e "${BLUE}   Reiniciando Traefik...${NC}"
    docker restart "$TRAEFIK_CONTAINER" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Traefik reiniciado${NC}"
    echo ""
    echo -e "${BLUE}📋 Aguarde alguns segundos para o Traefik detectar os containers${NC}"
    echo -e "${BLUE}   Teste os domínios:${NC}"
    echo -e "   - https://imob.locusup.shop"
    echo -e "   - https://apiapi.jyze.space/health"
else
    echo -e "${YELLOW}⚠️  Traefik já estava conectado ou erro${NC}"
    echo -e "${BLUE}   Verifique manualmente:${NC}"
    echo -e "   ${YELLOW}docker network inspect imovelpro-network${NC}"
fi


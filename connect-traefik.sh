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

# Verificar se já está na network
NETWORK_NAME="prototipo_mariana_imobiliarias_imovelpro-network"
if [ -z "$NETWORK_NAME" ]; then
    NETWORK_NAME="imovelpro-network"
fi

TRAEFIK_NETWORKS=$(docker inspect "$TRAEFIK_CONTAINER" --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}' 2>/dev/null || echo "")

if echo "$TRAEFIK_NETWORKS" | grep -q "$NETWORK_NAME\|imovelpro"; then
    echo -e "${GREEN}✅ Traefik já está na network${NC}"
    echo -e "${BLUE}   Reiniciando Traefik para detectar novos containers...${NC}"
    docker restart "$TRAEFIK_CONTAINER" 2>/dev/null || true
    sleep 5
    echo -e "${GREEN}✅ Traefik reiniciado${NC}"
else
    # Tentar conectar
    echo -e "${BLUE}   Conectando Traefik à network...${NC}"
    if docker network connect "$NETWORK_NAME" "$TRAEFIK_CONTAINER" 2>&1; then
        echo -e "${GREEN}✅ Traefik conectado à network${NC}"
        echo -e "${BLUE}   Reiniciando Traefik...${NC}"
        docker restart "$TRAEFIK_CONTAINER" 2>/dev/null || true
        sleep 5
        echo -e "${GREEN}✅ Traefik reiniciado${NC}"
    else
        # Tentar com nome alternativo
        if docker network connect imovelpro-network "$TRAEFIK_CONTAINER" 2>&1; then
            echo -e "${GREEN}✅ Traefik conectado à network${NC}"
            docker restart "$TRAEFIK_CONTAINER" 2>/dev/null || true
            sleep 5
        else
            echo -e "${YELLOW}⚠️  Erro ao conectar Traefik${NC}"
            echo -e "${BLUE}   Networks disponíveis:${NC}"
            docker network ls | grep imovelpro || echo "   Nenhuma network imovelpro encontrada"
            echo -e "${BLUE}   Verifique manualmente:${NC}"
            echo -e "   ${YELLOW}docker network inspect $NETWORK_NAME${NC}"
            echo -e "   ${YELLOW}docker network connect $NETWORK_NAME $TRAEFIK_CONTAINER${NC}"
        fi
    fi
fi

# Verificar containers na network
echo ""
echo -e "${BLUE}📋 Verificando containers na network...${NC}"
CONTAINERS_IN_NETWORK=$(docker network inspect "$NETWORK_NAME" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")
if [ ! -z "$CONTAINERS_IN_NETWORK" ]; then
    echo -e "${GREEN}✅ Containers na network:${NC}"
    echo "$CONTAINERS_IN_NETWORK" | tr ' ' '\n' | grep -v '^$' | while read container; do
        echo -e "   - ${container}"
    done
else
    echo -e "${YELLOW}⚠️  Nenhum container encontrado na network${NC}"
fi

echo ""
echo -e "${GREEN}✅ Processo concluído!${NC}"
echo ""
echo -e "${BLUE}🌐 Aguarde alguns segundos e teste os domínios:${NC}"
echo -e "   - https://imob.locusup.shop"
echo -e "   - https://apiapi.jyze.space/health"
echo ""
echo -e "${BLUE}💡 Para verificar rotas do Traefik:${NC}"
echo -e "   ${YELLOW}curl -s http://localhost:8080/api/http/routers | jq '.[] | select(.name | contains(\"imovelpro\"))'${NC}"


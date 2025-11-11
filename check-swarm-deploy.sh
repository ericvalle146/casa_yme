#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔍 Verificando deploy Swarm${NC}"
echo ""

# Verificar serviços
echo -e "${BLUE}1) Verificando serviços...${NC}"
docker service ls | grep imovelpro

echo ""

# Verificar se serviços estão na vpsnet
echo -e "${BLUE}2) Verificando network vpsnet...${NC}"
CONTAINERS_IN_VPSNET=$(docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")

if echo "$CONTAINERS_IN_VPSNET" | grep -q "imovelpro"; then
    echo -e "${GREEN}✅ Serviços estão na vpsnet${NC}"
    echo "$CONTAINERS_IN_VPSNET" | grep -o "imovelpro[^ ]*" | while read service; do
        echo -e "   - ${service}"
    done
else
    echo -e "${YELLOW}⚠️  Serviços não encontrados na vpsnet${NC}"
fi

echo ""

# Verificar labels dos serviços
echo -e "${BLUE}3) Verificando labels dos serviços...${NC}"

# Frontend
FRONTEND_LABELS=$(docker service inspect imovelpro_frontend --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' 2>/dev/null || echo "{}")
echo -e "${BLUE}   Frontend labels:${NC}"
echo "$FRONTEND_LABELS" | jq 'with_entries(select(.key | startswith("traefik")))' 2>/dev/null || echo "$FRONTEND_LABELS"

echo ""

# Backend
BACKEND_LABELS=$(docker service inspect imovelpro_backend --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' 2>/dev/null || echo "{}")
echo -e "${BLUE}   Backend labels:${NC}"
echo "$BACKEND_LABELS" | jq 'with_entries(select(.key | startswith("traefik")))' 2>/dev/null || echo "$BACKEND_LABELS"

echo ""

# Verificar Traefik
echo -e "${BLUE}4) Verificando Traefik...${NC}"
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${GREEN}✅ Traefik: ${TRAEFIK_CONTAINER}${NC}"
    
    # Verificar se está na vpsnet
    TRAEFIK_NETWORKS=$(docker inspect "$TRAEFIK_CONTAINER" --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}' 2>/dev/null || echo "")
    if echo "$TRAEFIK_NETWORKS" | grep -q "vpsnet"; then
        echo -e "${GREEN}✅ Traefik está na vpsnet${NC}"
    else
        echo -e "${YELLOW}⚠️  Traefik NÃO está na vpsnet${NC}"
    fi
else
    echo -e "${RED}❌ Traefik não encontrado${NC}"
fi

echo ""

# Aguardar e verificar rotas
echo -e "${BLUE}5) Aguardando Traefik detectar (30 segundos)...${NC}"
sleep 30

# Verificar rotas
echo -e "${BLUE}6) Verificando rotas do Traefik...${NC}"
ROUTES=$(curl -s http://localhost:8080/api/http/routers 2>/dev/null || echo "[]")

if [ "$ROUTES" != "[]" ] && [ ! -z "$ROUTES" ]; then
    IMOVELPRO_ROUTES=$(echo "$ROUTES" | jq '.[] | select(.name | contains("imovelpro"))' 2>/dev/null || echo "")
    
    if [ ! -z "$IMOVELPRO_ROUTES" ]; then
        echo -e "${GREEN}✅✅✅ ROTAS DETECTADAS!${NC}"
        echo "$IMOVELPRO_ROUTES" | jq -r '.name' 2>/dev/null
        echo ""
        echo -e "${GREEN}🎉 SUCESSO! Teste os domínios:${NC}"
        echo -e "   - https://imob.locusup.shop"
        echo -e "   - https://apiapi.jyze.space/health"
    else
        echo -e "${YELLOW}⚠️  Rotas do imovelpro não encontradas${NC}"
        echo -e "${BLUE}   Total de rotas: $(echo "$ROUTES" | jq 'length' 2>/dev/null || echo "0")${NC}"
        echo ""
        echo -e "${BLUE}💡 Tentando reiniciar Traefik...${NC}"
        if [ ! -z "$TRAEFIK_CONTAINER" ]; then
            docker restart "$TRAEFIK_CONTAINER" 2>/dev/null || true
            sleep 20
            echo -e "${GREEN}✅ Traefik reiniciado${NC}"
            echo -e "${BLUE}   Aguarde mais 30 segundos...${NC}"
            sleep 30
            ROUTES=$(curl -s http://localhost:8080/api/http/routers 2>/dev/null || echo "[]")
            IMOVELPRO_ROUTES=$(echo "$ROUTES" | jq '.[] | select(.name | contains("imovelpro"))' 2>/dev/null || echo "")
            if [ ! -z "$IMOVELPRO_ROUTES" ]; then
                echo -e "${GREEN}✅ Rotas detectadas após reinício!${NC}"
            else
                echo -e "${YELLOW}⚠️  Ainda não detectado${NC}"
                echo -e "${BLUE}   Verifique logs: docker logs -f $TRAEFIK_CONTAINER | grep -i imovelpro${NC}"
            fi
        fi
    fi
else
    echo -e "${YELLOW}⚠️  Não foi possível acessar a API do Traefik${NC}"
    echo -e "${BLUE}   A API pode não estar habilitada na porta 8080${NC}"
fi

echo ""
echo -e "${BLUE}💡 Teste direto:${NC}"
echo -e "   curl -I https://imob.locusup.shop"
echo -e "   curl -I https://apiapi.jyze.space/health"


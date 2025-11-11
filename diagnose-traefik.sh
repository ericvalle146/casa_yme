#!/bin/bash

# Script de diagnóstico do Traefik
# Verifica a configuração e identifica problemas

set -e

echo "🔍 Diagnóstico do Traefik e configuração de rede..."
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Verificar network vpsnet
echo -e "${BLUE}1. Verificando network vpsnet...${NC}"
if docker network inspect vpsnet >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Network vpsnet existe${NC}"
    
    IS_ATTACHABLE=$(docker network inspect vpsnet --format '{{.Attachable}}' 2>/dev/null || echo "false")
    DRIVER=$(docker network inspect vpsnet --format '{{.Driver}}' 2>/dev/null || echo "unknown")
    
    echo -e "   Driver: ${DRIVER}"
    echo -e "   Attachable: ${IS_ATTACHABLE}"
    
    if [ "$IS_ATTACHABLE" != "true" ]; then
        echo -e "${RED}❌ PROBLEMA: Network vpsnet não é attachable${NC}"
        echo -e "${YELLOW}   Solução:${NC}"
        echo -e "${YELLOW}   1. Parar serviços: docker stack rm <stack-name> (se usando Docker Swarm)${NC}"
        echo -e "${YELLOW}   2. Remover network: docker network rm vpsnet${NC}"
        echo -e "${YELLOW}   3. Recriar: docker network create --driver bridge --attachable vpsnet${NC}"
    else
        echo -e "${GREEN}✅ Network vpsnet é attachable${NC}"
    fi
    
    # Listar containers na network
    echo -e "${BLUE}   Containers na network vpsnet:${NC}"
    docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "   Nenhum container"
else
    echo -e "${RED}❌ Network vpsnet não existe${NC}"
    echo -e "${YELLOW}   Criando network vpsnet...${NC}"
    if docker network create --driver bridge --attachable vpsnet 2>/dev/null; then
        echo -e "${GREEN}✅ Network vpsnet criada${NC}"
    else
        echo -e "${RED}❌ Erro ao criar network${NC}"
    fi
fi

echo ""

# 2. Verificar Traefik
echo -e "${BLUE}2. Verificando Traefik...${NC}"
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${GREEN}✅ Traefik encontrado: ${TRAEFIK_CONTAINER}${NC}"
    
    # Verificar networks do Traefik
    TRAEFIK_NETWORKS=$(docker inspect $TRAEFIK_CONTAINER --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}' 2>/dev/null || echo "")
    echo -e "   Networks do Traefik: ${TRAEFIK_NETWORKS}"
    
    if echo "$TRAEFIK_NETWORKS" | grep -q "vpsnet"; then
        echo -e "${GREEN}✅ Traefik está na network vpsnet${NC}"
    else
        echo -e "${RED}❌ PROBLEMA: Traefik NÃO está na network vpsnet${NC}"
        echo -e "${YELLOW}   Solução: Conecte o Traefik à network vpsnet${NC}"
        echo -e "${YELLOW}   docker network connect vpsnet ${TRAEFIK_CONTAINER}${NC}"
    fi
    
    # Verificar labels do Traefik
    echo -e "${BLUE}   Verificando configuração do Traefik...${NC}"
    TRAEFIK_LABELS=$(docker inspect $TRAEFIK_CONTAINER --format '{{json .Config.Labels}}' 2>/dev/null || echo "{}")
    echo -e "   Labels do Traefik: $(echo $TRAEFIK_LABELS | jq -r 'keys[]' 2>/dev/null | head -5 | tr '\n' ' ' || echo 'N/A')"
else
    echo -e "${YELLOW}⚠️  Traefik não encontrado${NC}"
fi

echo ""

# 3. Verificar containers do projeto
echo -e "${BLUE}3. Verificando containers do projeto...${NC}"

# Frontend
FRONTEND_CONTAINER="imovelpro-frontend"
if docker ps --format "{{.Names}}" | grep -q "^${FRONTEND_CONTAINER}$"; then
    echo -e "${GREEN}✅ Container ${FRONTEND_CONTAINER} está rodando${NC}"
    
    FRONTEND_NETWORKS=$(docker inspect $FRONTEND_CONTAINER --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}' 2>/dev/null || echo "")
    echo -e "   Networks: ${FRONTEND_NETWORKS}"
    
    if echo "$FRONTEND_NETWORKS" | grep -q "vpsnet"; then
        echo -e "${GREEN}✅ ${FRONTEND_CONTAINER} está na network vpsnet${NC}"
    else
        echo -e "${RED}❌ PROBLEMA: ${FRONTEND_CONTAINER} NÃO está na network vpsnet${NC}"
        echo -e "${YELLOW}   Solução: docker network connect vpsnet ${FRONTEND_CONTAINER}${NC}"
    fi
    
    # Verificar labels do Traefik no frontend
    FRONTEND_LABELS=$(docker inspect $FRONTEND_CONTAINER --format '{{json .Config.Labels}}' 2>/dev/null || echo "{}")
    if echo "$FRONTEND_LABELS" | jq -e '.traefik.enable' >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Labels do Traefik configurados no frontend${NC}"
        echo -e "   Router: $(echo $FRONTEND_LABELS | jq -r '.["traefik.http.routers.imovelpro-frontend.rule"]' 2>/dev/null || echo 'N/A')"
        echo -e "   Entrypoint: $(echo $FRONTEND_LABELS | jq -r '.["traefik.http.routers.imovelpro-frontend.entrypoints"]' 2>/dev/null || echo 'N/A')"
    else
        echo -e "${RED}❌ Labels do Traefik não configurados no frontend${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Container ${FRONTEND_CONTAINER} não está rodando${NC}"
fi

# Backend
BACKEND_CONTAINER="imovelpro-backend"
if docker ps --format "{{.Names}}" | grep -q "^${BACKEND_CONTAINER}$"; then
    echo -e "${GREEN}✅ Container ${BACKEND_CONTAINER} está rodando${NC}"
    
    BACKEND_NETWORKS=$(docker inspect $BACKEND_CONTAINER --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}' 2>/dev/null || echo "")
    echo -e "   Networks: ${BACKEND_NETWORKS}"
    
    if echo "$BACKEND_NETWORKS" | grep -q "vpsnet"; then
        echo -e "${GREEN}✅ ${BACKEND_CONTAINER} está na network vpsnet${NC}"
    else
        echo -e "${RED}❌ PROBLEMA: ${BACKEND_CONTAINER} NÃO está na network vpsnet${NC}"
        echo -e "${YELLOW}   Solução: docker network connect vpsnet ${BACKEND_CONTAINER}${NC}"
    fi
    
    # Verificar labels do Traefik no backend
    BACKEND_LABELS=$(docker inspect $BACKEND_CONTAINER --format '{{json .Config.Labels}}' 2>/dev/null || echo "{}")
    if echo "$BACKEND_LABELS" | jq -e '.traefik.enable' >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Labels do Traefik configurados no backend${NC}"
        echo -e "   Router: $(echo $BACKEND_LABELS | jq -r '.["traefik.http.routers.imovelpro-backend.rule"]' 2>/dev/null || echo 'N/A')"
        echo -e "   Entrypoint: $(echo $BACKEND_LABELS | jq -r '.["traefik.http.routers.imovelpro-backend.entrypoints"]' 2>/dev/null || echo 'N/A')"
    else
        echo -e "${RED}❌ Labels do Traefik não configurados no backend${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Container ${BACKEND_CONTAINER} não está rodando${NC}"
fi

echo ""

# 4. Verificar DNS
echo -e "${BLUE}4. Verificando DNS...${NC}"
SERVER_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || hostname -I | awk '{print $1}')
echo -e "   IP do servidor: ${SERVER_IP}"

FRONTEND_DOMAIN="imob.locusup.shop"
BACKEND_DOMAIN="apiapi.jyze.space"

echo -e "   Verificando ${FRONTEND_DOMAIN}..."
FRONTEND_DNS_IP=$(dig +short ${FRONTEND_DOMAIN} @8.8.8.8 | tail -1 || echo "")
if [ ! -z "$FRONTEND_DNS_IP" ]; then
    echo -e "   DNS de ${FRONTEND_DOMAIN}: ${FRONTEND_DNS_IP}"
    if [ "$FRONTEND_DNS_IP" = "$SERVER_IP" ]; then
        echo -e "${GREEN}✅ ${FRONTEND_DOMAIN} aponta para o servidor${NC}"
    else
        echo -e "${YELLOW}⚠️  ${FRONTEND_DOMAIN} NÃO aponta para o servidor (${SERVER_IP})${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Não foi possível resolver ${FRONTEND_DOMAIN}${NC}"
fi

echo -e "   Verificando ${BACKEND_DOMAIN}..."
BACKEND_DNS_IP=$(dig +short ${BACKEND_DOMAIN} @8.8.8.8 | tail -1 || echo "")
if [ ! -z "$BACKEND_DNS_IP" ]; then
    echo -e "   DNS de ${BACKEND_DOMAIN}: ${BACKEND_DNS_IP}"
    if [ "$BACKEND_DNS_IP" = "$SERVER_IP" ]; then
        echo -e "${GREEN}✅ ${BACKEND_DOMAIN} aponta para o servidor${NC}"
    else
        echo -e "${YELLOW}⚠️  ${BACKEND_DOMAIN} NÃO aponta para o servidor (${SERVER_IP})${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Não foi possível resolver ${BACKEND_DOMAIN}${NC}"
fi

echo ""

# 5. Resumo
echo -e "${BLUE}5. Resumo:${NC}"
echo -e "   Para verificar se o Traefik está funcionando:"
echo -e "   - Acesse: https://${FRONTEND_DOMAIN}"
echo -e "   - Acesse: https://${BACKEND_DOMAIN}/health"
echo -e ""
echo -e "   Para ver logs do Traefik:"
echo -e "   docker logs ${TRAEFIK_CONTAINER:-traefik} 2>&1 | tail -50"
echo -e ""
echo -e "   Para verificar rotas do Traefik (se tiver API habilitada):"
echo -e "   curl -s http://localhost:8080/api/http/routers | jq '.[] | select(.name | contains(\"imovelpro\"))'"

echo ""
echo -e "${GREEN}✅ Diagnóstico concluído!${NC}"


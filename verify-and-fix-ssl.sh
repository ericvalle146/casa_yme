#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔍 Verificando e corrigindo SSL${NC}"
echo ""

# Encontrar Traefik
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Traefik não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik: ${TRAEFIK_CONTAINER}${NC}"
echo ""

# Verificar serviços
echo -e "${BLUE}1) Verificando serviços...${NC}"
SERVICES=$(docker service ls --format "{{.Name}}" | grep imovelpro || echo "")
if [ -z "$SERVICES" ]; then
    echo -e "${RED}❌ Serviços não encontrados${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Serviços encontrados:${NC}"
echo "$SERVICES" | while read service; do
    echo -e "   - ${service}"
done

echo ""

# Verificar labels dos serviços
echo -e "${BLUE}2) Verificando labels dos serviços...${NC}"
FRONTEND_TASK=$(docker service ps imovelpro_frontend --filter "desired-state=running" --format "{{.Name}}.{{.ID}}" | head -1 || echo "")
BACKEND_TASK=$(docker service ps imovelpro_backend --filter "desired-state=running" --format "{{.Name}}.{{.ID}}" | head -1 || echo "")

if [ ! -z "$FRONTEND_TASK" ]; then
    echo -e "${BLUE}   Frontend: ${FRONTEND_TASK}${NC}"
    FRONTEND_CONTAINER=$(docker ps --filter "name=${FRONTEND_TASK}" --format "{{.ID}}" | head -1 || echo "")
    if [ ! -z "$FRONTEND_CONTAINER" ]; then
        FRONTEND_LABELS=$(docker inspect "$FRONTEND_CONTAINER" --format '{{json .Config.Labels}}' 2>/dev/null || echo "{}")
        echo "$FRONTEND_LABELS" | jq 'with_entries(select(.key | startswith("traefik")))' | head -20
    fi
fi

echo ""

if [ ! -z "$BACKEND_TASK" ]; then
    echo -e "${BLUE}   Backend: ${BACKEND_TASK}${NC}"
    BACKEND_CONTAINER=$(docker ps --filter "name=${BACKEND_TASK}" --format "{{.ID}}" | head -1 || echo "")
    if [ ! -z "$BACKEND_CONTAINER" ]; then
        BACKEND_LABELS=$(docker inspect "$BACKEND_CONTAINER" --format '{{json .Config.Labels}}' 2>/dev/null || echo "{}")
        echo "$BACKEND_LABELS" | jq 'with_entries(select(.key | startswith("traefik")))' | head -20
    fi
fi

echo ""

# Verificar logs do Traefik para certificados
echo -e "${BLUE}3) Verificando logs do Traefik (certificados)...${NC}"
docker logs "$TRAEFIK_CONTAINER" --tail 200 2>&1 | grep -i "certificate\|letsencrypt\|acme\|apiapi\|locusup\|error" | tail -30 || echo "   Nenhum log relevante"

echo ""

# Verificar se API do Traefik está acessível
echo -e "${BLUE}4) Verificando API do Traefik...${NC}"
API_RESPONSE=$(curl -s http://localhost:8080/api/http/routers 2>&1 || echo "ERROR")

if echo "$API_RESPONSE" | grep -q "ERROR\|Failed\|Connection refused"; then
    echo -e "${YELLOW}⚠️  API do Traefik não está acessível${NC}"
else
    echo -e "${GREEN}✅ API do Traefik acessível${NC}"
    
    # Verificar rotas
    ROUTES=$(echo "$API_RESPONSE" | jq -r '.[].name' 2>/dev/null || echo "")
    if echo "$ROUTES" | grep -q "imovelpro"; then
        echo -e "${GREEN}✅ Rotas do imovelpro encontradas:${NC}"
        echo "$ROUTES" | grep "imovelpro" | while read route; do
            echo -e "   - ${route}"
        done
    else
        echo -e "${YELLOW}⚠️  Rotas do imovelpro NÃO encontradas${NC}"
        echo -e "${BLUE}   Aguardando 30 segundos para o Traefik detectar...${NC}"
        sleep 30
        
        # Verificar novamente
        API_RESPONSE=$(curl -s http://localhost:8080/api/http/routers 2>&1 || echo "ERROR")
        ROUTES=$(echo "$API_RESPONSE" | jq -r '.[].name' 2>/dev/null || echo "")
        if echo "$ROUTES" | grep -q "imovelpro"; then
            echo -e "${GREEN}✅ Rotas detectadas após espera!${NC}"
        else
            echo -e "${YELLOW}⚠️  Rotas ainda não detectadas${NC}"
        fi
    fi
fi

echo ""

# Testar acesso HTTPS
echo -e "${BLUE}5) Testando acesso HTTPS...${NC}"

# Testar backend
BACKEND_TEST=$(curl -s -k -I https://apiapi.jyze.space/health 2>&1 | head -1 || echo "ERROR")
if echo "$BACKEND_TEST" | grep -q "HTTP"; then
    echo -e "${GREEN}✅ Backend HTTPS acessível (com -k)${NC}"
    echo -e "${BLUE}   ${BACKEND_TEST}${NC}"
else
    echo -e "${YELLOW}⚠️  Backend HTTPS não acessível${NC}"
fi

# Testar frontend
FRONTEND_TEST=$(curl -s -k -I https://imob.locusup.shop 2>&1 | head -1 || echo "ERROR")
if echo "$FRONTEND_TEST" | grep -q "HTTP"; then
    echo -e "${GREEN}✅ Frontend HTTPS acessível (com -k)${NC}"
    echo -e "${BLUE}   ${FRONTEND_TEST}${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend HTTPS não acessível${NC}"
fi

echo ""

# Verificar certificados
echo -e "${BLUE}6) Verificando certificados SSL...${NC}"
echo -e "${BLUE}   Testando apiapi.jyze.space:${NC}"
CERT_INFO=$(echo | openssl s_client -connect apiapi.jyze.space:443 -servername apiapi.jyze.space 2>&1 | grep -i "verify\|certificate" | head -5 || echo "")
if [ ! -z "$CERT_INFO" ]; then
    echo "$CERT_INFO"
else
    echo -e "${YELLOW}   Não foi possível verificar certificado${NC}"
fi

echo ""
echo -e "${GREEN}✅ Verificação concluída!${NC}"
echo ""
echo -e "${BLUE}💡 Se os certificados não estiverem funcionando:${NC}"
echo -e "${BLUE}   1. Aguarde alguns minutos - Let's Encrypt pode estar gerando${NC}"
echo -e "${BLUE}   2. Verifique se os domínios apontam para o IP correto${NC}"
echo -e "${BLUE}   3. Verifique logs do Traefik: ${YELLOW}docker logs -f $TRAEFIK_CONTAINER${NC}"
echo -e "${BLUE}   4. Se necessário, reinicie o Traefik: ${YELLOW}docker service update --force traefik_traefik${NC}"


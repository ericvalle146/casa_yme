#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔒 Verificando e corrigindo SSL completo${NC}"
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

# Verificar se serviços estão na network vpsnet
echo -e "${BLUE}2) Verificando network vpsnet...${NC}"
CONTAINERS_IN_VPSNET=$(docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")
if echo "$CONTAINERS_IN_VPSNET" | grep -q "imovelpro"; then
    echo -e "${GREEN}✅ Serviços estão na network vpsnet${NC}"
else
    echo -e "${RED}❌ Serviços NÃO estão na network vpsnet${NC}"
    exit 1
fi

echo ""

# Verificar se Traefik detecta os serviços
echo -e "${BLUE}3) Verificando se Traefik detecta os serviços...${NC}"
MAX_WAIT=180
WAITED=0
INTERVAL=10
DETECTED=false

while [ $WAITED -lt $MAX_WAIT ]; do
    API_RESPONSE=$(curl -s http://localhost:8080/api/http/routers 2>/dev/null || echo "[]")
    
    if [ "$API_RESPONSE" != "[]" ]; then
        ROUTES=$(echo "$API_RESPONSE" | jq -r '.[].name' 2>/dev/null | grep "imovelpro" || echo "")
        
        if [ ! -z "$ROUTES" ]; then
            echo -e "${GREEN}✅ Rotas detectadas!${NC}"
            echo "$ROUTES" | while read route; do
                echo -e "   - ${route}"
            done
            DETECTED=true
            break
        fi
    fi
    
    echo -e "${BLUE}   Aguardando Traefik detectar... (${WAITED}s/${MAX_WAIT}s)${NC}"
    sleep $INTERVAL
    WAITED=$((WAITED + INTERVAL))
done

if [ "$DETECTED" = false ]; then
    echo -e "${YELLOW}⚠️  Rotas não foram detectadas após ${MAX_WAIT} segundos${NC}"
    echo -e "${BLUE}   Verificando logs do Traefik...${NC}"
    docker logs "$TRAEFIK_CONTAINER" --tail 50 | grep -i "error\|docker\|provider" | tail -10 || echo "   Nenhum erro encontrado"
fi

echo ""

# Verificar certificados
echo -e "${BLUE}4) Verificando certificados SSL...${NC}"
MAX_WAIT_CERT=300
WAITED_CERT=0
INTERVAL_CERT=15
CERT_VALID=false

while [ $WAITED_CERT -lt $MAX_WAIT_CERT ]; do
    # Testar backend
    BACKEND_TEST=$(curl -s -I https://apiapi.jyze.space/health 2>&1 | head -1 || echo "ERROR")
    
    if echo "$BACKEND_TEST" | grep -q "HTTP/"; then
        # Verificar se o certificado é válido (sem -k)
        CERT_CHECK=$(echo | timeout 5 openssl s_client -connect apiapi.jyze.space:443 -servername apiapi.jyze.space 2>&1 | grep -i "verify return code" || echo "")
        
        if echo "$CERT_CHECK" | grep -q "verify return code: 0"; then
            echo -e "${GREEN}✅ Certificado SSL válido!${NC}"
            CERT_VALID=true
            break
        else
            echo -e "${BLUE}   Certificado ainda sendo gerado... (${WAITED_CERT}s/${MAX_WAIT_CERT}s)${NC}"
            if [ ! -z "$CERT_CHECK" ]; then
                echo -e "${BLUE}   Status: ${CERT_CHECK}${NC}"
            fi
        fi
    else
        echo -e "${BLUE}   Aguardando HTTPS responder... (${WAITED_CERT}s/${MAX_WAIT_CERT}s)${NC}"
    fi
    
    sleep $INTERVAL_CERT
    WAITED_CERT=$((WAITED_CERT + INTERVAL_CERT))
done

if [ "$CERT_VALID" = false ]; then
    echo -e "${YELLOW}⚠️  Certificado ainda não está válido após ${MAX_WAIT_CERT} segundos${NC}"
    echo -e "${BLUE}   Verificando logs do Traefik (certificados)...${NC}"
    docker logs "$TRAEFIK_CONTAINER" --tail 100 | grep -i "certificate\|letsencrypt\|acme\|error" | tail -20 || echo "   Nenhum log relevante"
    
    echo ""
    echo -e "${BLUE}💡 Possíveis causas:${NC}"
    echo -e "${BLUE}   1. Domínios não apontam para o IP correto${NC}"
    echo -e "${BLUE}   2. Let's Encrypt está com rate limit${NC}"
    echo -e "${BLUE}   3. Firewall bloqueando porta 80/443${NC}"
    echo -e "${BLUE}   4. Traefik não está configurado corretamente para Let's Encrypt${NC}"
fi

echo ""
echo -e "${GREEN}✅ Verificação concluída!${NC}"
echo ""
echo -e "${BLUE}📋 Resumo:${NC}"
echo -e "${BLUE}   - Serviços: ${GREEN}✅${NC}"
echo -e "${BLUE}   - Network: ${GREEN}✅${NC}"
if [ "$DETECTED" = true ]; then
    echo -e "${BLUE}   - Traefik detectando: ${GREEN}✅${NC}"
else
    echo -e "${BLUE}   - Traefik detectando: ${YELLOW}⚠️${NC}"
fi
if [ "$CERT_VALID" = true ]; then
    echo -e "${BLUE}   - Certificado SSL: ${GREEN}✅${NC}"
else
    echo -e "${BLUE}   - Certificado SSL: ${YELLOW}⚠️${NC}"
fi

echo ""
echo -e "${BLUE}💡 Se o certificado não estiver válido:${NC}"
echo -e "${BLUE}   1. Verifique se os domínios apontam para o IP da VPS${NC}"
echo -e "${BLUE}   2. Aguarde alguns minutos (Let's Encrypt pode levar tempo)${NC}"
echo -e "${BLUE}   3. Verifique logs: ${YELLOW}docker logs -f $TRAEFIK_CONTAINER${NC}"
echo -e "${BLUE}   4. Teste acesso: ${YELLOW}curl -I https://apiapi.jyze.space/health${NC}"


#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔒 Verificando e corrigindo certificados SSL${NC}"
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

# Verificar network
echo -e "${BLUE}2) Verificando network vpsnet...${NC}"
CONTAINERS_IN_VPSNET=$(docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")
if echo "$CONTAINERS_IN_VPSNET" | grep -q "imovelpro"; then
    echo -e "${GREEN}✅ Serviços estão na network vpsnet${NC}"
else
    echo -e "${RED}❌ Serviços NÃO estão na network vpsnet${NC}"
    exit 1
fi

echo ""

# Verificar Traefik
echo -e "${BLUE}3) Verificando Traefik...${NC}"
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Traefik não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik: ${TRAEFIK_CONTAINER}${NC}"

# Verificar logs do Traefik para certificados
echo -e "${BLUE}4) Verificando logs do Traefik (certificados)...${NC}"
docker logs "$TRAEFIK_CONTAINER" --tail 100 2>&1 | grep -i "certificate\|letsencrypt\|acme\|imovelpro\|apiapi\|locusup" | tail -20 || echo "   Nenhum log relevante"

echo ""

# Testar acesso HTTP (sem SSL)
echo -e "${BLUE}5) Testando acesso HTTP (sem SSL)...${NC}"
if curl -s -I http://imob.locusup.shop 2>&1 | head -1; then
    echo -e "${GREEN}✅ HTTP funcionando${NC}"
else
    echo -e "${YELLOW}⚠️  HTTP não funcionando${NC}"
fi

if curl -s -I http://apiapi.jyze.space/health 2>&1 | head -1; then
    echo -e "${GREEN}✅ Backend HTTP funcionando${NC}"
else
    echo -e "${YELLOW}⚠️  Backend HTTP não funcionando${NC}"
fi

echo ""

# Testar acesso HTTPS (com SSL)
echo -e "${BLUE}6) Testando acesso HTTPS (com SSL)...${NC}"
if curl -s -k -I https://imob.locusup.shop 2>&1 | head -1; then
    echo -e "${GREEN}✅ HTTPS funcionando (com -k, ignorando certificado)${NC}"
else
    echo -e "${YELLOW}⚠️  HTTPS não funcionando${NC}"
fi

if curl -s -k -I https://apiapi.jyze.space/health 2>&1 | head -1; then
    echo -e "${GREEN}✅ Backend HTTPS funcionando (com -k)${NC}"
else
    echo -e "${YELLOW}⚠️  Backend HTTPS não funcionando${NC}"
fi

echo ""

# Verificar certificados
echo -e "${BLUE}7) Verificando certificados...${NC}"
echo -e "${BLUE}   Testando certificado de imob.locusup.shop:${NC}"
echo | openssl s_client -connect imob.locusup.shop:443 -servername imob.locusup.shop 2>&1 | grep -i "certificate\|verify" | head -5 || echo "   Erro ao verificar certificado"

echo ""
echo -e "${BLUE}   Testando certificado de apiapi.jyze.space:${NC}"
echo | openssl s_client -connect apiapi.jyze.space:443 -servername apiapi.jyze.space 2>&1 | grep -i "certificate\|verify" | head -5 || echo "   Erro ao verificar certificado"

echo ""

# Verificar se domínios apontam para o servidor
echo -e "${BLUE}8) Verificando DNS...${NC}"
SERVER_IP=$(hostname -I | awk '{print $1}')
FRONTEND_DNS=$(dig +short imob.locusup.shop @8.8.8.8 | tail -1 || echo "")
BACKEND_DNS=$(dig +short apiapi.jyze.space @8.8.8.8 | tail -1 || echo "")

echo -e "${BLUE}   IP do servidor: ${SERVER_IP}${NC}"
echo -e "${BLUE}   DNS de imob.locusup.shop: ${FRONTEND_DNS}${NC}"
echo -e "${BLUE}   DNS de apiapi.jyze.space: ${BACKEND_DNS}${NC}"

echo ""
echo -e "${GREEN}✅ Diagnóstico concluído!${NC}"
echo ""
echo -e "${BLUE}💡 Se os certificados não estiverem funcionando:${NC}"
echo -e "${BLUE}   1. Aguarde alguns minutos - Let's Encrypt pode estar gerando${NC}"
echo -e "${BLUE}   2. Verifique logs do Traefik: ${YELLOW}docker logs -f $TRAEFIK_CONTAINER${NC}"
echo -e "${BLUE}   3. Verifique se os domínios apontam para o IP correto${NC}"
echo -e "${BLUE}   4. Teste acesso direto: ${YELLOW}curl -k https://apiapi.jyze.space/health${NC}"


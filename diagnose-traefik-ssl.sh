#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔍 Diagnosticando problema de SSL do Traefik${NC}"
echo ""

# Encontrar Traefik
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Traefik não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik: ${TRAEFIK_CONTAINER}${NC}"
echo ""

# Verificar certificado atual
echo -e "${BLUE}1) Verificando certificado SSL atual...${NC}"
CERT_INFO=$(echo | timeout 5 openssl s_client -connect apiapi.jyze.space:443 -servername apiapi.jyze.space 2>&1 | grep -A 2 "Certificate chain\|CN =")
echo "$CERT_INFO"

if echo "$CERT_INFO" | grep -q "TRAEFIK DEFAULT CERT"; then
    echo -e "${RED}❌ PROBLEMA: Traefik está usando certificado auto-assinado!${NC}"
    echo -e "${YELLOW}   O Let's Encrypt não está gerando certificados${NC}"
else
    echo -e "${GREEN}✅ Certificado parece válido${NC}"
fi

echo ""

# Verificar se o backend responde
echo -e "${BLUE}2) Testando backend...${NC}"
BACKEND_RESPONSE=$(curl -s -k https://apiapi.jyze.space/health 2>&1)
if echo "$BACKEND_RESPONSE" | grep -q "ok"; then
    echo -e "${GREEN}✅ Backend está funcionando${NC}"
    echo -e "${BLUE}   Resposta: ${BACKEND_RESPONSE}${NC}"
else
    echo -e "${RED}❌ Backend não está respondendo${NC}"
fi

echo ""

# Verificar logs do Traefik
echo -e "${BLUE}3) Verificando logs do Traefik (últimas 100 linhas)...${NC}"
docker logs "$TRAEFIK_CONTAINER" --tail 100 2>&1 | grep -i "letsencrypt\|acme\|certificate\|error\|warning" | tail -20 || echo "   Nenhum log relevante encontrado"

echo ""

# Verificar DNS
echo -e "${BLUE}4) Verificando DNS...${NC}"
SERVER_IP=$(hostname -I | awk '{print $1}')
BACKEND_DNS=$(dig +short apiapi.jyze.space @8.8.8.8 | tail -1 || echo "")
FRONTEND_DNS=$(dig +short imob.locusup.shop @8.8.8.8 | tail -1 || echo "")

echo -e "${BLUE}   IP do servidor: ${SERVER_IP}${NC}"
echo -e "${BLUE}   DNS de apiapi.jyze.space: ${BACKEND_DNS}${NC}"
echo -e "${BLUE}   DNS de imob.locusup.shop: ${FRONTEND_DNS}${NC}"

if [ "$BACKEND_DNS" = "$SERVER_IP" ] && [ "$FRONTEND_DNS" = "$SERVER_IP" ]; then
    echo -e "${GREEN}✅ DNS está correto${NC}"
else
    echo -e "${YELLOW}⚠️  DNS pode estar incorreto${NC}"
    echo -e "${BLUE}   Verifique se os domínios apontam para ${SERVER_IP}${NC}"
fi

echo ""

# Verificar se portas 80 e 443 estão abertas
echo -e "${BLUE}5) Verificando portas...${NC}"
if netstat -tuln 2>/dev/null | grep -q ":80 "; then
    echo -e "${GREEN}✅ Porta 80 está aberta${NC}"
else
    echo -e "${YELLOW}⚠️  Porta 80 pode não estar aberta${NC}"
fi

if netstat -tuln 2>/dev/null | grep -q ":443 "; then
    echo -e "${GREEN}✅ Porta 443 está aberta${NC}"
else
    echo -e "${YELLOW}⚠️  Porta 443 pode não estar aberta${NC}"
fi

echo ""

# Resumo e soluções
echo -e "${GREEN}📋 Resumo do diagnóstico:${NC}"
echo ""

if echo "$CERT_INFO" | grep -q "TRAEFIK DEFAULT CERT"; then
    echo -e "${RED}❌ PROBLEMA PRINCIPAL: Certificado auto-assinado${NC}"
    echo ""
    echo -e "${BLUE}💡 Possíveis causas:${NC}"
    echo -e "${BLUE}   1. Traefik não está configurado para Let's Encrypt${NC}"
    echo -e "${BLUE}   2. Let's Encrypt não consegue validar os domínios${NC}"
    echo -e "${BLUE}   3. Porta 80 não está acessível para validação HTTP-01${NC}"
    echo -e "${BLUE}   4. DNS não está propagado corretamente${NC}"
    echo ""
    echo -e "${BLUE}💡 Soluções:${NC}"
    echo -e "${BLUE}   1. Aguarde alguns minutos - Let's Encrypt pode estar gerando${NC}"
    echo -e "${BLUE}   2. Verifique se o Traefik está configurado com Let's Encrypt${NC}"
    echo -e "${BLUE}   3. Verifique se a porta 80 está acessível publicamente${NC}"
    echo -e "${BLUE}   4. Verifique se os domínios apontam para o IP correto${NC}"
    echo -e "${BLUE}   5. Verifique logs do Traefik para erros do Let's Encrypt${NC}"
    echo ""
    echo -e "${BLUE}   Para forçar geração de certificado, você pode:${NC}"
    echo -e "${BLUE}   - Reiniciar o Traefik: ${YELLOW}docker restart $TRAEFIK_CONTAINER${NC}"
    echo -e "${BLUE}   - Ou atualizar a stack: ${YELLOW}docker stack deploy -c <stack-file> <stack-name>${NC}"
else
    echo -e "${GREEN}✅ Certificado parece estar OK${NC}"
fi

echo ""
echo -e "${BLUE}📝 Próximos passos:${NC}"
echo -e "${BLUE}   1. Execute: ${YELLOW}docker logs -f $TRAEFIK_CONTAINER${NC}"
echo -e "${BLUE}   2. Procure por mensagens sobre Let's Encrypt/ACME${NC}"
echo -e "${BLUE}   3. Verifique se há erros de validação${NC}"
echo -e "${BLUE}   4. Aguarde alguns minutos e teste novamente${NC}"


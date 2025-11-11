#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔍 Verificando se o Traefik está configurado para Let's Encrypt${NC}"
echo ""

# Encontrar Traefik
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Traefik não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik: ${TRAEFIK_CONTAINER}${NC}"
echo ""

# Verificar logs para mensagens de inicialização do ACME
echo -e "${BLUE}1) Verificando se o Traefik tem ACME configurado...${NC}"
INIT_LOGS=$(docker logs "$TRAEFIK_CONTAINER" 2>&1 | grep -i "acme\|letsencrypt\|certificate.*resolver" | head -10 || echo "")
if [ ! -z "$INIT_LOGS" ]; then
    echo -e "${GREEN}✅ Mensagens sobre ACME encontradas:${NC}"
    echo "$INIT_LOGS"
else
    echo -e "${RED}❌ Nenhuma mensagem sobre ACME encontrada${NC}"
    echo -e "${YELLOW}   Isso indica que o Traefik pode não estar configurado para Let's Encrypt${NC}"
fi

echo ""

# Verificar se há certificados sendo gerados
echo -e "${BLUE}2) Verificando se há tentativas de gerar certificados...${NC}"
CERT_LOGS=$(docker logs "$TRAEFIK_CONTAINER" --tail 1000 2>&1 | grep -i "obtain\|request\|challenge\|validation\|certificate.*obtain" | tail -20 || echo "")
if [ ! -z "$CERT_LOGS" ]; then
    echo -e "${GREEN}✅ Tentativas de gerar certificados encontradas:${NC}"
    echo "$CERT_LOGS"
else
    echo -e "${YELLOW}⚠️  Nenhuma tentativa de gerar certificados encontrada${NC}"
fi

echo ""

# Verificar entrypoints
echo -e "${BLUE}3) Verificando entrypoints configurados...${NC}"
ENTRYPOINTS=$(docker logs "$TRAEFIK_CONTAINER" 2>&1 | grep -i "entrypoint\|entryPoint" | head -10 || echo "")
if [ ! -z "$ENTRYPOINTS" ]; then
    echo "$ENTRYPOINTS"
else
    echo -e "${YELLOW}⚠️  Não foi possível verificar entrypoints${NC}"
fi

echo ""

# Verificar certificado atual
echo -e "${BLUE}4) Verificando certificado atual...${NC}"
CERT_INFO=$(echo | timeout 5 openssl s_client -connect apiapi.jyze.space:443 -servername apiapi.jyze.space 2>&1 | grep -A 2 "Certificate chain\|CN =" | head -5 || echo "")
echo "$CERT_INFO"

if echo "$CERT_INFO" | grep -q "TRAEFIK DEFAULT CERT"; then
    echo -e "${RED}❌ Certificado é auto-assinado (TRAEFIK DEFAULT CERT)${NC}"
elif echo "$CERT_INFO" | grep -q "Let's Encrypt\|Let\\\\'s Encrypt"; then
    echo -e "${GREEN}✅ Certificado é do Let's Encrypt!${NC}"
else
    echo -e "${YELLOW}⚠️  Certificado não identificado${NC}"
fi

echo ""

# Resumo e recomendações
echo -e "${GREEN}📋 Resumo:${NC}"
echo ""

if [ -z "$INIT_LOGS" ] && [ -z "$CERT_LOGS" ]; then
    echo -e "${RED}❌ PROBLEMA IDENTIFICADO:${NC}"
    echo -e "${RED}   O Traefik NÃO está configurado para Let's Encrypt${NC}"
    echo ""
    echo -e "${BLUE}💡 Solução:${NC}"
    echo -e "${BLUE}   O Traefik precisa ter o ACME (Let's Encrypt) configurado.${NC}"
    echo -e "${BLUE}   Isso geralmente é feito no stack do Traefik (não no seu stack).${NC}"
    echo ""
    echo -e "${BLUE}   Se você tem acesso ao stack do Traefik:${NC}"
    echo -e "${BLUE}   1. Verifique se há configuração de ACME${NC}"
    echo -e "${BLUE}   2. Adicione configuração de ACME se não houver${NC}"
    echo ""
    echo -e "${BLUE}   Se você NÃO tem acesso ao stack do Traefik:${NC}"
    echo -e "${BLUE}   1. Contacte quem configurou o Traefik${NC}"
    echo -e "${BLUE}   2. Peça para configurar Let's Encrypt no Traefik${NC}"
    echo -e "${BLUE}   3. Ou use outra solução de SSL (ex: Cloudflare)${NC}"
elif [ ! -z "$CERT_LOGS" ]; then
    echo -e "${GREEN}✅ Traefik está tentando gerar certificados${NC}"
    echo -e "${BLUE}   Verifique se há erros nas tentativas${NC}"
    echo -e "${BLUE}   Aguarde alguns minutos para o Let's Encrypt validar${NC}"
else
    echo -e "${YELLOW}⚠️  Não foi possível determinar se o Traefik está configurado${NC}"
    echo -e "${BLUE}   Verifique os logs manualmente${NC}"
fi

echo ""
echo -e "${BLUE}💡 Próximos passos:${NC}"
echo -e "${BLUE}   1. Se o Traefik não está configurado, configure-o para Let's Encrypt${NC}"
echo -e "${BLUE}   2. Se há erros, corrija-os${NC}"
echo -e "${BLUE}   3. Aguarde alguns minutos e verifique novamente:${NC}"
echo -e "${BLUE}      ${YELLOW}echo | openssl s_client -connect apiapi.jyze.space:443 -servername apiapi.jyze.space 2>&1 | grep -A 2 'Certificate chain\|CN ='${NC}"


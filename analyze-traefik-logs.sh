#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔍 Analisando logs do Traefik${NC}"
echo ""

# Encontrar Traefik
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Traefik não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik: ${TRAEFIK_CONTAINER}${NC}"
echo ""

# Verificar logs do Traefik sobre Let's Encrypt/ACME
echo -e "${BLUE}1) Verificando mensagens sobre Let's Encrypt/ACME...${NC}"
ACME_LOGS=$(docker logs "$TRAEFIK_CONTAINER" --tail 1000 2>&1 | grep -i "letsencrypt\|acme\|certificate" || echo "")
if [ ! -z "$ACME_LOGS" ]; then
    echo "$ACME_LOGS" | tail -30
else
    echo -e "${YELLOW}⚠️  Nenhuma mensagem sobre Let's Encrypt/ACME encontrada${NC}"
    echo -e "${RED}   Isso indica que o Traefik pode não estar configurado para Let's Encrypt!${NC}"
fi

echo ""

# Verificar erros
echo -e "${BLUE}2) Verificando erros...${NC}"
ERRORS=$(docker logs "$TRAEFIK_CONTAINER" --tail 1000 2>&1 | grep -i "error\|failed\|cannot\|unable" | tail -20 || echo "")
if [ ! -z "$ERRORS" ]; then
    echo -e "${RED}❌ Erros encontrados:${NC}"
    echo "$ERRORS"
else
    echo -e "${GREEN}✅ Nenhum erro encontrado${NC}"
fi

echo ""

# Verificar configuração do Traefik (entrypoints, providers, etc)
echo -e "${BLUE}3) Verificando configuração do Traefik...${NC}"
CONFIG_LOGS=$(docker logs "$TRAEFIK_CONTAINER" --tail 1000 2>&1 | grep -i "entrypoint\|provider\|docker\|swarm" | head -20 || echo "")
if [ ! -z "$CONFIG_LOGS" ]; then
    echo "$CONFIG_LOGS"
else
    echo -e "${YELLOW}⚠️  Poucas informações sobre configuração encontradas${NC}"
fi

echo ""

# Verificar se há certificados sendo gerados
echo -e "${BLUE}4) Verificando se há tentativas de gerar certificados...${NC}"
CERT_ATTEMPTS=$(docker logs "$TRAEFIK_CONTAINER" --tail 1000 2>&1 | grep -i "obtain\|request\|challenge\|validation" | tail -20 || echo "")
if [ ! -z "$CERT_ATTEMPTS" ]; then
    echo -e "${GREEN}✅ Tentativas de gerar certificados encontradas:${NC}"
    echo "$CERT_ATTEMPTS"
else
    echo -e "${YELLOW}⚠️  Nenhuma tentativa de gerar certificados encontrada${NC}"
    echo -e "${RED}   Isso indica que o Traefik não está tentando gerar certificados!${NC}"
fi

echo ""

# Verificar serviços detectados
echo -e "${BLUE}5) Verificando serviços detectados...${NC}"
SERVICES=$(docker logs "$TRAEFIK_CONTAINER" --tail 1000 2>&1 | grep -i "imovelpro\|apiapi\|locusup" | tail -10 || echo "")
if [ ! -z "$SERVICES" ]; then
    echo -e "${GREEN}✅ Serviços detectados:${NC}"
    echo "$SERVICES"
else
    echo -e "${YELLOW}⚠️  Nenhum serviço do imovelpro encontrado nos logs${NC}"
fi

echo ""

# Resumo
echo -e "${GREEN}📋 Resumo da análise:${NC}"
echo ""

if [ -z "$ACME_LOGS" ]; then
    echo -e "${RED}❌ PROBLEMA: Traefik não está configurado para Let's Encrypt${NC}"
    echo -e "${BLUE}   Não há mensagens sobre Let's Encrypt/ACME nos logs${NC}"
    echo -e "${BLUE}   O Traefik precisa ter o ACME configurado para gerar certificados${NC}"
    echo ""
    echo -e "${BLUE}💡 Solução:${NC}"
    echo -e "${BLUE}   1. Verifique se o Traefik está configurado com Let's Encrypt${NC}"
    echo -e "${BLUE}   2. Se você tem acesso ao stack do Traefik, verifique a configuração${NC}"
    echo -e "${BLUE}   3. Se não tem acesso, contacte quem configurou o Traefik${NC}"
elif [ -z "$CERT_ATTEMPTS" ]; then
    echo -e "${YELLOW}⚠️  Traefik pode estar configurado, mas não está tentando gerar certificados${NC}"
    echo -e "${BLUE}   Verifique se há erros ou problemas de configuração${NC}"
else
    echo -e "${GREEN}✅ Traefik parece estar configurado para Let's Encrypt${NC}"
    echo -e "${BLUE}   Verifique se há erros nas tentativas de gerar certificados${NC}"
fi

echo ""
echo -e "${BLUE}💡 Próximos passos:${NC}"
echo -e "${BLUE}   1. Se o Traefik não está configurado para Let's Encrypt, configure-o${NC}"
echo -e "${BLUE}   2. Se há erros, corrija-os${NC}"
echo -e "${BLUE}   3. Aguarde alguns minutos para o Let's Encrypt tentar validar${NC}"
echo -e "${BLUE}   4. Verifique novamente os certificados:${NC}"
echo -e "${BLUE}      ${YELLOW}echo | openssl s_client -connect apiapi.jyze.space:443 -servername apiapi.jyze.space 2>&1 | grep -A 2 'Certificate chain\|CN ='${NC}"






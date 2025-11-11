#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔍 Testando caminho do Let's Encrypt (ACME Challenge)${NC}"
echo ""

# Testar caminho do ACME Challenge
echo -e "${BLUE}1) Testando caminho .well-known/acme-challenge/...${NC}"

# Testar backend
BACKEND_ACME=$(curl -s -I http://apiapi.jyze.space/.well-known/acme-challenge/test 2>&1 | head -3 || echo "ERROR")
echo -e "${BLUE}   Backend (apiapi.jyze.space):${NC}"
echo "$BACKEND_ACME"

if echo "$BACKEND_ACME" | grep -q "308\|301\|302"; then
    echo -e "${RED}❌ PROBLEMA: HTTP está redirecionando para HTTPS!${NC}"
    echo -e "${YELLOW}   Isso impede o Let's Encrypt de validar!${NC}"
elif echo "$BACKEND_ACME" | grep -q "404\|403\|200"; then
    echo -e "${GREEN}✅ Caminho acessível (não está redirecionando)${NC}"
else
    echo -e "${YELLOW}⚠️  Resposta inesperada${NC}"
fi

echo ""

# Testar frontend
FRONTEND_ACME=$(curl -s -I http://imob.locusup.shop/.well-known/acme-challenge/test 2>&1 | head -3 || echo "ERROR")
echo -e "${BLUE}   Frontend (imob.locusup.shop):${NC}"
echo "$FRONTEND_ACME"

if echo "$FRONTEND_ACME" | grep -q "308\|301\|302"; then
    echo -e "${RED}❌ PROBLEMA: HTTP está redirecionando para HTTPS!${NC}"
    echo -e "${YELLOW}   Isso impede o Let's Encrypt de validar!${NC}"
elif echo "$FRONTEND_ACME" | grep -q "404\|403\|200"; then
    echo -e "${GREEN}✅ Caminho acessível (não está redirecionando)${NC}"
else
    echo -e "${YELLOW}⚠️  Resposta inesperada${NC}"
fi

echo ""

# Verificar se há redirecionamento no /health
echo -e "${BLUE}2) Verificando redirecionamento no /health...${NC}"
HEALTH_REDIRECT=$(curl -s -I http://apiapi.jyze.space/health 2>&1 | head -3 || echo "ERROR")
echo "$HEALTH_REDIRECT"

if echo "$HEALTH_REDIRECT" | grep -q "308\|301\|302"; then
    echo -e "${YELLOW}⚠️  /health está redirecionando para HTTPS${NC}"
    echo -e "${BLUE}   Isso é normal para rotas de aplicação${NC}"
    echo -e "${BLUE}   MAS o .well-known/acme-challenge/ NÃO deve redirecionar!${NC}"
fi

echo ""

# Resumo
echo -e "${GREEN}📋 Resumo:${NC}"
echo ""
if echo "$BACKEND_ACME" | grep -q "308\|301\|302"; then
    echo -e "${RED}❌ PROBLEMA ENCONTRADO:${NC}"
    echo -e "${RED}   O Traefik está redirecionando TUDO para HTTPS${NC}"
    echo -e "${RED}   Isso impede o Let's Encrypt de validar os domínios${NC}"
    echo ""
    echo -e "${BLUE}💡 Solução:${NC}"
    echo -e "${BLUE}   O Traefik precisa permitir que o Let's Encrypt acesse${NC}"
    echo -e "${BLUE}   .well-known/acme-challenge/ via HTTP SEM redirecionar${NC}"
    echo ""
    echo -e "${BLUE}   Isso geralmente é feito automaticamente pelo Traefik quando:${NC}"
    echo -e "${BLUE}   1. O ACME (Let's Encrypt) está configurado${NC}"
    echo -e "${BLUE}   2. O certresolver está configurado corretamente${NC}"
    echo ""
    echo -e "${BLUE}   Se o Traefik não está fazendo isso automaticamente, pode ser que:${NC}"
    echo -e "${BLUE}   1. O Traefik não está configurado para Let's Encrypt${NC}"
    echo -e "${BLUE}   2. O certresolver não está configurado corretamente${NC}"
    echo -e "${BLUE}   3. Há uma configuração de redirecionamento muito agressiva${NC}"
else
    echo -e "${GREEN}✅ O caminho .well-known/acme-challenge/ está acessível${NC}"
    echo -e "${BLUE}   O Let's Encrypt deve conseguir validar${NC}"
fi

echo ""
echo -e "${BLUE}💡 Próximos passos:${NC}"
echo -e "${BLUE}   1. Verifique se o Traefik está configurado para Let's Encrypt${NC}"
echo -e "${BLUE}   2. Verifique se o certresolver está configurado${NC}"
echo -e "${BLUE}   3. Aguarde alguns minutos para o Let's Encrypt tentar validar${NC}"
echo -e "${BLUE}   4. Verifique os logs do Traefik para mensagens do ACME${NC}"


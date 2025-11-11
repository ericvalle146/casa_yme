#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔍 Verificando configuração do Traefik${NC}"
echo ""

# Encontrar Traefik
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Traefik não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik: ${TRAEFIK_CONTAINER}${NC}"
echo ""

# Verificar logs do Traefik
echo -e "${BLUE}1) Verificando logs do Traefik (Let's Encrypt/ACME)...${NC}"
docker logs "$TRAEFIK_CONTAINER" --tail 500 2>&1 | grep -i "letsencrypt\|acme\|certificate\|tls\|certresolver" | tail -50

echo ""

# Verificar se há erros
echo -e "${BLUE}2) Verificando erros nos logs...${NC}"
ERRORS=$(docker logs "$TRAEFIK_CONTAINER" --tail 500 2>&1 | grep -i "error\|failed\|cannot\|unable" | tail -20 || echo "")
if [ ! -z "$ERRORS" ]; then
    echo -e "${RED}❌ Erros encontrados:${NC}"
    echo "$ERRORS"
else
    echo -e "${GREEN}✅ Nenhum erro encontrado${NC}"
fi

echo ""

# Verificar portas
echo -e "${BLUE}3) Verificando portas do Traefik...${NC}"
TRAEFIK_PORTS=$(docker port "$TRAEFIK_CONTAINER" 2>/dev/null || echo "")
if [ ! -z "$TRAEFIK_PORTS" ]; then
    echo -e "${GREEN}✅ Portas do Traefik:${NC}"
    echo "$TRAEFIK_PORTS"
else
    echo -e "${YELLOW}⚠️  Não foi possível verificar portas${NC}"
fi

echo ""

# Verificar se portas estão escutando
echo -e "${BLUE}4) Verificando se portas estão escutando...${NC}"
if ss -tuln 2>/dev/null | grep -q ":80 "; then
    echo -e "${GREEN}✅ Porta 80 está escutando${NC}"
    ss -tuln | grep ":80 "
else
    echo -e "${YELLOW}⚠️  Porta 80 não está escutando${NC}"
fi

if ss -tuln 2>/dev/null | grep -q ":443 "; then
    echo -e "${GREEN}✅ Porta 443 está escutando${NC}"
    ss -tuln | grep ":443 "
else
    echo -e "${YELLOW}⚠️  Porta 443 não está escutando${NC}"
fi

echo ""

# Verificar firewall
echo -e "${BLUE}5) Verificando firewall...${NC}"
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status 2>/dev/null || echo "inactive")
    if echo "$UFW_STATUS" | grep -q "Status: active"; then
        echo -e "${YELLOW}⚠️  UFW está ativo${NC}"
        echo "$UFW_STATUS" | grep -E "80|443" || echo "   Portas 80/443 não encontradas nas regras"
    else
        echo -e "${GREEN}✅ UFW está inativo${NC}"
    fi
else
    echo -e "${BLUE}   UFW não instalado${NC}"
fi

echo ""

# Testar acesso HTTP (validação Let's Encrypt)
echo -e "${BLUE}6) Testando acesso HTTP (validação Let's Encrypt)...${NC}"
HTTP_TEST=$(curl -s -I http://apiapi.jyze.space/health 2>&1 | head -1 || echo "ERROR")
if echo "$HTTP_TEST" | grep -q "HTTP"; then
    echo -e "${GREEN}✅ HTTP está acessível${NC}"
    echo -e "${BLUE}   ${HTTP_TEST}${NC}"
else
    echo -e "${RED}❌ HTTP não está acessível${NC}"
    echo -e "${BLUE}   ${HTTP_TEST}${NC}"
    echo -e "${YELLOW}   ⚠️  Isso pode impedir o Let's Encrypt de validar!${NC}"
fi

echo ""

# Verificar se há rotas HTTP configuradas
echo -e "${BLUE}7) Verificando se há rotas HTTP configuradas...${NC}"
# Verificar se os serviços têm rotas HTTP
echo -e "${BLUE}   Os serviços devem ter rotas HTTP (entrypoint=web) para validação${NC}"
echo -e "${BLUE}   Verifique se o docker-stack.yml tem rotas HTTP configuradas${NC}"

echo ""
echo -e "${GREEN}✅ Verificação concluída!${NC}"
echo ""
echo -e "${BLUE}💡 Se o HTTP não estiver acessível:${NC}"
echo -e "${BLUE}   1. O Let's Encrypt precisa da porta 80 para validação HTTP-01${NC}"
echo -e "${BLUE}   2. Verifique se o firewall permite a porta 80${NC}"
echo -e "${BLUE}   3. Verifique se o Traefik está escutando na porta 80${NC}"
echo -e "${BLUE}   4. Verifique se há rotas HTTP configuradas nos serviços${NC}"


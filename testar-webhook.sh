#!/usr/bin/env bash

set -euo pipefail

# Cores
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

WEBHOOK_URL="https://webhook.locusup.shop/webhook/mariana_imobiliaria"

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           Teste de Conectividade do Webhook              ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Webhook URL: ${YELLOW}$WEBHOOK_URL${NC}"
echo ""

# Teste 1: DNS Resolution
echo -e "${BLUE}[1] Testando resolução DNS...${NC}"
if nslookup webhook.locusp.shop >/dev/null 2>&1; then
    echo -e "${GREEN}✅ DNS resolve corretamente${NC}"
    DNS_RESULT=$(nslookup webhook.locusp.shop 2>&1 | grep -A 2 "Name:" | tail -1 | awk '{print $2}' || echo "")
    if [ -n "$DNS_RESULT" ]; then
        echo -e "${BLUE}   IP: ${YELLOW}$DNS_RESULT${NC}"
    fi
else
    echo -e "${RED}❌ DNS NÃO resolve${NC}"
    echo -e "${YELLOW}   O domínio webhook.locusp.shop não está configurado no DNS${NC}"
    echo -e "${YELLOW}   Verifique se o domínio está apontando para o servidor correto${NC}"
fi
echo ""

# Teste 2: Conexão HTTP
echo -e "${BLUE}[2] Testando conexão HTTP...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$WEBHOOK_URL" 2>&1 || echo "000")

if [ "$HTTP_CODE" = "000" ]; then
    echo -e "${RED}❌ Não foi possível conectar${NC}"
    echo -e "${YELLOW}   Erro: DNS não resolve ou servidor não está acessível${NC}"
elif [ "$HTTP_CODE" = "405" ] || [ "$HTTP_CODE" = "404" ] || [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Servidor está respondendo (HTTP $HTTP_CODE)${NC}"
    echo -e "${BLUE}   O servidor existe e está acessível${NC}"
else
    echo -e "${YELLOW}⚠️  Servidor respondeu com código: $HTTP_CODE${NC}"
fi
echo ""

# Teste 3: Teste POST
echo -e "${BLUE}[3] Testando envio POST...${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d '{"name":"Teste","email":"teste@teste.com","phone":"123456789","message":"Teste de conexão"}' \
    --max-time 10 \
    "$WEBHOOK_URL" 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "000" ]; then
    echo -e "${RED}❌ Erro ao enviar POST${NC}"
    echo -e "${YELLOW}   Verifique se o domínio está configurado corretamente${NC}"
elif [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "202" ]; then
    echo -e "${GREEN}✅ POST enviado com sucesso (HTTP $HTTP_CODE)${NC}"
    echo -e "${BLUE}   Resposta: ${YELLOW}$BODY${NC}"
else
    echo -e "${YELLOW}⚠️  POST retornou código: $HTTP_CODE${NC}"
    echo -e "${BLUE}   Resposta: ${YELLOW}$BODY${NC}"
fi
echo ""

# Resumo
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                      RESUMO                              ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if nslookup webhook.locusp.shop >/dev/null 2>&1; then
    echo -e "${GREEN}✅ DNS está configurado${NC}"
else
    echo -e "${RED}❌ DNS NÃO está configurado${NC}"
    echo -e "${YELLOW}   Ação necessária:${NC}"
    echo -e "${YELLOW}   1. Verifique se o domínio webhook.locusp.shop existe${NC}"
    echo -e "${YELLOW}   2. Configure o DNS para apontar para o servidor do N8N${NC}"
    echo -e "${YELLOW}   3. Aguarde a propagação do DNS (pode levar algumas horas)${NC}"
fi

echo ""
echo -e "${BLUE}💡 Para testar manualmente:${NC}"
echo -e "${YELLOW}   curl -X POST -H 'Content-Type: application/json' \\${NC}"
echo -e "${YELLOW}   -d '{\"name\":\"Teste\",\"email\":\"teste@teste.com\",\"phone\":\"123\",\"message\":\"teste\"}' \\${NC}"
echo -e "${YELLOW}   $WEBHOOK_URL${NC}"
echo ""


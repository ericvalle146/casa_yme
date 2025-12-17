#!/usr/bin/env bash

set -euo pipefail

# Cores
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         Verificador de Configuração do Traefik           ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Encontrar container do Traefik
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)

if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Container do Traefik não encontrado${NC}"
    echo -e "${YELLOW}   Verifique se o Traefik está rodando: docker ps | grep traefik${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik encontrado: ${YELLOW}$TRAEFIK_CONTAINER${NC}"
echo ""

# Verificar se está na network vpsnet
echo -e "${BLUE}[1] Verificando networks...${NC}"
TRAEFIK_NETWORKS=$(docker inspect "$TRAEFIK_CONTAINER" --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}} {{end}}' 2>/dev/null || echo "")

if echo "$TRAEFIK_NETWORKS" | grep -q "vpsnet"; then
    echo -e "${GREEN}✅ Traefik está na network 'vpsnet'${NC}"
else
    echo -e "${YELLOW}⚠️  Traefik NÃO está na network 'vpsnet'${NC}"
    echo -e "${YELLOW}   Networks do Traefik: ${TRAEFIK_NETWORKS}${NC}"
    echo -e "${YELLOW}   Certifique-se de que os serviços usam a mesma network${NC}"
fi
echo ""

# Verificar logs para ACME/Let's Encrypt
echo -e "${BLUE}[2] Verificando configuração ACME/Let's Encrypt...${NC}"
TRAEFIK_LOGS=$(docker logs "$TRAEFIK_CONTAINER" 2>&1 | tail -100)

ACME_FOUND=false
if echo "$TRAEFIK_LOGS" | grep -qi "acme"; then
    echo -e "${GREEN}✅ ACME mencionado nos logs${NC}"
    ACME_FOUND=true
fi

if echo "$TRAEFIK_LOGS" | grep -qi "letsencrypt"; then
    echo -e "${GREEN}✅ Let's Encrypt mencionado nos logs${NC}"
    ACME_FOUND=true
fi

if echo "$TRAEFIK_LOGS" | grep -qi "certificate.*obtained\|certificate.*generated"; then
    echo -e "${GREEN}✅ Certificados sendo gerados${NC}"
    ACME_FOUND=true
fi

if [ "$ACME_FOUND" = false ]; then
    echo -e "${RED}❌ Nenhuma evidência de ACME/Let's Encrypt nos logs${NC}"
    echo -e "${YELLOW}   O Traefik pode não estar configurado para gerar certificados SSL${NC}"
fi
echo ""

# Verificar API do Traefik
echo -e "${BLUE}[3] Verificando API do Traefik...${NC}"
TRAEFIK_API_PORT=$(docker port "$TRAEFIK_CONTAINER" 2>/dev/null | grep "8080/tcp" | cut -d: -f2 | head -1)

if [ -n "$TRAEFIK_API_PORT" ]; then
    echo -e "${GREEN}✅ API do Traefik na porta: ${YELLOW}$TRAEFIK_API_PORT${NC}"
    
    # Tentar acessar a API
    if curl -sf "http://localhost:${TRAEFIK_API_PORT}/api/http/routers" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ API do Traefik está acessível${NC}"
        
        # Verificar rotas
        ROUTERS=$(curl -sf "http://localhost:${TRAEFIK_API_PORT}/api/http/routers" 2>/dev/null || echo "[]")
        if echo "$ROUTERS" | grep -q "imovelpro"; then
            echo -e "${GREEN}✅ Rotas do ImóvelPro encontradas${NC}"
        else
            echo -e "${YELLOW}⚠️  Rotas do ImóvelPro não encontradas na API${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  API do Traefik não está acessível${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Porta da API do Traefik não encontrada${NC}"
fi
echo ""

# Verificar certificados SSL dos domínios
echo -e "${BLUE}[4] Verificando certificados SSL...${NC}"

check_cert() {
    local domain=$1
    echo -e "${BLUE}   Verificando ${domain}...${NC}"
    
    CERT_INFO=$(echo | timeout 5 openssl s_client -connect "${domain}:443" -servername "$domain" 2>&1 | grep -E "CN =|subject=" | head -1 || echo "")
    
    if [ -z "$CERT_INFO" ]; then
        echo -e "${YELLOW}   ⚠️  Não foi possível conectar a ${domain}:443${NC}"
        return
    fi
    
    if echo "$CERT_INFO" | grep -qi "TRAEFIK DEFAULT CERT"; then
        echo -e "${RED}   ❌ Certificado auto-assinado (TRAEFIK DEFAULT CERT)${NC}"
        echo -e "${YELLOW}   ⚠️  O Traefik não está gerando certificados do Let's Encrypt${NC}"
    elif echo "$CERT_INFO" | grep -qi "$domain\|Let's Encrypt"; then
        echo -e "${GREEN}   ✅ Certificado válido${NC}"
        echo -e "${BLUE}   ${CERT_INFO}${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Certificado: ${CERT_INFO}${NC}"
    fi
}

check_cert "apiapi.jyze.space"
check_cert "casayme.com.br"

echo ""

# Verificar portas 80 e 443
echo -e "${BLUE}[5] Verificando portas 80 e 443...${NC}"
if netstat -tuln 2>/dev/null | grep -q ":80 "; then
    echo -e "${GREEN}✅ Porta 80 está escutando${NC}"
else
    echo -e "${YELLOW}⚠️  Porta 80 não está escutando${NC}"
fi

if netstat -tuln 2>/dev/null | grep -q ":443 "; then
    echo -e "${GREEN}✅ Porta 443 está escutando${NC}"
else
    echo -e "${YELLOW}⚠️  Porta 443 não está escutando${NC}"
fi
echo ""

# Resumo e recomendações
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    RESUMO E RECOMENDAÇÕES                 ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$ACME_FOUND" = false ]; then
    echo -e "${RED}⚠️  PROBLEMA DETECTADO: Traefik não tem Let's Encrypt configurado${NC}"
    echo ""
    echo -e "${YELLOW}Para resolver, você precisa:${NC}"
    echo -e "1. Acessar a configuração do Traefik"
    echo -e "2. Adicionar configuração ACME com Let's Encrypt"
    echo -e "3. Reiniciar o Traefik"
    echo ""
    echo -e "${BLUE}Exemplo de configuração ACME no Traefik:${NC}"
    echo -e "${CYAN}certificatesResolvers:${NC}"
    echo -e "${CYAN}  letsencrypt:${NC}"
    echo -e "${CYAN}    acme:${NC}"
    echo -e "${CYAN}      email: seu-email@exemplo.com${NC}"
    echo -e "${CYAN}      storage: /letsencrypt/acme.json${NC}"
    echo -e "${CYAN}      httpChallenge:${NC}"
    echo -e "${CYAN}        entryPoint: web${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Traefik parece estar configurado corretamente${NC}"
    echo -e "${YELLOW}   Se os certificados ainda estiverem auto-assinados, aguarde alguns minutos${NC}"
    echo -e "${YELLOW}   O Let's Encrypt pode levar alguns minutos para gerar os certificados${NC}"
fi

echo ""
echo -e "${BLUE}💡 Comandos úteis:${NC}"
echo -e "   - Ver logs do Traefik: ${YELLOW}docker logs -f $TRAEFIK_CONTAINER${NC}"
echo -e "   - Ver rotas: ${YELLOW}curl -s http://localhost:${TRAEFIK_API_PORT:-8080}/api/http/routers | jq${NC}"
echo -e "   - Ver serviços: ${YELLOW}docker ps | grep imovelpro${NC}"
echo ""


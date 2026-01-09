#!/usr/bin/env bash

# Script para validar se tudo está pronto para o deploy
# Rode antes de enviar para a VPS

set -euo pipefail

# Cores
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

ERRORS=0
WARNINGS=0

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🔍 VALIDAÇÃO PRÉ-DEPLOY - CASA YME                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Função para verificar arquivo
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅${NC} $2"
    else
        echo -e "${RED}❌${NC} $2"
        ((ERRORS++))
    fi
}

# Função para verificar diretório
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✅${NC} $2"
    else
        echo -e "${RED}❌${NC} $2"
        ((ERRORS++))
    fi
}

# Função para aviso
warn() {
    echo -e "${YELLOW}⚠️${NC}  $1"
    ((WARNINGS++))
}

# Função para info
info() {
    echo -e "${CYAN}ℹ️${NC}  $1"
}

echo -e "${CYAN}[1/6] Verificando estrutura de arquivos...${NC}\n"

check_file "deploy/deploy.sh" "Script de deploy principal"
check_file "deploy/docker-compose.yml" "Configuração Docker Compose"
check_file "deploy/.env.example" "Arquivo de exemplo de variáveis"
check_file "deploy/README.md" "Documentação de deploy"
check_file "deploy/test-local.sh" "Script de teste local"

check_file "frontend/Dockerfile" "Dockerfile do frontend"
check_file "frontend/package.json" "Package.json do frontend"
check_file "frontend/nginx.conf" "Configuração Nginx do frontend"

check_file "backend/Dockerfile" "Dockerfile do backend"
check_file "backend/package.json" "Package.json do backend"

check_dir "sql" "Pasta de scripts SQL"

check_file "enviar-para-vps.sh" "Script de upload para VPS"
check_file "GUIA-DEPLOY.md" "Guia de deploy"
check_file "CHECKLIST-DEPLOY.md" "Checklist de deploy"
check_file "COMO-FAZER-DEPLOY.txt" "Resumo executivo"

echo ""
echo -e "${CYAN}[2/6] Verificando permissões de execução...${NC}\n"

if [ -x "deploy/deploy.sh" ]; then
    echo -e "${GREEN}✅${NC} deploy/deploy.sh é executável"
else
    echo -e "${YELLOW}⚠️${NC}  deploy/deploy.sh não é executável (será corrigido no upload)"
    ((WARNINGS++))
fi

if [ -x "enviar-para-vps.sh" ]; then
    echo -e "${GREEN}✅${NC} enviar-para-vps.sh é executável"
else
    warn "enviar-para-vps.sh não é executável"
fi

echo ""
echo -e "${CYAN}[3/6] Verificando configurações do .env.example...${NC}\n"

if [ -f "deploy/.env.example" ]; then
    # Verificar variáveis críticas
    if grep -q "DOMAIN_FRONTEND=casayme.com.br" deploy/.env.example; then
        echo -e "${GREEN}✅${NC} DOMAIN_FRONTEND configurado"
    else
        echo -e "${RED}❌${NC} DOMAIN_FRONTEND não está configurado corretamente"
        ((ERRORS++))
    fi

    if grep -q "DOMAIN_BACKEND=backend.casayme.com.br" deploy/.env.example; then
        echo -e "${GREEN}✅${NC} DOMAIN_BACKEND configurado"
    else
        echo -e "${RED}❌${NC} DOMAIN_BACKEND não está configurado corretamente"
        ((ERRORS++))
    fi

    if grep -q "DB_HOST=72.61.131.168" deploy/.env.example; then
        echo -e "${GREEN}✅${NC} DB_HOST configurado"
    else
        echo -e "${RED}❌${NC} DB_HOST não está configurado corretamente"
        ((ERRORS++))
    fi

    if grep -q "DB_PASSWORD=" deploy/.env.example; then
        echo -e "${GREEN}✅${NC} DB_PASSWORD presente"
    else
        echo -e "${RED}❌${NC} DB_PASSWORD não encontrado"
        ((ERRORS++))
    fi

    if grep -q "ACCESS_TOKEN_SECRET=MUDE_ISSO" deploy/.env.example; then
        echo -e "${GREEN}✅${NC} ACCESS_TOKEN_SECRET será gerado automaticamente"
    else
        warn "ACCESS_TOKEN_SECRET tem valor customizado (OK se intencional)"
    fi
fi

echo ""
echo -e "${CYAN}[4/6] Verificando Dockerfiles...${NC}\n"

# Frontend Dockerfile
if [ -f "frontend/Dockerfile" ]; then
    if grep -q "FROM node" frontend/Dockerfile; then
        echo -e "${GREEN}✅${NC} Frontend Dockerfile usa Node.js"
    fi
    if grep -q "FROM nginx" frontend/Dockerfile; then
        echo -e "${GREEN}✅${NC} Frontend usa Nginx para servir"
    fi
    if grep -q "ARG VITE_API_BASE_URL" frontend/Dockerfile; then
        echo -e "${GREEN}✅${NC} Frontend aceita variável VITE_API_BASE_URL"
    fi
fi

# Backend Dockerfile
if [ -f "backend/Dockerfile" ]; then
    if grep -q "FROM node" backend/Dockerfile; then
        echo -e "${GREEN}✅${NC} Backend Dockerfile usa Node.js"
    fi
    if grep -q "EXPOSE 4000" backend/Dockerfile; then
        echo -e "${GREEN}✅${NC} Backend expõe porta 4000"
    fi
fi

echo ""
echo -e "${CYAN}[5/6] Verificando docker-compose.yml...${NC}\n"

if [ -f "deploy/docker-compose.yml" ]; then
    if grep -q "traefik:" deploy/docker-compose.yml; then
        echo -e "${GREEN}✅${NC} Serviço Traefik configurado"
    else
        echo -e "${RED}❌${NC} Serviço Traefik não encontrado"
        ((ERRORS++))
    fi

    if grep -q "backend:" deploy/docker-compose.yml; then
        echo -e "${GREEN}✅${NC} Serviço backend configurado"
    else
        echo -e "${RED}❌${NC} Serviço backend não encontrado"
        ((ERRORS++))
    fi

    if grep -q "frontend:" deploy/docker-compose.yml; then
        echo -e "${GREEN}✅${NC} Serviço frontend configurado"
    else
        echo -e "${RED}❌${NC} Serviço frontend não encontrado"
        ((ERRORS++))
    fi

    if grep -q "letsencrypt" deploy/docker-compose.yml; then
        echo -e "${GREEN}✅${NC} Let's Encrypt configurado"
    else
        warn "Let's Encrypt pode não estar configurado"
    fi

    # Verificar se NÃO tem postgres (pois é externo)
    if ! grep -q "postgres:" deploy/docker-compose.yml; then
        echo -e "${GREEN}✅${NC} Sem container Postgres (usando externo)"
    else
        warn "Container Postgres encontrado (pode conflitar com banco externo)"
    fi
fi

echo ""
echo -e "${CYAN}[6/6] Verificando scripts SQL...${NC}\n"

if [ -d "sql" ]; then
    SQL_COUNT=$(find sql -name "*.sql" | wc -l)
    if [ "$SQL_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅${NC} Encontrados $SQL_COUNT arquivos SQL"
        find sql -name "*.sql" -exec basename {} \; | while read file; do
            info "  • $file"
        done
    else
        warn "Nenhum arquivo SQL encontrado em sql/"
    fi
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ TUDO PRONTO PARA DEPLOY! 🎉                       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Próximos passos:${NC}"
    echo -e "1. ${YELLOW}./enviar-para-vps.sh${NC} - Enviar arquivos para VPS"
    echo -e "2. ${YELLOW}cd /root/casa_yme/deploy && ./deploy.sh${NC} - Fazer deploy"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  ⚠️  TUDO OK COM $WARNINGS AVISOS                     ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Você pode prosseguir com o deploy, mas revise os avisos acima.${NC}"
else
    echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ ENCONTRADOS $ERRORS ERROS                         ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Corrija os erros acima antes de fazer deploy.${NC}"
    exit 1
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

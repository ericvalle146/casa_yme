#!/usr/bin/env bash

# Script para testar o deploy localmente antes de subir para a VPS
# Usa domínios localhost para validar se tudo funciona

set -euo pipefail

cd "$(dirname "$0")"

# Cores
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🧪 TESTE LOCAL - CASA YME                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Criar .env para teste local
echo -e "${CYAN}Criando .env para teste local...${NC}"

cat > .env << 'EOF'
# TESTE LOCAL
DOMAIN_FRONTEND=localhost
DOMAIN_BACKEND=api.localhost
LETSENCRYPT_EMAIL=test@localhost

# Frontend
VITE_WEBHOOK_URL=

# Backend
PORT=4000
NODE_ENV=production
CORS_ORIGINS=http://localhost,https://localhost
N8N_WEBHOOK_URL=

# Banco de dados externo (mesmo da produção)
DB_HOST=72.61.131.168
DB_PORT=5432
DB_USER=admin
DB_PASSWORD=a32js@31#t3?$1%&*!Sk45!
DB_NAME=casa_yme
DATABASE_URL=postgres://admin:a32js@31#t3?$1%&*!Sk45!@72.61.131.168:5432/casa_yme

# JWT
ACCESS_TOKEN_SECRET=test-secret-key-local-only-not-for-production
ACCESS_TOKEN_TTL_MINUTES=15
REFRESH_TOKEN_TTL_DAYS=7
PASSWORD_SALT_ROUNDS=12

# Postgres container (não usado)
POSTGRES_USER=casayme
POSTGRES_PASSWORD=localdevpassword
POSTGRES_DB=casayme
EOF

echo -e "${GREEN}✅ .env criado para teste local${NC}"
echo ""

echo -e "${CYAN}Iniciando containers...${NC}"
docker compose down 2>/dev/null || true
docker compose up -d --build

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Containers iniciados!${NC}"
echo ""
echo -e "Aguarde ~30 segundos para os containers ficarem prontos..."
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

sleep 30

# Testar backend
echo -e "${CYAN}Testando backend...${NC}"
if curl -f -s http://localhost/health > /dev/null; then
    echo -e "${GREEN}✅ Backend respondendo em http://localhost/health${NC}"
else
    echo -e "${RED}❌ Backend não está respondendo${NC}"
    echo -e "${YELLOW}Logs do backend:${NC}"
    docker compose logs backend | tail -20
fi

# Testar frontend
echo -e "\n${CYAN}Testando frontend...${NC}"
if curl -f -s http://localhost/ > /dev/null; then
    echo -e "${GREEN}✅ Frontend respondendo em http://localhost/${NC}"
else
    echo -e "${RED}❌ Frontend não está respondendo${NC}"
    echo -e "${YELLOW}Logs do frontend:${NC}"
    docker compose logs frontend | tail -20
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 Teste local concluído!${NC}"
echo ""
echo -e "Acesse localmente:"
echo -e "  Frontend: ${CYAN}http://localhost${NC}"
echo -e "  Backend:  ${CYAN}http://localhost/health${NC}"
echo -e "  Traefik:  ${CYAN}http://localhost:8080${NC}"
echo ""
echo -e "${YELLOW}Para parar o teste:${NC}"
echo -e "  ${CYAN}docker compose down${NC}"
echo ""
echo -e "${GREEN}Se tudo funcionar aqui, está pronto para produção!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

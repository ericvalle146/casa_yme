#!/usr/bin/env bash

set -euo pipefail

# Mudar para o diretório onde o script está localizado
cd "$(dirname "$0")"

# Cores para output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🏠 DEPLOY AUTOMÁTICO - CASA YME                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# --- 1. Verificar dependências ---
echo -e "${CYAN}[1/5]${NC} Verificando dependências..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ ERRO: Docker não está instalado.${NC}"
    echo -e "${YELLOW}Instale o Docker: https://docs.docker.com/engine/install/${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}❌ ERRO: Docker não está rodando.${NC}"
    echo -e "${YELLOW}Inicie o Docker daemon e tente novamente.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker instalado e rodando${NC}"

# --- 2. Preparar arquivo .env AUTOMATICAMENTE ---
echo -e "\n${CYAN}[2/5]${NC} Configurando variáveis de ambiente..."

if [ ! -f .env.example ]; then
    echo -e "${RED}❌ ERRO: .env.example não encontrado!${NC}"
    echo -e "${YELLOW}O arquivo .env.example é necessário para o deploy automático.${NC}"
    exit 1
fi

# Sempre criar/sobrescrever o .env a partir do .env.example
echo -e "${BLUE}📝 Criando .env a partir do .env.example...${NC}"
cp .env.example .env

# Gerar segredo JWT aleatório e seguro
echo -e "${BLUE}🔐 Gerando chave de segurança JWT (ACCESS_TOKEN_SECRET)...${NC}"

# Método 1: Tentar com openssl (mais confiável)
if command -v openssl &> /dev/null; then
    NEW_SECRET=$(openssl rand -base64 48 | tr -d '/+=' | head -c 64)
else
    # Método 2: Fallback para tr + urandom (simplificado)
    NEW_SECRET=$(tr -dc 'A-Za-z0-9' < /dev/urandom | dd bs=64 count=1 2>/dev/null)
fi

if [[ -z "$NEW_SECRET" ]]; then
    echo -e "${RED}❌ Falha ao gerar chave de segurança.${NC}"
    echo -e "${YELLOW}ATENÇÃO: Você precisará editar o .env manualmente para trocar ACCESS_TOKEN_SECRET${NC}"
else
    # Substituir no arquivo .env (direto, sem escape especial pois usamos apenas base64)
    sed -i "s/MUDE_ISSO_PARA_UMA_STRING_BEM_SEGURA_E_ALEATORIA/$NEW_SECRET/" .env
    echo -e "${GREEN}✅ Chave de segurança gerada e configurada${NC}"
fi

echo -e "${GREEN}✅ Arquivo .env criado com sucesso${NC}"

# --- 3. Carregar e validar variáveis ---
echo -e "\n${CYAN}[3/5]${NC} Validando configurações..."
# Temporariamente desabilitar verificação de variáveis não definidas
# (a senha do banco tem caracteres especiais que podem confundir bash)
set +u
set -a
source .env
set +a
set -u

# Validar variáveis críticas
if [[ -z "${DOMAIN_FRONTEND:-}" ]]; then
    echo -e "${RED}❌ ERRO: DOMAIN_FRONTEND não está definido no .env${NC}"
    exit 1
fi

if [[ -z "${DOMAIN_BACKEND:-}" ]]; then
    echo -e "${RED}❌ ERRO: DOMAIN_BACKEND não está definido no .env${NC}"
    exit 1
fi

if [[ -z "${DB_HOST:-}" ]] || [[ -z "${DB_USER:-}" ]] || [[ -z "${DB_PASSWORD:-}" ]] || [[ -z "${DB_NAME:-}" ]]; then
    echo -e "${RED}❌ ERRO: Configurações do banco de dados estão incompletas${NC}"
    echo -e "${YELLOW}Verifique: DB_HOST, DB_USER, DB_PASSWORD, DB_NAME${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Configurações validadas${NC}"

# --- 4. Exibir avisos informativos ---
echo -e "\n${CYAN}[4/5]${NC} Informações do deploy..."
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "🌐 Frontend:  ${CYAN}https://${DOMAIN_FRONTEND}${NC}"
echo -e "🔧 Backend:   ${CYAN}https://${DOMAIN_BACKEND}${NC}"
echo -e "📊 Dashboard: ${CYAN}http://localhost:8080${NC} (Traefik)"
echo -e "💾 Banco:     ${CYAN}${DB_HOST}:${DB_PORT}/${DB_NAME}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ "${LETSENCRYPT_EMAIL}" == "contato@casayme.com.br" ]]; then
    echo -e "${YELLOW}⚠️  Usando e-mail padrão para Let's Encrypt${NC}"
    echo -e "${YELLOW}   Edite LETSENCRYPT_EMAIL no .env se necessário${NC}"
fi

if [[ -z "${VITE_WEBHOOK_URL:-}" ]] || [[ -z "${N8N_WEBHOOK_URL:-}" ]]; then
    echo -e "${YELLOW}⚠️  Webhook N8N não configurado${NC}"
    echo -e "${YELLOW}   O formulário de contato não funcionará até configurar${NC}"
    echo -e "${YELLOW}   Edite VITE_WEBHOOK_URL e N8N_WEBHOOK_URL no .env${NC}"
fi

# --- 5. Fazer o deploy ---
echo -e "\n${CYAN}[5/5]${NC} Iniciando deploy dos containers..."
echo -e "${BLUE}⏳ Fazendo build e deploy... (isso pode levar alguns minutos)${NC}\n"

# Parar e remover containers/serviços antigos
echo -e "${YELLOW}📦 Removendo containers antigos (docker compose)...${NC}"
docker compose down --remove-orphans 2>/dev/null || true

echo -e "${YELLOW}📦 Removendo stack antigo (docker swarm)...${NC}"
docker stack rm casayme 2>/dev/null || true

echo -e "${YELLOW}⏳ Aguardando remoção completa (10 segundos)...${NC}"
sleep 10

# Build das imagens localmente
echo -e "\n${BLUE}🔨 Fazendo build das imagens Docker...${NC}"
echo -e "${YELLOW}   Backend: casayme-backend:latest${NC}"
docker build -t casayme-backend:latest ../backend

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Falha ao fazer build do backend${NC}"
    exit 1
fi

echo -e "${YELLOW}   Frontend: casayme-frontend:latest${NC}"
docker build -t casayme-frontend:latest \
    --build-arg VITE_API_BASE_URL="https://${DOMAIN_BACKEND}/api" \
    --build-arg VITE_WEBHOOK_URL="${VITE_WEBHOOK_URL}" \
    ../frontend

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Falha ao fazer build do frontend${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build concluído${NC}"

# Deploy com Docker Stack
echo -e "\n${BLUE}🚀 Fazendo deploy com Docker Stack...${NC}"
docker stack deploy -c docker-stack.yml --with-registry-auth casayme

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  🚀 DEPLOY CONCLUÍDO COM SUCESSO! 🎉                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "📱 Acesse sua aplicação:"
    echo -e "   Frontend: ${CYAN}https://${DOMAIN_FRONTEND}${NC}"
    echo -e "   Backend:  ${CYAN}https://${DOMAIN_BACKEND}/health${NC}"
    echo -e ""
    echo -e "🔍 Monitoramento:"
    echo -e "   Traefik Dashboard: ${CYAN}http://localhost:8080${NC}"
    echo -e "   Stack status: ${CYAN}docker stack ps casayme${NC}"
    echo -e "   Logs backend: ${CYAN}docker service logs casayme_backend -f${NC}"
    echo -e "   Logs frontend: ${CYAN}docker service logs casayme_frontend -f${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}⏰ Aguarde alguns minutos para:${NC}"
    echo -e "${YELLOW}   1. Os serviços iniciarem completamente${NC}"
    echo -e "${YELLOW}   2. Os certificados SSL serem gerados${NC}"
    echo -e "${YELLOW}   3. O Traefik detectar os novos serviços${NC}"
    echo ""
    echo -e "${YELLOW}🔍 Acompanhe o status:${NC}"
    echo -e "${YELLOW}   docker stack ps casayme${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ DEPLOY FALHOU                                     ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Verifique os logs acima para identificar o erro.${NC}"
    echo -e "${YELLOW}Comandos úteis:${NC}"
    echo -e "  - ${CYAN}docker stack ps casayme${NC}"
    echo -e "  - ${CYAN}docker service logs casayme_backend${NC}"
    echo -e "  - ${CYAN}docker service logs casayme_frontend${NC}"
    echo ""
    exit 1
fi

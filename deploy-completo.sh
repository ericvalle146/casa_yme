#!/usr/bin/env bash

set -euo pipefail

# Cores para output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

# Configurações
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
DOMAIN_FRONTEND="imob.locusup.shop"
DOMAIN_BACKEND="apiapi.jyze.space"
EMAIL_LETSENCRYPT="${LETSENCRYPT_EMAIL:-admin@${DOMAIN_FRONTEND}}"

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     DEPLOY COMPLETO - ImóvelPro com SSL Let's Encrypt     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Função para verificar se comando existe
check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo -e "${RED}❌ $1 não encontrado. Instale primeiro.${NC}"
        exit 1
    fi
}

# Verificar dependências
echo -e "${BLUE}[1/10] Verificando dependências...${NC}"
check_command docker
check_command docker-compose

if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker não está rodando${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Dependências OK${NC}"
echo ""

# Verificar se está em modo Swarm ou Compose
SWARM_MODE=false
if docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active\|manager"; then
    SWARM_MODE=true
    echo -e "${BLUE}[2/10] Modo Docker Swarm detectado${NC}"
else
    echo -e "${BLUE}[2/10] Modo Docker Compose${NC}"
fi
echo ""

# Detectar network do Traefik
echo -e "${BLUE}[3/10] Detectando rede do Traefik...${NC}"
TRAEFIK_NETWORK=""

# Lista de networks possíveis
NETWORK_CANDIDATES=("vpsnet" "traefik" "traefik-public" "proxy" "web" "JyzeCliente")

for net in "${NETWORK_CANDIDATES[@]}"; do
    if docker network inspect "$net" >/dev/null 2>&1; then
        NET_TYPE=$(docker network inspect "$net" --format '{{.Driver}}' 2>/dev/null || echo "")
        if [ "$NET_TYPE" = "overlay" ] || [ "$NET_TYPE" = "bridge" ]; then
            TRAEFIK_NETWORK="$net"
            echo -e "${GREEN}✅ Rede encontrada: ${YELLOW}$TRAEFIK_NETWORK${NC}"
            break
        fi
    fi
done

if [ -z "$TRAEFIK_NETWORK" ]; then
    echo -e "${YELLOW}⚠️  Rede do Traefik não encontrada automaticamente${NC}"
    echo -e "${YELLOW}   Tentando criar rede 'vpsnet'...${NC}"
    
    if [ "$SWARM_MODE" = true ]; then
        docker network create --driver overlay --attachable vpsnet 2>/dev/null || true
    else
        docker network create --driver bridge vpsnet 2>/dev/null || true
    fi
    
    if docker network inspect vpsnet >/dev/null 2>&1; then
        TRAEFIK_NETWORK="vpsnet"
        echo -e "${GREEN}✅ Rede 'vpsnet' criada${NC}"
    else
        echo -e "${RED}❌ Não foi possível criar a rede${NC}"
        echo -e "${YELLOW}   Configure manualmente: export TRAEFIK_NETWORK=<nome-da-rede>${NC}"
        exit 1
    fi
fi
echo ""

# Verificar e configurar Traefik com Let's Encrypt
echo -e "${BLUE}[4/10] Verificando configuração do Traefik...${NC}"

TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)

if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${YELLOW}⚠️  Container do Traefik não encontrado${NC}"
    echo -e "${YELLOW}   O Traefik precisa estar rodando e configurado com Let's Encrypt${NC}"
    echo -e "${YELLOW}   Verifique se o Traefik está rodando: docker ps | grep traefik${NC}"
    echo ""
    read -p "Continuar mesmo assim? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✅ Traefik encontrado: ${YELLOW}$TRAEFIK_CONTAINER${NC}"
    
    # Verificar se o Traefik tem ACME configurado
    TRAEFIK_LOGS=$(docker logs "$TRAEFIK_CONTAINER" 2>&1 | tail -50)
    
    if echo "$TRAEFIK_LOGS" | grep -qi "acme\|letsencrypt"; then
        echo -e "${GREEN}✅ Traefik parece ter ACME configurado${NC}"
    else
        echo -e "${YELLOW}⚠️  Traefik pode não ter Let's Encrypt configurado${NC}"
        echo -e "${YELLOW}   Certifique-se de que o Traefik tem ACME habilitado${NC}"
        echo -e "${YELLOW}   O certificado SSL pode não ser gerado automaticamente${NC}"
    fi
fi
echo ""

# Verificar arquivo .env do backend
echo -e "${BLUE}[5/10] Verificando configuração do backend...${NC}"
if [ ! -f "$PROJECT_ROOT/server/.env" ]; then
    echo -e "${YELLOW}⚠️  Arquivo server/.env não encontrado${NC}"
    if [ -f "$PROJECT_ROOT/server/env.example" ]; then
        echo -e "${BLUE}   Criando a partir de env.example...${NC}"
        cp "$PROJECT_ROOT/server/env.example" "$PROJECT_ROOT/server/.env"
        echo -e "${YELLOW}   ⚠️  IMPORTANTE: Configure o N8N_WEBHOOK_URL no arquivo server/.env${NC}"
        echo -e "${YELLOW}   Edite: nano $PROJECT_ROOT/server/.env${NC}"
        echo ""
        read -p "Pressione Enter após configurar o .env ou Ctrl+C para cancelar..."
    else
        echo -e "${RED}❌ Arquivo server/env.example não encontrado${NC}"
        exit 1
    fi
fi

# Verificar se N8N_WEBHOOK_URL está configurado
if grep -q "N8N_WEBHOOK_URL=https://" "$PROJECT_ROOT/server/.env" 2>/dev/null; then
    echo -e "${GREEN}✅ N8N_WEBHOOK_URL configurado${NC}"
else
    echo -e "${YELLOW}⚠️  N8N_WEBHOOK_URL pode não estar configurado corretamente${NC}"
fi
echo ""

# Parar containers antigos
echo -e "${BLUE}[6/10] Parando containers antigos...${NC}"
cd "$PROJECT_ROOT"

# Parar docker-compose se estiver rodando
docker-compose -f docker-compose.yml down 2>/dev/null || true
docker-compose -f docker-compose.standalone.yml down 2>/dev/null || true

# Parar containers individuais
docker stop imovelpro-frontend imovelpro-backend 2>/dev/null || true
docker rm imovelpro-frontend imovelpro-backend 2>/dev/null || true

# Remover stack do Swarm se existir
if [ "$SWARM_MODE" = true ]; then
    docker stack rm imovelpro 2>/dev/null || true
    sleep 5
fi

echo -e "${GREEN}✅ Containers antigos removidos${NC}"
echo ""

# Build das imagens
echo -e "${BLUE}[7/10] Construindo imagens Docker...${NC}"

# Verificar se vite.config.ts existe
if [ ! -f "$PROJECT_ROOT/vite.config.ts" ]; then
    echo -e "${YELLOW}⚠️  vite.config.ts não encontrado, criando...${NC}"
    cat > "$PROJECT_ROOT/vite.config.ts" << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: process.env.VITE_PROXY_TARGET || 'http://localhost:4000',
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
  },
})
EOF
    echo -e "${GREEN}✅ vite.config.ts criado${NC}"
fi

# Build frontend
echo -e "${BLUE}   Building frontend...${NC}"
docker build \
    --pull \
    -t imovelpro-frontend:latest \
    -f "$PROJECT_ROOT/Dockerfile.frontend" \
    --build-arg VITE_API_BASE_URL="https://${DOMAIN_BACKEND}" \
    "$PROJECT_ROOT" || {
    echo -e "${RED}❌ Erro ao construir frontend${NC}"
    exit 1
}

# Build backend
echo -e "${BLUE}   Building backend...${NC}"
docker build \
    --pull \
    -t imovelpro-backend:latest \
    -f "$PROJECT_ROOT/server/Dockerfile" \
    "$PROJECT_ROOT/server" || {
    echo -e "${RED}❌ Erro ao construir backend${NC}"
    exit 1
}

echo -e "${GREEN}✅ Imagens construídas${NC}"
echo ""

# Deploy
echo -e "${BLUE}[8/10] Fazendo deploy dos serviços...${NC}"

if [ "$SWARM_MODE" = true ]; then
    # Deploy com Swarm
    echo -e "${BLUE}   Deployando com Docker Swarm...${NC}"
    
    # Carregar variáveis do .env
    set -a
    source "$PROJECT_ROOT/server/.env" 2>/dev/null || true
    set +a
    
    # Exportar variáveis para o stack
    export TRAEFIK_NETWORK
    export FRONTEND_IMAGE="imovelpro-frontend:latest"
    export BACKEND_IMAGE="imovelpro-backend:latest"
    export PORT=${PORT:-4000}
    export CORS_ORIGINS=${CORS_ORIGINS:-"https://${DOMAIN_FRONTEND}"}
    export NODE_ENV=${NODE_ENV:-production}
    export N8N_WEBHOOK_URL=${N8N_WEBHOOK_URL:-}
    
    docker stack deploy -c "$PROJECT_ROOT/deploy/docker-stack.yml" imovelpro || {
        echo -e "${RED}❌ Erro ao fazer deploy da stack${NC}"
        exit 1
    }
    
    echo -e "${GREEN}✅ Stack deploy iniciado${NC}"
    sleep 10
    
    # Verificar serviços
    echo -e "${BLUE}   Verificando serviços...${NC}"
    docker service ls | grep imovelpro || true
    
else
    # Deploy com Compose
    echo -e "${BLUE}   Deployando com Docker Compose...${NC}"
    
    # Usar docker-compose.yml que já tem a network vpsnet
    docker-compose -f docker-compose.yml up -d || {
        echo -e "${RED}❌ Erro ao fazer deploy${NC}"
        exit 1
    }
    
    echo -e "${GREEN}✅ Serviços iniciados${NC}"
    sleep 5
fi

echo ""

# Verificar saúde dos serviços
echo -e "${BLUE}[9/10] Verificando saúde dos serviços...${NC}"

check_service_health() {
    local service_name=$1
    local port=$2
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -sf "http://localhost:${port}/health" >/dev/null 2>&1; then
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    return 1
}

# Verificar backend
if check_service_health "backend" "4000"; then
    echo -e "${GREEN}✅ Backend está saudável${NC}"
else
    echo -e "${YELLOW}⚠️  Backend pode ainda estar iniciando${NC}"
fi

# Verificar frontend
if check_service_health "frontend" "3429"; then
    echo -e "${GREEN}✅ Frontend está saudável${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend pode ainda estar iniciando${NC}"
fi

echo ""

# Verificar certificados SSL
echo -e "${BLUE}[10/10] Verificando certificados SSL...${NC}"

check_ssl_cert() {
    local domain=$1
    local cert_info=$(echo | openssl s_client -connect "${domain}:443" -servername "$domain" 2>&1 | grep -E "CN =|subject=" | head -1)
    
    if echo "$cert_info" | grep -qi "TRAEFIK DEFAULT CERT\|self-signed"; then
        echo -e "${RED}❌ Certificado auto-assinado detectado para ${domain}${NC}"
        return 1
    elif echo "$cert_info" | grep -qi "$domain\|Let's Encrypt"; then
        echo -e "${GREEN}✅ Certificado válido para ${domain}${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Não foi possível verificar certificado para ${domain}${NC}"
        return 2
    fi
}

# Aguardar um pouco para o Traefik gerar certificados
echo -e "${BLUE}   Aguardando 30 segundos para o Traefik gerar certificados...${NC}"
sleep 30

check_ssl_cert "$DOMAIN_BACKEND" || true
check_ssl_cert "$DOMAIN_FRONTEND" || true

echo ""

# Resumo final
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    DEPLOY CONCLUÍDO!                      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ Deploy realizado com sucesso!${NC}"
echo ""
echo -e "${BLUE}📋 Informações:${NC}"
echo -e "   - Frontend: ${CYAN}https://${DOMAIN_FRONTEND}${NC}"
echo -e "   - Backend:  ${CYAN}https://${DOMAIN_BACKEND}${NC}"
echo -e "   - Network:  ${YELLOW}${TRAEFIK_NETWORK}${NC}"
echo ""
echo -e "${BLUE}💡 Comandos úteis:${NC}"
if [ "$SWARM_MODE" = true ]; then
    echo -e "   - Ver serviços: ${YELLOW}docker service ls | grep imovelpro${NC}"
    echo -e "   - Ver logs: ${YELLOW}docker service logs -f imovelpro_frontend${NC}"
    echo -e "   - Remover: ${YELLOW}docker stack rm imovelpro${NC}"
else
    echo -e "   - Ver status: ${YELLOW}docker-compose ps${NC}"
    echo -e "   - Ver logs: ${YELLOW}docker-compose logs -f${NC}"
    echo -e "   - Parar: ${YELLOW}docker-compose down${NC}"
fi
echo ""
echo -e "${BLUE}🔍 Verificar SSL:${NC}"
echo -e "   - Backend:  ${YELLOW}curl -I https://${DOMAIN_BACKEND}/health${NC}"
echo -e "   - Frontend: ${YELLOW}curl -I https://${DOMAIN_FRONTEND}${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo -e "   - Se os certificados SSL ainda estiverem auto-assinados,"
echo -e "     verifique se o Traefik tem Let's Encrypt configurado"
echo -e "   - Pode levar alguns minutos para o Let's Encrypt gerar os certificados"
echo -e "   - Verifique os logs do Traefik: ${YELLOW}docker logs ${TRAEFIK_CONTAINER:-traefik}${NC}"
echo ""


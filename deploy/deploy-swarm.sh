#!/usr/bin/env bash

set -euo pipefail

# Cores
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

echo -e "${GREEN}==> ImóvelPro - Deploy automático (Docker Swarm + Traefik)${NC}"
echo ""

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STACK_NAME="imovelpro"

cd "$PROJECT_ROOT"

# Verificar Docker e Swarm
echo -e "${BLUE}1) Verificando Docker/Swarm...${NC}"
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker não encontrado${NC}"
    exit 1
fi

docker version >/dev/null

SWARM_STATE=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || echo "inactive")
if [ "$SWARM_STATE" != "active" ] && [ "$SWARM_STATE" != "manager" ]; then
    echo -e "${RED}❌ Swarm não está ativo${NC}"
    echo -e "${YELLOW}   Ative com: docker swarm init${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker Swarm ativo${NC}"
echo ""

# Detectar network do Traefik
echo -e "${BLUE}2) Detectando rede do Traefik (prioriza vpsnet)...${NC}"
TRAEFIK_NETWORK=${TRAEFIK_NETWORK:-}

if [ -z "${TRAEFIK_NETWORK}" ]; then
    # Prioriza vpsnet, depois tenta outras overlay
    CANDIDATES=$(docker network ls --format '{{.Name}} {{.Driver}} {{.Scope}}' | awk '$2=="overlay" && $3=="swarm" {print $1}' || echo "")
    
    for n in vpsnet traefik traefik-public proxy web JyzeCliente; do
        if echo "$CANDIDATES" | grep -Fxq "$n"; then
            TRAEFIK_NETWORK="$n"
            break
        fi
    done
fi

if [ -z "${TRAEFIK_NETWORK}" ]; then
    # Como fallback, tenta qualquer overlay existente
    TRAEFIK_NETWORK=$(docker network ls --format '{{.Name}} {{.Driver}} {{.Scope}}' | awk '$2=="overlay" && $3=="swarm" {print $1; exit}' || echo "")
fi

if [ -z "${TRAEFIK_NETWORK}" ]; then
    echo -e "${RED}❌ Não encontrei uma rede do Traefik${NC}"
    echo -e "${YELLOW}   Crie/identifique a rede e exporte TRAEFIK_NETWORK=<nome>${NC}"
    echo -e "${YELLOW}   Exemplo: export TRAEFIK_NETWORK=vpsnet${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Usando rede Traefik: ${YELLOW}$TRAEFIK_NETWORK${NC}"
echo ""

# Verificar se a network existe
if ! docker network inspect "$TRAEFIK_NETWORK" >/dev/null 2>&1; then
    echo -e "${RED}❌ Network $TRAEFIK_NETWORK não existe${NC}"
    exit 1
fi

# Build das imagens
echo -e "${BLUE}3) Build das imagens...${NC}"

# Tag das imagens
TIMESTAMP_TAG=$(date +%Y%m%d-%H%M%S)
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "nogit")
IMAGE_TAG="${TIMESTAMP_TAG}-${GIT_SHA}"

FRONTEND_IMAGE="${FRONTEND_IMAGE:-prototipo_mariana_imobiliarias-frontend:${IMAGE_TAG}}"
BACKEND_IMAGE="${BACKEND_IMAGE:-prototipo_mariana_imobiliarias-backend:${IMAGE_TAG}}"

echo -e "${BLUE}   Building frontend...${NC}"
docker build \
    --pull \
    -t "$FRONTEND_IMAGE" \
    -f "$PROJECT_ROOT/Dockerfile.frontend" \
    --build-arg VITE_API_BASE_URL=https://apiapi.jyze.space \
    "$PROJECT_ROOT"

echo -e "${BLUE}   Building backend...${NC}"
docker build \
    --pull \
    -t "$BACKEND_IMAGE" \
    -f "$PROJECT_ROOT/server/Dockerfile" \
    "$PROJECT_ROOT/server"

echo -e "${GREEN}✅ Imagens construídas${NC}"
echo ""

# Remover containers antigos (se existirem)
echo -e "${BLUE}4) Removendo containers antigos (se existirem)...${NC}"
docker stop imovelpro-frontend imovelpro-backend 2>/dev/null || true
docker rm imovelpro-frontend imovelpro-backend 2>/dev/null || true

# Remover network antiga (se existir)
docker network rm prototipo_mariana_imobiliarias_imovelpro-network 2>/dev/null || true

echo -e "${GREEN}✅ Containers antigos removidos${NC}"
echo ""

# Verificar arquivo .env do backend
if [ ! -f "$PROJECT_ROOT/server/.env" ]; then
    echo -e "${YELLOW}⚠️  Arquivo server/.env não encontrado${NC}"
    if [ -f "$PROJECT_ROOT/server/env.example" ]; then
        echo -e "${BLUE}   Criando a partir de env.example...${NC}"
        cp "$PROJECT_ROOT/server/env.example" "$PROJECT_ROOT/server/.env"
        echo -e "${YELLOW}   IMPORTANTE: Configure o N8N_WEBHOOK_URL no arquivo server/.env${NC}"
    else
        echo -e "${RED}❌ Arquivo server/env.example não encontrado${NC}"
        exit 1
    fi
fi

# Carregar variáveis de ambiente do backend
if [ -f "$PROJECT_ROOT/server/.env" ]; then
    echo -e "${BLUE}5) Carregando variáveis de ambiente do backend...${NC}"
    # Carregar variáveis do .env e exportar
    set -a
    source "$PROJECT_ROOT/server/.env"
    set +a
    echo -e "${GREEN}✅ Variáveis de ambiente carregadas${NC}"
    echo ""
fi

# Deploy da stack
echo -e "${BLUE}6) Deploy/atualização da stack '$STACK_NAME'...${NC}"

# Exportar variáveis necessárias para o docker-stack.yml
export TRAEFIK_NETWORK
export FRONTEND_IMAGE
export BACKEND_IMAGE

# Exportar variáveis de ambiente do backend (se carregadas do .env)
export PORT=${PORT:-4000}
export CORS_ORIGINS=${CORS_ORIGINS:-https://imob.locusup.shop}
export NODE_ENV=${NODE_ENV:-production}
export N8N_WEBHOOK_URL=${N8N_WEBHOOK_URL:-}

# Usar docker stack deploy
docker stack deploy \
    -c "$PROJECT_ROOT/deploy/docker-stack.yml" \
    "$STACK_NAME"

echo -e "${GREEN}✅ Stack deploy iniciado${NC}"
echo ""

# Aguardar serviços subirem
echo -e "${BLUE}7) Aguardando serviços subirem...${NC}"
sleep 10

# Verificar status dos serviços
echo -e "${BLUE}8) Verificando status dos serviços...${NC}"
docker service ls | grep "$STACK_NAME" || true

echo ""

# Verificar se os serviços estão rodando
FRONTEND_SERVICE="${STACK_NAME}_frontend"
BACKEND_SERVICE="${STACK_NAME}_backend"

echo -e "${BLUE}9) Verificando health dos serviços...${NC}"
sleep 5

FRONTEND_STATUS=$(docker service ps "$FRONTEND_SERVICE" --format '{{.CurrentState}}' --no-trunc 2>/dev/null | head -1 || echo "")
BACKEND_STATUS=$(docker service ps "$BACKEND_SERVICE" --format '{{.CurrentState}}' --no-trunc 2>/dev/null | head -1 || echo "")

if echo "$FRONTEND_STATUS" | grep -q "Running"; then
    echo -e "${GREEN}✅ Frontend está rodando${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend: $FRONTEND_STATUS${NC}"
fi

if echo "$BACKEND_STATUS" | grep -q "Running"; then
    echo -e "${GREEN}✅ Backend está rodando${NC}"
else
    echo -e "${YELLOW}⚠️  Backend: $BACKEND_STATUS${NC}"
fi

echo ""

# Verificar network
echo -e "${BLUE}10) Verificando conexão à network $TRAEFIK_NETWORK...${NC}"
CONTAINERS_IN_NETWORK=$(docker network inspect "$TRAEFIK_NETWORK" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")

if echo "$CONTAINERS_IN_NETWORK" | grep -q "imovelpro"; then
    echo -e "${GREEN}✅ Serviços estão na network $TRAEFIK_NETWORK${NC}"
else
    echo -e "${YELLOW}⚠️  Serviços podem ainda não estar na network (aguarde alguns segundos)${NC}"
fi

echo ""

# Resumo final
echo -e "${GREEN}✅ Deploy concluído!${NC}"
echo ""
echo -e "${BLUE}📋 Resumo:${NC}"
echo -e "   - Stack: ${YELLOW}$STACK_NAME${NC}"
echo -e "   - Network: ${YELLOW}$TRAEFIK_NETWORK${NC}"
echo -e "   - Frontend: ${YELLOW}$FRONTEND_IMAGE${NC}"
echo -e "   - Backend: ${YELLOW}$BACKEND_IMAGE${NC}"
echo ""
echo -e "${BLUE}🌐 Domínios:${NC}"
echo -e "   - Frontend: https://imob.locusup.shop"
echo -e "   - Backend:  https://apiapi.jyze.space"
echo ""
echo -e "${BLUE}💡 Comandos úteis:${NC}"
echo -e "   - Ver serviços: ${YELLOW}docker service ls | grep $STACK_NAME${NC}"
echo -e "   - Ver logs frontend: ${YELLOW}docker service logs -f ${FRONTEND_SERVICE}${NC}"
echo -e "   - Ver logs backend: ${YELLOW}docker service logs -f ${BACKEND_SERVICE}${NC}"
echo -e "   - Ver status: ${YELLOW}docker service ps $STACK_NAME${NC}"
echo -e "   - Remover stack: ${YELLOW}docker stack rm $STACK_NAME${NC}"
echo ""
echo -e "${BLUE}🔍 Verificar Traefik:${NC}"
echo -e "   - Ver rotas: ${YELLOW}curl -s http://localhost:8080/api/http/routers | jq '.[] | select(.name | contains(\"imovelpro\"))'${NC}"
echo ""


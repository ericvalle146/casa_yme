#!/usr/bin/env bash

# Script para migrar de docker-compose para Docker Swarm Stack

set -euo pipefail

# Cores
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

echo -e "${GREEN}==> Migração: docker-compose para Docker Swarm Stack${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Verificar se está usando docker-compose
echo -e "${BLUE}1) Verificando containers existentes...${NC}"
if docker ps --format "{{.Names}}" | grep -q "imovelpro-frontend\|imovelpro-backend"; then
    echo -e "${YELLOW}⚠️  Containers do docker-compose encontrados${NC}"
    echo -e "${BLUE}   Vamos parar e remover antes de migrar para Swarm${NC}"
    echo ""
    
    read -p "Deseja continuar? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}   Migração cancelada${NC}"
        exit 0
    fi
else
    echo -e "${GREEN}✅ Nenhum container do docker-compose encontrado${NC}"
fi

# Parar containers do docker-compose
echo -e "${BLUE}2) Parando containers do docker-compose...${NC}"
if [ -f "docker-compose.yml" ]; then
    docker compose down 2>/dev/null || true
    echo -e "${GREEN}✅ Containers parados${NC}"
else
    echo -e "${YELLOW}⚠️  docker-compose.yml não encontrado${NC}"
fi

# Parar containers manualmente (caso o docker-compose não tenha funcionado)
echo -e "${BLUE}3) Removendo containers antigos...${NC}"
docker stop imovelpro-frontend imovelpro-backend 2>/dev/null || true
docker rm imovelpro-frontend imovelpro-backend 2>/dev/null || true
echo -e "${GREEN}✅ Containers removidos${NC}"

# Remover network antiga
echo -e "${BLUE}4) Removendo network antiga...${NC}"
docker network rm prototipo_mariana_imobiliarias_imovelpro-network 2>/dev/null || true
echo -e "${GREEN}✅ Network removida${NC}"

# Verificar Docker Swarm
echo -e "${BLUE}5) Verificando Docker Swarm...${NC}"
SWARM_STATE=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || echo "inactive")
if [ "$SWARM_STATE" != "active" ] && [ "$SWARM_STATE" != "manager" ]; then
    echo -e "${RED}❌ Docker Swarm não está ativo${NC}"
    echo -e "${YELLOW}   Ative com: docker swarm init${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker Swarm ativo${NC}"

# Verificar se a stack já existe
echo -e "${BLUE}6) Verificando stack existente...${NC}"
if docker stack ls --format "{{.Name}}" | grep -q "^imovelpro$"; then
    echo -e "${YELLOW}⚠️  Stack 'imovelpro' já existe${NC}"
    echo -e "${BLUE}   Vamos atualizar a stack${NC}"
else
    echo -e "${GREEN}✅ Stack 'imovelpro' não existe - será criada${NC}"
fi

echo ""
echo -e "${GREEN}✅ Migração preparada!${NC}"
echo ""
echo -e "${BLUE}📋 Próximos passos:${NC}"
echo -e "   1. Execute o deploy Swarm: ${YELLOW}./deploy/deploy-swarm.sh${NC}"
echo -e "   2. Verifique os serviços: ${YELLOW}docker service ls | grep imovelpro${NC}"
echo -e "   3. Verifique os logs: ${YELLOW}docker service logs -f imovelpro_frontend${NC}"
echo ""
read -p "Deseja executar o deploy agora? (S/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    if [ -f "./deploy/deploy-swarm.sh" ]; then
        echo ""
        ./deploy/deploy-swarm.sh
    else
        echo -e "${RED}❌ Script deploy-swarm.sh não encontrado${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}   Execute manualmente: ./deploy/deploy-swarm.sh${NC}"
fi


#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🚀 Deploy Standalone - ImóvelPro${NC}"
echo ""

# Verificar Docker
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker não encontrado${NC}"
    exit 1
fi

# Parar containers existentes
echo -e "${BLUE}1) Parando containers existentes...${NC}"
docker compose -f docker-compose.standalone.yml down 2>/dev/null || true
docker stop imovelpro-frontend imovelpro-backend 2>/dev/null || true
docker rm imovelpro-frontend imovelpro-backend 2>/dev/null || true

# Criar network independente
echo -e "${BLUE}2) Criando network independente...${NC}"
docker network rm imovelpro-network 2>/dev/null || true
docker network create --driver bridge --attachable imovelpro-network 2>/dev/null || true
echo -e "${GREEN}✅ Network criada${NC}"

# Verificar .env do backend
if [ ! -f "./server/.env" ]; then
    echo -e "${YELLOW}⚠️  Criando server/.env...${NC}"
    if [ -f "./server/env.example" ]; then
        cp ./server/env.example ./server/.env
    else
        echo "PORT=4000" > ./server/.env
        echo "CORS_ORIGINS=https://imob.locusup.shop" >> ./server/.env
        echo "NODE_ENV=production" >> ./server/.env
        echo "N8N_WEBHOOK_URL=https://seu-servidor-n8n.com/webhook/endpoint" >> ./server/.env
    fi
fi

# Build das imagens
echo -e "${BLUE}3) Build das imagens...${NC}"
docker compose -f docker-compose.standalone.yml build --no-cache

# Iniciar containers
echo -e "${BLUE}4) Iniciando containers...${NC}"
docker compose -f docker-compose.standalone.yml up -d

# Aguardar containers iniciarem
echo -e "${BLUE}5) Aguardando containers iniciarem...${NC}"
sleep 15

# Verificar status
echo -e "${BLUE}6) Verificando status...${NC}"
docker compose -f docker-compose.standalone.yml ps

# Testar endpoints
echo -e "${BLUE}7) Testando endpoints...${NC}"
if curl -s http://localhost:3429/health >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend: http://localhost:3429/health${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend não está respondendo${NC}"
fi

if curl -s http://localhost:4000/health >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend: http://localhost:4000/health${NC}"
else
    echo -e "${YELLOW}⚠️  Backend não está respondendo${NC}"
fi

# Conectar Traefik (se existir)
echo -e "${BLUE}8) Conectando Traefik (se existir)...${NC}"
if [ -f "./connect-traefik.sh" ]; then
    ./connect-traefik.sh
else
    TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
    if [ ! -z "$TRAEFIK_CONTAINER" ]; then
        docker network connect imovelpro-network "$TRAEFIK_CONTAINER" 2>/dev/null && \
        docker restart "$TRAEFIK_CONTAINER" 2>/dev/null || true
        echo -e "${GREEN}✅ Traefik conectado${NC}"
    fi
fi

# Obter IP do host
HOST_IP=$(hostname -I | awk '{print $1}' || echo "localhost")
echo ""
echo -e "${GREEN}✅ Deploy concluído!${NC}"
echo ""
echo -e "${BLUE}📋 Informações:${NC}"
echo -e "   - Frontend: http://${HOST_IP}:3429"
echo -e "   - Backend: http://${HOST_IP}:4000"
echo -e "   - Network: imovelpro-network (independente)"
echo ""
echo -e "${BLUE}🌐 Domínios (se Traefik conectado):${NC}"
echo -e "   - https://imob.locusup.shop"
echo -e "   - https://apiapi.jyze.space/health"
echo ""
echo -e "${BLUE}💡 Comandos úteis:${NC}"
echo -e "   - Logs: ${YELLOW}docker compose -f docker-compose.standalone.yml logs -f${NC}"
echo -e "   - Parar: ${YELLOW}docker compose -f docker-compose.standalone.yml down${NC}"
echo -e "   - Status: ${YELLOW}docker compose -f docker-compose.standalone.yml ps${NC}"
echo -e "   - Conectar Traefik: ${YELLOW}./connect-traefik.sh${NC}"


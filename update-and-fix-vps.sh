#!/bin/bash

# Script para atualizar código e corrigir network vpsnet na VPS
# Execute este script na VPS após fazer git pull

set -e

echo "🔄 Atualizando código e corrigindo configuração na VPS..."
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Atualizar código do GitHub
echo -e "${BLUE}1. Atualizando código do GitHub...${NC}"
if git pull origin main; then
    echo -e "${GREEN}✅ Código atualizado${NC}"
else
    echo -e "${RED}❌ Erro ao atualizar código${NC}"
    echo -e "${YELLOW}   Verifique sua conexão e credenciais do GitHub${NC}"
    exit 1
fi

echo ""

# 2. Parar containers do projeto
echo -e "${BLUE}2. Parando containers do projeto...${NC}"
if docker compose down 2>/dev/null; then
    echo -e "${GREEN}✅ Containers parados${NC}"
else
    echo -e "${YELLOW}⚠️  Nenhum container para parar ou erro ao parar${NC}"
fi

echo ""

# 3. Verificar se está usando Docker Swarm
echo -e "${BLUE}3. Verificando Docker Swarm...${NC}"
if docker stack ls >/dev/null 2>&1; then
    STACKS=$(docker stack ls --format "{{.Name}}" | grep -v "NAME" || echo "")
    if [ ! -z "$STACKS" ]; then
        echo -e "${YELLOW}⚠️  Docker Swarm detectado com os seguintes stacks:${NC}"
        echo "$STACKS" | while read stack; do
            echo -e "   - ${stack}"
        done
        echo ""
        echo -e "${YELLOW}   Você precisa parar os stacks manualmente antes de continuar${NC}"
        echo -e "${YELLOW}   Execute: docker stack rm <nome-do-stack>${NC}"
        echo ""
        read -p "Deseja continuar mesmo assim? (s/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            echo -e "${RED}   Operação cancelada${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ Docker Swarm não está em uso ou não há stacks rodando${NC}"
    fi
else
    echo -e "${GREEN}✅ Docker Swarm não está configurado${NC}"
fi

echo ""

# 4. Listar containers que usam vpsnet
echo -e "${BLUE}4. Verificando containers na network vpsnet...${NC}"
if docker network inspect vpsnet >/dev/null 2>&1; then
    CONTAINERS_IN_VPSNET=$(docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")
    if [ ! -z "$CONTAINERS_IN_VPSNET" ]; then
        echo -e "${YELLOW}⚠️  Containers na network vpsnet:${NC}"
        echo "$CONTAINERS_IN_VPSNET" | tr ' ' '\n' | while read container; do
            if [ ! -z "$container" ]; then
                echo -e "   - ${container}"
            fi
        done
        echo ""
        echo -e "${YELLOW}   Estes containers precisam ser parados antes de remover a network${NC}"
        echo -e "${YELLOW}   Você pode parar manualmente ou continuar (a network será removida mesmo assim)${NC}"
        echo ""
        read -p "Deseja continuar? (s/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            echo -e "${RED}   Operação cancelada${NC}"
            exit 1
        fi
        
        # Tentar desconectar containers
        echo "$CONTAINERS_IN_VPSNET" | tr ' ' '\n' | while read container; do
            if [ ! -z "$container" ]; then
                echo -e "${YELLOW}   Desconectando ${container}...${NC}"
                docker network disconnect vpsnet "$container" 2>/dev/null || true
            fi
        done
    else
        echo -e "${GREEN}✅ Nenhum container na network vpsnet${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Network vpsnet não existe${NC}"
fi

echo ""

# 5. Remover network vpsnet
echo -e "${BLUE}5. Removendo network vpsnet...${NC}"
if docker network inspect vpsnet >/dev/null 2>&1; then
    if docker network rm vpsnet 2>/dev/null; then
        echo -e "${GREEN}✅ Network vpsnet removida${NC}"
    else
        echo -e "${RED}❌ Erro ao remover network vpsnet${NC}"
        echo -e "${YELLOW}   A network pode estar em uso. Verifique manualmente:${NC}"
        echo -e "${YELLOW}   docker network inspect vpsnet${NC}"
        echo -e "${YELLOW}   docker network rm vpsnet --force${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Network vpsnet já não existe${NC}"
fi

echo ""

# 6. Recriar network vpsnet como attachable
echo -e "${BLUE}6. Recriando network vpsnet como attachable...${NC}"
if docker network create --driver bridge --attachable vpsnet 2>/dev/null; then
    echo -e "${GREEN}✅ Network vpsnet recriada como attachable${NC}"
    
    # Verificar se foi criada corretamente
    IS_ATTACHABLE=$(docker network inspect vpsnet --format '{{.Attachable}}' 2>/dev/null || echo "false")
    if [ "$IS_ATTACHABLE" = "true" ]; then
        echo -e "${GREEN}✅ Network vpsnet confirmada como attachable${NC}"
    else
        echo -e "${RED}❌ ERRO: Network vpsnet não é attachable após criação${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Erro ao criar network vpsnet${NC}"
    exit 1
fi

echo ""

# 7. Reconectar Traefik à network vpsnet (se existir)
echo -e "${BLUE}7. Verificando Traefik...${NC}"
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ ! -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${GREEN}✅ Traefik encontrado: ${TRAEFIK_CONTAINER}${NC}"
    
    # Verificar se está na network vpsnet
    TRAEFIK_NETWORKS=$(docker inspect $TRAEFIK_CONTAINER --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}' 2>/dev/null || echo "")
    if echo "$TRAEFIK_NETWORKS" | grep -q "vpsnet"; then
        echo -e "${GREEN}✅ Traefik já está na network vpsnet${NC}"
    else
        echo -e "${YELLOW}⚠️  Conectando Traefik à network vpsnet...${NC}"
        if docker network connect vpsnet $TRAEFIK_CONTAINER 2>/dev/null; then
            echo -e "${GREEN}✅ Traefik conectado à network vpsnet${NC}"
        else
            echo -e "${YELLOW}⚠️  Erro ao conectar Traefik (pode já estar conectado)${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  Traefik não encontrado${NC}"
    echo -e "${YELLOW}   Se você usar Traefik, certifique-se de conectá-lo à network vpsnet${NC}"
fi

echo ""

# 8. Executar deploy
echo -e "${BLUE}8. Executando deploy...${NC}"
echo -e "${YELLOW}   Execute: ./deploy.sh${NC}"
echo ""
read -p "Deseja executar o deploy agora? (S/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    if [ -f "./deploy.sh" ]; then
        chmod +x ./deploy.sh
        ./deploy.sh
    else
        echo -e "${RED}❌ Script deploy.sh não encontrado${NC}"
    fi
else
    echo -e "${YELLOW}   Execute manualmente: ./deploy.sh${NC}"
fi

echo ""
echo -e "${GREEN}✅ Atualização e correção concluídas!${NC}"
echo ""
echo -e "${BLUE}📝 Próximos passos:${NC}"
echo -e "   1. Verificar se os containers estão rodando: docker compose ps"
echo -e "   2. Verificar se estão na network vpsnet: docker network inspect vpsnet"
echo -e "   3. Executar diagnóstico: ./diagnose-traefik.sh"
echo -e "   4. Testar domínios: curl -I https://imob.locusup.shop"


#!/bin/bash

# Script SEGURO para atualizar código e corrigir network vpsnet na VPS
# NÃO para stacks do Docker Swarm - apenas conecta containers manualmente

set -e

echo "🔄 Atualizando código e corrigindo configuração na VPS (MODO SEGURO)..."
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

# 2. Parar apenas containers do projeto (não stacks)
echo -e "${BLUE}2. Parando containers do projeto...${NC}"
if docker compose down 2>/dev/null; then
    echo -e "${GREEN}✅ Containers do projeto parados${NC}"
else
    echo -e "${YELLOW}⚠️  Nenhum container do projeto para parar${NC}"
fi

echo ""

# 3. Verificar network vpsnet
echo -e "${BLUE}3. Verificando network vpsnet...${NC}"
if docker network inspect vpsnet >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Network vpsnet existe${NC}"
    
    IS_ATTACHABLE=$(docker network inspect vpsnet --format '{{.Attachable}}' 2>/dev/null || echo "false")
    DRIVER=$(docker network inspect vpsnet --format '{{.Driver}}' 2>/dev/null || echo "unknown")
    SCOPE=$(docker network inspect vpsnet --format '{{.Scope}}' 2>/dev/null || echo "local")
    
    echo -e "   Driver: ${DRIVER}"
    echo -e "   Scope: ${SCOPE}"
    echo -e "   Attachable: ${IS_ATTACHABLE}"
    
    # Verificar se foi criada pelo Docker Swarm
    if [ "$SCOPE" = "swarm" ] || [ "$DRIVER" = "overlay" ]; then
        echo -e "${YELLOW}⚠️  Network vpsnet foi criada pelo Docker Swarm${NC}"
        echo -e "${YELLOW}   Não podemos removê-la sem parar os stacks${NC}"
        echo -e "${BLUE}   Solução: Vamos usar conexão manual dos containers${NC}"
        echo ""
        echo -e "${YELLOW}   IMPORTANTE: O docker-compose.yml foi modificado para conectar${NC}"
        echo -e "${YELLOW}   os containers manualmente após iniciar, já que a network não é attachable${NC}"
        USE_MANUAL_CONNECTION=true
    elif [ "$IS_ATTACHABLE" != "true" ]; then
        echo -e "${YELLOW}⚠️  Network vpsnet não é attachable${NC}"
        echo -e "${YELLOW}   Mas não podemos removê-la (pode estar em uso por outros serviços)${NC}"
        echo -e "${BLUE}   Solução: Vamos usar conexão manual dos containers${NC}"
        USE_MANUAL_CONNECTION=true
    else
        echo -e "${GREEN}✅ Network vpsnet é attachable - containers se conectarão automaticamente${NC}"
        USE_MANUAL_CONNECTION=false
    fi
else
    echo -e "${YELLOW}⚠️  Network vpsnet não existe${NC}"
    echo -e "${BLUE}   Criando network vpsnet como attachable...${NC}"
    if docker network create --driver bridge --attachable vpsnet 2>/dev/null; then
        echo -e "${GREEN}✅ Network vpsnet criada como attachable${NC}"
        USE_MANUAL_CONNECTION=false
    else
        echo -e "${RED}❌ Erro ao criar network vpsnet${NC}"
        exit 1
    fi
fi

echo ""

# 4. Modificar docker-compose.yml para remover network vpsnet como external se necessário
if [ "$USE_MANUAL_CONNECTION" = "true" ]; then
    echo -e "${BLUE}4. Ajustando docker-compose.yml para conexão manual...${NC}"
    
    # Verificar se docker-compose.yml tem vpsnet como external
    if grep -q "vpsnet:" docker-compose.yml && grep -q "external: true" docker-compose.yml; then
        echo -e "${YELLOW}⚠️  docker-compose.yml tem vpsnet como external${NC}"
        echo -e "${YELLOW}   Isso pode causar erro se a network não for attachable${NC}"
        echo -e "${BLUE}   Vamos criar uma versão temporária sem vpsnet como external...${NC}"
        
        # Criar backup
        cp docker-compose.yml docker-compose.yml.backup
        
        # Remover vpsnet das networks dos serviços temporariamente
        # (vamos adicionar de volta depois via conexão manual)
        echo -e "${YELLOW}   Criando docker-compose.temp.yml sem vpsnet...${NC}"
        
        # Criar arquivo temporário sem vpsnet
        sed '/vpsnet:/,/name: vpsnet/d' docker-compose.yml | \
        sed '/- vpsnet$/d' > docker-compose.temp.yml
        
        # Verificar se o arquivo foi criado corretamente
        if [ -f docker-compose.temp.yml ]; then
            echo -e "${GREEN}✅ Arquivo temporário criado${NC}"
            USE_TEMP_COMPOSE=true
        else
            echo -e "${YELLOW}⚠️  Não foi possível criar arquivo temporário${NC}"
            echo -e "${YELLOW}   Continuando com docker-compose.yml original...${NC}"
            USE_TEMP_COMPOSE=false
        fi
    else
        USE_TEMP_COMPOSE=false
    fi
else
    USE_TEMP_COMPOSE=false
fi

echo ""

# 5. Executar deploy
echo -e "${BLUE}5. Executando deploy...${NC}"

if [ "$USE_TEMP_COMPOSE" = "true" ]; then
    echo -e "${YELLOW}   Usando docker-compose.temp.yml (sem vpsnet como external)...${NC}"
    DOCKER_COMPOSE_CMD="docker compose -f docker-compose.temp.yml"
else
    DOCKER_COMPOSE_CMD="docker compose"
fi

# Modificar deploy.sh temporariamente para usar o comando correto
if [ "$USE_MANUAL_CONNECTION" = "true" ]; then
    echo -e "${YELLOW}   Modo de conexão manual ativado${NC}"
    
    # Iniciar containers sem vpsnet
    if [ "$USE_TEMP_COMPOSE" = "true" ]; then
        if $DOCKER_COMPOSE_CMD up -d; then
            echo -e "${GREEN}✅ Containers iniciados${NC}"
        else
            echo -e "${RED}❌ Erro ao iniciar containers${NC}"
            # Restaurar backup
            if [ -f docker-compose.yml.backup ]; then
                mv docker-compose.yml.backup docker-compose.yml
            fi
            exit 1
        fi
    else
        # Tentar iniciar normalmente - pode falhar se vpsnet não for attachable
        if $DOCKER_COMPOSE_CMD up -d 2>&1 | grep -q "network vpsnet"; then
            echo -e "${YELLOW}⚠️  Erro: network vpsnet não é attachable${NC}"
            echo -e "${BLUE}   Vamos conectar os containers manualmente...${NC}"
        else
            if $DOCKER_COMPOSE_CMD up -d; then
                echo -e "${GREEN}✅ Containers iniciados${NC}"
            else
                echo -e "${RED}❌ Erro ao iniciar containers${NC}"
                exit 1
            fi
        fi
    fi
    
    # Conectar containers manualmente à network vpsnet
    echo -e "${BLUE}   Conectando containers à network vpsnet manualmente...${NC}"
    
    sleep 2  # Aguardar containers iniciarem
    
    if docker ps --format "{{.Names}}" | grep -q "imovelpro-frontend"; then
        if docker network connect vpsnet imovelpro-frontend 2>/dev/null; then
            echo -e "${GREEN}✅ Frontend conectado à vpsnet${NC}"
        else
            echo -e "${YELLOW}⚠️  Frontend já estava conectado ou erro${NC}"
        fi
    fi
    
    if docker ps --format "{{.Names}}" | grep -q "imovelpro-backend"; then
        if docker network connect vpsnet imovelpro-backend 2>/dev/null; then
            echo -e "${GREEN}✅ Backend conectado à vpsnet${NC}"
        else
            echo -e "${YELLOW}⚠️  Backend já estava conectado ou erro${NC}"
        fi
    fi
    
    # Restaurar docker-compose.yml original
    if [ -f docker-compose.yml.backup ]; then
        mv docker-compose.yml.backup docker-compose.yml
        echo -e "${GREEN}✅ docker-compose.yml restaurado${NC}"
    fi
    
    # Remover arquivo temporário
    if [ -f docker-compose.temp.yml ]; then
        rm docker-compose.temp.yml
    fi
else
    # Network é attachable - usar deploy normal
    if [ -f "./deploy.sh" ]; then
        chmod +x ./deploy.sh
        ./deploy.sh
    else
        echo -e "${RED}❌ Script deploy.sh não encontrado${NC}"
        exit 1
    fi
fi

echo ""

# 6. Verificar conexão
echo -e "${BLUE}6. Verificando conexão dos containers...${NC}"
if docker network inspect vpsnet >/dev/null 2>&1; then
    CONTAINERS_IN_VPSNET=$(docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")
    
    if echo "$CONTAINERS_IN_VPSNET" | grep -q "imovelpro-frontend"; then
        echo -e "${GREEN}✅ Frontend está na network vpsnet${NC}"
    else
        echo -e "${RED}❌ Frontend NÃO está na network vpsnet${NC}"
    fi
    
    if echo "$CONTAINERS_IN_VPSNET" | grep -q "imovelpro-backend"; then
        echo -e "${GREEN}✅ Backend está na network vpsnet${NC}"
    else
        echo -e "${RED}❌ Backend NÃO está na network vpsnet${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✅ Atualização concluída!${NC}"
echo ""
echo -e "${BLUE}📝 Próximos passos:${NC}"
echo -e "   1. Verificar containers: docker compose ps"
echo -e "   2. Verificar network: docker network inspect vpsnet"
echo -e "   3. Executar diagnóstico: ./diagnose-traefik.sh"
echo -e "   4. Testar domínios: curl -I https://imob.locusup.shop"





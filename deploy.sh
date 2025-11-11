#!/bin/bash

set -e

echo "🚀 Iniciando deploy automático do ImóvelPro..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para instalar Docker
install_docker() {
    echo -e "${YELLOW}📦 Instalando Docker...${NC}"
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    sudo usermod -aG docker $USER
    rm /tmp/get-docker.sh
    echo -e "${GREEN}✅ Docker instalado${NC}"
}

# Função para instalar Docker Compose
install_docker_compose() {
    echo -e "${YELLOW}📦 Instalando Docker Compose...${NC}"
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✅ Docker Compose instalado${NC}"
}

# Função para instalar Nginx
install_nginx() {
    echo -e "${YELLOW}📦 Instalando Nginx...${NC}"
    sudo apt update -qq
    sudo apt install -y nginx
    sudo systemctl enable nginx
    echo -e "${GREEN}✅ Nginx instalado${NC}"
}

# Função para instalar Certbot
install_certbot() {
    echo -e "${YELLOW}📦 Instalando Certbot...${NC}"
    sudo apt install -y certbot python3-certbot-nginx
    echo -e "${GREEN}✅ Certbot instalado${NC}"
}

# Verificar e instalar Docker
if ! command_exists docker; then
    echo -e "${YELLOW}⚠️  Docker não encontrado. Instalando...${NC}"
    install_docker
    echo -e "${YELLOW}⚠️  Você precisará fazer logout/login ou executar: newgrp docker${NC}"
    newgrp docker || true
else
    echo -e "${GREEN}✅ Docker encontrado${NC}"
fi

# Verificar e instalar Docker Compose
DOCKER_COMPOSE_CMD=""
if command_exists docker-compose; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo -e "${YELLOW}⚠️  Docker Compose não encontrado. Instalando...${NC}"
    install_docker_compose
    DOCKER_COMPOSE_CMD="docker-compose"
fi

echo -e "${GREEN}✅ Docker e Docker Compose prontos${NC}"
echo -e "${BLUE}ℹ️  Usando comando: ${DOCKER_COMPOSE_CMD}${NC}"

# Verificar se estamos no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ Arquivo docker-compose.yml não encontrado.${NC}"
    echo -e "${RED}   Execute este script na raiz do projeto.${NC}"
    exit 1
fi

# Verificar se diretório server existe
if [ ! -d "./server" ]; then
    echo -e "${RED}❌ Diretório server/ não encontrado.${NC}"
    exit 1
fi

# Criar arquivo .env do backend se não existir
if [ ! -f "./server/.env" ]; then
    echo -e "${YELLOW}⚠️  Arquivo server/.env não encontrado. Criando automaticamente...${NC}"
    
    if [ ! -f "./server/env.example" ]; then
        echo -e "${RED}❌ Arquivo server/env.example não encontrado.${NC}"
        exit 1
    fi
    
    cp ./server/env.example ./server/.env
    
    if [ ! -f "./server/.env" ]; then
        echo -e "${RED}❌ Erro ao criar arquivo server/.env${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Arquivo server/.env criado${NC}"
    echo -e "${YELLOW}⚠️  IMPORTANTE: Configure o N8N_WEBHOOK_URL no arquivo server/.env${NC}"
    echo ""
    echo -e "${BLUE}📝 Editando server/.env...${NC}"
    
    if command_exists nano; then
        nano ./server/.env
    elif command_exists vim; then
        vim ./server/.env
    elif command_exists vi; then
        vi ./server/.env
    else
        echo -e "${YELLOW}   Nenhum editor encontrado. Edite manualmente: ./server/.env${NC}"
        read -p "Pressione ENTER após configurar o arquivo server/.env..."
    fi
else
    echo -e "${GREEN}✅ Arquivo server/.env já existe${NC}"
fi

# Verificar se N8N_WEBHOOK_URL está configurado
if grep -q "https://seu-servidor-n8n.com/webhook/endpoint" ./server/.env 2>/dev/null; then
    echo -e "${YELLOW}⚠️  ATENÇÃO: N8N_WEBHOOK_URL ainda está com o valor padrão!${NC}"
    echo -e "${YELLOW}   Por favor, configure o webhook do N8N no arquivo server/.env${NC}"
    echo ""
    read -p "Deseja continuar mesmo assim? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}   Edite o arquivo: ./server/.env${NC}"
        exit 1
    fi
fi

# Verificar se o arquivo .env tem conteúdo válido
if [ ! -s "./server/.env" ]; then
    echo -e "${RED}❌ Arquivo server/.env está vazio.${NC}"
    exit 1
fi

# Parar containers existentes
echo -e "${YELLOW}🛑 Parando containers existentes...${NC}"
$DOCKER_COMPOSE_CMD down || true

# Build das imagens
echo -e "${GREEN}🔨 Construindo imagens Docker...${NC}"
if $DOCKER_COMPOSE_CMD build --no-cache; then
    echo -e "${GREEN}✅ Build concluído com sucesso${NC}"
else
    echo -e "${RED}❌ Erro ao construir imagens Docker${NC}"
    exit 1
fi

# Verificar network vpsnet (OBRIGATÓRIA para Traefik)
echo -e "${YELLOW}🔍 Verificando network vpsnet...${NC}"
USE_MANUAL_CONNECTION=false
VPSNET_EXISTS=false

if docker network inspect vpsnet >/dev/null 2>&1; then
    VPSNET_EXISTS=true
    IS_ATTACHABLE=$(docker network inspect vpsnet --format '{{.Attachable}}' 2>/dev/null || echo "false")
    SCOPE=$(docker network inspect vpsnet --format '{{.Scope}}' 2>/dev/null || echo "local")
    DRIVER=$(docker network inspect vpsnet --format '{{.Driver}}' 2>/dev/null || echo "unknown")
    
    echo -e "${BLUE}   Driver: ${DRIVER}${NC}"
    echo -e "${BLUE}   Scope: ${SCOPE}${NC}"
    echo -e "${BLUE}   Attachable: ${IS_ATTACHABLE}${NC}"
    
    if [ "$IS_ATTACHABLE" != "true" ]; then
        if [ "$SCOPE" = "swarm" ] || [ "$DRIVER" = "overlay" ]; then
            echo -e "${YELLOW}⚠️  Network vpsnet foi criada pelo Docker Swarm e não é attachable${NC}"
            echo -e "${BLUE}   Modo seguro: Containers serão conectados manualmente após iniciar${NC}"
            echo -e "${BLUE}   (NÃO vamos parar os stacks do Docker Swarm)${NC}"
        else
            echo -e "${YELLOW}⚠️  Network vpsnet não é attachable${NC}"
            echo -e "${BLUE}   Modo seguro: Containers serão conectados manualmente após iniciar${NC}"
        fi
        USE_MANUAL_CONNECTION=true
    else
        echo -e "${GREEN}✅ Network vpsnet encontrada e attachable${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Network vpsnet não encontrada. Criando...${NC}"
    if docker network create --driver bridge --attachable vpsnet 2>/dev/null; then
        echo -e "${GREEN}✅ Network vpsnet criada como attachable${NC}"
        VPSNET_EXISTS=true
    else
        echo -e "${RED}❌ Erro ao criar network vpsnet${NC}"
        echo -e "${YELLOW}   A network pode já existir com outro driver. Verifique manualmente.${NC}"
        exit 1
    fi
fi

# Iniciar containers
echo -e "${GREEN}🚀 Iniciando containers...${NC}"

if [ "$USE_MANUAL_CONNECTION" = "true" ] && [ "$VPSNET_EXISTS" = "true" ]; then
    # Modo seguro: usar docker-compose sem vpsnet como external
    echo -e "${BLUE}   Modo seguro: Criando containers sem vpsnet primeiro...${NC}"
    echo -e "${BLUE}   (Network vpsnet será conectada manualmente após iniciar)${NC}"
    
    # Usar arquivo docker-compose sem vpsnet se existir, senão criar temporário
    if [ -f "docker-compose.no-vpsnet.yml" ]; then
        COMPOSE_FILE="docker-compose.no-vpsnet.yml"
        echo -e "${BLUE}   Usando docker-compose.no-vpsnet.yml${NC}"
    else
        # Criar arquivo temporário sem vpsnet
        grep -v "vpsnet" docker-compose.yml | \
        grep -v "external: true" | \
        grep -v "name: vpsnet" > docker-compose.temp.yml 2>/dev/null || true
        COMPOSE_FILE="docker-compose.temp.yml"
        echo -e "${BLUE}   Criado docker-compose.temp.yml${NC}"
    fi
    
    # Tentar iniciar com arquivo sem vpsnet
    if $DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" up -d 2>&1; then
        echo -e "${GREEN}✅ Containers iniciados (sem vpsnet)${NC}"
        
        # Aguardar containers iniciarem
        sleep 5
        
        # Conectar containers manualmente à network vpsnet
        echo -e "${BLUE}   Conectando containers à network vpsnet manualmente...${NC}"
        
        FRONTEND_CONNECTED=false
        BACKEND_CONNECTED=false
        
        if docker ps --format "{{.Names}}" | grep -q "imovelpro-frontend"; then
            # Tentar conectar e capturar erro
            CONNECT_OUTPUT=$(docker network connect vpsnet imovelpro-frontend 2>&1)
            CONNECT_EXIT=$?
            
            if [ $CONNECT_EXIT -eq 0 ]; then
                echo -e "${GREEN}   ✅ Frontend conectado à vpsnet${NC}"
                FRONTEND_CONNECTED=true
            else
                # Verificar se já está conectado
                if echo "$CONNECT_OUTPUT" | grep -qE "(already|already exists)"; then
                    echo -e "${GREEN}   ✅ Frontend já estava conectado à vpsnet${NC}"
                    FRONTEND_CONNECTED=true
                else
                    echo -e "${RED}   ❌ Erro ao conectar Frontend: ${CONNECT_OUTPUT}${NC}"
                    echo -e "${YELLOW}   ⚠️  Networks overlay do Docker Swarm não permitem conexão de containers externos${NC}"
                    echo -e "${YELLOW}   ℹ️  Traefik precisará acessar os containers via IP/hostname do host${NC}"
                fi
            fi
        fi
        
        if docker ps --format "{{.Names}}" | grep -q "imovelpro-backend"; then
            # Tentar conectar e capturar erro
            CONNECT_OUTPUT=$(docker network connect vpsnet imovelpro-backend 2>&1)
            CONNECT_EXIT=$?
            
            if [ $CONNECT_EXIT -eq 0 ]; then
                echo -e "${GREEN}   ✅ Backend conectado à vpsnet${NC}"
                BACKEND_CONNECTED=true
            else
                # Verificar se já está conectado
                if echo "$CONNECT_OUTPUT" | grep -qE "(already|already exists)"; then
                    echo -e "${GREEN}   ✅ Backend já estava conectado à vpsnet${NC}"
                    BACKEND_CONNECTED=true
                else
                    echo -e "${RED}   ❌ Erro ao conectar Backend: ${CONNECT_OUTPUT}${NC}"
                    echo -e "${YELLOW}   ⚠️  Networks overlay do Docker Swarm não permitem conexão de containers externos${NC}"
                    echo -e "${YELLOW}   ℹ️  Traefik precisará acessar os containers via IP/hostname do host${NC}"
                fi
            fi
        fi
        
        # Remover arquivo temporário se foi criado
        if [ "$COMPOSE_FILE" = "docker-compose.temp.yml" ]; then
            rm -f docker-compose.temp.yml
        fi
        
        # Verificar se realmente estão conectados
        sleep 2
        echo -e "${BLUE}   Verificando conexão...${NC}"
        
        if docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null | grep -q "imovelpro-frontend"; then
            echo -e "${GREEN}   ✅ Frontend confirmado na network vpsnet${NC}"
            FRONTEND_CONNECTED=true
        else
            echo -e "${YELLOW}   ⚠️  Frontend NÃO está na network vpsnet${NC}"
        fi
        
        if docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null | grep -q "imovelpro-backend"; then
            echo -e "${GREEN}   ✅ Backend confirmado na network vpsnet${NC}"
            BACKEND_CONNECTED=true
        else
            echo -e "${YELLOW}   ⚠️  Backend NÃO está na network vpsnet${NC}"
        fi
        
        if [ "$FRONTEND_CONNECTED" = "false" ] || [ "$BACKEND_CONNECTED" = "false" ]; then
            echo -e "${YELLOW}⚠️  ATENÇÃO: Containers não conseguiram se conectar à network vpsnet${NC}"
            echo -e "${YELLOW}   Isso é normal para networks overlay do Docker Swarm${NC}"
            echo -e "${BLUE}   Solução: Configurar Traefik para acessar via host.docker.internal ou IP do host${NC}"
            echo -e "${BLUE}   OU tornar a network attachable no stack do Traefik${NC}"
        else
            echo -e "${GREEN}✅ Containers conectados à network vpsnet${NC}"
        fi
    else
        echo -e "${RED}❌ Erro ao iniciar containers${NC}"
        if [ "$COMPOSE_FILE" = "docker-compose.temp.yml" ]; then
            rm -f docker-compose.temp.yml
        fi
        exit 1
    fi
else
    # Modo normal: iniciar com docker-compose.yml original
    if $DOCKER_COMPOSE_CMD up -d; then
        echo -e "${GREEN}✅ Containers iniciados com sucesso${NC}"
        echo -e "${BLUE}ℹ️  Containers conectados automaticamente à network vpsnet via docker-compose.yml${NC}"
    else
        echo -e "${RED}❌ Erro ao iniciar containers${NC}"
        echo -e "${YELLOW}   Verifique se a network vpsnet existe e é attachable${NC}"
        echo -e "${YELLOW}   Execute: docker network inspect vpsnet${NC}"
        exit 1
    fi
fi

# Aguardar containers iniciarem
echo -e "${YELLOW}⏳ Aguardando containers iniciarem...${NC}"
sleep 20

# Verificar status dos containers
echo -e "${GREEN}📊 Status dos containers:${NC}"
$DOCKER_COMPOSE_CMD ps

# Verificar se os containers estão rodando
CONTAINER_STATUS=$($DOCKER_COMPOSE_CMD ps --format json 2>/dev/null || $DOCKER_COMPOSE_CMD ps 2>/dev/null)
if echo "$CONTAINER_STATUS" | grep -qE "(Up|running)" || [ -z "$CONTAINER_STATUS" ]; then
    RUNNING_COUNT=$($DOCKER_COMPOSE_CMD ps -q 2>/dev/null | wc -l)
    if [ "$RUNNING_COUNT" -lt 2 ]; then
        echo -e "${YELLOW}⚠️  Alguns containers podem não estar rodando. Verifique os logs.${NC}"
    else
        echo -e "${GREEN}✅ Todos os containers estão rodando${NC}"
    fi
fi

# Verificar se Traefik está rodando (usar recursos existentes)
echo -e "${GREEN}🔍 Verificando Traefik...${NC}"
TRAEFIK_RUNNING=$(docker ps --format "{{.Names}}" | grep -i traefik || echo "")
if [ ! -z "$TRAEFIK_RUNNING" ]; then
    echo -e "${GREEN}✅ Traefik detectado: ${TRAEFIK_RUNNING}${NC}"
    echo -e "${BLUE}ℹ️  Usando Traefik existente para proxy reverso${NC}"
    
    # Verificar se o Traefik está na network vpsnet
    TRAEFIK_NETWORKS=$(docker inspect $TRAEFIK_RUNNING --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}' 2>/dev/null || echo "")
    if echo "$TRAEFIK_NETWORKS" | grep -q "vpsnet"; then
        echo -e "${GREEN}✅ Traefik está na network vpsnet${NC}"
    else
        echo -e "${YELLOW}⚠️  Traefik não está na network vpsnet${NC}"
        echo -e "${YELLOW}   Networks do Traefik: ${TRAEFIK_NETWORKS}${NC}"
        echo -e "${YELLOW}   O Traefik precisa estar na network vpsnet para funcionar corretamente${NC}"
    fi
    
    # Verificar se os containers estão na network vpsnet
    echo -e "${BLUE}🔍 Verificando conexão dos containers à network vpsnet...${NC}"
    if docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null | grep -q "imovelpro-frontend"; then
        echo -e "${GREEN}✅ Frontend está na network vpsnet${NC}"
    else
        echo -e "${RED}❌ Frontend NÃO está na network vpsnet${NC}"
    fi
    if docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null | grep -q "imovelpro-backend"; then
        echo -e "${GREEN}✅ Backend está na network vpsnet${NC}"
    else
        echo -e "${RED}❌ Backend NÃO está na network vpsnet${NC}"
    fi
    
    echo -e "${BLUE}ℹ️  Os containers serão configurados com labels do Traefik${NC}"
    echo -e "${BLUE}ℹ️  Domínios configurados:${NC}"
    echo -e "${BLUE}   - Frontend: https://imob.locusup.shop${NC}"
    echo -e "${BLUE}   - Backend: https://apiapi.jyze.space${NC}"
    echo -e "${YELLOW}⚠️  Certifique-se de que os domínios apontam para o IP do servidor${NC}"
else
    echo -e "${YELLOW}⚠️  Traefik não encontrado. Verificando Nginx...${NC}"
    
    # Verificar se Nginx está rodando
    if sudo systemctl is-active --quiet nginx 2>/dev/null; then
        echo -e "${GREEN}✅ Nginx detectado e rodando${NC}"
        echo -e "${BLUE}ℹ️  Nginx já está configurado e funcionando${NC}"
    else
        echo -e "${YELLOW}⚠️  Nenhum proxy reverso detectado. Containers estarão acessíveis apenas nas portas 3429 e 4000${NC}"
    fi
fi

# Verificar se os domínios apontam para este servidor
echo -e "${BLUE}ℹ️  Verificando configuração de domínios...${NC}"
SERVER_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || hostname -I | awk '{print $1}')
echo -e "${BLUE}   IP do servidor: ${SERVER_IP}${NC}"
echo -e "${BLUE}   Certifique-se de que os domínios apontam para este IP${NC}"

# Verificar logs
echo -e "${GREEN}📋 Últimas linhas dos logs:${NC}"
$DOCKER_COMPOSE_CMD logs --tail=30

# Verificar health checks
echo -e "${GREEN}🏥 Verificando health checks...${NC}"
sleep 5

# Testar endpoints
echo -e "${GREEN}🧪 Testando endpoints...${NC}"
if curl -s http://localhost:3429/health >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend respondendo na porta 3429${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend não está respondendo na porta 3429${NC}"
fi

if curl -s http://localhost:4000/health >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend respondendo na porta 4000${NC}"
else
    echo -e "${YELLOW}⚠️  Backend não está respondendo na porta 4000${NC}"
fi

echo ""
echo -e "${GREEN}✅ Deploy concluído!${NC}"
echo ""
echo -e "${YELLOW}📝 Status Final:${NC}"
echo -e "   - Containers: $($DOCKER_COMPOSE_CMD ps -q 2>/dev/null | wc -l) rodando"
echo -e "   - Frontend: http://localhost:3429/health"
echo -e "   - Backend: http://localhost:4000/health"
echo -e "   - Nginx: $(sudo systemctl is-active nginx 2>/dev/null || echo 'inativo')"
echo ""
echo -e "${BLUE}💡 Comandos úteis:${NC}"
echo -e "   - Ver logs: ${DOCKER_COMPOSE_CMD} logs -f"
echo -e "   - Parar: ${DOCKER_COMPOSE_CMD} down"
echo -e "   - Reiniciar: ${DOCKER_COMPOSE_CMD} restart"
echo -e "   - Status: ${DOCKER_COMPOSE_CMD} ps"
echo ""
echo -e "${YELLOW}⚠️  Se os certificados SSL não foram configurados automaticamente, execute:${NC}"
echo -e "   sudo certbot --nginx -d imob.locusup.shop"
echo -e "   sudo certbot --nginx -d apiapi.jyze.space"
echo ""
echo -e "${GREEN}🎉 Tudo pronto!${NC}"

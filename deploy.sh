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

# Iniciar containers
echo -e "${GREEN}🚀 Iniciando containers...${NC}"
if $DOCKER_COMPOSE_CMD up -d; then
    echo -e "${GREEN}✅ Containers iniciados com sucesso${NC}"
else
    echo -e "${RED}❌ Erro ao iniciar containers${NC}"
    exit 1
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

# Verificar e instalar Nginx se necessário
if ! command_exists nginx; then
    echo -e "${YELLOW}⚠️  Nginx não encontrado. Instalando...${NC}"
    install_nginx
fi

# Criar diretórios do Nginx se não existirem
sudo mkdir -p /etc/nginx/sites-available
sudo mkdir -p /etc/nginx/sites-enabled

# Configurar Nginx automaticamente
echo -e "${GREEN}🔧 Configurando Nginx...${NC}"

# Parar Nginx temporariamente se estiver rodando na porta 80
if sudo systemctl is-active --quiet nginx; then
    echo -e "${YELLOW}🛑 Parando Nginx temporariamente...${NC}"
    sudo systemctl stop nginx || true
fi

# Copiar configuração do Nginx
sudo cp nginx-proxy.conf /etc/nginx/sites-available/imovelpro

# Criar link simbólico
sudo rm -f /etc/nginx/sites-enabled/imovelpro
sudo ln -sf /etc/nginx/sites-available/imovelpro /etc/nginx/sites-enabled/

# Remover configuração padrão
sudo rm -f /etc/nginx/sites-enabled/default

# Testar configuração do Nginx
echo -e "${GREEN}🔍 Testando configuração do Nginx...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuração do Nginx válida${NC}"
else
    echo -e "${RED}❌ Erro na configuração do Nginx. Verifique os erros acima.${NC}"
    sudo nginx -t
    exit 1
fi

# Verificar o que está usando a porta 80
echo -e "${YELLOW}🔍 Verificando o que está usando a porta 80...${NC}"
PORT_80_PID=$(sudo lsof -ti:80 2>/dev/null || sudo fuser 80/tcp 2>/dev/null | awk '{print $1}' || echo "")
if [ ! -z "$PORT_80_PID" ]; then
    echo -e "${YELLOW}⚠️  Porta 80 está em uso pelo processo: ${PORT_80_PID}${NC}"
    PORT_80_NAME=$(ps -p $PORT_80_PID -o comm= 2>/dev/null || echo "desconhecido")
    echo -e "${YELLOW}   Processo: ${PORT_80_NAME}${NC}"
    
    # Se for Nginx, parar
    if echo "$PORT_80_NAME" | grep -q "nginx"; then
        echo -e "${YELLOW}🛑 Parando Nginx...${NC}"
        sudo systemctl stop nginx 2>/dev/null || true
        sudo pkill -9 nginx 2>/dev/null || true
    # Se for Docker, verificar qual container
    elif echo "$PORT_80_NAME" | grep -q "docker"; then
        echo -e "${YELLOW}⚠️  Docker está usando a porta 80${NC}"
        echo -e "${YELLOW}   Verificando containers...${NC}"
        $DOCKER_COMPOSE_CMD ps | grep ":80->" || true
    else
        echo -e "${YELLOW}⚠️  Outro processo está usando a porta 80${NC}"
        echo -e "${YELLOW}   Parando processo...${NC}"
        sudo kill -9 $PORT_80_PID 2>/dev/null || true
    fi
    sleep 3
else
    echo -e "${GREEN}✅ Porta 80 está livre${NC}"
fi

# Parar Nginx se estiver rodando (para evitar conflitos)
echo -e "${YELLOW}🛑 Parando Nginx se estiver rodando...${NC}"
sudo systemctl stop nginx 2>/dev/null || true
sudo pkill -9 nginx 2>/dev/null || true
sleep 2

# Verificar novamente se a porta 80 está livre
PORT_80_CHECK=$(sudo lsof -ti:80 2>/dev/null || echo "")
if [ ! -z "$PORT_80_CHECK" ]; then
    echo -e "${RED}❌ Porta 80 ainda está em uso. Liberando forçadamente...${NC}"
    sudo fuser -k 80/tcp 2>/dev/null || true
    sleep 2
fi

# Iniciar Nginx
echo -e "${GREEN}🔄 Iniciando Nginx...${NC}"
if sudo systemctl start nginx; then
    echo -e "${GREEN}✅ Nginx iniciado com sucesso${NC}"
    sudo systemctl enable nginx
else
    echo -e "${RED}❌ Erro ao iniciar Nginx${NC}"
    sudo systemctl status nginx
    exit 1
fi

# Verificar se Nginx está rodando
sleep 3
if sudo systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ Nginx está rodando${NC}"
else
    echo -e "${RED}❌ Nginx não está rodando. Verificando logs...${NC}"
    sudo journalctl -u nginx --no-pager -n 20
    exit 1
fi

# Verificar e instalar Certbot se necessário
if ! command_exists certbot; then
    echo -e "${YELLOW}⚠️  Certbot não encontrado. Instalando...${NC}"
    install_certbot
fi

# Testar se os domínios estão acessíveis via HTTP primeiro
echo -e "${GREEN}🧪 Testando acesso HTTP aos domínios...${NC}"
sleep 2

if curl -s -o /dev/null -w "%{http_code}" http://localhost -H "Host: imob.locusup.shop" | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✅ Frontend acessível via HTTP${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend pode não estar acessível ainda${NC}"
fi

# Tentar obter certificados SSL automaticamente (não bloqueante)
echo -e "${GREEN}🔒 Tentando configurar SSL/HTTPS...${NC}"
echo -e "${YELLOW}⚠️  Isso pode pedir confirmação de email e aceitar termos...${NC}"

# Verificar se os domínios apontam para este servidor
echo -e "${BLUE}ℹ️  Verificando se os domínios apontam para este servidor...${NC}"
SERVER_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || hostname -I | awk '{print $1}')
echo -e "${BLUE}   IP do servidor: ${SERVER_IP}${NC}"
echo -e "${BLUE}   Certifique-se de que os domínios apontam para este IP${NC}"

# Obter certificado para frontend (não bloqueante)
echo -e "${YELLOW}   Tentando obter certificado para imob.locusup.shop...${NC}"
if sudo certbot --nginx -d imob.locusup.shop --non-interactive --agree-tos --email admin@imob.locusup.shop --redirect --quiet 2>&1; then
    echo -e "${GREEN}✅ Certificado SSL para imob.locusup.shop configurado${NC}"
    sudo systemctl reload nginx
else
    echo -e "${YELLOW}⚠️  Não foi possível obter certificado SSL para imob.locusup.shop automaticamente${NC}"
    echo -e "${YELLOW}   Possíveis causas:${NC}"
    echo -e "${YELLOW}   - Domínio não aponta para este servidor${NC}"
    echo -e "${YELLOW}   - Porta 80 não está acessível externamente${NC}"
    echo -e "${YELLOW}   Execute manualmente: sudo certbot --nginx -d imob.locusup.shop${NC}"
fi

# Obter certificado para backend (não bloqueante)
echo -e "${YELLOW}   Tentando obter certificado para apiapi.jyze.space...${NC}"
if sudo certbot --nginx -d apiapi.jyze.space --non-interactive --agree-tos --email admin@imob.locusup.shop --redirect --quiet 2>&1; then
    echo -e "${GREEN}✅ Certificado SSL para apiapi.jyze.space configurado${NC}"
    sudo systemctl reload nginx
else
    echo -e "${YELLOW}⚠️  Não foi possível obter certificado SSL para apiapi.jyze.space automaticamente${NC}"
    echo -e "${YELLOW}   Execute manualmente: sudo certbot --nginx -d apiapi.jyze.space${NC}"
fi

# Verificar logs
echo -e "${GREEN}📋 Últimas linhas dos logs:${NC}"
$DOCKER_COMPOSE_CMD logs --tail=30

# Verificar health checks
echo -e "${GREEN}🏥 Verificando health checks...${NC}"
sleep 5

# Testar endpoints
echo -e "${GREEN}🧪 Testando endpoints...${NC}"
if curl -s http://localhost:8080/health >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend respondendo na porta 8080${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend não está respondendo na porta 8080${NC}"
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
echo -e "   - Frontend: http://localhost:8080/health"
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

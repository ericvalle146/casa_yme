#!/bin/bash

set -e

echo "🚀 Iniciando deploy do ImóvelPro..."

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

# Verificar se Docker está instalado
if ! command_exists docker; then
    echo -e "${RED}❌ Docker não está instalado. Por favor, instale o Docker primeiro.${NC}"
    exit 1
fi

# Verificar se Docker Compose está instalado (tenta ambas as versões)
DOCKER_COMPOSE_CMD=""
if command_exists docker-compose; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo -e "${RED}❌ Docker Compose não está instalado. Por favor, instale o Docker Compose primeiro.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker e Docker Compose encontrados${NC}"
echo -e "${BLUE}ℹ️  Usando comando: ${DOCKER_COMPOSE_CMD}${NC}"

# Verificar se estamos no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ Arquivo docker-compose.yml não encontrado.${NC}"
    echo -e "${RED}   Execute este script na raiz do projeto.${NC}"
    exit 1
fi

# Criar diretório server se não existir
if [ ! -d "./server" ]; then
    echo -e "${RED}❌ Diretório server/ não encontrado.${NC}"
    exit 1
fi

# Criar arquivo .env do backend se não existir
if [ ! -f "./server/.env" ]; then
    echo -e "${YELLOW}⚠️  Arquivo server/.env não encontrado. Criando automaticamente...${NC}"
    
    # Verificar se existe o arquivo de exemplo
    if [ ! -f "./server/env.example" ]; then
        echo -e "${RED}❌ Arquivo server/env.example não encontrado.${NC}"
        exit 1
    fi
    
    # Criar o arquivo .env a partir do exemplo
    cp ./server/env.example ./server/.env
    
    # Verificar se o arquivo foi criado
    if [ ! -f "./server/.env" ]; then
        echo -e "${RED}❌ Erro ao criar arquivo server/.env${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Arquivo server/.env criado com sucesso${NC}"
    echo -e "${YELLOW}⚠️  IMPORTANTE: Configure o N8N_WEBHOOK_URL no arquivo server/.env${NC}"
    echo ""
    echo -e "${BLUE}📝 Abrindo arquivo para edição...${NC}"
    echo ""
    
    # Tentar abrir o arquivo com editor padrão
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

# Verificar se N8N_WEBHOOK_URL está configurado corretamente
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

# Remover imagens antigas (opcional)
read -p "Deseja remover imagens antigas antes do build? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}🗑️  Removendo imagens antigas...${NC}"
    $DOCKER_COMPOSE_CMD down --rmi all || true
fi

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
sleep 15

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
else
    echo -e "${YELLOW}⚠️  Verifique o status dos containers manualmente${NC}"
fi

# Verificar logs
echo -e "${GREEN}📋 Últimas linhas dos logs:${NC}"
$DOCKER_COMPOSE_CMD logs --tail=50

# Verificar health checks
echo -e "${GREEN}🏥 Verificando health checks...${NC}"
sleep 5
$DOCKER_COMPOSE_CMD ps

echo ""
echo -e "${GREEN}✅ Deploy concluído!${NC}"
echo ""
echo -e "${YELLOW}📝 Próximos passos:${NC}"
echo -e "   1. Configure o Nginx na VPS para apontar para o container frontend (porta 80)"
echo -e "   2. Configure o SSL/HTTPS para os domínios:"
echo -e "      - Frontend: https://imob.locusup.shop"
echo -e "      - Backend: https://apiapi.jyze.space"
echo -e "   3. Verifique os logs com: ${DOCKER_COMPOSE_CMD} logs -f"
echo -e "   4. Acesse o frontend em: http://$(hostname -I 2>/dev/null | awk '{print $1}' || echo 'localhost')"
echo ""
echo -e "${BLUE}💡 Comandos úteis:${NC}"
echo -e "   - Ver logs: ${DOCKER_COMPOSE_CMD} logs -f"
echo -e "   - Parar: ${DOCKER_COMPOSE_CMD} down"
echo -e "   - Reiniciar: ${DOCKER_COMPOSE_CMD} restart"
echo -e "   - Status: ${DOCKER_COMPOSE_CMD} ps"
echo ""
echo -e "${GREEN}🎉 Tudo pronto!${NC}"


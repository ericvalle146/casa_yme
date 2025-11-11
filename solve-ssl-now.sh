#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔧 SOLUÇÃO RÁPIDA PARA SSL${NC}"
echo -e "${GREEN}============================${NC}"
echo ""

# Verificar se está na VPS
if [ ! -f /etc/os-release ]; then
    echo -e "${RED}❌ Este script deve ser executado na VPS!${NC}"
    exit 1
fi

echo -e "${BLUE}1) Verificando acesso ao Traefik...${NC}"

# Encontrar Traefik
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Traefik não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik encontrado: ${TRAEFIK_CONTAINER}${NC}"

# Verificar se é serviço do Swarm
TRAEFIK_SERVICE=$(docker ps --filter "name=$TRAEFIK_CONTAINER" --format "{{.Label \"com.docker.swarm.service.name\"}}" || echo "")
if [ ! -z "$TRAEFIK_SERVICE" ]; then
    echo -e "${BLUE}   Traefik é um serviço do Swarm: ${TRAEFIK_SERVICE}${NC}"
    
    # Tentar encontrar o stack
    STACK_NAME=$(echo "$TRAEFIK_SERVICE" | cut -d'_' -f1)
    echo -e "${BLUE}   Stack provável: ${STACK_NAME}${NC}"
    
    # Verificar se há arquivo docker-compose ou stack file
    if [ -f "/root/${STACK_NAME}/docker-compose.yml" ]; then
        echo -e "${GREEN}✅ Arquivo docker-compose encontrado: /root/${STACK_NAME}/docker-compose.yml${NC}"
        TRAEFIK_COMPOSE_FILE="/root/${STACK_NAME}/docker-compose.yml"
    elif [ -f "/opt/${STACK_NAME}/docker-compose.yml" ]; then
        echo -e "${GREEN}✅ Arquivo docker-compose encontrado: /opt/${STACK_NAME}/docker-compose.yml${NC}"
        TRAEFIK_COMPOSE_FILE="/opt/${STACK_NAME}/docker-compose.yml"
    elif [ -f "/home/${STACK_NAME}/docker-compose.yml" ]; then
        echo -e "${GREEN}✅ Arquivo docker-compose encontrado: /home/${STACK_NAME}/docker-compose.yml${NC}"
        TRAEFIK_COMPOSE_FILE="/home/${STACK_NAME}/docker-compose.yml"
    else
        echo -e "${YELLOW}⚠️  Arquivo docker-compose não encontrado${NC}"
        TRAEFIK_COMPOSE_FILE=""
    fi
else
    echo -e "${BLUE}   Traefik não é um serviço do Swarm (pode ser container standalone)${NC}"
    TRAEFIK_COMPOSE_FILE=""
fi

echo ""

# Verificar configuração atual do Traefik
echo -e "${BLUE}2) Verificando configuração atual do Traefik...${NC}"

# Verificar se há volumes do Traefik
TRAEFIK_VOLUMES=$(docker inspect "$TRAEFIK_CONTAINER" --format '{{range .Mounts}}{{.Source}} {{end}}' 2>/dev/null || echo "")
if [ ! -z "$TRAEFIK_VOLUMES" ]; then
    echo -e "${BLUE}   Volumes do Traefik:${NC}"
    echo "$TRAEFIK_VOLUMES" | tr ' ' '\n' | grep -v "^$" | while read volume; do
        echo -e "      - ${volume}"
    done
fi

# Verificar variáveis de ambiente do Traefik
echo -e "${BLUE}   Variáveis de ambiente do Traefik:${NC}"
docker inspect "$TRAEFIK_CONTAINER" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep -i "traefik\|acme\|letsencrypt\|email" | head -10 || echo "      Nenhuma variável relevante encontrada"

echo ""

# SOLUÇÃO 1: Verificar se podemos adicionar configuração via labels
echo -e "${BLUE}3) Tentando solução via File Provider...${NC}"

# Criar diretório para configuração do Traefik
TRAEFIK_CONFIG_DIR="/tmp/traefik-acme-config"
mkdir -p "$TRAEFIK_CONFIG_DIR"

# Criar arquivo de configuração do ACME
cat > "$TRAEFIK_CONFIG_DIR/acme.yml" << 'EOF'
certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@locusup.shop
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
EOF

echo -e "${GREEN}✅ Arquivo de configuração criado: ${TRAEFIK_CONFIG_DIR}/acme.yml${NC}"
echo ""

# SOLUÇÃO 2: Criar script para configurar Traefik via API
echo -e "${BLUE}4) Criando script para configurar Traefik...${NC}"

cat > /tmp/configure-traefik-acme.sh << 'SCRIPT'
#!/bin/bash
# Script para configurar ACME no Traefik

TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)

if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo "❌ Traefik não encontrado"
    exit 1
fi

echo "✅ Traefik encontrado: $TRAEFIK_CONTAINER"

# Verificar se o Traefik tem API habilitada
API_RESPONSE=$(curl -s http://localhost:8080/api/rawdata 2>&1 || echo "ERROR")

if echo "$API_RESPONSE" | grep -q "ERROR\|Failed\|Connection refused"; then
    echo "⚠️  API do Traefik não está acessível na porta 8080"
    echo "   O Traefik precisa ter a API habilitada para esta solução"
    exit 1
fi

echo "✅ API do Traefik está acessível"
SCRIPT

chmod +x /tmp/configure-traefik-acme.sh
echo -e "${GREEN}✅ Script criado: /tmp/configure-traefik-acme.sh${NC}"

echo ""

# SOLUÇÃO 3: Instruções para configurar manualmente
echo -e "${BLUE}5) SOLUÇÃO RECOMENDADA: Configurar Traefik manualmente${NC}"
echo ""
echo -e "${GREEN}📋 INSTRUÇÕES:${NC}"
echo ""
echo -e "${BLUE}Opção 1: Se você tem acesso ao stack do Traefik${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}1. Encontre o arquivo docker-compose.yml do Traefik${NC}"
echo -e "${YELLOW}2. Adicione a seguinte configuração:${NC}"
echo ""
cat << 'YAML'
certificatesResolvers:
  letsencrypt:
    acme:
      email: seu-email@exemplo.com
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
YAML

echo ""
echo -e "${YELLOW}3. Adicione volume para armazenar certificados:${NC}"
echo -e "${YELLOW}   volumes:${NC}"
echo -e "${YELLOW}     - /letsencrypt:/letsencrypt${NC}"
echo ""
echo -e "${YELLOW}4. Reinicie o Traefik:${NC}"
echo -e "${YELLOW}   docker stack deploy -c docker-compose.yml <stack-name>${NC}"
echo ""

echo -e "${BLUE}Opção 2: Usar Cloudflare (MAIS RÁPIDO)${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""
echo -e "${YELLOW}1. Crie uma conta no Cloudflare (grátis)${NC}"
echo -e "${YELLOW}2. Adicione seus domínios no Cloudflare${NC}"
echo -e "${YELLOW}3. Altere os nameservers dos domínios para os do Cloudflare${NC}"
echo -e "${YELLOW}4. Configure SSL/TLS como 'Flexible' ou 'Full'${NC}"
echo -e "${YELLOW}5. O Cloudflare fornece SSL automático (não precisa Let's Encrypt)${NC}"
echo ""

echo -e "${BLUE}Opção 3: Usar Certbot diretamente${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""
echo -e "${YELLOW}1. Instale o Certbot:${NC}"
echo -e "${YELLOW}   sudo apt update && sudo apt install certbot -y${NC}"
echo ""
echo -e "${YELLOW}2. Gere certificados:${NC}"
echo -e "${YELLOW}   sudo certbot certonly --standalone -d apiapi.jyze.space -d imob.locusup.shop${NC}"
echo ""
echo -e "${YELLOW}3. Configure o Traefik para usar os certificados${NC}"
echo ""

echo -e "${GREEN}✅ Script de diagnóstico criado!${NC}"
echo ""
echo -e "${BLUE}💡 PRÓXIMOS PASSOS:${NC}"
echo -e "${BLUE}   1. Escolha uma das opções acima${NC}"
echo -e "${BLUE}   2. Se escolher Cloudflare, é a solução mais rápida${NC}"
echo -e "${BLUE}   3. Se escolher configurar Traefik, precisa ter acesso ao stack${NC}"


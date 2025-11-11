#!/usr/bin/env bash

set -euo pipefail

# Cores
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Configurador de Traefik com Let's Encrypt (ACME)     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Solicitar email para Let's Encrypt
echo -e "${BLUE}Configuração do Let's Encrypt${NC}"
echo -e "${YELLOW}O Let's Encrypt requer um email para notificações de expiração${NC}"
read -p "Digite seu email: " LETSENCRYPT_EMAIL

if [ -z "$LETSENCRYPT_EMAIL" ]; then
    echo -e "${RED}❌ Email é obrigatório${NC}"
    exit 1
fi

echo ""

# Encontrar container do Traefik
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)

if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Container do Traefik não encontrado${NC}"
    echo -e "${YELLOW}   Certifique-se de que o Traefik está rodando${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik encontrado: ${YELLOW}$TRAEFIK_CONTAINER${NC}"
echo ""

# Verificar como o Traefik está configurado
echo -e "${BLUE}Verificando configuração atual do Traefik...${NC}"

# Tentar encontrar arquivo de configuração
TRAEFIK_CONFIG_PATH=""
POSSIBLE_PATHS=(
    "/etc/traefik/traefik.yml"
    "/traefik/traefik.yml"
    "./traefik.yml"
    "/opt/traefik/traefik.yml"
)

for path in "${POSSIBLE_PATHS[@]}"; do
    if docker exec "$TRAEFIK_CONTAINER" test -f "$path" 2>/dev/null; then
        TRAEFIK_CONFIG_PATH="$path"
        break
    fi
done

if [ -z "$TRAEFIK_CONFIG_PATH" ]; then
    echo -e "${YELLOW}⚠️  Não foi possível encontrar o arquivo de configuração do Traefik${NC}"
    echo -e "${YELLOW}   O Traefik pode estar usando labels do Docker ou variáveis de ambiente${NC}"
    echo ""
    echo -e "${BLUE}Para configurar o Traefik com Let's Encrypt, você precisa:${NC}"
    echo ""
    echo -e "${CYAN}1. Adicionar ao arquivo de configuração do Traefik (traefik.yml):${NC}"
    echo ""
    cat << 'EOF'
certificatesResolvers:
  letsencrypt:
    acme:
      email: SEU_EMAIL_AQUI
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
EOF
    echo ""
    echo -e "${CYAN}2. Criar o diretório para armazenar certificados:${NC}"
    echo -e "${YELLOW}   docker exec $TRAEFIK_CONTAINER mkdir -p /letsencrypt${NC}"
    echo -e "${YELLOW}   docker exec $TRAEFIK_CONTAINER chmod 600 /letsencrypt/acme.json${NC}"
    echo ""
    echo -e "${CYAN}3. Adicionar volume no docker compose/stack do Traefik:${NC}"
    echo -e "${YELLOW}   volumes:${NC}"
    echo -e "${YELLOW}     - ./letsencrypt:/letsencrypt${NC}"
    echo ""
    echo -e "${CYAN}4. Reiniciar o Traefik${NC}"
    echo ""
    exit 0
fi

echo -e "${GREEN}✅ Arquivo de configuração encontrado: ${YELLOW}$TRAEFIK_CONFIG_PATH${NC}"
echo ""

# Verificar se já tem ACME configurado
CURRENT_CONFIG=$(docker exec "$TRAEFIK_CONTAINER" cat "$TRAEFIK_CONFIG_PATH" 2>/dev/null || echo "")

if echo "$CURRENT_CONFIG" | grep -qi "certificatesResolvers\|letsencrypt\|acme"; then
    echo -e "${YELLOW}⚠️  O Traefik já parece ter ACME configurado${NC}"
    echo ""
    read -p "Deseja atualizar a configuração? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${BLUE}Operação cancelada${NC}"
        exit 0
    fi
fi

# Criar backup
echo -e "${BLUE}Criando backup da configuração...${NC}"
docker exec "$TRAEFIK_CONTAINER" cp "$TRAEFIK_CONFIG_PATH" "${TRAEFIK_CONFIG_PATH}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
echo -e "${GREEN}✅ Backup criado${NC}"
echo ""

# Gerar configuração ACME
echo -e "${BLUE}Gerando configuração ACME...${NC}"

ACME_CONFIG=$(cat << EOF
certificatesResolvers:
  letsencrypt:
    acme:
      email: ${LETSENCRYPT_EMAIL}
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
EOF
)

echo -e "${CYAN}Configuração ACME a ser adicionada:${NC}"
echo "$ACME_CONFIG"
echo ""

# Verificar se precisa adicionar ao arquivo
if ! echo "$CURRENT_CONFIG" | grep -qi "certificatesResolvers"; then
    echo -e "${YELLOW}⚠️  A configuração precisa ser adicionada manualmente${NC}"
    echo -e "${YELLOW}   O arquivo está dentro do container e pode precisar de montagem de volume${NC}"
    echo ""
    echo -e "${BLUE}Instruções:${NC}"
    echo -e "1. Adicione a configuração acima ao arquivo: ${YELLOW}$TRAEFIK_CONFIG_PATH${NC}"
    echo -e "2. Certifique-se de que o diretório /letsencrypt existe e tem permissões corretas"
    echo -e "3. Reinicie o Traefik"
    echo ""
else
    echo -e "${GREEN}✅ Configuração ACME já existe${NC}"
fi

# Verificar diretório de certificados
echo -e "${BLUE}Verificando diretório de certificados...${NC}"
if docker exec "$TRAEFIK_CONTAINER" test -d /letsencrypt 2>/dev/null; then
    echo -e "${GREEN}✅ Diretório /letsencrypt existe${NC}"
    
    # Verificar permissões do acme.json
    if docker exec "$TRAEFIK_CONTAINER" test -f /letsencrypt/acme.json 2>/dev/null; then
        PERMS=$(docker exec "$TRAEFIK_CONTAINER" stat -c "%a" /letsencrypt/acme.json 2>/dev/null || echo "unknown")
        echo -e "${BLUE}   Permissões do acme.json: ${PERMS}${NC}"
        
        if [ "$PERMS" != "600" ]; then
            echo -e "${YELLOW}⚠️  Recomendado: chmod 600 /letsencrypt/acme.json${NC}"
            read -p "Ajustar permissões? (s/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Ss]$ ]]; then
                docker exec "$TRAEFIK_CONTAINER" chmod 600 /letsencrypt/acme.json 2>/dev/null || true
                echo -e "${GREEN}✅ Permissões ajustadas${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  Arquivo acme.json não existe${NC}"
        echo -e "${BLUE}   Criando arquivo...${NC}"
        docker exec "$TRAEFIK_CONTAINER" touch /letsencrypt/acme.json 2>/dev/null || true
        docker exec "$TRAEFIK_CONTAINER" chmod 600 /letsencrypt/acme.json 2>/dev/null || true
        echo -e "${GREEN}✅ Arquivo criado${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Diretório /letsencrypt não existe${NC}"
    echo -e "${BLUE}   Criando diretório...${NC}"
    docker exec "$TRAEFIK_CONTAINER" mkdir -p /letsencrypt 2>/dev/null || true
    docker exec "$TRAEFIK_CONTAINER" touch /letsencrypt/acme.json 2>/dev/null || true
    docker exec "$TRAEFIK_CONTAINER" chmod 600 /letsencrypt/acme.json 2>/dev/null || true
    echo -e "${GREEN}✅ Diretório criado${NC}"
fi

echo ""

# Resumo
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                      RESUMO                                ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Próximos passos:${NC}"
echo ""
echo -e "1. ${YELLOW}Adicione a configuração ACME ao arquivo do Traefik${NC}"
echo -e "   Arquivo: ${CYAN}$TRAEFIK_CONFIG_PATH${NC}"
echo ""
echo -e "2. ${YELLOW}Certifique-se de que o volume está montado${NC}"
echo -e "   O diretório /letsencrypt precisa estar persistido"
echo ""
echo -e "3. ${YELLOW}Reinicie o Traefik${NC}"
echo -e "   ${CYAN}docker restart $TRAEFIK_CONTAINER${NC}"
echo ""
echo -e "4. ${YELLOW}Aguarde alguns minutos${NC}"
echo -e "   O Let's Encrypt pode levar alguns minutos para gerar os certificados"
echo ""
echo -e "5. ${YELLOW}Verifique os certificados${NC}"
echo -e "   Execute: ${CYAN}./verificar-traefik.sh${NC}"
echo ""


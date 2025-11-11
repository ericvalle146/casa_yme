#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔧 CONFIGURANDO TRAEFIK PARA LET'S ENCRYPT AUTOMATICAMENTE${NC}"
echo -e "${GREEN}========================================================${NC}"
echo ""

# Email para Let's Encrypt
ACME_EMAIL="${ACME_EMAIL:-admin@locusup.shop}"

echo -e "${BLUE}Email para Let's Encrypt: ${ACME_EMAIL}${NC}"
echo ""

# Encontrar Traefik
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Traefik não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik encontrado: ${TRAEFIK_CONTAINER}${NC}"

# Verificar se é serviço do Swarm
TRAEFIK_SERVICE=$(docker inspect "$TRAEFIK_CONTAINER" --format '{{index .Config.Labels "com.docker.swarm.service.name"}}' 2>/dev/null || echo "")
STACK_NAME=""

if [ ! -z "$TRAEFIK_SERVICE" ]; then
    STACK_NAME=$(echo "$TRAEFIK_SERVICE" | cut -d'_' -f1)
    echo -e "${BLUE}   Serviço Swarm: ${TRAEFIK_SERVICE}${NC}"
    echo -e "${BLUE}   Stack: ${STACK_NAME}${NC}"
fi

echo ""

# Procurar arquivo docker-compose.yml do Traefik em locais comuns
echo -e "${BLUE}1) Procurando arquivo de configuração do Traefik...${NC}"

POSSIBLE_LOCATIONS=(
    "/root/${STACK_NAME}"
    "/opt/${STACK_NAME}"
    "/home/${STACK_NAME}"
    "/root/traefik"
    "/opt/traefik"
    "/home/traefik"
    "/root"
    "/opt"
    "/home"
)

TRAEFIK_COMPOSE_FILE=""

for location in "${POSSIBLE_LOCATIONS[@]}"; do
    if [ -f "${location}/docker-compose.yml" ]; then
        # Verificar se é do Traefik
        if grep -q "traefik" "${location}/docker-compose.yml" 2>/dev/null; then
            TRAEFIK_COMPOSE_FILE="${location}/docker-compose.yml"
            echo -e "${GREEN}✅ Arquivo encontrado: ${TRAEFIK_COMPOSE_FILE}${NC}"
            break
        fi
    fi
    if [ -f "${location}/docker-stack.yml" ]; then
        if grep -q "traefik" "${location}/docker-stack.yml" 2>/dev/null; then
            TRAEFIK_COMPOSE_FILE="${location}/docker-stack.yml"
            echo -e "${GREEN}✅ Arquivo encontrado: ${TRAEFIK_COMPOSE_FILE}${NC}"
            break
        fi
    fi
done

if [ -z "$TRAEFIK_COMPOSE_FILE" ]; then
    echo -e "${YELLOW}⚠️  Arquivo docker-compose.yml do Traefik não encontrado${NC}"
    echo -e "${YELLOW}   Tentando outra abordagem...${NC}"
    
    # SOLUÇÃO ALTERNATIVA: Configurar via variáveis de ambiente
    echo ""
    echo -e "${BLUE}2) Tentando configurar via variáveis de ambiente...${NC}"
    
    # Criar script para atualizar o Traefik
    cat > /tmp/update-traefik-env.sh << SCRIPT
#!/bin/bash
# Atualizar Traefik com variáveis de ambiente para ACME

TRAEFIK_SERVICE="${TRAEFIK_SERVICE}"
STACK_NAME="${STACK_NAME}"

if [ -z "\$TRAEFIK_SERVICE" ] || [ -z "\$STACK_NAME" ]; then
    echo "❌ Não foi possível determinar serviço do Traefik"
    exit 1
fi

echo "⚠️  Esta solução requer acesso ao stack do Traefik"
echo "⚠️  Você precisa modificar o stack manualmente"
echo ""
echo "Adicione as seguintes variáveis de ambiente ao serviço do Traefik:"
echo ""
echo "  - TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_EMAIL=${ACME_EMAIL}"
echo "  - TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_STORAGE=/letsencrypt/acme.json"
echo "  - TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_HTTPCHALLENGE_ENTRYPOINT=web"
SCRIPT

    chmod +x /tmp/update-traefik-env.sh
    echo -e "${GREEN}✅ Script criado: /tmp/update-traefik-env.sh${NC}"
    
    echo ""
    echo -e "${RED}❌ NÃO FOI POSSÍVEL CONFIGURAR AUTOMATICAMENTE${NC}"
    echo ""
    echo -e "${YELLOW}SOLUÇÃO RÁPIDA: USE CLOUDFLARE${NC}"
    echo -e "${YELLOW}=====================================${NC}"
    echo ""
    echo -e "${BLUE}1. Acesse: https://dash.cloudflare.com${NC}"
    echo -e "${BLUE}2. Crie uma conta (grátis)${NC}"
    echo -e "${BLUE}3. Adicione seus domínios:${NC}"
    echo -e "${BLUE}   - apiapi.jyze.space${NC}"
    echo -e "${BLUE}   - imob.locusup.shop${NC}"
    echo -e "${BLUE}4. Altere os nameservers dos domínios para os do Cloudflare${NC}"
    echo -e "${BLUE}5. Configure SSL/TLS como 'Full' ou 'Flexible'${NC}"
    echo -e "${BLUE}6. Pronto! SSL automático sem configurar servidor${NC}"
    echo ""
    exit 1
fi

echo ""

# Backup do arquivo
echo -e "${BLUE}2) Fazendo backup do arquivo...${NC}"
BACKUP_FILE="${TRAEFIK_COMPOSE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$TRAEFIK_COMPOSE_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✅ Backup criado: ${BACKUP_FILE}${NC}"

echo ""

# Verificar se já tem ACME configurado
echo -e "${BLUE}3) Verificando se já tem ACME configurado...${NC}"
if grep -q "certificatesResolvers\|letsencrypt\|ACME" "$TRAEFIK_COMPOSE_FILE" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Parece que já tem alguma configuração de ACME${NC}"
    echo -e "${YELLOW}   Verificando se está correto...${NC}"
    
    if grep -q "certificatesResolvers.*letsencrypt" "$TRAEFIK_COMPOSE_FILE" 2>/dev/null; then
        echo -e "${GREEN}✅ ACME já está configurado!${NC}"
        echo -e "${BLUE}   Verifique se o email está correto e se o volume /letsencrypt está montado${NC}"
        exit 0
    fi
fi

echo ""

# Adicionar configuração do ACME
echo -e "${BLUE}4) Adicionando configuração do ACME...${NC}"

# Criar script Python para modificar o YAML
cat > /tmp/add-acme-to-traefik.py << 'PYTHON'
import yaml
import sys
import os

file_path = sys.argv[1]
email = sys.argv[2]

with open(file_path, 'r') as f:
    data = yaml.safe_load(f)

# Adicionar certificadosResolvers ao Traefik
if 'services' in data and 'traefik' in data['services']:
    traefik_service = data['services']['traefik']
    
    # Adicionar command ou modificar command existente
    if 'command' not in traefik_service:
        traefik_service['command'] = []
    
    commands = traefik_service['command'] if isinstance(traefik_service['command'], list) else traefik_service['command'].split()
    
    # Adicionar configuração do ACME
    acme_config = [
        '--certificatesresolvers.letsencrypt.acme.email=' + email,
        '--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json',
        '--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web'
    ]
    
    # Adicionar comandos se não existirem
    for cmd in acme_config:
        if not any(cmd.split('=')[0] in c for c in commands):
            commands.append(cmd)
    
    traefik_service['command'] = commands
    
    # Adicionar volume para /letsencrypt se não existir
    if 'volumes' not in traefik_service:
        traefik_service['volumes'] = []
    
    if not any('/letsencrypt' in str(v) for v in traefik_service['volumes']):
        traefik_service['volumes'].append('/letsencrypt:/letsencrypt')
    
    # Criar volume se não existir
    if 'volumes' not in data:
        data['volumes'] = {}
    if 'letsencrypt' not in data['volumes']:
        data['volumes']['letsencrypt'] = {}

with open(file_path, 'w') as f:
    yaml.dump(data, f, default_flow_style=False, sort_keys=False)

print("✅ Configuração do ACME adicionada com sucesso!")
PYTHON

# Tentar usar Python para modificar
if command -v python3 &> /dev/null; then
    if python3 -c "import yaml" 2>/dev/null; then
        python3 /tmp/add-acme-to-traefik.py "$TRAEFIK_COMPOSE_FILE" "$ACME_EMAIL"
        echo -e "${GREEN}✅ Configuração adicionada usando Python${NC}"
    else
        echo -e "${YELLOW}⚠️  PyYAML não está instalado, usando método alternativo...${NC}"
        # Método alternativo: usar sed/awk
        echo -e "${RED}❌ Não foi possível modificar automaticamente${NC}"
        echo -e "${YELLOW}   Você precisa modificar manualmente o arquivo: ${TRAEFIK_COMPOSE_FILE}${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  Python3 não está instalado, usando método alternativo...${NC}"
    echo -e "${RED}❌ Não foi possível modificar automaticamente${NC}"
    echo -e "${YELLOW}   Você precisa modificar manualmente o arquivo: ${TRAEFIK_COMPOSE_FILE}${NC}"
    exit 1
fi

echo ""

# Criar diretório para certificados
echo -e "${BLUE}5) Criando diretório para certificados...${NC}"
mkdir -p /letsencrypt
chmod 600 /letsencrypt
echo -e "${GREEN}✅ Diretório criado: /letsencrypt${NC}"

echo ""

# Instruções finais
echo -e "${GREEN}✅ CONFIGURAÇÃO CONCLUÍDA!${NC}"
echo ""
echo -e "${BLUE}📋 PRÓXIMOS PASSOS:${NC}"
echo ""
echo -e "${YELLOW}1. Reinicie o Traefik:${NC}"
if [ ! -z "$STACK_NAME" ]; then
    echo -e "${BLUE}   docker stack deploy -c ${TRAEFIK_COMPOSE_FILE} ${STACK_NAME}${NC}"
else
    echo -e "${BLUE}   docker-compose -f ${TRAEFIK_COMPOSE_FILE} up -d${NC}"
fi
echo ""
echo -e "${YELLOW}2. Aguarde alguns minutos para o Let's Encrypt gerar certificados${NC}"
echo ""
echo -e "${YELLOW}3. Verifique os certificados:${NC}"
echo -e "${BLUE}   echo | openssl s_client -connect apiapi.jyze.space:443 -servername apiapi.jyze.space 2>&1 | grep -A 2 'Certificate chain\|CN ='${NC}"
echo ""


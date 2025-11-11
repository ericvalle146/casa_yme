#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔧 Configurando Traefik via File Provider${NC}"
echo ""

# Obter IP do host
HOST_IP=$(hostname -I | awk '{print $1}' || echo "127.0.0.1")
echo -e "${BLUE}   IP do host: ${HOST_IP}${NC}"

# Verificar onde o Traefik monta volumes de configuração
TRAEFIK_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1 || echo "")
if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Traefik não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik: ${TRAEFIK_CONTAINER}${NC}"

# Verificar volumes do Traefik
echo -e "${BLUE}1) Verificando volumes do Traefik...${NC}"
TRAEFIK_MOUNTS=$(docker inspect "$TRAEFIK_CONTAINER" --format '{{range .Mounts}}{{.Destination}} {{end}}' 2>/dev/null || echo "")

# Procurar por volumes de configuração dinâmica
DYNAMIC_CONFIG_PATH=""
for mount in $TRAEFIK_MOUNTS; do
    if echo "$mount" | grep -qE "(dynamic|config|traefik)"; then
        DYNAMIC_CONFIG_PATH="$mount"
        break
    fi
done

if [ -z "$DYNAMIC_CONFIG_PATH" ]; then
    # Tentar encontrar volume nomeado
    TRAEFIK_VOLUMES=$(docker inspect "$TRAEFIK_CONTAINER" --format '{{range .Mounts}}{{.Name}}:{{.Destination}} {{end}}' 2>/dev/null || echo "")
    echo -e "${YELLOW}⚠️  Volume de configuração dinâmica não encontrado nos mounts${NC}"
    echo -e "${BLUE}   Volumes encontrados:${NC}"
    echo "$TRAEFIK_VOLUMES" | tr ' ' '\n' | head -5
    echo ""
    echo -e "${BLUE}💡 Vamos criar arquivo de configuração local e você pode montá-lo manualmente${NC}"
    DYNAMIC_CONFIG_PATH="/tmp/traefik-dynamic"
fi

# Criar diretório
mkdir -p "$DYNAMIC_CONFIG_PATH"

# Criar arquivo de configuração
CONFIG_FILE="$DYNAMIC_CONFIG_PATH/imovelpro.yml"
cat > "$CONFIG_FILE" <<EOF
http:
  routers:
    imovelpro-frontend:
      rule: "Host(\`imob.locusup.shop\`)"
      entryPoints:
        - websecure
      service: imovelpro-frontend
      tls:
        certResolver: letsencrypt
    
    imovelpro-frontend-http:
      rule: "Host(\`imob.locusup.shop\`)"
      entryPoints:
        - web
      middlewares:
        - redirect-to-https-frontend
      service: imovelpro-frontend
    
    imovelpro-backend:
      rule: "Host(\`apiapi.jyze.space\`)"
      entryPoints:
        - websecure
      service: imovelpro-backend
      tls:
        certResolver: letsencrypt
    
    imovelpro-backend-http:
      rule: "Host(\`apiapi.jyze.space\`)"
      entryPoints:
        - web
      middlewares:
        - redirect-to-https-backend
      service: imovelpro-backend

  services:
    imovelpro-frontend:
      loadBalancer:
        servers:
          - url: "http://${HOST_IP}:3429"
    
    imovelpro-backend:
      loadBalancer:
        servers:
          - url: "http://${HOST_IP}:4000"

  middlewares:
    redirect-to-https-frontend:
      redirectScheme:
        scheme: https
        permanent: true
    
    redirect-to-https-backend:
      redirectScheme:
        scheme: https
        permanent: true
EOF

echo -e "${GREEN}✅ Configuração criada: ${CONFIG_FILE}${NC}"
echo ""

# Verificar se o Traefik tem file provider habilitado
echo -e "${BLUE}2) Verificando se Traefik tem file provider...${NC}"
TRAEFIK_CMD=$(docker inspect "$TRAEFIK_CONTAINER" --format '{{join .Args " "}}' 2>/dev/null || echo "")

if echo "$TRAEFIK_CMD" | grep -q "providers.file"; then
    echo -e "${GREEN}✅ File provider encontrado${NC}"
    FILE_DIRECTORY=$(echo "$TRAEFIK_CMD" | grep -oP 'providers.file.directory=\K[^\s]+' || echo "")
    if [ ! -z "$FILE_DIRECTORY" ]; then
        echo -e "${BLUE}   Diretório do file provider: ${FILE_DIRECTORY}${NC}"
        echo -e "${BLUE}   Copiando arquivo para o volume do Traefik...${NC}"
        
        # Tentar copiar para o volume
        if docker cp "$CONFIG_FILE" "$TRAEFIK_CONTAINER:$FILE_DIRECTORY/imovelpro.yml" 2>/dev/null; then
            echo -e "${GREEN}✅ Arquivo copiado para o Traefik${NC}"
        else
            echo -e "${YELLOW}⚠️  Não foi possível copiar automaticamente${NC}"
            echo -e "${BLUE}   Copie manualmente: ${YELLOW}docker cp $CONFIG_FILE $TRAEFIK_CONTAINER:$FILE_DIRECTORY/imovelpro.yml${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Diretório do file provider não especificado${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  File provider não encontrado na configuração do Traefik${NC}"
    echo -e "${BLUE}   Você precisa habilitar o file provider no Traefik${NC}"
fi

echo ""
echo -e "${BLUE}3) Reiniciando Traefik...${NC}"
docker restart "$TRAEFIK_CONTAINER" 2>/dev/null || true
sleep 10

echo ""
echo -e "${GREEN}✅ Configuração aplicada!${NC}"
echo ""
echo -e "${BLUE}📋 Arquivo de configuração: ${CONFIG_FILE}${NC}"
echo -e "${BLUE}   Se o Traefik não tiver file provider, você precisa:${NC}"
echo -e "${BLUE}   1. Habilitar file provider no stack do Traefik${NC}"
echo -e "${BLUE}   2. Montar o diretório ${DYNAMIC_CONFIG_PATH} no Traefik${NC}"
echo ""
echo -e "${BLUE}💡 Teste os domínios:${NC}"
echo -e "   - https://imob.locusup.shop"
echo -e "   - https://apiapi.jyze.space/health"


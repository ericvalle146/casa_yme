#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}📝 Criando configuração do Traefik via File Provider${NC}"
echo ""

# Obter IP do host
HOST_IP=$(hostname -I | awk '{print $1}' || echo "localhost")

# Criar diretório de configuração
CONFIG_DIR="/tmp/traefik-dynamic"
mkdir -p "$CONFIG_DIR"

# Criar arquivo de configuração
cat > "$CONFIG_DIR/imovelpro.yml" <<EOF
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

echo -e "${GREEN}✅ Configuração criada em: ${CONFIG_DIR}/imovelpro.yml${NC}"
echo ""
echo -e "${BLUE}📋 Próximo passo:${NC}"
echo -e "${BLUE}   Você precisa montar este arquivo no Traefik${NC}"
echo -e "${BLUE}   Ou copiar para o volume de configuração do Traefik${NC}"
echo ""
echo -e "${BLUE}💡 Para usar:${NC}"
echo -e "   1. Copie o arquivo para o volume do Traefik"
echo -e "   2. Configure o Traefik para usar file provider apontando para este arquivo"
echo -e "   3. Reinicie o Traefik"
echo ""
echo -e "${BLUE}📄 Conteúdo do arquivo:${NC}"
cat "$CONFIG_DIR/imovelpro.yml"


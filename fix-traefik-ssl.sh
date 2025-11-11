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
echo -e "${CYAN}║     Configurar Traefik com Let's Encrypt - FIX SSL      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Encontrar container do Traefik
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)

if [ -z "$TRAEFIK_CONTAINER" ]; then
    echo -e "${RED}❌ Container do Traefik não encontrado${NC}"
    echo -e "${YELLOW}   Verifique se o Traefik está rodando: docker ps | grep traefik${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Traefik encontrado: ${YELLOW}$TRAEFIK_CONTAINER${NC}"
echo ""

# Verificar se está em Swarm
IS_SWARM=false
if echo "$TRAEFIK_CONTAINER" | grep -q "\.1\."; then
    IS_SWARM=true
    echo -e "${BLUE}Modo Docker Swarm detectado${NC}"
    TRAEFIK_SERVICE=$(echo "$TRAEFIK_CONTAINER" | cut -d'.' -f1-2)
    echo -e "${BLUE}Serviço do Traefik: ${YELLOW}$TRAEFIK_SERVICE${NC}"
else
    echo -e "${BLUE}Modo Docker Compose detectado${NC}"
fi
echo ""

# Verificar logs do Traefik para entender a configuração
echo -e "${BLUE}[1] Analisando logs do Traefik...${NC}"
TRAEFIK_LOGS=$(docker logs "$TRAEFIK_CONTAINER" 2>&1 | tail -100)

if echo "$TRAEFIK_LOGS" | grep -qi "acme\|letsencrypt\|certificatesResolvers"; then
    echo -e "${GREEN}✅ Traefik tem referências a ACME/Let's Encrypt nos logs${NC}"
else
    echo -e "${RED}❌ Traefik NÃO tem ACME/Let's Encrypt configurado${NC}"
    echo -e "${YELLOW}   Precisamos configurar o Let's Encrypt${NC}"
fi
echo ""

# Verificar se o diretório /letsencrypt existe
echo -e "${BLUE}[2] Verificando diretório de certificados...${NC}"
if docker exec "$TRAEFIK_CONTAINER" test -d /letsencrypt 2>/dev/null; then
    echo -e "${GREEN}✅ Diretório /letsencrypt existe${NC}"
    
    if docker exec "$TRAEFIK_CONTAINER" test -f /letsencrypt/acme.json 2>/dev/null; then
        PERMS=$(docker exec "$TRAEFIK_CONTAINER" stat -c "%a" /letsencrypt/acme.json 2>/dev/null || echo "unknown")
        echo -e "${BLUE}   Arquivo acme.json existe com permissões: ${PERMS}${NC}"
        
        if [ "$PERMS" != "600" ]; then
            echo -e "${YELLOW}   Ajustando permissões para 600...${NC}"
            docker exec "$TRAEFIK_CONTAINER" chmod 600 /letsencrypt/acme.json 2>/dev/null || true
        fi
    else
        echo -e "${YELLOW}   Arquivo acme.json não existe, criando...${NC}"
        docker exec "$TRAEFIK_CONTAINER" touch /letsencrypt/acme.json 2>/dev/null || true
        docker exec "$TRAEFIK_CONTAINER" chmod 600 /letsencrypt/acme.json 2>/dev/null || true
        echo -e "${GREEN}✅ Arquivo acme.json criado${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Diretório /letsencrypt não existe${NC}"
    echo -e "${BLUE}   Tentando criar...${NC}"
    docker exec "$TRAEFIK_CONTAINER" mkdir -p /letsencrypt 2>/dev/null || true
    docker exec "$TRAEFIK_CONTAINER" touch /letsencrypt/acme.json 2>/dev/null || true
    docker exec "$TRAEFIK_CONTAINER" chmod 600 /letsencrypt/acme.json 2>/dev/null || true
    
    if docker exec "$TRAEFIK_CONTAINER" test -d /letsencrypt 2>/dev/null; then
        echo -e "${GREEN}✅ Diretório criado${NC}"
    else
        echo -e "${RED}❌ Não foi possível criar o diretório${NC}"
        echo -e "${YELLOW}   O volume pode não estar montado corretamente${NC}"
    fi
fi
echo ""

# Verificar configuração do Traefik
echo -e "${BLUE}[3] Verificando configuração do Traefik...${NC}"

# Tentar encontrar arquivo de configuração
CONFIG_FOUND=false
POSSIBLE_CONFIGS=(
    "/etc/traefik/traefik.yml"
    "/traefik/traefik.yml"
    "/traefik.yml"
    "/etc/traefik/traefik.yaml"
    "/traefik/traefik.yaml"
    "/traefik.yaml"
)

for config in "${POSSIBLE_CONFIGS[@]}"; do
    if docker exec "$TRAEFIK_CONTAINER" test -f "$config" 2>/dev/null; then
        echo -e "${GREEN}✅ Arquivo de configuração encontrado: ${YELLOW}$config${NC}"
        CONFIG_FOUND=true
        
        # Verificar se tem ACME configurado
        CONFIG_CONTENT=$(docker exec "$TRAEFIK_CONTAINER" cat "$config" 2>/dev/null || echo "")
        if echo "$CONFIG_CONTENT" | grep -qi "certificatesResolvers\|letsencrypt"; then
            echo -e "${GREEN}✅ Configuração ACME encontrada no arquivo${NC}"
        else
            echo -e "${RED}❌ Configuração ACME NÃO encontrada no arquivo${NC}"
        fi
        break
    fi
done

if [ "$CONFIG_FOUND" = false ]; then
    echo -e "${YELLOW}⚠️  Arquivo de configuração não encontrado${NC}"
    echo -e "${YELLOW}   O Traefik pode estar usando labels do Docker ou variáveis de ambiente${NC}"
fi
echo ""

# Verificar labels do Traefik
echo -e "${BLUE}[4] Verificando labels do Traefik...${NC}"
if [ "$IS_SWARM" = true ]; then
    TRAEFIK_LABELS=$(docker service inspect "$TRAEFIK_SERVICE" --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' 2>/dev/null || echo "{}")
else
    TRAEFIK_LABELS=$(docker inspect "$TRAEFIK_CONTAINER" --format '{{json .Config.Labels}}' 2>/dev/null || echo "{}")
fi

if echo "$TRAEFIK_LABELS" | grep -qi "traefik.*acme\|traefik.*letsencrypt"; then
    echo -e "${GREEN}✅ Labels do Traefik têm referências a ACME${NC}"
else
    echo -e "${YELLOW}⚠️  Labels do Traefik não têm referências a ACME${NC}"
fi
echo ""

# Verificar se os serviços estão com as labels corretas
echo -e "${BLUE}[5] Verificando labels dos serviços ImóvelPro...${NC}"
FRONTEND_SERVICE="imovelpro_frontend"
BACKEND_SERVICE="imovelpro_backend"

if docker service inspect "$FRONTEND_SERVICE" >/dev/null 2>&1; then
    FRONTEND_LABELS=$(docker service inspect "$FRONTEND_SERVICE" --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' 2>/dev/null || echo "{}")
    
    if echo "$FRONTEND_LABELS" | grep -q "certresolver.*letsencrypt"; then
        echo -e "${GREEN}✅ Frontend tem certresolver=letsencrypt${NC}"
    else
        echo -e "${RED}❌ Frontend NÃO tem certresolver=letsencrypt${NC}"
    fi
fi

if docker service inspect "$BACKEND_SERVICE" >/dev/null 2>&1; then
    BACKEND_LABELS=$(docker service inspect "$BACKEND_SERVICE" --format '{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' 2>/dev/null || echo "{}")
    
    if echo "$BACKEND_LABELS" | grep -q "certresolver.*letsencrypt"; then
        echo -e "${GREEN}✅ Backend tem certresolver=letsencrypt${NC}"
    else
        echo -e "${RED}❌ Backend NÃO tem certresolver=letsencrypt${NC}"
    fi
fi
echo ""

# Resumo e recomendações
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    DIAGNÓSTICO COMPLETO                   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se o Traefik precisa ser reiniciado
echo -e "${BLUE}[6] Verificando se precisa reiniciar o Traefik...${NC}"

NEEDS_RESTART=false
NEEDS_CONFIG=false

# Verificar se tem ACME mas não está funcionando
if echo "$TRAEFIK_LOGS" | grep -qi "acme\|letsencrypt"; then
    if echo "$TRAEFIK_LOGS" | grep -qi "error.*acme\|failed.*acme\|acme.*error"; then
        echo -e "${YELLOW}⚠️  Erros relacionados a ACME nos logs${NC}"
        NEEDS_RESTART=true
    fi
else
    echo -e "${RED}❌ Traefik não tem Let's Encrypt configurado${NC}"
    NEEDS_CONFIG=true
fi

echo ""

# Mostrar logs recentes do Traefik
echo -e "${BLUE}[7] Últimas linhas dos logs do Traefik:${NC}"
docker logs "$TRAEFIK_CONTAINER" 2>&1 | tail -20
echo ""

# Instruções finais
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    PRÓXIMOS PASSOS                        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$NEEDS_CONFIG" = true ]; then
    echo -e "${RED}⚠️  PROBLEMA: Traefik não tem Let's Encrypt configurado${NC}"
    echo ""
    echo -e "${YELLOW}Para resolver:${NC}"
    echo ""
    echo -e "1. ${BLUE}Acesse a configuração do Traefik${NC}"
    echo -e "   - Se estiver em Swarm: ${CYAN}docker service inspect $TRAEFIK_SERVICE${NC}"
    echo -e "   - Se estiver em Compose: ${CYAN}docker inspect $TRAEFIK_CONTAINER${NC}"
    echo ""
    echo -e "2. ${BLUE}Adicione a configuração ACME:${NC}"
    echo ""
    cat << 'EOF'
certificatesResolvers:
  letsencrypt:
    acme:
      email: seu-email@exemplo.com
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
EOF
    echo ""
    echo -e "3. ${BLUE}Certifique-se de que o volume está montado:${NC}"
    echo -e "   ${CYAN}volumes:${NC}"
    echo -e "   ${CYAN}  - ./letsencrypt:/letsencrypt${NC}"
    echo ""
    echo -e "4. ${BLUE}Reinicie o Traefik:${NC}"
    if [ "$IS_SWARM" = true ]; then
        echo -e "   ${CYAN}docker service update --force $TRAEFIK_SERVICE${NC}"
    else
        echo -e "   ${CYAN}docker restart $TRAEFIK_CONTAINER${NC}"
    fi
    echo ""
else
    echo -e "${GREEN}✅ Traefik parece ter Let's Encrypt configurado${NC}"
    echo ""
    echo -e "${YELLOW}Se os certificados ainda estão auto-assinados:${NC}"
    echo ""
    echo -e "1. ${BLUE}Aguarde alguns minutos${NC}"
    echo -e "   O Let's Encrypt pode levar 2-5 minutos para gerar certificados"
    echo ""
    echo -e "2. ${BLUE}Verifique os logs do Traefik:${NC}"
    echo -e "   ${CYAN}docker logs -f $TRAEFIK_CONTAINER${NC}"
    echo ""
    echo -e "3. ${BLUE}Verifique se a porta 80 está acessível:${NC}"
    echo -e "   ${CYAN}curl -I http://apiapi.jyze.space/.well-known/acme-challenge/test${NC}"
    echo ""
    echo -e "4. ${BLUE}Se necessário, force a renovação:${NC}"
    if [ "$IS_SWARM" = true ]; then
        echo -e "   ${CYAN}docker service update --force $TRAEFIK_SERVICE${NC}"
    else
        echo -e "   ${CYAN}docker restart $TRAEFIK_CONTAINER${NC}"
    fi
fi

echo ""
echo -e "${BLUE}💡 Comandos úteis:${NC}"
echo -e "   - Ver logs do Traefik: ${YELLOW}docker logs -f $TRAEFIK_CONTAINER${NC}"
echo -e "   - Ver rotas do Traefik: ${YELLOW}curl -s http://localhost:8080/api/http/routers | jq${NC}"
echo -e "   - Verificar certificado: ${YELLOW}echo | openssl s_client -connect apiapi.jyze.space:443 -servername apiapi.jyze.space 2>&1 | grep CN${NC}"
echo ""


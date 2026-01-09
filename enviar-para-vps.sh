#!/usr/bin/env bash

# Script para enviar os arquivos para a VPS
# Facilita o processo de upload

set -euo pipefail

# Cores
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  📤 ENVIAR PARA VPS - CASA YME                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Pedir informações da VPS
read -p "Digite o usuário da VPS (ex: root, ubuntu): " VPS_USER
read -p "Digite o IP da VPS (ex: 123.45.67.89): " VPS_IP
read -p "Digite o caminho de destino na VPS (ex: /root/casa_yme): " VPS_PATH

echo ""
echo -e "${CYAN}Configurações:${NC}"
echo -e "  Usuário: ${YELLOW}$VPS_USER${NC}"
echo -e "  IP: ${YELLOW}$VPS_IP${NC}"
echo -e "  Destino: ${YELLOW}$VPS_PATH${NC}"
echo ""
read -p "Confirma? (s/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Ss]$ ]]; then
    echo -e "${RED}Cancelado.${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}[1/5] Criando diretório na VPS...${NC}"
ssh "$VPS_USER@$VPS_IP" "mkdir -p $VPS_PATH" || {
    echo -e "${RED}❌ Erro ao conectar na VPS${NC}"
    exit 1
}
echo -e "${GREEN}✅ Diretório criado${NC}"

echo ""
echo -e "${CYAN}[2/5] Enviando pasta deploy/...${NC}"
rsync -avz --progress deploy/ "$VPS_USER@$VPS_IP:$VPS_PATH/deploy/" || {
    echo -e "${RED}❌ Erro ao enviar deploy/${NC}"
    exit 1
}
echo -e "${GREEN}✅ Deploy enviado${NC}"

echo ""
echo -e "${CYAN}[3/5] Enviando pasta backend/...${NC}"
rsync -avz --progress --exclude 'node_modules' --exclude 'uploads' backend/ "$VPS_USER@$VPS_IP:$VPS_PATH/backend/" || {
    echo -e "${RED}❌ Erro ao enviar backend/${NC}"
    exit 1
}
echo -e "${GREEN}✅ Backend enviado${NC}"

echo ""
echo -e "${CYAN}[4/5] Enviando pasta frontend/...${NC}"
rsync -avz --progress --exclude 'node_modules' --exclude 'dist' frontend/ "$VPS_USER@$VPS_IP:$VPS_PATH/frontend/" || {
    echo -e "${RED}❌ Erro ao enviar frontend/${NC}"
    exit 1
}
echo -e "${GREEN}✅ Frontend enviado${NC}"

echo ""
echo -e "${CYAN}[5/5] Enviando pasta sql/...${NC}"
rsync -avz --progress sql/ "$VPS_USER@$VPS_IP:$VPS_PATH/sql/" || {
    echo -e "${RED}❌ Erro ao enviar sql/${NC}"
    exit 1
}
echo -e "${GREEN}✅ SQL enviado${NC}"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ ARQUIVOS ENVIADOS COM SUCESSO!                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "📋 Próximos passos:"
echo ""
echo -e "1. Conectar na VPS:"
echo -e "   ${CYAN}ssh $VPS_USER@$VPS_IP${NC}"
echo ""
echo -e "2. Entrar no diretório do projeto:"
echo -e "   ${CYAN}cd $VPS_PATH/deploy${NC}"
echo ""
echo -e "3. Rodar o deploy (APENAS ISSO!):"
echo -e "   ${CYAN}./deploy.sh${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}💡 Dica: Copie e cole os comandos acima!${NC}"
echo ""

# Perguntar se quer conectar na VPS agora
read -p "Deseja conectar na VPS agora? (s/N): " CONNECT

if [[ "$CONNECT" =~ ^[Ss]$ ]]; then
    echo ""
    echo -e "${CYAN}Conectando na VPS...${NC}"
    ssh -t "$VPS_USER@$VPS_IP" "cd $VPS_PATH/deploy && bash"
fi

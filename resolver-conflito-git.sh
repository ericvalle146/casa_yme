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
echo -e "${CYAN}║         Resolver Conflito Git - Atualizar VPS             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se estamos em um repositório git
if [ ! -d .git ]; then
    echo -e "${RED}❌ Não é um repositório git${NC}"
    exit 1
fi

# Verificar status
echo -e "${BLUE}[1] Verificando status do repositório...${NC}"
git status --short

# Verificar se há mudanças locais
HAS_CHANGES=$(git status --porcelain | wc -l)

if [ "$HAS_CHANGES" -eq 0 ]; then
    echo -e "${GREEN}✅ Nenhuma mudança local${NC}"
    echo ""
    echo -e "${BLUE}[2] Fazendo pull...${NC}"
    git pull origin main
    echo -e "${GREEN}✅ Atualização concluída!${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}⚠️  Mudanças locais detectadas${NC}"
echo ""

# Mostrar arquivos com mudanças
echo -e "${BLUE}Arquivos com mudanças locais:${NC}"
git status --short

echo ""
echo -e "${BLUE}[2] Opções para resolver:${NC}"
echo -e "   1) ${YELLOW}Descartar mudanças locais${NC} (recomendado se não forem importantes)"
echo -e "   2) ${YELLOW}Salvar mudanças em stash${NC} (para aplicar depois)"
echo -e "   3) ${YELLOW}Fazer commit das mudanças${NC} (se forem importantes)"
echo ""

read -p "Escolha uma opção (1/2/3) [1]: " opcao
opcao=${opcao:-1}

case $opcao in
    1)
        echo ""
        echo -e "${BLUE}[3] Descartando mudanças locais...${NC}"
        git reset --hard HEAD
        git clean -fd
        echo -e "${GREEN}✅ Mudanças locais descartadas${NC}"
        echo ""
        echo -e "${BLUE}[4] Fazendo pull...${NC}"
        git pull origin main
        echo -e "${GREEN}✅ Atualização concluída!${NC}"
        ;;
    2)
        echo ""
        echo -e "${BLUE}[3] Salvando mudanças em stash...${NC}"
        git stash push -m "Mudanças locais antes do pull $(date +%Y-%m-%d_%H:%M:%S)"
        echo -e "${GREEN}✅ Mudanças salvas em stash${NC}"
        echo ""
        echo -e "${BLUE}[4] Fazendo pull...${NC}"
        git pull origin main
        echo -e "${GREEN}✅ Atualização concluída!${NC}"
        echo ""
        echo -e "${YELLOW}💡 Para recuperar as mudanças: git stash pop${NC}"
        ;;
    3)
        echo ""
        echo -e "${BLUE}[3] Fazendo commit das mudanças locais...${NC}"
        git add -A
        read -p "Digite a mensagem do commit: " commit_msg
        if [ -z "$commit_msg" ]; then
            commit_msg="chore: Mudanças locais antes do pull"
        fi
        git commit -m "$commit_msg"
        echo -e "${GREEN}✅ Mudanças commitadas${NC}"
        echo ""
        echo -e "${BLUE}[4] Fazendo pull (pode haver conflitos)...${NC}"
        if git pull origin main; then
            echo -e "${GREEN}✅ Atualização concluída!${NC}"
        else
            echo -e "${RED}❌ Conflitos detectados durante o merge${NC}"
            echo -e "${YELLOW}   Resolva os conflitos manualmente e depois:${NC}"
            echo -e "${YELLOW}   git add . && git commit${NC}"
        fi
        ;;
    *)
        echo -e "${RED}❌ Opção inválida${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    ATUALIZAÇÃO CONCLUÍDA                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se os novos arquivos estão presentes
echo -e "${BLUE}Verificando novos arquivos...${NC}"
NEW_FILES=("deploy-completo.sh" "verificar-traefik.sh" "configurar-traefik-acme.sh" "DEPLOY-FINAL.md" "COMO-USAR.md" "SOLUCAO-DEPLOY.md")

for file in "${NEW_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${YELLOW}⚠️  $file não encontrado${NC}"
    fi
done

echo ""
echo -e "${BLUE}💡 Próximos passos:${NC}"
echo -e "   - Execute: ${YELLOW}./deploy-completo.sh${NC} para fazer o deploy"
echo -e "   - Ou verifique: ${YELLOW}./verificar-traefik.sh${NC} para diagnosticar problemas"
echo ""


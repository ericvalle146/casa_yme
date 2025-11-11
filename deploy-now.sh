#!/bin/bash

# Script simples para fazer deploy via Docker Swarm Stack
# NÃO afeta outros serviços - apenas cria uma nova stack

set -e

cd ~/Prototipo_Mariana_Imobiliarias

echo "🚀 Fazendo deploy via Docker Swarm Stack..."
echo "   Isso NÃO vai derrubar nenhum serviço existente"
echo ""

# Parar containers do docker-compose se existirem
docker compose -f docker-compose.standalone.yml down 2>/dev/null || true

# Fazer deploy via Swarm
./deploy/deploy-swarm.sh

echo ""
echo "✅ Deploy concluído!"
echo "   Os serviços estão rodando na stack 'imovelpro'"
echo "   E estão na network vpsnet junto com o Traefik"


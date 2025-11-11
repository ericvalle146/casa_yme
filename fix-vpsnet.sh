#!/bin/bash

echo "🔧 Tornando a network vpsnet anexável..."

# Verificar se a network existe
if ! docker network inspect vpsnet >/dev/null 2>&1; then
    echo "❌ Network vpsnet não encontrada"
    exit 1
fi

# Remover a network e recriar como attachable
echo "📋 Informações da network atual:"
docker network inspect vpsnet --format '{{json .}}' | jq '{Name, Driver, Attachable, Options}' 2>/dev/null || docker network inspect vpsnet

echo ""
echo "⚠️  Para tornar a network attachable, você precisa:"
echo ""
echo "Opção 1: Se a network foi criada pelo Docker Compose, edite o arquivo docker-compose.yml do Traefik e adicione:"
echo "  networks:"
echo "    vpsnet:"
echo "      driver: bridge"
echo "      attachable: true"
echo ""
echo "Opção 2: Remover e recriar a network (CUIDADO: pode afetar outros containers):"
echo "  docker network rm vpsnet"
echo "  docker network create --driver bridge --attachable vpsnet"
echo ""
echo "Opção 3: Verificar se há um arquivo de configuração do Traefik e adicionar attachable: true"
echo ""
echo "Qual opção você prefere? (1/2/3)"


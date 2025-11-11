#!/bin/bash

echo "🚨 RECUPERANDO NETWORK VPSNET..."

# Recriar a network
echo "1. Recriando network vpsnet..."
docker network create --driver bridge --attachable vpsnet

# Listar todos os containers Docker
echo ""
echo "2. Listando todos os containers..."
ALL_CONTAINERS=$(docker ps -a --format "{{.Names}}")

echo "Containers encontrados:"
echo "$ALL_CONTAINERS"

echo ""
echo "3. Reconectando containers à vpsnet..."

# Reconectar containers comuns do Traefik/Docker Swarm
for container in $ALL_CONTAINERS; do
    # Pular containers que já estão na network ou que são do nosso projeto
    if [[ "$container" == "imovelpro-frontend" ]] || [[ "$container" == "imovelpro-backend" ]]; then
        continue
    fi
    
    # Tentar conectar (ignorar erros se já estiver conectado)
    if docker network connect vpsnet "$container" 2>/dev/null; then
        echo "✅ Conectado: $container"
    else
        echo "⚠️  $container (já conectado ou erro)"
    fi
done

echo ""
echo "4. Verificando network vpsnet..."
docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}'

echo ""
echo "✅ Network vpsnet recuperada!"
echo ""
echo "Se algum serviço não estiver funcionando, reinicie os containers:"
echo "  docker restart <nome-do-container>"


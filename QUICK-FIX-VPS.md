# Correção Rápida na VPS

## Problema
A network `vpsnet` não é attachable, impedindo que o docker-compose conecte os containers automaticamente.

## Solução Rápida (3 passos)

### Passo 1: Atualizar código e corrigir network

Execute na VPS:

```bash
cd ~/Prototipo_Mariana_Imobiliarias
git pull origin main
```

### Passo 2: Executar script de correção

```bash
chmod +x update-and-fix-vps.sh
./update-and-fix-vps.sh
```

OU execute manualmente:

```bash
# 1. Parar containers
docker compose down

# 2. Verificar containers na vpsnet e desconectar se necessário
docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}'

# 3. Remover network
docker network rm vpsnet

# 4. Recriar como attachable
docker network create --driver bridge --attachable vpsnet

# 5. Verificar se foi criada corretamente
docker network inspect vpsnet --format '{{.Attachable}}'
# Deve retornar: true

# 6. Reconectar Traefik (se existir)
TRAEFIK=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)
if [ ! -z "$TRAEFIK" ]; then
    docker network connect vpsnet $TRAEFIK
fi
```

### Passo 3: Executar deploy

```bash
./deploy.sh
```

## Verificação

```bash
# Verificar containers
docker compose ps

# Verificar network
docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}'
# Deve mostrar: imovelpro-frontend imovelpro-backend

# Executar diagnóstico
./diagnose-traefik.sh

# Testar domínios
curl -I https://imob.locusup.shop
curl -I https://apiapi.jyze.space/health
```

## Se estiver usando Docker Swarm

Se você estiver usando Docker Swarm, você precisa parar o stack primeiro:

```bash
# 1. Listar stacks
docker stack ls

# 2. Parar stack do Traefik (ou outro que use vpsnet)
docker stack rm <nome-do-stack>

# 3. Aguardar até que todos os serviços sejam removidos
docker stack ps <nome-do-stack>

# 4. Remover network
docker network rm vpsnet

# 5. Recriar network
docker network create --driver bridge --attachable vpsnet

# 6. Reiniciar stack
docker stack deploy -c <docker-compose-traefik.yml> <nome-do-stack>

# 7. Executar deploy do projeto
cd ~/Prototipo_Mariana_Imobiliarias
./deploy.sh
```

## Solução Automatizada (Recomendada)

Execute este comando único na VPS:

```bash
cd ~/Prototipo_Mariana_Imobiliarias && \
git pull origin main && \
docker compose down && \
(docker network rm vpsnet 2>/dev/null || true) && \
docker network create --driver bridge --attachable vpsnet && \
TRAEFIK=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1) && \
([ ! -z "$TRAEFIK" ] && docker network connect vpsnet $TRAEFIK || true) && \
./deploy.sh
```

Este comando:
1. Atualiza o código
2. Para os containers
3. Remove a network vpsnet (se existir)
4. Recria a network como attachable
5. Reconecta o Traefik (se existir)
6. Executa o deploy

## Troubleshooting

### Erro: "network vpsnet is in use"

Isso significa que há containers ainda usando a network. Execute:

```bash
# Listar containers na network
docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}'

# Parar containers manualmente
docker stop <container1> <container2> ...

# Ou forçar remoção (CUIDADO!)
docker network rm vpsnet --force
```

### Erro: "network vpsnet declared as external, but could not be found"

A network não existe. Execute:

```bash
docker network create --driver bridge --attachable vpsnet
```

### Containers não aparecem no Traefik

Verifique se:
1. Containers estão na network vpsnet: `docker network inspect vpsnet`
2. Traefik está na network vpsnet: `docker inspect <traefik-container>`
3. Labels do Traefik estão corretos: `docker inspect imovelpro-frontend --format '{{json .Config.Labels}}'`

### Traefik não está na network vpsnet

Conecte manualmente:

```bash
TRAEFIK=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)
docker network connect vpsnet $TRAEFIK
docker restart $TRAEFIK
```

## Comandos Úteis

```bash
# Ver status dos containers
docker compose ps

# Ver logs
docker compose logs -f

# Ver networks
docker network ls

# Inspecionar network
docker network inspect vpsnet

# Ver containers em uma network
docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}'

# Executar diagnóstico
./diagnose-traefik.sh
```

## Suporte

Para mais informações, consulte:
- `FIX-DEPLOY.md` - Guia detalhado de correção
- `TROUBLESHOOTING.md` - Guia completo de troubleshooting
- Execute `./diagnose-traefik.sh` para diagnóstico automático


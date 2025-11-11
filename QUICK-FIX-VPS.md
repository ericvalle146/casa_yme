# Correção Rápida na VPS

## Problema
A network `vpsnet` não é attachable (criada pelo Docker Swarm), impedindo que o docker-compose conecte os containers automaticamente.

## ✅ Solução Segura (NÃO para os stacks do Docker Swarm)

### Opção 1: Deploy Automático (Recomendado)

O script `deploy.sh` foi atualizado para detectar automaticamente se a network não é attachable e conectar os containers manualmente. **NÃO é necessário parar os stacks do Docker Swarm!**

Execute na VPS:

```bash
cd ~/Prototipo_Mariana_Imobiliarias
git pull origin main
./deploy.sh
```

O script vai:
1. Detectar que a network vpsnet não é attachable (Docker Swarm)
2. Criar containers sem conectar à vpsnet primeiro
3. Conectar containers manualmente à vpsnet após iniciar
4. **NÃO vai parar nenhum stack do Docker Swarm**

### Opção 2: Manual (se necessário)

Execute manualmente:

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

## ⚠️ IMPORTANTE: Docker Swarm

**NÃO é necessário parar os stacks do Docker Swarm!**

O script `deploy.sh` detecta automaticamente quando a network `vpsnet` foi criada pelo Docker Swarm e usa conexão manual dos containers. Isso significa que:

✅ **Seus serviços continuam rodando** (chatwoot, evolution, n8n, traefik, etc.)  
✅ **Nenhum downtime**  
✅ **Conexão automática** dos containers à network vpsnet

### Como funciona:

1. O script detecta que `vpsnet` não é attachable (criada pelo Swarm)
2. Usa `docker-compose.no-vpsnet.yml` para criar containers sem vpsnet
3. Conecta containers manualmente à vpsnet após iniciar
4. Traefik detecta os containers automaticamente via labels

### Se quiser tornar a network attachable (opcional, requer downtime):

```bash
# 1. Parar todos os stacks (ISSO VAI PARAR TODOS OS SERVIÇOS!)
docker stack rm chatwoot evolution n8n traefik pgvector portainer postgres rabbitmq redis saborpaulista

# 2. Aguardar remoção completa
# ... aguarde alguns minutos ...

# 3. Remover network
docker network rm vpsnet

# 4. Recriar network como attachable
docker network create --driver bridge --attachable vpsnet

# 5. Reiniciar todos os stacks
# ... reinicie todos os stacks manualmente ...

# 6. Executar deploy do projeto
cd ~/Prototipo_Mariana_Imobiliarias
./deploy.sh
```

**⚠️ NÃO RECOMENDADO** - Isso vai causar downtime em todos os serviços!

## Solução Automatizada (Recomendada)

Execute este comando único na VPS:

```bash
cd ~/Prototipo_Mariana_Imobiliarias && \
git pull origin main && \
./deploy.sh
```

Este comando:
1. Atualiza o código do GitHub
2. Executa o deploy (que detecta automaticamente Docker Swarm)
3. Conecta containers manualmente se necessário
4. **NÃO para nenhum stack do Docker Swarm**

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


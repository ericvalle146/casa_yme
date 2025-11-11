# Guia de Troubleshooting - Deploy na VPS

## Problemas Comuns

### 1. Network vpsnet não é attachable

**Sintoma:**
```
⚠️  Network vpsnet não é attachable
❌ NÃO É POSSÍVEL tornar attachable sem remover a network
```

**Solução:**

Se você estiver usando Docker Swarm, você precisa parar o stack primeiro:

```bash
# 1. Parar o stack do Traefik (se estiver usando Docker Swarm)
docker stack rm <nome-do-stack>

# 2. Aguardar até que todos os serviços sejam removidos
docker stack ps <nome-do-stack>

# 3. Remover a network
docker network rm vpsnet

# 4. Recriar a network como attachable
docker network create --driver bridge --attachable vpsnet

# 5. Reiniciar o stack do Traefik
docker stack deploy -c <docker-compose-traefik.yml> <nome-do-stack>

# 6. Executar o deploy novamente
./deploy.sh
```

Se você NÃO estiver usando Docker Swarm:

```bash
# 1. Parar todos os containers que usam vpsnet
docker ps --format "{{.Names}}" | xargs -I {} docker stop {}

# 2. Remover a network
docker network rm vpsnet

# 3. Recriar a network como attachable
docker network create --driver bridge --attachable vpsnet

# 4. Reiniciar os containers
# (depende de como você iniciou eles - docker-compose, docker run, etc.)

# 5. Executar o deploy novamente
./deploy.sh
```

### 2. Containers não aparecem no Traefik

**Sintoma:**
- Containers estão rodando
- Mas não aparecem no Traefik dashboard
- Domínios não funcionam

**Solução:**

1. Verificar se os containers estão na network vpsnet:
```bash
docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}'
```

2. Verificar se o Traefik está na network vpsnet:
```bash
docker inspect <nome-do-container-traefik> --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}{{end}}'
```

3. Verificar labels dos containers:
```bash
docker inspect imovelpro-frontend --format '{{json .Config.Labels}}' | jq
docker inspect imovelpro-backend --format '{{json .Config.Labels}}' | jq
```

4. Se os containers não estiverem na network vpsnet, conecte-os:
```bash
docker network connect vpsnet imovelpro-frontend
docker network connect vpsnet imovelpro-backend
```

5. Reiniciar o Traefik para que ele detecte os novos containers:
```bash
docker restart <nome-do-container-traefik>
```

### 3. Erro ao iniciar containers: network vpsnet not found

**Sintoma:**
```
ERROR: Network vpsnet declared as external, but could not be found
```

**Solução:**

1. Verificar se a network existe:
```bash
docker network ls | grep vpsnet
```

2. Se não existir, criar:
```bash
docker network create --driver bridge --attachable vpsnet
```

3. Executar o deploy novamente:
```bash
./deploy.sh
```

### 4. Traefik não está na network vpsnet

**Sintoma:**
- Traefik está rodando
- Mas não consegue acessar os containers

**Solução:**

1. Conectar o Traefik à network vpsnet:
```bash
docker network connect vpsnet <nome-do-container-traefik>
```

2. Reiniciar o Traefik:
```bash
docker restart <nome-do-container-traefik>
```

### 5. Entrypoints do Traefik incorretos

**Sintoma:**
- Containers estão na network correta
- Labels estão corretos
- Mas o Traefik não roteia o tráfego

**Solução:**

1. Verificar quais entrypoints o Traefik tem configurados:
```bash
# Se o Traefik tiver API habilitada
curl -s http://localhost:8080/api/http/entrypoints | jq
```

2. Verificar a configuração do Traefik:
```bash
docker inspect <nome-do-container-traefik> --format '{{json .Config.Labels}}' | jq
```

3. Se os entrypoints forem diferentes (ex: `http`, `https` ao invés de `web`, `websecure`), ajuste o `docker-compose.yml`:

```yaml
labels:
  - "traefik.http.routers.imovelpro-frontend.entrypoints=https"  # ao invés de websecure
  - "traefik.http.routers.imovelpro-frontend-http.entrypoints=http"  # ao invés de web
```

### 6. Certificados SSL não são gerados

**Sintoma:**
- Domínios funcionam via HTTP
- Mas não funcionam via HTTPS
- Erros de certificado SSL

**Solução:**

1. Verificar se o certresolver está configurado no Traefik:
```bash
docker inspect <nome-do-container-traefik> --format '{{json .Config.Labels}}' | jq '.["traefik.http.certresolver"]'
```

2. Verificar se o Let's Encrypt está configurado no Traefik

3. Verificar logs do Traefik para erros de certificado:
```bash
docker logs <nome-do-container-traefik> 2>&1 | grep -i cert
```

4. Verificar se os domínios apontam para o IP do servidor:
```bash
dig +short imob.locusup.shop
dig +short apiapi.jyze.space
```

### 7. Containers não conseguem se comunicar

**Sintoma:**
- Frontend não consegue acessar o backend
- Erros de conexão

**Solução:**

1. Verificar se ambos os containers estão na network `imovelpro-network`:
```bash
docker network inspect prototipo_mariana_imobiliarias_imovelpro-network --format '{{range .Containers}}{{.Name}} {{end}}'
```

2. Verificar se o frontend está usando a URL correta do backend:
```bash
docker inspect imovelpro-frontend --format '{{json .Config.Env}}' | jq
```

3. No frontend, o backend deve ser acessado via `https://apiapi.jyze.space` (não via nome do container)

## Script de Diagnóstico

Execute o script de diagnóstico para identificar problemas automaticamente:

```bash
./diagnose-traefik.sh
```

Este script verifica:
- Se a network vpsnet existe e é attachable
- Se o Traefik está rodando e na network correta
- Se os containers estão na network correta
- Se os labels do Traefik estão configurados
- Se os domínios apontam para o IP correto

## Verificações Pós-Deploy

Após o deploy, verifique:

1. **Status dos containers:**
```bash
docker compose ps
```

2. **Logs dos containers:**
```bash
docker compose logs -f
```

3. **Health checks:**
```bash
curl http://localhost:3429/health
curl http://localhost:4000/health
```

4. **Acesso via domínio:**
```bash
curl -I https://imob.locusup.shop
curl -I https://apiapi.jyze.space/health
```

5. **Rotas do Traefik:**
```bash
# Se o Traefik tiver API habilitada na porta 8080
curl -s http://localhost:8080/api/http/routers | jq '.[] | select(.name | contains("imovelpro"))'
```

## Comandos Úteis

### Ver todas as networks
```bash
docker network ls
```

### Inspecionar uma network
```bash
docker network inspect vpsnet
```

### Ver containers em uma network
```bash
docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}'
```

### Conectar um container a uma network
```bash
docker network connect vpsnet <nome-do-container>
```

### Desconectar um container de uma network
```bash
docker network disconnect vpsnet <nome-do-container>
```

### Ver logs do Traefik
```bash
docker logs <nome-do-container-traefik> -f
```

### Reiniciar containers
```bash
docker compose restart
```

### Parar e remover containers
```bash
docker compose down
```

### Rebuild e restart
```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

## Contato e Suporte

Se você continuar tendo problemas após seguir este guia, verifique:

1. Logs dos containers
2. Logs do Traefik
3. Configuração do firewall
4. Configuração de DNS
5. Configuração do Traefik

Para mais informações, consulte a documentação do Traefik: https://doc.traefik.io/traefik/






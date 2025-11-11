# Changelog - Correções de Deploy

## Data: 2025-01-11

## Problema Identificado

O deploy estava falhando porque:
1. A network `vpsnet` não era attachable, impedindo que o docker-compose conectasse os containers automaticamente
2. Os containers eram conectados manualmente após o início, o que pode causar problemas com o Traefik
3. Faltavam verificações de diagnóstico para identificar problemas

## Mudanças Realizadas

### 1. `docker-compose.yml`

**Antes:**
- Containers estavam apenas na network `imovelpro-network`
- Network `vpsnet` não estava configurada no docker-compose
- Containers eram conectados manualmente após o início

**Depois:**
- ✅ Containers agora estão em ambas as networks (`imovelpro-network` e `vpsnet`)
- ✅ Network `vpsnet` configurada como external
- ✅ Containers são conectados automaticamente ao iniciar
- ✅ Labels do Traefik melhorados com redirecionamento HTTP para HTTPS
- ✅ Entrypoints configurados corretamente (`web` e `websecure`)

### 2. `deploy.sh`

**Melhorias:**
- ✅ Verificação mais rigorosa da network `vpsnet`
- ✅ Verificação se a network é attachable antes de iniciar
- ✅ Removida a conexão manual dos containers (agora feita automaticamente)
- ✅ Verificações detalhadas do Traefik após o deploy
- ✅ Verificação se containers estão na network correta
- ✅ Melhor feedback sobre problemas encontrados

### 3. Novos Arquivos

#### `diagnose-traefik.sh`
Script de diagnóstico que verifica:
- Se a network `vpsnet` existe e é attachable
- Se o Traefik está rodando e na network correta
- Se os containers estão na network correta
- Se os labels do Traefik estão configurados
- Se os domínios apontam para o IP correto

#### `TROUBLESHOOTING.md`
Guia completo de troubleshooting com:
- Problemas comuns e soluções
- Comandos úteis
- Verificações pós-deploy
- Instruções detalhadas para cada problema

#### `FIX-DEPLOY.md`
Guia passo a passo para corrigir o problema de deploy:
- Instruções para tornar a network attachable
- Solução rápida com script automático
- Verificações pós-deploy
- Problemas comuns e soluções

## Próximos Passos

### 1. Tornar a network vpsnet attachable

**IMPORTANTE:** Se você estiver usando Docker Swarm, pare o stack primeiro!

```bash
# Verificar se está usando Docker Swarm
docker stack ls

# Se houver stacks, parar o stack do Traefik
docker stack rm <nome-do-stack>

# Aguardar até que todos os serviços sejam removidos
docker stack ps <nome-do-stack>
```

**Remover e recriar a network:**

```bash
# Remover a network vpsnet
docker network rm vpsnet

# Recriar como attachable
docker network create --driver bridge --attachable vpsnet

# Verificar se foi criada corretamente
docker network inspect vpsnet --format '{{.Attachable}}'
# Deve retornar: true
```

### 2. Reiniciar o Traefik

```bash
# Se usando Docker Swarm
docker stack deploy -c <docker-compose-traefik.yml> <nome-do-stack>

# Se não usando Docker Swarm
docker restart <nome-do-container-traefik>
```

### 3. Conectar o Traefik à network vpsnet (se necessário)

```bash
# Verificar se o Traefik está na network vpsnet
docker inspect <nome-do-container-traefik> --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}{{end}}'

# Se não estiver, conectar
docker network connect vpsnet <nome-do-container-traefik>
```

### 4. Executar o deploy

```bash
./deploy.sh
```

### 5. Verificar se funcionou

```bash
# Executar diagnóstico
./diagnose-traefik.sh

# Verificar containers
docker compose ps

# Verificar networks
docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}'

# Testar domínios
curl -I https://imob.locusup.shop
curl -I https://apiapi.jyze.space/health
```

## Arquivos Modificados

- `docker-compose.yml` - Configuração de networks e labels do Traefik
- `deploy.sh` - Melhorias nas verificações e remoção de conexão manual

## Arquivos Criados

- `diagnose-traefik.sh` - Script de diagnóstico
- `TROUBLESHOOTING.md` - Guia de troubleshooting
- `FIX-DEPLOY.md` - Guia de correção de deploy
- `CHANGELOG-DEPLOY.md` - Este arquivo

## Notas Importantes

1. **Network vpsnet deve ser attachable:** Sem isso, o docker-compose não conseguirá conectar os containers
2. **Traefik deve estar na network vpsnet:** Caso contrário, não conseguirá acessar os containers
3. **Entrypoints do Traefik:** Se seus entrypoints forem diferentes de `web` e `websecure`, ajuste o `docker-compose.yml`
4. **DNS:** Certifique-se de que os domínios apontam para o IP do servidor
5. **Certificados SSL:** O Traefik deve ter o certresolver `letsencrypt` configurado

## Suporte

Para mais informações, consulte:
- `FIX-DEPLOY.md` - Guia de correção passo a passo
- `TROUBLESHOOTING.md` - Guia completo de troubleshooting
- Execute `./diagnose-traefik.sh` para diagnóstico automático


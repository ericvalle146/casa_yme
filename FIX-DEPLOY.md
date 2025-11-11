# Correção do Problema de Deploy na VPS

## Problema Identificado

O problema principal é que a **network `vpsnet` não é attachable**, o que impede que o docker-compose conecte os containers a ela automaticamente. Além disso, os containers estavam sendo conectados manualmente após o início, o que pode causar problemas com o Traefik.

## Mudanças Realizadas

### 1. `docker-compose.yml`
- ✅ Adicionada a network `vpsnet` como external
- ✅ Containers agora estão configurados para estarem em ambas as networks (`imovelpro-network` e `vpsnet`) desde o início
- ✅ Melhorada a configuração dos labels do Traefik
- ✅ Adicionado redirecionamento HTTP para HTTPS

### 2. `deploy.sh`
- ✅ Melhorada a verificação da network `vpsnet`
- ✅ Removida a conexão manual dos containers (agora feita automaticamente pelo docker-compose)
- ✅ Adicionadas verificações mais detalhadas do Traefik
- ✅ Melhor feedback sobre problemas encontrados

### 3. Novos Arquivos
- ✅ `diagnose-traefik.sh` - Script de diagnóstico para identificar problemas
- ✅ `TROUBLESHOOTING.md` - Guia completo de troubleshooting

## Solução Passo a Passo

### Passo 1: Tornar a network vpsnet attachable

**IMPORTANTE:** Se você estiver usando Docker Swarm, você precisa parar o stack primeiro!

```bash
# Verificar se está usando Docker Swarm
docker stack ls

# Se houver stacks rodando, parar o stack do Traefik
docker stack rm <nome-do-stack-do-traefik>

# Aguardar até que todos os serviços sejam removidos
docker stack ps <nome-do-stack-do-traefik>
# Aguarde até que não haja mais serviços rodando
```

**Se NÃO estiver usando Docker Swarm:**

```bash
# Parar todos os containers que usam vpsnet (CUIDADO!)
# Listar containers na network
docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}'

# Parar containers manualmente se necessário
docker stop <container1> <container2> ...
```

### Passo 2: Remover e recriar a network

```bash
# Remover a network vpsnet
docker network rm vpsnet

# Recriar como attachable
docker network create --driver bridge --attachable vpsnet

# Verificar se foi criada corretamente
docker network inspect vpsnet --format '{{.Attachable}}'
# Deve retornar: true
```

### Passo 3: Reiniciar o Traefik

Se você estiver usando Docker Swarm:

```bash
# Reiniciar o stack do Traefik
docker stack deploy -c <docker-compose-traefik.yml> <nome-do-stack>
```

Se você não estiver usando Docker Swarm:

```bash
# Reiniciar o container do Traefik
docker restart <nome-do-container-traefik>

# Ou iniciar o Traefik se não estiver rodando
docker start <nome-do-container-traefik>
```

### Passo 4: Conectar o Traefik à network vpsnet (se necessário)

```bash
# Verificar se o Traefik está na network vpsnet
docker inspect <nome-do-container-traefik> --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}{{end}}'

# Se não estiver, conectar
docker network connect vpsnet <nome-do-container-traefik>
```

### Passo 5: Executar o deploy

```bash
# Executar o script de deploy
./deploy.sh
```

### Passo 6: Verificar se funcionou

```bash
# Executar o script de diagnóstico
./diagnose-traefik.sh

# Verificar se os containers estão na network vpsnet
docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}'

# Verificar se os domínios estão funcionando
curl -I https://imob.locusup.shop
curl -I https://apiapi.jyze.space/health
```

## Solução Rápida (Script Automático)

Se você não estiver usando Docker Swarm, pode usar este comando:

```bash
# ATENÇÃO: Isso vai parar TODOS os containers na network vpsnet!
# Faça backup ou tenha certeza do que está fazendo!

# Parar containers do projeto
docker compose down

# Remover e recriar network
docker network rm vpsnet
docker network create --driver bridge --attachable vpsnet

# Reiniciar Traefik (ajuste o nome do container)
docker restart $(docker ps --format "{{.Names}}" | grep -i traefik | head -1)

# Conectar Traefik à network (se necessário)
docker network connect vpsnet $(docker ps --format "{{.Names}}" | grep -i traefik | head -1)

# Executar deploy
./deploy.sh
```

## Verificações Pós-Deploy

1. **Containers rodando:**
```bash
docker compose ps
```

2. **Containers na network vpsnet:**
```bash
docker network inspect vpsnet --format '{{range .Containers}}{{.Name}} {{end}}'
```
Deve mostrar: `imovelpro-frontend imovelpro-backend` (e possivelmente o Traefik)

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

## Problemas Comuns

### Erro: "network vpsnet declared as external, but could not be found"

**Solução:**
```bash
docker network create --driver bridge --attachable vpsnet
```

### Erro: "network vpsnet is not attachable"

**Solução:**
Siga o Passo 1 e 2 acima para tornar a network attachable.

### Containers não aparecem no Traefik

**Solução:**
1. Verifique se os containers estão na network vpsnet
2. Verifique se o Traefik está na network vpsnet
3. Reinicie o Traefik: `docker restart <nome-do-container-traefik>`

### Certificados SSL não são gerados

**Solução:**
1. Verifique se os domínios apontam para o IP do servidor
2. Verifique se o certresolver está configurado no Traefik
3. Verifique os logs do Traefik: `docker logs <nome-do-container-traefik>`

## Próximos Passos

1. Execute o script de diagnóstico: `./diagnose-traefik.sh`
2. Se houver problemas, consulte o `TROUBLESHOOTING.md`
3. Verifique os logs dos containers: `docker compose logs -f`
4. Verifique os logs do Traefik: `docker logs <nome-do-container-traefik> -f`

## Suporte

Se você continuar tendo problemas após seguir este guia:

1. Execute o script de diagnóstico: `./diagnose-traefik.sh`
2. Verifique os logs: `docker compose logs -f`
3. Verifique a configuração do Traefik
4. Consulte o `TROUBLESHOOTING.md` para mais informações


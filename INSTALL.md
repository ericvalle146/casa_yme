# Guia de Deploy - ImóvelPro

Este guia explica como fazer o deploy da aplicação ImóvelPro na VPS usando Docker.

## Pré-requisitos

- VPS com Ubuntu 20.04+ ou Debian 11+
- Docker e Docker Compose instalados
- Nginx instalado (para proxy reverso)
- Certbot instalado (para SSL/HTTPS)
- Domínios configurados:
  - Frontend: `imob.locusup.shop`
  - Backend: `apiapi.jyze.space`

## Passo 1: Instalar Docker e Docker Compose

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Reiniciar sessão (ou fazer logout/login)
newgrp docker
```

## Passo 2: Instalar Nginx

```bash
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
```

## Passo 3: Instalar Certbot (Let's Encrypt)

```bash
sudo apt install certbot python3-certbot-nginx -y
```

## Passo 4: Preparar o Projeto

1. Copie todos os arquivos do projeto para a VPS (via git, scp, ou outro método)
2. Navegue até o diretório do projeto:
```bash
cd /caminho/para/projeto
```

3. Configure o arquivo de ambiente do backend:
```bash
cp server/env.example server/.env
nano server/.env
```

Edite o arquivo `server/.env` e configure:
```
PORT=4000
CORS_ORIGINS=https://imob.locusup.shop
N8N_WEBHOOK_URL=https://seu-webhook-n8n.com/webhook/endpoint
```

**IMPORTANTE**: Substitua `https://seu-webhook-n8n.com/webhook/endpoint` pela URL real do seu webhook do N8N.

## Passo 5: Tornar o Script de Deploy Executável

```bash
chmod +x deploy.sh
```

## Passo 6: Executar o Deploy

```bash
./deploy.sh
```

O script irá:
- Verificar se Docker e Docker Compose estão instalados
- Verificar se o arquivo `.env` do backend está configurado
- Parar containers existentes
- Construir as imagens Docker
- Iniciar os containers

## Passo 7: Configurar Nginx como Proxy Reverso

1. Copie o arquivo de configuração do Nginx:
```bash
sudo cp nginx-proxy.conf /etc/nginx/sites-available/imovelpro
```

2. Crie um link simbólico:
```bash
sudo ln -s /etc/nginx/sites-available/imovelpro /etc/nginx/sites-enabled/
```

3. Remova a configuração padrão do Nginx (opcional):
```bash
sudo rm /etc/nginx/sites-enabled/default
```

4. Teste a configuração do Nginx:
```bash
sudo nginx -t
```

5. Recarregue o Nginx:
```bash
sudo systemctl reload nginx
```

## Passo 8: Configurar SSL/HTTPS com Let's Encrypt

1. Obter certificados SSL para o frontend:
```bash
sudo certbot --nginx -d imob.locusup.shop
```

2. Obter certificados SSL para o backend:
```bash
sudo certbot --nginx -d apiapi.jyze.space
```

3. Certbot irá modificar automaticamente os arquivos do Nginx para incluir as configurações SSL.

4. Teste a renovação automática:
```bash
sudo certbot renew --dry-run
```

## Passo 9: Verificar o Deploy

1. Verificar status dos containers:
```bash
docker-compose ps
```

2. Verificar logs:
```bash
docker-compose logs -f
```

3. Verificar health checks:
```bash
# Frontend
curl http://localhost/health

# Backend
curl http://localhost:4000/health
```

4. Acessar a aplicação:
   - Frontend: https://imob.locusup.shop
   - Backend API: https://apiapi.jyze.space/health

## Comandos Úteis

### Parar os containers
```bash
docker-compose down
```

### Reiniciar os containers
```bash
docker-compose restart
```

### Ver logs em tempo real
```bash
docker-compose logs -f
```

### Ver logs de um serviço específico
```bash
docker-compose logs -f frontend
docker-compose logs -f backend
```

### Reconstruir e reiniciar
```bash
docker-compose up -d --build
```

### Acessar shell do container
```bash
docker-compose exec frontend sh
docker-compose exec backend sh
```

## Troubleshooting

### Containers não iniciam
```bash
# Verificar logs
docker-compose logs

# Verificar se as portas estão em uso
sudo netstat -tulpn | grep -E ':(80|4000)'
```

### Erro de permissão do Docker
```bash
# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER
newgrp docker
```

### Nginx não consegue se conectar aos containers
```bash
# Verificar se os containers estão rodando
docker-compose ps

# Verificar se as portas estão acessíveis
curl http://localhost:80
curl http://localhost:4000/health
```

### SSL não funciona
```bash
# Verificar certificados
sudo certbot certificates

# Renovar certificados manualmente
sudo certbot renew
```

## Atualizar a Aplicação

Para atualizar a aplicação após fazer alterações:

1. Faça pull das alterações (se usar git):
```bash
git pull
```

2. Reconstrua e reinicie os containers:
```bash
./deploy.sh
```

Ou manualmente:
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Notas Importantes

- O frontend está configurado para usar `https://apiapi.jyze.space` como URL da API
- O backend está configurado para aceitar requisições apenas de `https://imob.locusup.shop`
- Certifique-se de que o `N8N_WEBHOOK_URL` está correto no arquivo `server/.env`
- Os certificados SSL são renovados automaticamente pelo Certbot
- Os containers são reiniciados automaticamente em caso de falha (restart: unless-stopped)


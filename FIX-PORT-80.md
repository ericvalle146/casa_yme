# 🔧 Solução para Erro: Porta 80 já está em uso

## Problema
A porta 80 já está sendo usada (provavelmente pelo Nginx que já está rodando na VPS).

## Solução Rápida

### Opção 1: Parar Nginx temporariamente (RECOMENDADO)

```bash
# Parar o Nginx
sudo systemctl stop nginx

# Executar o deploy
./deploy.sh

# Depois do deploy, iniciar o Nginx novamente
sudo systemctl start nginx
```

### Opção 2: Verificar e liberar a porta 80

```bash
# Ver o que está usando a porta 80
sudo netstat -tulpn | grep :80
# ou
sudo ss -tulpn | grep :80

# Se for o Nginx, pare temporariamente
sudo systemctl stop nginx

# Execute o deploy
./deploy.sh

# Depois, configure o Nginx para fazer proxy reverso
sudo systemctl start nginx
```

### Opção 3: Mudar porta do container (NÃO RECOMENDADO)

Se você realmente não puder parar o Nginx, pode mudar a porta:

1. Edite `docker-compose.yml`:
```yaml
ports:
  - "8080:80"  # Mude de "80:80" para "8080:80"
```

2. Execute o deploy novamente:
```bash
./deploy.sh
```

3. Configure o Nginx para fazer proxy da porta 80 para 8080:
```nginx
location / {
    proxy_pass http://localhost:8080;
    ...
}
```

## ⚠️ IMPORTANTE

**A Opção 1 é a melhor**, pois:
- O Nginx na VPS deve fazer proxy reverso para o container
- O container não precisa expor a porta 80 diretamente
- É a configuração correta para produção

## Passos Completos Recomendados

```bash
# 1. Parar Nginx
sudo systemctl stop nginx

# 2. Executar deploy
./deploy.sh

# 3. Configurar Nginx como proxy reverso
sudo cp nginx-proxy.conf /etc/nginx/sites-available/imovelpro
sudo ln -s /etc/nginx/sites-available/imovelpro /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default  # opcional

# 4. Iniciar Nginx
sudo systemctl start nginx
sudo systemctl reload nginx

# 5. Configurar SSL
sudo certbot --nginx -d casayme.com.br
sudo certbot --nginx -d apiapi.jyze.space
```

## Verificação

Após configurar, verifique:

```bash
# Ver se containers estão rodando
docker-compose ps

# Ver se Nginx está rodando
sudo systemctl status nginx

# Testar
curl http://localhost/health
curl http://localhost:4000/health
```


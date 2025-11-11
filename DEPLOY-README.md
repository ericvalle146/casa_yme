# 📦 Arquivos de Deploy Criados

## ✅ Arquivos Principais

### 1. **deploy.sh** (Script Executável)
Script bash para executar o deploy na VPS. Basta executar:
```bash
chmod +x deploy.sh
./deploy.sh
```

### 2. **docker-compose.yml**
Configuração do Docker Compose com:
- Frontend: Container Nginx na porta 80
- Backend: Container Node.js na porta 4000
- Rede interna entre containers
- Health checks configurados
- Restart automático

### 3. **Dockerfile.frontend**
Dockerfile multi-stage para o frontend:
- Build da aplicação React/Vite
- Servido com Nginx Alpine
- Configurado com `VITE_API_BASE_URL=https://apiapi.jyze.space`

### 4. **server/Dockerfile**
Dockerfile para o backend:
- Node.js 20 Alpine
- Apenas dependências de produção
- Health check configurado

### 5. **nginx.conf**
Configuração do Nginx dentro do container do frontend:
- Servindo arquivos estáticos
- Roteamento SPA (React Router)
- Gzip compression
- Security headers
- Health check endpoint

### 6. **nginx-proxy.conf**
Configuração do Nginx na VPS (proxy reverso):
- Frontend: `imob.locusup.shop` → Container porta 80
- Backend: `apiapi.jyze.space` → Container porta 4000
- SSL/HTTPS configurável via Let's Encrypt

## 📋 Documentação

### **DEPLOY.md**
Guia rápido de deploy com comandos essenciais.

### **INSTALL.md**
Guia completo de instalação incluindo:
- Instalação do Docker e Docker Compose
- Configuração do Nginx
- Configuração do SSL/HTTPS
- Troubleshooting

### **README.md** (atualizado)
Documentação principal com seção de deploy atualizada.

## 🔧 Configurações

### Variáveis de Ambiente

#### Frontend (Build-time)
- `VITE_API_BASE_URL=https://apiapi.jyze.space` (configurado no docker-compose.yml)

#### Backend (Runtime)
- `PORT=4000`
- `CORS_ORIGINS=https://imob.locusup.shop`
- `N8N_WEBHOOK_URL=<sua-url>` (OBRIGATÓRIO - configure em server/.env)

### Arquivos .env.example Atualizados
- `frontend.env.example`: URL do backend em produção
- `server/env.example`: Domínio do frontend e webhook do N8N

## 🚀 Como Usar

1. **Na VPS, copie o projeto**:
   ```bash
   git clone <seu-repositorio>
   cd Prototipo_Mariana_Imobiliarias-main
   ```

2. **Configure o backend**:
   ```bash
   cd server
   cp env.example .env
   nano .env  # Configure N8N_WEBHOOK_URL
   ```

3. **Execute o deploy**:
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

4. **Configure Nginx e SSL**:
   ```bash
   sudo cp nginx-proxy.conf /etc/nginx/sites-available/imovelpro
   sudo ln -s /etc/nginx/sites-available/imovelpro /etc/nginx/sites-enabled/
   sudo certbot --nginx -d imob.locusup.shop
   sudo certbot --nginx -d apiapi.jyze.space
   ```

## 📝 Notas Importantes

- O frontend está configurado para usar `https://apiapi.jyze.space` como URL da API
- O backend aceita requisições apenas de `https://imob.locusup.shop`
- Certifique-se de configurar o `N8N_WEBHOOK_URL` no arquivo `server/.env`
- Os certificados SSL são renovados automaticamente pelo Certbot
- Os containers reiniciam automaticamente em caso de falha

## 🔍 Verificação

Após o deploy, verifique:

```bash
# Status dos containers
docker-compose ps

# Logs
docker-compose logs -f

# Health checks
curl http://localhost/health          # Frontend
curl http://localhost:4000/health     # Backend
```

## 🆘 Suporte

Para problemas, consulte:
- `INSTALL.md` - Guia completo de instalação
- `DEPLOY.md` - Guia rápido de deploy
- Logs dos containers: `docker-compose logs -f`


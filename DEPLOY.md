# Deploy Rápido - ImóvelPro

## Arquivo Executável de Deploy

O arquivo `deploy.sh` está pronto para uso. Siga estes passos:

### 1. Na VPS, copie o projeto

```bash
# Via git (recomendado)
git clone <seu-repositorio>
cd Prototipo_Mariana_Imobiliarias-main

# Ou via scp/rsync
scp -r /caminho/local/projeto user@vps:/caminho/na/vps
```

### 2. Configure o ambiente do backend

```bash
cd server
cp env.example .env
nano .env
```

**Configure obrigatoriamente:**
- `N8N_WEBHOOK_URL`: URL do seu webhook do N8N
- `CORS_ORIGINS`: https://casayme.com.br (já configurado)

### 3. Execute o deploy

```bash
chmod +x deploy.sh
./deploy.sh
```

### 4. Configure Nginx e SSL

Siga as instruções no arquivo `INSTALL.md` para configurar o Nginx como proxy reverso e obter certificados SSL.

## Domínios Configurados

- **Frontend**: `casayme.com.br` → Container na porta 80
- **Backend**: `apiapi.jyze.space` → Container na porta 4000

## Variáveis de Ambiente

### Frontend (Build-time)
- `VITE_API_BASE_URL=https://apiapi.jyze.space` (configurado no docker-compose.yml)

### Backend (Runtime)
- `PORT=4000`
- `CORS_ORIGINS=https://casayme.com.br`
- `N8N_WEBHOOK_URL=<sua-url-do-webhook>` (OBRIGATÓRIO)

## Comandos Úteis

```bash
# Ver status
docker-compose ps

# Ver logs
docker-compose logs -f

# Reiniciar
docker-compose restart

# Parar
docker-compose down

# Reconstruir
docker-compose up -d --build
```

## Troubleshooting

### Containers não iniciam
```bash
docker-compose logs
```

### Verificar se as portas estão livres
```bash
sudo netstat -tulpn | grep -E ':(80|4000)'
```

### Testar API do backend
```bash
curl http://localhost:4000/health
```

### Testar frontend
```bash
curl http://localhost/health
```


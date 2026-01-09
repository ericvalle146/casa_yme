# 🚀 Deploy Automático - Casa YME

Deploy 100% automatizado para a aplicação Casa YME na VPS.

## 📋 Pré-requisitos

- Docker e Docker Compose instalados na VPS
- Domínios apontados para o IP da VPS:
  - `casayme.com.br` → IP da VPS
  - `backend.casayme.com.br` → IP da VPS
- Banco de dados Postgres externo já configurado
- Portas 80 e 443 liberadas no firewall

## 🎯 Como usar

### 1. Subir os arquivos para a VPS

```bash
# Na sua máquina local, dentro do projeto
scp -r deploy/ usuario@ip-da-vps:/home/usuario/casa_yme/
scp -r frontend/ usuario@ip-da-vps:/home/usuario/casa_yme/
scp -r backend/ usuario@ip-da-vps:/home/usuario/casa_yme/
scp -r sql/ usuario@ip-da-vps:/home/usuario/casa_yme/
```

### 2. Conectar na VPS e rodar o deploy

```bash
# Conectar na VPS
ssh usuario@ip-da-vps

# Entrar na pasta de deploy
cd /home/usuario/casa_yme/deploy

# Tornar o script executável (apenas na primeira vez)
chmod +x deploy.sh

# RODAR O DEPLOY - APENAS ISSO!
./deploy.sh
```

**Pronto! O script faz TUDO automaticamente:**
- ✅ Cria o arquivo `.env` com dados reais
- ✅ Gera uma chave de segurança JWT aleatória
- ✅ Valida todas as configurações
- ✅ Faz build dos containers
- ✅ Configura SSL com Let's Encrypt
- ✅ Sobe toda a aplicação

### 3. Verificar se subiu

```bash
# Ver status dos containers
docker compose ps

# Ver logs em tempo real
docker compose logs -f

# Testar o backend
curl https://backend.casayme.com.br/health

# Testar o frontend
curl https://casayme.com.br
```

## 🌐 Acessar a aplicação

Após o deploy, acesse:

- **Frontend**: https://casayme.com.br
- **Backend**: https://backend.casayme.com.br
- **Traefik Dashboard**: http://ip-da-vps:8080

## ⚙️ Configurações

### Arquivo `.env.example`

Contém **TODOS os dados reais** já configurados:

- ✅ Domínios de produção
- ✅ Email para SSL
- ✅ Conexão com banco de dados externo
- ✅ CORS configurado
- ✅ Todas as variáveis do backend

O script `deploy.sh` copia automaticamente `.env.example` → `.env`

### Variáveis importantes

Se precisar alterar algo, edite o `.env` após o primeiro deploy:

```bash
# Editar configurações (opcional)
nano .env

# Aplicar mudanças
docker compose up -d --build
```

## 📝 Variáveis de ambiente

| Variável | Valor Padrão | Descrição |
|----------|--------------|-----------|
| `DOMAIN_FRONTEND` | casayme.com.br | Domínio do site |
| `DOMAIN_BACKEND` | backend.casayme.com.br | Domínio da API |
| `LETSENCRYPT_EMAIL` | contato@casayme.com.br | Email para SSL |
| `DB_HOST` | 72.61.131.168 | IP do banco externo |
| `DB_USER` | admin | Usuário do banco |
| `DB_PASSWORD` | *** | Senha do banco |
| `DB_NAME` | casa_yme | Nome do banco |
| `VITE_WEBHOOK_URL` | (vazio) | Webhook N8N (opcional) |

## 🔧 Comandos úteis

```bash
# Ver logs de um serviço específico
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f traefik

# Reiniciar um serviço
docker compose restart backend

# Parar tudo
docker compose down

# Atualizar e fazer redeploy
git pull  # se estiver usando git
./deploy.sh

# Limpar tudo e fazer deploy limpo
docker compose down -v
./deploy.sh
```

## 🐛 Troubleshooting

### SSL não funciona

1. Verificar se os domínios apontam para o IP correto:
   ```bash
   nslookup casayme.com.br
   nslookup backend.casayme.com.br
   ```

2. Ver logs do Traefik:
   ```bash
   docker logs traefik
   ```

3. Aguardar alguns minutos - Let's Encrypt pode demorar

### Backend não conecta no banco

1. Verificar se o IP do banco está acessível:
   ```bash
   nc -zv 72.61.131.168 5432
   ```

2. Ver logs do backend:
   ```bash
   docker compose logs backend
   ```

### Containers não sobem

1. Ver status:
   ```bash
   docker compose ps
   ```

2. Ver logs de erro:
   ```bash
   docker compose logs
   ```

## 📦 Estrutura

```
deploy/
├── docker-compose.yml   # Configuração dos serviços
├── .env.example         # Variáveis com dados reais
├── .env                 # Gerado automaticamente pelo script
├── deploy.sh            # Script de deploy automático
└── README.md            # Este arquivo
```

## 🔄 Atualizar a aplicação

Para atualizar o código:

```bash
# Fazer as mudanças no código
# Subir novamente para a VPS
scp -r frontend/ usuario@ip-da-vps:/home/usuario/casa_yme/
scp -r backend/ usuario@ip-da-vps:/home/usuario/casa_yme/

# Na VPS, fazer redeploy
cd /home/usuario/casa_yme/deploy
./deploy.sh
```

## 📧 Suporte

Em caso de problemas, verifique:
1. Os logs dos containers
2. Se os domínios estão apontando corretamente
3. Se as portas 80 e 443 estão liberadas
4. Se o banco de dados está acessível

---

**Deploy automático criado para Casa YME** 🏠

# 🚀 Guia Rápido de Deploy - Casa YME

Deploy 100% automático para VPS. **Você só precisa rodar 2 comandos!**

## ✅ Pré-requisitos

Na VPS, você precisa ter instalado:
- [x] Docker
- [x] Docker Compose

DNS configurado:
- [x] `casayme.com.br` apontando para o IP da VPS
- [x] `backend.casayme.com.br` apontando para o IP da VPS

Portas liberadas no firewall:
- [x] Porta 80 (HTTP)
- [x] Porta 443 (HTTPS)

---

## 🎯 Opção 1: Upload Automático (Recomendado)

### 1. Rodar o script de upload

Na sua máquina local, execute:

```bash
./enviar-para-vps.sh
```

O script vai pedir:
- Usuário da VPS (ex: `root`, `ubuntu`)
- IP da VPS (ex: `123.45.67.89`)
- Caminho de destino (ex: `/root/casa_yme`)

### 2. Fazer deploy na VPS

Após o upload, conecte na VPS e rode:

```bash
cd /root/casa_yme/deploy
./deploy.sh
```

**Pronto! Aguarde alguns minutos e sua aplicação estará no ar!** 🎉

---

## 📦 Opção 2: Upload Manual

### 1. Enviar arquivos para VPS

```bash
# Na sua máquina local
scp -r deploy/ usuario@ip-vps:/root/casa_yme/
scp -r frontend/ usuario@ip-vps:/root/casa_yme/
scp -r backend/ usuario@ip-vps:/root/casa_yme/
scp -r sql/ usuario@ip-vps:/root/casa_yme/
```

### 2. Conectar na VPS e fazer deploy

```bash
# Conectar na VPS
ssh usuario@ip-vps

# Entrar na pasta e rodar deploy
cd /root/casa_yme/deploy
chmod +x deploy.sh
./deploy.sh
```

---

## 🧪 Testar Localmente (Opcional)

Antes de subir para produção, você pode testar localmente:

```bash
cd deploy/
./test-local.sh
```

Acesse http://localhost para ver a aplicação rodando localmente.

---

## 📊 O que o deploy faz automaticamente?

O script `deploy.sh` faz **TUDO** para você:

1. ✅ Cria o arquivo `.env` com dados reais (sem você precisar editar nada)
2. ✅ Gera uma chave de segurança JWT aleatória e forte
3. ✅ Valida todas as configurações
4. ✅ Faz build do frontend e backend
5. ✅ Configura o Traefik com SSL automático (Let's Encrypt)
6. ✅ Sobe todos os containers (frontend, backend, traefik)
7. ✅ Configura redirecionamento HTTP → HTTPS
8. ✅ Conecta no banco de dados Postgres externo

**Você não precisa configurar NADA! Apenas rode `./deploy.sh`**

---

## 🌐 Acessar após deploy

- **Frontend**: https://casayme.com.br
- **Backend**: https://backend.casayme.com.br
- **API Health**: https://backend.casayme.com.br/health
- **Traefik Dashboard**: http://IP-DA-VPS:8080

---

## 🔧 Comandos úteis na VPS

```bash
# Ver status dos containers
docker compose ps

# Ver logs em tempo real
docker compose logs -f

# Ver logs só do backend
docker compose logs -f backend

# Ver logs só do frontend
docker compose logs -f frontend

# Reiniciar tudo
docker compose restart

# Parar tudo
docker compose down

# Refazer deploy
./deploy.sh
```

---

## 🐛 Problemas comuns

### SSL não funciona

**Solução:**
1. Verifique se os domínios apontam para o IP correto:
   ```bash
   nslookup casayme.com.br
   nslookup backend.casayme.com.br
   ```
2. Aguarde 2-5 minutos - Let's Encrypt leva um tempo
3. Veja os logs do Traefik: `docker logs traefik`

### Backend não conecta no banco

**Solução:**
1. Verifique se o IP do banco está acessível:
   ```bash
   nc -zv 72.61.131.168 5432
   ```
2. Veja os logs: `docker compose logs backend`

### Containers não sobem

**Solução:**
```bash
docker compose down
docker system prune -af
./deploy.sh
```

---

## 🔄 Atualizar código em produção

Quando fizer alterações no código:

### Opção 1: Com script automático
```bash
# Na sua máquina local
./enviar-para-vps.sh

# Na VPS
cd /root/casa_yme/deploy
./deploy.sh
```

### Opção 2: Manual
```bash
# Enviar código atualizado
scp -r frontend/ usuario@ip-vps:/root/casa_yme/
scp -r backend/ usuario@ip-vps:/root/casa_yme/

# Na VPS, refazer deploy
cd /root/casa_yme/deploy
./deploy.sh
```

---

## 📝 Estrutura dos arquivos

```
casa_yme/
├── deploy/
│   ├── docker-compose.yml    # Configuração dos containers
│   ├── .env.example          # Variáveis com DADOS REAIS
│   ├── deploy.sh             # Script de deploy automático ⭐
│   ├── test-local.sh         # Testar localmente
│   └── README.md             # Documentação completa
├── frontend/                 # Código React
├── backend/                  # Código Node.js
├── sql/                      # Scripts SQL do banco
├── enviar-para-vps.sh        # Script de upload automático ⭐
└── GUIA-DEPLOY.md            # Este arquivo
```

---

## ⚙️ Configurações do .env

Todas as configurações já estão no arquivo `.env.example` com **dados reais**:

| Configuração | Valor |
|--------------|-------|
| Frontend | casayme.com.br |
| Backend | backend.casayme.com.br |
| Email SSL | contato@casayme.com.br |
| Banco IP | 72.61.131.168 |
| Banco Usuário | admin |
| Banco Nome | casa_yme |
| Banco Senha | (configurada) |

O script `deploy.sh` copia automaticamente `.env.example` → `.env`

---

## 🎉 Resumo

**Para fazer deploy pela primeira vez:**

```bash
# 1. Na sua máquina
./enviar-para-vps.sh

# 2. Na VPS (após conectar)
cd /root/casa_yme/deploy
./deploy.sh

# Pronto! 🚀
```

**Para atualizar depois:**

```bash
# 1. Na sua máquina
./enviar-para-vps.sh

# 2. Na VPS
cd /root/casa_yme/deploy
./deploy.sh
```

---

## 💡 Dicas

- O primeiro deploy pode demorar 5-10 minutos (download de imagens Docker + build)
- SSL demora 2-5 minutos para ser gerado pelo Let's Encrypt
- Use `docker compose logs -f` para acompanhar o processo
- Se algo der errado, rode `./deploy.sh` novamente

---

**Deploy criado com ❤️ para Casa YME** 🏠

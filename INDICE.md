# 📚 Índice - Documentação de Deploy

Navegue rapidamente pela documentação do deploy automático.

---

## 🚀 Começar Aqui

### Para quem quer fazer deploy agora
1. 📄 **[COMO-FAZER-DEPLOY.txt](COMO-FAZER-DEPLOY.txt)** - Resumo de 2 minutos
2. 🎯 **[DEPLOY-PRONTO.md](DEPLOY-PRONTO.md)** - Visão geral completa
3. ⚡ **[enviar-para-vps.sh](enviar-para-vps.sh)** - Script de upload

### Para quem quer entender tudo
1. 📖 **[GUIA-DEPLOY.md](GUIA-DEPLOY.md)** - Guia passo a passo detalhado
2. ✅ **[CHECKLIST-DEPLOY.md](CHECKLIST-DEPLOY.md)** - Checklist de validação
3. 📁 **[deploy/README.md](deploy/README.md)** - Documentação técnica

---

## 📂 Estrutura de Arquivos

### 🎯 Arquivos Principais (USE ESTES)

| Arquivo | Descrição | Quando Usar |
|---------|-----------|-------------|
| **[enviar-para-vps.sh](enviar-para-vps.sh)** | Upload automático para VPS | Antes do deploy |
| **[validar-antes-deploy.sh](validar-antes-deploy.sh)** | Validação pré-deploy | Antes do deploy |
| **[deploy/deploy.sh](deploy/deploy.sh)** | Deploy automático | Na VPS |
| **[deploy/test-local.sh](deploy/test-local.sh)** | Teste local | Opcional, antes da VPS |

### 📖 Documentação

| Arquivo | Conteúdo | Para Quem |
|---------|----------|-----------|
| **[COMO-FAZER-DEPLOY.txt](COMO-FAZER-DEPLOY.txt)** | Resumo executivo (2 min) | Quem quer rapidez |
| **[DEPLOY-PRONTO.md](DEPLOY-PRONTO.md)** | Visão geral completa | Quem quer contexto |
| **[GUIA-DEPLOY.md](GUIA-DEPLOY.md)** | Guia passo a passo | Quem quer detalhes |
| **[CHECKLIST-DEPLOY.md](CHECKLIST-DEPLOY.md)** | Checklist de validação | Quem quer garantir tudo |
| **[deploy/README.md](deploy/README.md)** | Documentação técnica | Desenvolvedores |
| **[INDICE.md](INDICE.md)** | Este arquivo | Navegação |

### ⚙️ Configuração

| Arquivo | Descrição | Editável? |
|---------|-----------|-----------|
| **[deploy/.env.example](deploy/.env.example)** | Variáveis com dados reais | ✅ Sim, se necessário |
| **[deploy/docker-compose.yml](deploy/docker-compose.yml)** | Configuração containers | ⚠️ Não recomendado |
| **[frontend/Dockerfile](frontend/Dockerfile)** | Build do frontend | ⚠️ Não recomendado |
| **[backend/Dockerfile](backend/Dockerfile)** | Build do backend | ⚠️ Não recomendado |

### 📊 Banco de Dados

| Arquivo | Descrição |
|---------|-----------|
| **[sql/001-auth.sql](sql/001-auth.sql)** | Tabelas de autenticação |
| **[sql/002-properties.sql](sql/002-properties.sql)** | Tabelas de imóveis |
| **[sql/003-seed-properties.sql](sql/003-seed-properties.sql)** | Dados iniciais |

---

## 🎯 Fluxos de Uso

### Fluxo 1: Deploy Pela Primeira Vez

```
1. Ler: COMO-FAZER-DEPLOY.txt (2 min)
   ↓
2. Executar: ./validar-antes-deploy.sh
   ↓
3. Executar: ./enviar-para-vps.sh
   ↓
4. Na VPS: cd deploy && ./deploy.sh
   ↓
5. Acessar: https://casayme.com.br
```

### Fluxo 2: Testar Localmente Antes

```
1. Ler: deploy/README.md
   ↓
2. Executar: cd deploy && ./test-local.sh
   ↓
3. Testar: http://localhost
   ↓
4. Se OK: Seguir Fluxo 1 (deploy produção)
```

### Fluxo 3: Atualizar Código

```
1. Fazer mudanças no código
   ↓
2. Executar: ./enviar-para-vps.sh
   ↓
3. Na VPS: cd deploy && ./deploy.sh
   ↓
4. Verificar: docker compose logs -f
```

### Fluxo 4: Troubleshooting

```
1. Ler: CHECKLIST-DEPLOY.md (seção "Se algo deu errado")
   ↓
2. Ver logs: docker compose logs
   ↓
3. Tentar: docker compose down && ./deploy.sh
   ↓
4. Se persistir: Ver GUIA-DEPLOY.md (seção Troubleshooting)
```

---

## 📋 Comandos Rápidos

### Validação
```bash
./validar-antes-deploy.sh          # Validar antes de enviar
```

### Upload
```bash
./enviar-para-vps.sh               # Enviar para VPS
```

### Deploy
```bash
cd deploy && ./deploy.sh           # Fazer deploy
```

### Teste Local
```bash
cd deploy && ./test-local.sh       # Testar localmente
```

### Monitoramento
```bash
docker compose ps                  # Ver status
docker compose logs -f             # Ver logs ao vivo
docker compose logs backend        # Logs do backend
```

### Manutenção
```bash
docker compose restart             # Reiniciar
docker compose down                # Parar
./deploy.sh                        # Refazer deploy
```

---

## 🎓 Entendendo a Arquitetura

### Componentes

```
┌─────────────────────────────────────────────┐
│           INTERNET (HTTPS)                  │
└─────────────┬───────────────────────────────┘
              │
              │  Port 80/443
              ▼
┌─────────────────────────────────────────────┐
│         TRAEFIK (Proxy + SSL)               │
│  - Certificados Let's Encrypt               │
│  - Redirecionamento HTTP → HTTPS            │
│  - Roteamento por domínio                   │
└──────────┬──────────────────┬───────────────┘
           │                  │
           │                  │
           ▼                  ▼
┌──────────────────┐  ┌──────────────────┐
│   FRONTEND       │  │    BACKEND       │
│   (Nginx)        │  │    (Node.js)     │
│                  │  │                  │
│  casayme.com.br  │  │  backend.        │
│                  │  │  casayme.com.br  │
└──────────────────┘  └────────┬─────────┘
                               │
                               │
                               ▼
                    ┌──────────────────┐
                    │  POSTGRES        │
                    │  (Externo)       │
                    │  72.61.131.168   │
                    └──────────────────┘
```

### Fluxo de Requisição

```
1. Usuário acessa casayme.com.br
   ↓
2. Traefik recebe na porta 80
   ↓
3. Traefik redireciona para HTTPS (443)
   ↓
4. Traefik roteia para container frontend
   ↓
5. Nginx serve o React build
   ↓
6. React faz chamadas para backend.casayme.com.br/api
   ↓
7. Traefik roteia para container backend
   ↓
8. Backend processa e consulta Postgres
   ↓
9. Resposta retorna para frontend
   ↓
10. Usuário vê o resultado
```

---

## 🔧 Variáveis de Ambiente

### Variáveis Críticas (NÃO MUDAR)

| Variável | Valor | Motivo |
|----------|-------|--------|
| `DOMAIN_FRONTEND` | casayme.com.br | DNS configurado |
| `DOMAIN_BACKEND` | backend.casayme.com.br | DNS configurado |
| `DB_HOST` | 72.61.131.168 | Banco externo |
| `DB_USER` | admin | Usuário do banco |
| `DB_PASSWORD` | *** | Senha do banco |
| `DB_NAME` | casa_yme | Nome do banco |

### Variáveis Opcionais (PODE MUDAR)

| Variável | Valor Padrão | Quando Mudar |
|----------|--------------|--------------|
| `LETSENCRYPT_EMAIL` | contato@casayme.com.br | Usar outro email |
| `VITE_WEBHOOK_URL` | (vazio) | Ao configurar N8N |
| `N8N_WEBHOOK_URL` | (vazio) | Ao configurar N8N |

### Variáveis Automáticas (GERADAS)

| Variável | Como é Gerada |
|----------|---------------|
| `ACCESS_TOKEN_SECRET` | Script gera 64 caracteres aleatórios |

---

## 📦 Checklist de Arquivos

Use para verificar se todos os arquivos estão presentes:

### Raiz do Projeto
- [ ] enviar-para-vps.sh
- [ ] validar-antes-deploy.sh
- [ ] COMO-FAZER-DEPLOY.txt
- [ ] DEPLOY-PRONTO.md
- [ ] GUIA-DEPLOY.md
- [ ] CHECKLIST-DEPLOY.md
- [ ] INDICE.md

### deploy/
- [ ] deploy.sh
- [ ] docker-compose.yml
- [ ] .env.example
- [ ] test-local.sh
- [ ] README.md

### frontend/
- [ ] Dockerfile
- [ ] nginx.conf
- [ ] package.json
- [ ] src/

### backend/
- [ ] Dockerfile
- [ ] package.json
- [ ] src/

### sql/
- [ ] 001-auth.sql
- [ ] 002-properties.sql
- [ ] 003-seed-properties.sql

---

## 🎯 Por Onde Começar?

### Você quer fazer deploy AGORA?
👉 Leia: **[COMO-FAZER-DEPLOY.txt](COMO-FAZER-DEPLOY.txt)** (2 minutos)

### Você quer entender tudo primeiro?
👉 Leia: **[DEPLOY-PRONTO.md](DEPLOY-PRONTO.md)** (5 minutos)

### Você quer um guia passo a passo?
👉 Leia: **[GUIA-DEPLOY.md](GUIA-DEPLOY.md)** (10 minutos)

### Você quer validar tudo antes?
👉 Use: **[CHECKLIST-DEPLOY.md](CHECKLIST-DEPLOY.md)** e **./validar-antes-deploy.sh**

### Você quer testar localmente?
👉 Use: **[deploy/test-local.sh](deploy/test-local.sh)**

---

## 🆘 Precisa de Ajuda?

### Problema com Deploy
1. Ver: [CHECKLIST-DEPLOY.md](CHECKLIST-DEPLOY.md) - Seção "Se algo deu errado"
2. Ver: [GUIA-DEPLOY.md](GUIA-DEPLOY.md) - Seção "Troubleshooting"
3. Rodar: `docker compose logs` para ver erros

### Dúvida sobre Configuração
1. Ver: [DEPLOY-PRONTO.md](DEPLOY-PRONTO.md) - Seção "Configurações"
2. Ver: [deploy/.env.example](deploy/.env.example) - Comentários das variáveis
3. Ver: [deploy/README.md](deploy/README.md) - Documentação técnica

### Erro Específico
1. SSL: Ver [GUIA-DEPLOY.md](GUIA-DEPLOY.md) - "SSL não funciona"
2. Banco: Ver [CHECKLIST-DEPLOY.md](CHECKLIST-DEPLOY.md) - "Backend não conecta no banco"
3. Containers: Ver [DEPLOY-PRONTO.md](DEPLOY-PRONTO.md) - "Troubleshooting"

---

## 📊 Resumo Visual

```
DOCUMENTAÇÃO
├── INÍCIO RÁPIDO
│   └── COMO-FAZER-DEPLOY.txt .................. 📝 Resumo de 2 min
│
├── VISÃO GERAL
│   ├── DEPLOY-PRONTO.md ....................... 🎯 Status e contexto
│   └── INDICE.md .............................. 📚 Este arquivo
│
├── GUIAS DETALHADOS
│   ├── GUIA-DEPLOY.md ......................... 📖 Passo a passo
│   └── CHECKLIST-DEPLOY.md .................... ✅ Validação
│
└── DOCUMENTAÇÃO TÉCNICA
    └── deploy/README.md ....................... 🔧 Referência técnica

SCRIPTS
├── AUTOMAÇÃO
│   ├── enviar-para-vps.sh ..................... 📤 Upload automático
│   └── validar-antes-deploy.sh ................ 🔍 Validação
│
└── DEPLOY
    ├── deploy/deploy.sh ....................... 🚀 Deploy automático
    └── deploy/test-local.sh ................... 🧪 Teste local

CONFIGURAÇÃO
├── deploy/.env.example ........................ ⚙️ Variáveis (DADOS REAIS)
├── deploy/docker-compose.yml .................. 🐳 Containers
├── frontend/Dockerfile ........................ 📦 Build frontend
└── backend/Dockerfile ......................... 📦 Build backend
```

---

## ✅ Validação Final

Execute para garantir que tudo está OK:

```bash
./validar-antes-deploy.sh
```

**Resultado Esperado:** ✅ TUDO PRONTO PARA DEPLOY! 🎉

---

## 🎉 Pronto!

Você tem um sistema de deploy completamente automático e documentado.

**Próximos passos:**
1. Execute: `./validar-antes-deploy.sh`
2. Execute: `./enviar-para-vps.sh`
3. Na VPS: `cd deploy && ./deploy.sh`
4. Acesse: https://casayme.com.br

---

**📚 Documentação criada para Casa YME**

**Status:** ✅ COMPLETA E VALIDADA

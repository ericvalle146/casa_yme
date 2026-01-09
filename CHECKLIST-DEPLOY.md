# ✅ Checklist de Deploy - Casa YME

Use este checklist para garantir que tudo está pronto antes do deploy.

---

## 📋 Pré-Deploy

### VPS
- [ ] Docker instalado (`docker --version`)
- [ ] Docker Compose instalado (`docker compose version`)
- [ ] Portas 80 e 443 liberadas no firewall
- [ ] Acesso SSH configurado

### DNS
- [ ] `casayme.com.br` aponta para o IP da VPS
- [ ] `backend.casayme.com.br` aponta para o IP da VPS
- [ ] Verificado com `nslookup casayme.com.br`
- [ ] Verificado com `nslookup backend.casayme.com.br`

### Banco de Dados
- [ ] Banco Postgres acessível em `72.61.131.168:5432`
- [ ] Banco `casa_yme` existe
- [ ] Usuário `admin` tem permissões
- [ ] Senha `a32js@31#t3?$1%&*!Sk45!` está correta
- [ ] Tabelas criadas (`users`, `auth_sessions`, `properties`, `property_media`)
- [ ] Testado conexão: `nc -zv 72.61.131.168 5432`

---

## 🔧 Configuração

### Arquivos Verificados
- [ ] `deploy/.env.example` existe com dados reais
- [ ] `deploy/docker-compose.yml` configurado
- [ ] `deploy/deploy.sh` tem permissão de execução
- [ ] `frontend/Dockerfile` existe
- [ ] `backend/Dockerfile` existe
- [ ] `sql/` contém scripts de criação das tabelas

### Variáveis de Ambiente
- [ ] `DOMAIN_FRONTEND=casayme.com.br`
- [ ] `DOMAIN_BACKEND=backend.casayme.com.br`
- [ ] `LETSENCRYPT_EMAIL=contato@casayme.com.br`
- [ ] `DB_HOST=72.61.131.168`
- [ ] `DB_USER=admin`
- [ ] `DB_PASSWORD` configurada
- [ ] `DB_NAME=casa_yme`

---

## 🧪 Teste Local (Opcional mas Recomendado)

```bash
cd deploy/
./test-local.sh
```

- [ ] Script executou sem erros
- [ ] Frontend acessível em `http://localhost`
- [ ] Backend acessível em `http://localhost/health`
- [ ] Traefik Dashboard em `http://localhost:8080`
- [ ] Backend conectou no banco de dados
- [ ] Logs sem erros críticos (`docker compose logs`)

Se o teste local passou, você está pronto para produção!

---

## 🚀 Deploy em Produção

### 1. Upload dos Arquivos

#### Opção A: Script Automático (Recomendado)
```bash
./enviar-para-vps.sh
```

- [ ] Informou usuário da VPS
- [ ] Informou IP da VPS
- [ ] Informou caminho de destino
- [ ] Upload completou sem erros
- [ ] Todos os arquivos enviados (deploy, frontend, backend, sql)

#### Opção B: Upload Manual
```bash
scp -r deploy/ usuario@ip:/root/casa_yme/
scp -r frontend/ usuario@ip:/root/casa_yme/
scp -r backend/ usuario@ip:/root/casa_yme/
scp -r sql/ usuario@ip:/root/casa_yme/
```

- [ ] Pasta `deploy/` enviada
- [ ] Pasta `frontend/` enviada
- [ ] Pasta `backend/` enviada
- [ ] Pasta `sql/` enviada

### 2. Executar Deploy na VPS

```bash
ssh usuario@ip-vps
cd /root/casa_yme/deploy
chmod +x deploy.sh
./deploy.sh
```

- [ ] Conectou na VPS
- [ ] Navegou para o diretório correto
- [ ] Script `deploy.sh` tem permissão de execução
- [ ] Executou `./deploy.sh`
- [ ] Script completou sem erros
- [ ] Mensagem de sucesso exibida

---

## ✅ Pós-Deploy

### Containers
```bash
docker compose ps
```

- [ ] Container `traefik` rodando (status: `Up`)
- [ ] Container `backend_casayme` rodando (status: `Up (healthy)`)
- [ ] Container `frontend_casayme` rodando (status: `Up`)
- [ ] Nenhum container com status `Exited` ou `Restarting`

### Logs
```bash
docker compose logs
```

- [ ] Sem erros críticos nos logs
- [ ] Backend conectou no banco de dados
- [ ] Traefik gerou certificados SSL
- [ ] Frontend compilado com sucesso

### Acessibilidade

#### Frontend
```bash
curl -I https://casayme.com.br
```
- [ ] Status `200 OK` ou `301/302` (redirect)
- [ ] Acessível no navegador
- [ ] SSL funcionando (cadeado verde)
- [ ] Sem avisos de certificado inválido

#### Backend
```bash
curl https://backend.casayme.com.br/health
```
- [ ] Retorna `{"status":"ok"}`
- [ ] Status `200 OK`
- [ ] SSL funcionando

#### Traefik Dashboard
```bash
curl -I http://ip-vps:8080
```
- [ ] Acessível em `http://IP-VPS:8080`
- [ ] Mostra rotas configuradas
- [ ] Certificados SSL aparecem

---

## 🧪 Testes Funcionais

### API
```bash
# Health check
curl https://backend.casayme.com.br/health

# Listar propriedades (pode estar vazio)
curl https://backend.casayme.com.br/api/properties
```

- [ ] Health endpoint responde
- [ ] API properties responde (mesmo que vazio)
- [ ] CORS configurado corretamente

### Frontend
- [ ] Página inicial carrega
- [ ] Formulário de contato aparece
- [ ] Listagem de propriedades carrega
- [ ] Console do navegador sem erros JS
- [ ] Imagens carregam
- [ ] CSS aplicado corretamente

### Integração
- [ ] Frontend consegue chamar API do backend
- [ ] Backend responde ao frontend (CORS OK)
- [ ] SSL funciona em ambos
- [ ] Webhook N8N configurado (se aplicável)

---

## 🔍 Monitoramento

```bash
# Acompanhar logs em tempo real
docker compose logs -f

# Ver uso de recursos
docker stats

# Ver processos
docker compose ps
```

- [ ] CPU < 80%
- [ ] Memória < 80%
- [ ] Disco tem espaço livre
- [ ] Logs sem erros contínuos

---

## 📝 Documentação

- [ ] Credenciais salvas em local seguro
- [ ] IP da VPS documentado
- [ ] Domínios documentados
- [ ] Processo de deploy documentado para equipe

---

## 🎉 Deploy Completo!

Se todos os itens acima estão marcados, **parabéns!** 🎊

Sua aplicação está no ar em:
- 🌐 **Frontend**: https://casayme.com.br
- 🔧 **Backend**: https://backend.casayme.com.br
- 📊 **Dashboard**: http://IP-VPS:8080

---

## 🐛 Se algo deu errado

### Containers não sobem
```bash
docker compose down
docker system prune -af
./deploy.sh
```

### SSL não funciona
```bash
# Verificar logs do Traefik
docker logs traefik

# Aguardar 5 minutos
# Verificar se DNS está correto
nslookup casayme.com.br
```

### Backend não conecta no banco
```bash
# Testar conexão
nc -zv 72.61.131.168 5432

# Ver logs do backend
docker compose logs backend

# Verificar variáveis de ambiente
docker compose exec backend env | grep DB_
```

### Refazer deploy do zero
```bash
docker compose down -v
docker system prune -af
./deploy.sh
```

---

## 📞 Comandos de Emergência

```bash
# Parar tudo imediatamente
docker compose down

# Ver o que está consumindo recursos
docker stats

# Limpar tudo e recomeçar
docker compose down -v
docker system prune -af
./deploy.sh

# Backup rápido do banco
docker exec postgres_casayme pg_dump -U admin casa_yme > backup.sql
```

---

**Checklist criado para garantir deploy perfeito!** ✅

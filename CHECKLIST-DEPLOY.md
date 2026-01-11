# ✅ Checklist de Deploy - Casa YME

## ⚠️ AÇÃO OBRIGATÓRIA ANTES DO DEPLOY

### **Executar Migração 004 no Banco de Produção**

```bash
# Conectar no banco
psql -h 72.61.131.168 -p 5432 -U admin -d casa-yme

# Executar migração
\i sql/004-vivareal-extensions.sql
```

**O que adiciona:**
- ✅ user_type, phone, creci em users
- ✅ iptu, condominio, vagas, suites, street, number, zip_code em properties  
- ✅ Tabelas: favorites, property_alerts, property_contacts, etc

---

## 🚀 DEPLOY

```bash
./deploy.sh
```

---

## ✅ VERIFICAÇÕES PÓS-DEPLOY

### 1. Backend funcionando
```bash
curl https://backend.casayme.com.br/health
```

### 2. Frontend funcionando
```bash
curl https://casayme.com.br
```

### 3. Login de teste
- https://casayme.com.br
- Login: `admin@casayme.com` / `123456`

### 4. Teste completo
1. Login → Painel Admin
2. Adicionar Novo Imóvel
3. Preencher TODOS os campos novos
4. Salvar e verificar

---

## 📊 COMANDOS ÚTEIS

```bash
# Ver logs
docker service logs -f casayme_backend
docker service logs -f casayme_frontend

# Status
docker service ls | grep casayme

# Reiniciar
docker service update --force casayme_backend
```

---

## ✅ ESTÁ PRONTO PARA DEPLOY!

O sistema está configurado corretamente:
- ✅ Network: `traefik_imobiliaria` (hardcoded)
- ✅ Backend com todos os novos campos
- ✅ Frontend com painel admin redesenhado
- ✅ Dockerfiles corretos
- ✅ Deploy script funcionando

**ÚNICA PENDÊNCIA:** Executar migração 004 no banco de produção!

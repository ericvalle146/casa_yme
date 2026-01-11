# 🔐 Credenciais de Teste - Casa YME

## 🌐 Acesso ao Sistema
- **Frontend:** http://localhost:5175
- **Backend API:** http://localhost:4000

---

## 👥 Usuários Criados

### 🔴 ADMINISTRADOR (ADMIN)

```
📧 Email: admin@casayme.com
🔑 Senha: 123456
```

**Permissões:**
- ✅ Ver todos os imóveis
- ✅ Criar novos imóveis
- ✅ Editar QUALQUER imóvel (de qualquer corretor)
- ✅ Deletar QUALQUER imóvel
- ✅ Acessar painel administrativo (`/admin`)
- ✅ Favoritar imóveis
- ✅ Criar alertas
- ✅ Gerenciar sistema completo

**Menu Extra:**
- Painel Admin

---

### 🟢 CORRETOR

```
📧 Email: corretor@casayme.com
🔑 Senha: 123456
```

**Informações Profissionais:**
- 📋 Nome: João Corretor Silva
- 🏢 Empresa: Casa YME Imóveis
- 📱 Telefone: (11) 99988-7766
- 🆔 CRECI: 12345-SP

**Permissões:**
- ✅ Ver todos os imóveis
- ✅ Criar novos imóveis
- ✅ Editar seus próprios imóveis
- ✅ Deletar seus próprios imóveis
- ✅ Acessar painel administrativo (`/admin`)
- ✅ Favoritar imóveis
- ✅ Criar alertas

**Menu Extra:**
- Painel Admin

---

### 🔵 VISITANTE (Cliente)

```
📧 Email: visitante@casayme.com
🔑 Senha: 123456
```

**Informações:**
- 📋 Nome: Maria Cliente Santos

**Permissões:**
- ✅ Ver todos os imóveis
- ✅ Buscar e filtrar imóveis
- ✅ Ver detalhes completos (fotos, mapa, informações)
- ✅ Favoritar/Desfavoritar imóveis
- ✅ Acessar página de favoritos (`/favoritos`)
- ✅ Criar alertas personalizados
- ✅ Gerenciar alertas (`/perfil` → Alertas)
- ✅ Ver perfil e histórico
- ❌ **NÃO** pode criar/editar/deletar imóveis
- ❌ **NÃO** pode acessar `/admin`

---

## 🎯 Como Testar Cada Tipo

### Testar ADMIN
1. Acesse http://localhost:5175
2. Clique em "Entrar" no header
3. Login: `admin@casayme.com` / Senha: `123456`
4. Após login, clique no avatar no header
5. Veja o menu com "Painel Admin"
6. Acesse `/admin` e adicione/edite imóveis

### Testar CORRETOR
1. Faça logout se estiver logado
2. Login: `corretor@casayme.com` / Senha: `123456`
3. Clique no avatar → "Painel Admin"
4. Adicione novos imóveis
5. Tente editar imóveis que você criou

### Testar VISITANTE
1. Faça logout se estiver logado
2. Login: `visitante@casayme.com` / Senha: `123456`
3. Navegue pelos imóveis
4. Clique no ❤️ para favoritar
5. Vá em "Favoritos" no menu do avatar
6. Vá em "Meu Perfil" → "Alertas" → Criar novo alerta
7. Note que **não há** opção "Painel Admin" no menu

---

## 🔄 Diferenças Visuais

### Menu do Avatar

**VISITANTE:**
```
┌──────────────────┐
│ Maria Cliente    │
│ visitante@...    │
├──────────────────┤
│ 👤 Meu Perfil    │
│ ❤️  Favoritos    │
│ 🔔 Alertas       │
│ 📜 Histórico     │
├──────────────────┤
│ 🚪 Sair          │
└──────────────────┘
```

**CORRETOR/ADMIN:**
```
┌──────────────────┐
│ João Corretor    │
│ corretor@...     │
├──────────────────┤
│ 👤 Meu Perfil    │
│ ❤️  Favoritos    │
│ 🔔 Alertas       │
│ 📜 Histórico     │
├──────────────────┤
│ 🎛️  Painel Admin │ ← EXTRA!
├──────────────────┤
│ 🚪 Sair          │
└──────────────────┘
```

---

## 🧪 Cenários de Teste

### ✅ Teste 1: Favoritos (Todos os tipos)
1. Login com qualquer usuário
2. Navegue até um imóvel
3. Clique no ❤️ para favoritar
4. Vá em Menu → Favoritos
5. Veja o imóvel favoritado

### ✅ Teste 2: Criar Imóvel (CORRETOR/ADMIN)
1. Login como CORRETOR ou ADMIN
2. Vá em Menu → Painel Admin
3. Clique "Adicionar Imóvel"
4. Preencha os dados e salve
5. Veja o imóvel criado na listagem

### ✅ Teste 3: Criar Alerta (Todos os tipos)
1. Login com qualquer usuário
2. Vá em Menu → Meu Perfil
3. Tab "Alertas"
4. Clique "Criar Novo Alerta"
5. Configure filtros (Ex: "Apartamento 2 quartos até R$ 300k")
6. Salve

### ✅ Teste 4: Busca Avançada (Todos)
1. Na home, use o formulário de busca
2. Digite uma cidade no campo "Cidade ou bairro"
3. Selecione filtros (preço, quartos, etc.)
4. Clique "Pesquisar agora"
5. Veja resultados filtrados

### ✅ Teste 5: Mapa (Todos)
1. Abra detalhes de um imóvel
2. Role até "Localização"
3. Veja o mapa interativo com o marker
4. Role até "Imóveis próximos"
5. Veja outros imóveis com distância em km

### ❌ Teste 6: Restrição VISITANTE
1. Login como VISITANTE
2. Tente acessar `/admin` diretamente
3. Veja que não há menu "Painel Admin"
4. Não consegue adicionar imóveis

---

## 🔧 Resetar Senhas

Se precisar resetar alguma senha:

```sql
-- Resetar senha para 123456
UPDATE users
SET password_hash = '$2a$12$hash_aqui'
WHERE email = 'usuario@casayme.com';
```

Ou execute novamente:
```bash
cd backend
node generate-test-users.js
```

---

## 📊 Verificar Usuários no Banco

```sql
-- Ver todos os usuários e tipos
SELECT
  id,
  name,
  email,
  user_type,
  creci,
  company_name,
  phone,
  created_at
FROM users
ORDER BY user_type, name;
```

---

## 🎯 Status do Sistema

- ✅ Backend: http://localhost:4000
- ✅ Frontend: http://localhost:5175
- ✅ Banco de Dados: Conectado
- ✅ 3 Usuários de Teste: Criados
- ✅ Todas as Funcionalidades: Operacionais

**Tudo pronto para testar! 🚀**

# Plano de Redesign do Painel Admin

## Data: 2026-01-10

## Objetivo
Reorganizar o painel administrativo com layout moderno, barra lateral com categorias e campos completos conforme estrutura do banco de dados.

---

## Análise Atual

### Campos Existentes no Formulário
✅ title, type, transaction, price, bedrooms, bathrooms, area, neighborhood, city, state, description, amenities

### Campos Faltantes (da migração 004)
❌ iptu (NUMERIC)
❌ condominio (NUMERIC)
❌ vagas (INT)
❌ street (TEXT)
❌ number (TEXT)
❌ complement (TEXT)
❌ zip_code (VARCHAR)
❌ suites (INT)
❌ is_active (BOOLEAN)
❌ latitude/longitude (AUTO via geocoding no backend)
❌ full_address (AUTO via geocoding no backend)

### Problemas Identificados no Layout Atual
1. Formulário e lista de imóveis na mesma página (confuso)
2. Não há navegação lateral
3. Campos importantes faltando
4. Não separa claramente "adicionar" vs "gerenciar"
5. Interface não intuitiva para CRUD

---

## Novo Layout Proposto

```
┌─────────────────────────────────────────────────────────┐
│ Header (mantém o atual)                                 │
├──────────┬──────────────────────────────────────────────┤
│          │                                              │
│ Sidebar  │  Área de Conteúdo                           │
│          │                                              │
│ ┌──────┐ │  [Baseado na categoria selecionada]         │
│ │📊 Dash│ │                                             │
│ │🏠 Imóv│ │  - Dashboard: Estatísticas gerais          │
│ │➕ Novo│ │  - Imóveis: Lista com editar/excluir       │
│ │⚙️ Conf│ │  - Novo Imóvel: Formulário completo        │
│ └──────┘ │                                             │
│          │                                              │
└──────────┴──────────────────────────────────────────────┘
```

---

## Estrutura de Componentes

### 1. AdminLayout.tsx (novo)
- Layout com sidebar + content area
- Gerencia navegação entre seções

### 2. AdminSidebar.tsx (novo)
- Menu lateral fixo
- Categorias:
  - 📊 Dashboard
  - 🏠 Meus Imóveis
  - ➕ Adicionar Novo
  - ⚙️ Configurações (futuro)

### 3. AdminDashboard.tsx (novo)
- Cards com estatísticas:
  - Total de imóveis
  - Imóveis ativos
  - Total de favoritos
  - Visualizações totais

### 4. PropertyList.tsx (novo)
- Tabela melhorada com:
  - Imagem thumbnail
  - Status (ativo/inativo)
  - Visualizações
  - Ações: Editar, Excluir, Ver no site
- Filtros: Status, Tipo, Transação
- Paginação

### 5. PropertyForm.tsx (novo)
- Formulário dividido em seções:
  - **Informações Básicas**: título, tipo, transação, preço
  - **Características**: quartos, banheiros, suítes, área, vagas
  - **Localização**: CEP, rua, número, complemento, bairro, cidade, estado
  - **Custos Adicionais**: IPTU, condomínio
  - **Descrição e Comodidades**
  - **Galeria de Imagens**
  - **Configurações**: status ativo/inativo

---

## Fases de Implementação

### Fase 1: Criar Estrutura de Layout ✅ A fazer
**Arquivos a criar:**
- `/frontend/src/layouts/AdminLayout.tsx`
- `/frontend/src/components/admin/AdminSidebar.tsx`

**Funcionalidades:**
- Layout com sidebar responsiva
- Navegação entre seções usando React Router
- Rotas: `/admin/dashboard`, `/admin/properties`, `/admin/properties/new`

---

### Fase 2: Dashboard (Visão Geral) ✅ A fazer
**Arquivos a criar:**
- `/frontend/src/pages/admin/AdminDashboard.tsx`

**Funcionalidades:**
- Cards com estatísticas básicas
- Gráficos simples (opcional, futuro)
- Link rápido "Adicionar Novo Imóvel"

---

### Fase 3: Lista de Imóveis (PropertyList) ✅ A fazer
**Arquivos a criar:**
- `/frontend/src/pages/admin/PropertyList.tsx`
- `/frontend/src/components/admin/PropertyTableRow.tsx`

**Funcionalidades:**
- Tabela com thumbnail, título, cidade, tipo, transação, status, ações
- Filtros por status, tipo, transação
- Botões: Editar, Excluir, Ver no site
- Confirmação antes de excluir

---

### Fase 4: Formulário de Imóvel Completo ✅ A fazer
**Arquivos a criar:**
- `/frontend/src/pages/admin/PropertyFormPage.tsx`
- `/frontend/src/components/admin/PropertyFormSections.tsx`

**Campos do formulário (organizados por seção):**

#### 📋 Seção 1: Informações Básicas
- Título* (text)
- Tipo* (select: Casa, Apartamento, Terreno, etc)
- Transação* (radio: VENDA / ALUGUEL)
- Preço* (number, R$)
- Status Ativo (checkbox, default: true)

#### 🏠 Seção 2: Características do Imóvel
- Dormitórios* (number)
- Banheiros* (number)
- Suítes (number)
- Área Total* (m², number)
- Vagas de Garagem (number, default: 0)

#### 📍 Seção 3: Localização
- CEP (text, mask: 00000-000)
- Rua/Logradouro* (text)
- Número* (text)
- Complemento (text)
- Bairro* (text)
- Cidade* (text)
- Estado* (text, select ou input)

*Nota: Latitude/Longitude e Full Address serão gerados automaticamente pelo backend via geocoding*

#### 💰 Seção 4: Custos Adicionais
- IPTU Anual (number, R$, default: 0)
- Condomínio Mensal (number, R$, default: 0)

#### 📝 Seção 5: Descrição e Comodidades
- Descrição* (textarea, 500 caracteres mínimo)
- Comodidades (tags input: Piscina, Churrasqueira, Academia, etc)

#### 🖼️ Seção 6: Galeria de Imagens
- Upload de arquivos (múltiplos)
- URL externa (input)
- Preview de imagens
- Definir imagem de capa
- Reordenar imagens (drag and drop - futuro)

---

### Fase 5: Atualizar Backend (PropertyController) ✅ A fazer
**Arquivo a modificar:**
- `/backend/src/controllers/propertyController.js`

**Modificações:**
- Aceitar novos campos: iptu, condominio, vagas, street, number, complement, zip_code, suites, is_active
- Validar campos obrigatórios
- Retornar campos completos na listagem

**Arquivo a modificar:**
- `/backend/src/services/propertyService.js`

**Modificações:**
- Incluir novos campos no create/update
- Manter geocoding automático para latitude/longitude/full_address

---

### Fase 6: Atualizar Rotas e App.tsx ✅ A fazer
**Arquivo a modificar:**
- `/frontend/src/App.tsx`

**Nova estrutura de rotas:**
```tsx
<Route path="/admin" element={<AdminLayout />}>
  <Route index element={<Navigate to="/admin/dashboard" replace />} />
  <Route path="dashboard" element={<AdminDashboard />} />
  <Route path="properties" element={<PropertyList />} />
  <Route path="properties/new" element={<PropertyFormPage />} />
  <Route path="properties/:id/edit" element={<PropertyFormPage />} />
</Route>
```

---

### Fase 7: Atualizar Documentação ✅ A fazer
**Arquivos a atualizar:**
- `/APLICACAO.md` - Descrever novo layout do admin
- `/APIS.md` - Documentar novos campos nas APIs
- `/sql/ESTRUTURA-BANCO.md` - Já atualizado com migração 004

---

## Validações Importantes

### Frontend
- Título: mínimo 10 caracteres
- Descrição: mínimo 50 caracteres
- Preço: maior que 0
- Área: maior que 0
- CEP: formato válido (00000-000)
- Pelo menos 1 imagem obrigatória

### Backend (já implementado)
- Campos obrigatórios conforme schema
- Upload de imagens: max 10MB por arquivo, 12 arquivos
- Geocoding automático ao salvar

---

## Melhorias de UX

1. **Feedback Visual**
   - Loading states em todas as ações
   - Toast notifications para sucesso/erro
   - Skeleton loaders na tabela

2. **Confirmações**
   - Dialog de confirmação ao excluir imóvel
   - Aviso ao sair do formulário com alterações não salvas

3. **Responsividade**
   - Sidebar collapse em mobile
   - Formulário adaptável para telas pequenas
   - Tabela com scroll horizontal em mobile

4. **Acessibilidade**
   - Labels corretos em todos os campos
   - Navegação por teclado
   - Mensagens de erro descritivas

---

## Próximos Passos (Ordem de Execução)

1. ✅ Criar AdminLayout.tsx com sidebar
2. ✅ Criar AdminSidebar.tsx
3. ✅ Criar AdminDashboard.tsx (básico)
4. ✅ Criar PropertyList.tsx
5. ✅ Criar PropertyFormPage.tsx com TODOS os campos
6. ✅ Atualizar backend para aceitar novos campos
7. ✅ Atualizar rotas no App.tsx
8. ✅ Testar CRUD completo
9. ✅ Atualizar documentação

---

## Estimativa de Tempo

- Fase 1: Layout + Sidebar: ~30min
- Fase 2: Dashboard: ~20min
- Fase 3: PropertyList: ~40min
- Fase 4: PropertyForm completo: ~60min
- Fase 5: Backend updates: ~30min
- Fase 6: Rotas: ~10min
- Fase 7: Documentação: ~20min

**Total estimado: ~3h30min**

---

## Tecnologias Utilizadas

- React 18 + TypeScript
- React Router v6 (nested routes)
- Radix UI + Tailwind CSS
- React Query (cache e mutations)
- Sonner (toast notifications)
- Lucide React (ícones)

---

## Observações Finais

- Latitude/Longitude são gerados automaticamente pelo backend via geocoding (OpenStreetMap)
- Full Address também é gerado automaticamente
- O sistema já suporta RBAC (apenas CORRETOR e ADMIN podem criar/editar imóveis)
- Favoritos, visualizações e contatos já estão implementados no backend
- Alertas foram removidos da UI conforme solicitação anterior

-- ============================================
-- MIGRAÇÃO: EXTENSÕES VIVAREAL
-- Versão: 004
-- Data: 2026-01-10
-- Descrição: Adiciona funcionalidades tipo VivaReal ao sistema
-- ============================================

BEGIN;

-- ============================================
-- 1. EXTENSÃO DA TABELA USERS (Tipos de Usuário)
-- ============================================
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS user_type VARCHAR(20) NOT NULL DEFAULT 'VISITANTE' CHECK (user_type IN ('VISITANTE', 'CORRETOR', 'ADMIN')),
  ADD COLUMN IF NOT EXISTS phone VARCHAR(20),
  ADD COLUMN IF NOT EXISTS creci VARCHAR(20),
  ADD COLUMN IF NOT EXISTS company_name TEXT,
  ADD COLUMN IF NOT EXISTS company_logo_url TEXT,
  ADD COLUMN IF NOT EXISTS bio TEXT,
  ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;

CREATE INDEX IF NOT EXISTS idx_users_user_type ON users(user_type);

COMMENT ON COLUMN users.user_type IS 'Tipo de usuário: VISITANTE (padrão), CORRETOR (pode postar imóveis), ADMIN';
COMMENT ON COLUMN users.creci IS 'Registro CRECI para corretores';
COMMENT ON COLUMN users.company_name IS 'Nome da empresa/imobiliária (para corretores)';

-- ============================================
-- 2. EXTENSÃO DA TABELA PROPERTIES
-- ============================================
ALTER TABLE properties
  ADD COLUMN IF NOT EXISTS iptu NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS condominio NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS vagas INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8),
  ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8),
  ADD COLUMN IF NOT EXISTS full_address TEXT,
  ADD COLUMN IF NOT EXISTS street TEXT,
  ADD COLUMN IF NOT EXISTS number TEXT,
  ADD COLUMN IF NOT EXISTS complement TEXT,
  ADD COLUMN IF NOT EXISTS zip_code VARCHAR(10),
  ADD COLUMN IF NOT EXISTS area_total INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS suites INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS views_count INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS contacts_count INT DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_properties_location ON properties(latitude, longitude) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_properties_active ON properties(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_properties_vagas ON properties(vagas);
CREATE INDEX IF NOT EXISTS idx_properties_city_state ON properties(city, state);
CREATE INDEX IF NOT EXISTS idx_properties_neighborhood ON properties(neighborhood);

COMMENT ON COLUMN properties.iptu IS 'Valor anual do IPTU';
COMMENT ON COLUMN properties.condominio IS 'Valor mensal do condomínio';
COMMENT ON COLUMN properties.vagas IS 'Número de vagas de garagem';
COMMENT ON COLUMN properties.latitude IS 'Latitude (geocoding)';
COMMENT ON COLUMN properties.longitude IS 'Longitude (geocoding)';
COMMENT ON COLUMN properties.is_active IS 'Imóvel ativo/visível no site';

-- ============================================
-- 3. TABELA DE FAVORITOS
-- ============================================
CREATE TABLE IF NOT EXISTS favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, property_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_property ON favorites(property_id);
CREATE INDEX IF NOT EXISTS idx_favorites_created ON favorites(created_at DESC);

COMMENT ON TABLE favorites IS 'Imóveis favoritados pelos usuários';

-- ============================================
-- 4. TABELA DE CONTATOS/LEADS
-- ============================================
CREATE TABLE IF NOT EXISTS property_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  message TEXT NOT NULL,
  contact_type VARCHAR(20) NOT NULL CHECK (contact_type IN ('MESSAGE', 'PHONE', 'WHATSAPP')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_property_contacts_property ON property_contacts(property_id);
CREATE INDEX IF NOT EXISTS idx_property_contacts_user ON property_contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_property_contacts_created ON property_contacts(created_at DESC);

COMMENT ON TABLE property_contacts IS 'Registro de contatos feitos em imóveis';

-- ============================================
-- 5. TABELA DE ALERTAS DE NOVOS IMÓVEIS
-- ============================================
CREATE TABLE IF NOT EXISTS property_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  transaction TEXT NOT NULL CHECK (transaction IN ('VENDA', 'ALUGUEL')),
  city TEXT,
  state TEXT,
  neighborhood TEXT,
  type TEXT,
  min_price NUMERIC(14,2),
  max_price NUMERIC(14,2),
  min_bedrooms INT,
  min_area INT,
  is_active BOOLEAN DEFAULT TRUE,
  frequency VARCHAR(20) DEFAULT 'DAILY' CHECK (frequency IN ('INSTANT', 'DAILY', 'WEEKLY')),
  last_sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_property_alerts_user ON property_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_property_alerts_active ON property_alerts(is_active) WHERE is_active = TRUE;

COMMENT ON TABLE property_alerts IS 'Alertas configurados pelos usuários para novos imóveis';
COMMENT ON COLUMN property_alerts.frequency IS 'Frequência de envio: INSTANT, DAILY, WEEKLY';

-- Criar função updated_at se não existir
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_property_alerts_updated_at ON property_alerts;
CREATE TRIGGER trg_property_alerts_updated_at
  BEFORE UPDATE ON property_alerts
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- ============================================
-- 6. TABELA DE HISTÓRICO DE BUSCAS
-- ============================================
CREATE TABLE IF NOT EXISTS search_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  search_query TEXT NOT NULL,
  filters JSONB NOT NULL,
  results_count INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_search_history_user ON search_history(user_id);
CREATE INDEX IF NOT EXISTS idx_search_history_created ON search_history(created_at DESC);

COMMENT ON TABLE search_history IS 'Histórico de buscas realizadas pelos usuários';

-- ============================================
-- 7. TABELA DE VISUALIZAÇÕES DE IMÓVEIS
-- ============================================
CREATE TABLE IF NOT EXISTS property_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  session_id TEXT,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_property_views_property ON property_views(property_id);
CREATE INDEX IF NOT EXISTS idx_property_views_user ON property_views(user_id);
CREATE INDEX IF NOT EXISTS idx_property_views_created ON property_views(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_property_views_session ON property_views(session_id);

COMMENT ON TABLE property_views IS 'Registro de visualizações de imóveis (analytics)';

-- ============================================
-- 8. FUNÇÃO PARA INCREMENTAR CONTADOR DE VIEWS
-- ============================================
CREATE OR REPLACE FUNCTION increment_property_views()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE properties
  SET views_count = views_count + 1
  WHERE id = NEW.property_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_increment_views ON property_views;
CREATE TRIGGER trg_increment_views
  AFTER INSERT ON property_views
  FOR EACH ROW
  EXECUTE FUNCTION increment_property_views();

-- ============================================
-- 9. FUNÇÃO PARA INCREMENTAR CONTADOR DE CONTATOS
-- ============================================
CREATE OR REPLACE FUNCTION increment_property_contacts()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE properties
  SET contacts_count = contacts_count + 1
  WHERE id = NEW.property_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_increment_contacts ON property_contacts;
CREATE TRIGGER trg_increment_contacts
  AFTER INSERT ON property_contacts
  FOR EACH ROW
  EXECUTE FUNCTION increment_property_contacts();

-- ============================================
-- 10. ATUALIZAR TRIGGER DE UPDATED_AT PARA PROPERTIES
-- ============================================
DROP TRIGGER IF EXISTS trg_properties_updated_at ON properties;
CREATE TRIGGER trg_properties_updated_at
  BEFORE UPDATE ON properties
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

COMMIT;

-- ============================================
-- RESUMO DA MIGRAÇÃO
-- ============================================
-- Tabelas criadas:
-- - favorites (sistema de favoritos)
-- - property_contacts (registro de contatos)
-- - property_alerts (alertas de novos imóveis)
-- - search_history (histórico de buscas)
-- - property_views (analytics de visualizações)
--
-- Campos adicionados em users:
-- - user_type, phone, creci, company_name, company_logo_url, bio, profile_photo_url
--
-- Campos adicionados em properties:
-- - iptu, condominio, vagas, latitude, longitude, full_address
-- - street, number, complement, zip_code, area_total, suites
-- - is_active, views_count, contacts_count
--
-- Triggers criados:
-- - Incremento automático de views_count
-- - Incremento automático de contacts_count
-- - Atualização automática de updated_at
--
-- Índices criados para otimização de consultas
-- ============================================

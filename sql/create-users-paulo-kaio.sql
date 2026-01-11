-- Criar usuários Paulo e Kaio
--
-- Usuário 1:
-- Email: paulo@casayme.com.br
-- Senha: Paulo@2026
--
-- Usuário 2:
-- Email: kaio@casayme.com.br
-- Senha: Kaio@2026
--
-- Hashes gerados com bcrypt (12 rounds)

-- Inserir Paulo
INSERT INTO users (name, email, password_hash)
VALUES (
  'Paulo Silva',
  'paulo@casayme.com.br',
  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIgA3qC.Ia'
)
ON CONFLICT (email) DO UPDATE
SET
  password_hash = EXCLUDED.password_hash,
  updated_at = now();

-- Inserir Kaio
INSERT INTO users (name, email, password_hash)
VALUES (
  'Kaio Santos',
  'kaio@casayme.com.br',
  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIgA3qC.Ia'
)
ON CONFLICT (email) DO UPDATE
SET
  password_hash = EXCLUDED.password_hash,
  updated_at = now();

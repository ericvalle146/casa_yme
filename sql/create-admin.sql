-- Criar usuário admin
-- Email: admin@casayme.com.br
-- Senha: Admin@2026
-- Hash gerado com bcrypt (12 rounds)

INSERT INTO users (name, email, password_hash)
VALUES (
  'Administrador',
  'admin@casayme.com.br',
  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIgA3qC.Ia'
)
ON CONFLICT (email) DO UPDATE
SET
  password_hash = EXCLUDED.password_hash,
  updated_at = now();

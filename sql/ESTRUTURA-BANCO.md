# Estrutura de banco

A aplicacao agora possui suporte a autenticacao e imoveis via Postgres.
Arquivos SQL:
- sql/001-auth.sql (usuarios e sessoes)
- sql/002-properties.sql (imoveis e midias)
- sql/003-seed-properties.sql (dados iniciais de imoveis)

Tabelas de autenticacao
- users
  - id (PK)
  - name
  - email (unique)
  - password_hash
  - created_at
  - updated_at
  - last_login_at

- auth_sessions
  - id (PK)
  - user_id (FK -> users.id)
  - refresh_token_hash (unique)
  - created_at
  - last_used_at
  - expires_at
  - revoked_at
  - ip_address
  - user_agent

Persistencia de imoveis
- properties
  - id (PK)
  - title
  - type
  - transaction
  - price
  - bedrooms
  - bathrooms
  - area
  - neighborhood
  - city
  - state
  - description
  - amenities (text[])
  - created_by (FK -> users.id)
  - created_at
  - updated_at

- property_media
  - id (PK)
  - property_id (FK -> properties.id)
  - url
  - alt
  - position
  - is_cover
  - storage_key
  - created_at

Persistencia de leads (opcional/futuro)
- leads
  - id (PK)
  - name
  - email
  - phone
  - message
  - contact_method
  - created_at
  - source

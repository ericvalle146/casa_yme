# APIs

## Backend (backend/)
Base URL (local): http://localhost:4000
Base URL (producao): https://backend.casayme.com.br

### GET /health
Descricao: retorna o status do servico.

Resposta 200:
{
  "status": "ok"
}

### POST /api/contact
Descricao: recebe um lead do formulario e encaminha para o webhook N8N configurado em N8N_WEBHOOK_URL.

Request body (JSON):
{
  "name": "string",
  "email": "string",
  "phone": "string",
  "message": "string"
}

Responses:
- 200: { "message": "Lead enviado com sucesso." }
- 400: { "error": "Todos os campos sao obrigatorios." }
- 500: { "error": "Webhook nao configurado." } ou { "error": "Erro interno ao processar solicitacao." }
- 502: { "error": "Falha ao enviar dados para o webhook." }

### POST /api/auth/register
Descricao: cria um novo usuario e inicia uma sessao com tokens.

Request body (JSON):
{
  "name": "string",
  "email": "string",
  "password": "string"
}

Resposta 201:
{
  "user": {
    "id": "uuid",
    "name": "string",
    "email": "string",
    "createdAt": "timestamp",
    "lastLoginAt": "timestamp"
  },
  "accessToken": "string",
  "refreshToken": "string",
  "expiresIn": 900
}

Responses:
- 400: { "error": "Nome, e-mail e senha sao obrigatorios." } ou { "error": "E-mail invalido." }
- 409: { "error": "E-mail ja cadastrado." }
- 500: { "error": "Erro interno ao processar solicitacao." }

### POST /api/auth/login
Descricao: autentica um usuario e retorna tokens.

Request body (JSON):
{
  "email": "string",
  "password": "string"
}

Resposta 200:
{
  "user": {
    "id": "uuid",
    "name": "string",
    "email": "string",
    "createdAt": "timestamp",
    "lastLoginAt": "timestamp"
  },
  "accessToken": "string",
  "refreshToken": "string",
  "expiresIn": 900
}

Responses:
- 400: { "error": "E-mail e senha sao obrigatorios." } ou { "error": "E-mail invalido." }
- 401: { "error": "Credenciais invalidas." }
- 500: { "error": "Erro interno ao processar solicitacao." }

### POST /api/auth/refresh
Descricao: renova a sessao com base no refresh token.

Request body (JSON):
{
  "refreshToken": "string"
}

Resposta 200:
{
  "user": {
    "id": "uuid",
    "name": "string",
    "email": "string",
    "createdAt": "timestamp",
    "lastLoginAt": "timestamp"
  },
  "accessToken": "string",
  "refreshToken": "string",
  "expiresIn": 900
}

Responses:
- 400: { "error": "Refresh token obrigatorio." }
- 401: { "error": "Sessao invalida." } ou { "error": "Sessao expirada." } ou { "error": "Sessao revogada." }

### POST /api/auth/logout
Descricao: encerra a sessao atual (revoga o refresh token).

Request body (JSON):
{
  "refreshToken": "string"
}

Resposta 200:
{
  "message": "Sessao encerrada."
}

Responses:
- 400: { "error": "Refresh token obrigatorio." }

### GET /api/auth/me
Descricao: retorna o usuario autenticado.

Headers:
Authorization: Bearer <accessToken>

Resposta 200:
{
  "id": "uuid",
  "name": "string",
  "email": "string",
  "createdAt": "timestamp",
  "lastLoginAt": "timestamp"
}

Responses:
- 401: { "error": "Token de acesso ausente." } ou { "error": "Token de acesso invalido." }

### GET /api/properties
Descricao: lista imoveis disponiveis no site.

Resposta 200:
[
  {
    "id": "uuid",
    "title": "string",
    "type": "string",
    "transaction": "VENDA|ALUGUEL",
    "price": 123,
    "bedrooms": 3,
    "bathrooms": 2,
    "area": 120,
    "neighborhood": "string",
    "city": "string",
    "state": "string",
    "description": "string",
    "amenities": ["string"],
    "image": "string|null",
    "createdBy": "uuid",
    "createdAt": "timestamp",
    "updatedAt": "timestamp"
  }
]

### GET /api/properties/:id
Descricao: retorna detalhes completos do imovel e sua galeria.

Resposta 200:
{
  "id": "uuid",
  "title": "string",
  "type": "string",
  "transaction": "VENDA|ALUGUEL",
  "price": 123,
  "bedrooms": 3,
  "bathrooms": 2,
  "area": 120,
  "neighborhood": "string",
  "city": "string",
  "state": "string",
  "description": "string",
  "amenities": ["string"],
  "image": "string|null",
  "gallery": [
    { "id": "uuid", "url": "string", "alt": "string", "position": 0, "isCover": true }
  ],
  "createdBy": "uuid",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}

### POST /api/properties
Descricao: cria um imovel (autenticado).

Headers:
Authorization: Bearer <accessToken>

Content-Type: multipart/form-data

Campos:
- title, type, transaction, price, bedrooms, bathrooms, suites, area, vagas, neighborhood, city, state, description
- iptu, condominio (valores numericos)
- street, number, complement, zip_code (endereco completo para geocoding automatico)
- is_active (boolean, default: true)
- amenities (JSON array ou lista separada por virgula)
- mediaUrls (JSON array de objetos: { url, alt, isCover })
- mediaFiles (arquivos)
- mediaFilesMeta (JSON array de objetos: { alt, isCover })

Obs: latitude, longitude e full_address sao gerados automaticamente pelo backend via geocoding do OpenStreetMap

Resposta 201: objeto do imovel com galeria.

Responses:
- 400: { "error": "Campo obrigatorio: title." } ou { "error": "Transacao invalida." }
- 401: { "error": "Token de acesso ausente." } ou { "error": "Token de acesso invalido." }

### PUT /api/properties/:id
Descricao: atualiza um imovel (autenticado).

Headers:
Authorization: Bearer <accessToken>

Content-Type: multipart/form-data

Campos:
- mesmos campos do POST
- replaceMedia=true para substituir a galeria atual

Resposta 200: objeto do imovel atualizado.

### DELETE /api/properties/:id
Descricao: remove um imovel (autenticado).

Headers:
Authorization: Bearer <accessToken>

Resposta 200:
{
  "message": "Imovel removido."
}

## Variaveis de ambiente
- PORT (default 4000)
- NODE_ENV
- CORS_ORIGINS (lista separada por virgula)
- N8N_WEBHOOK_URL (obrigatoria para POST /api/contact)
- DB_HOST
- DB_PORT
- DB_USER
- DB_PASSWORD
- DB_NAME
- DATABASE_URL (opcional, alternativa ao uso de DB_*)
- ACCESS_TOKEN_SECRET
- ACCESS_TOKEN_TTL_MINUTES (default 15)
- REFRESH_TOKEN_TTL_DAYS (default 7)
- PASSWORD_SALT_ROUNDS (default 12)

## Observacao
O frontend envia o formulario direto para o webhook configurado em VITE_WEBHOOK_URL.
O backend esta disponivel caso queira centralizar esse envio via API.
A autenticacao usa access token (JWT) e refresh token persistido em auth_sessions.
Uploads de imagens sao salvos localmente em backend/uploads e expostos em /uploads/<arquivo>.
As URLs de imagem retornadas podem ser externas (http) ou relativas (/uploads/...).

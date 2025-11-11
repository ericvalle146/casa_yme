# 🔍 Verificar Webhook - ERR_NAME_NOT_RESOLVED

## ❌ Problema

O erro `ERR_NAME_NOT_RESOLVED` significa que o DNS não consegue resolver o domínio `webhook.locusup.shop`.

## 🔍 Verificações

### 1. Verificar se o domínio está correto

Teste no terminal:

```bash
# Verificar DNS
nslookup webhook.locusup.shop

# Ou
dig webhook.locusup.shop

# Testar conexão
curl -I https://webhook.locusup.shop/webhook/mariana_imobiliaria
```

### 2. Possíveis problemas

- **Domínio não existe**: `webhook.locusup.shop` pode não estar configurado
- **DNS não configurado**: O domínio pode não ter DNS apontando

### 3. Soluções

#### Opção 1: Verificar qual é o domínio correto

Pergunte ao responsável pelo N8N qual é a URL correta do webhook.

#### Opção 2: Usar variável de ambiente

Agora o webhook é configurável via variável de ambiente:

1. Crie um arquivo `.env` na raiz do projeto:
```bash
VITE_WEBHOOK_URL=https://webhook.locusup.shop/webhook/mariana_imobiliaria
```

2. Ou configure no build:
```bash
docker build --build-arg VITE_WEBHOOK_URL=https://webhook.locusup.shop/webhook/mariana_imobiliaria ...
```

#### Opção 3: Usar IP direto (temporário)

Se souber o IP do servidor do webhook:

```bash
VITE_WEBHOOK_URL=https://IP_DO_SERVIDOR/webhook/mariana_imobiliaria
```

## ✅ Como corrigir

1. **Verifique qual é a URL correta do webhook**
2. **Se for diferente, atualize o código ou use variável de ambiente**
3. **Reconstrua a imagem Docker com a URL correta**
4. **Faça deploy novamente**

## 📝 Exemplo de uso com variável de ambiente

No script de deploy, você pode passar:

```bash
docker build \
    --build-arg VITE_WEBHOOK_URL=https://webhook.locusup.shop/webhook/mariana_imobiliaria \
    -t imovelpro-frontend:latest \
    -f Dockerfile.frontend .
```


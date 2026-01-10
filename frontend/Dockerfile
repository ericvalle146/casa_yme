FROM node:20-alpine AS builder

WORKDIR /app

# Copiar arquivos de dependências
COPY package*.json ./
COPY tsconfig.json ./
COPY tsconfig.node.json ./
COPY tsconfig.app.json ./
COPY vite.config.ts ./
COPY tailwind.config.ts ./
COPY postcss.config.js ./
COPY index.html ./

# Instalar dependências
RUN npm ci

# Copiar código fonte
COPY src ./src
COPY public ./public

# Build da aplicação
# Variáveis de ambiente do frontend (opcionais, com valor padrão no código)
ARG VITE_WEBHOOK_URL
ARG VITE_API_BASE_URL
ENV VITE_WEBHOOK_URL=${VITE_WEBHOOK_URL}
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}

# DEBUG: Mostrar as variáveis que Vite vai usar
RUN echo "🔍 DEBUG - Variáveis de ambiente durante o build:" && \
    echo "VITE_API_BASE_URL=${VITE_API_BASE_URL}" && \
    echo "VITE_WEBHOOK_URL=${VITE_WEBHOOK_URL}" && \
    env | grep VITE || true

RUN npm run build

# DEBUG: Verificar se a variável foi embutida no build
RUN echo "🔍 Verificando se backend.casayme.com.br está no build:" && \
    grep -r "backend.casayme.com.br" dist/assets/*.js && echo "✅ Encontrado!" || echo "❌ NÃO encontrado!"

# Estágio de produção com Nginx
FROM nginx:alpine

# Instalar wget para healthcheck
RUN apk add --no-cache wget

# Copiar arquivos buildados
COPY --from=builder /app/dist /usr/share/nginx/html

# Copiar configuração do Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expor porta 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]

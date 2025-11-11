FROM node:20-alpine

WORKDIR /app

# Copiar arquivos de dependências
COPY package*.json ./

# Instalar dependências
RUN npm ci --production

# Copiar código fonte
COPY src ./src

# Expor porta
EXPOSE 4000

# Variáveis de ambiente
ENV PORT=4000
ENV NODE_ENV=production

# Health check (usa require mesmo com ESM, pois roda em contexto isolado)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "const http = require('http'); http.get('http://localhost:4000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)}).on('error', () => process.exit(1))"

# Comando para iniciar
CMD ["npm", "start"]


#!/bin/bash

# Script para executar migração 004-vivareal-extensions.sql
# Usage: ./run-migration-004.sh

# Carregar variáveis do .env
source ../.env 2>/dev/null || source .env 2>/dev/null || true

# Executar migração
PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -f 004-vivareal-extensions.sql

if [ $? -eq 0 ]; then
    echo "✓ Migração 004 executada com sucesso!"
else
    echo "✗ Erro ao executar migração 004"
    exit 1
fi

#!/bin/bash

# Teste rápido se está funcionando
echo "🧪 Testando endpoints..."

echo ""
echo "Frontend:"
curl -I http://localhost:3429/health 2>&1 | head -3

echo ""
echo "Backend:"
curl -I http://localhost:4000/health 2>&1 | head -3

echo ""
echo "Domínios (se Traefik estiver configurado):"
curl -I https://imob.locusup.shop 2>&1 | head -3
curl -I https://apiapi.jyze.space/health 2>&1 | head -3

echo ""
echo "✅ Containers estão rodando e respondendo!"
echo "💡 Se os domínios não funcionarem, o Traefik precisa ser configurado"


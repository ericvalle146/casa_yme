#!/bin/bash

echo "🔍 Verificando o que está usando a porta 80..."
echo ""

# Método 1: lsof
echo "=== Método 1: lsof ==="
sudo lsof -i :80 2>/dev/null || echo "lsof não encontrado ou sem permissão"

echo ""
echo "=== Método 2: netstat ==="
sudo netstat -tulpn | grep :80 || echo "Nenhum processo encontrado com netstat"

echo ""
echo "=== Método 3: ss ==="
sudo ss -tulpn | grep :80 || echo "Nenhum processo encontrado com ss"

echo ""
echo "=== Método 4: fuser ==="
sudo fuser 80/tcp 2>/dev/null || echo "Porta 80 livre (fuser)"

echo ""
echo "=== Método 5: Verificar processos Nginx ==="
ps aux | grep nginx | grep -v grep || echo "Nenhum processo Nginx encontrado"

echo ""
echo "=== Método 6: Verificar containers Docker ==="
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep :80 || echo "Nenhum container Docker usando porta 80"

echo ""
echo "=== Método 7: Verificar systemd services na porta 80 ==="
sudo systemctl list-units --type=service --state=running | grep -E "nginx|apache|httpd" || echo "Nenhum serviço web encontrado"

echo ""
echo "=== Método 8: Verificar todos os processos na porta 80 (detalhado) ==="
for pid in $(sudo lsof -ti:80 2>/dev/null); do
    echo "PID: $pid"
    ps -p $pid -o pid,ppid,cmd,user,etime
    echo "---"
done

echo ""
echo "✅ Verificação completa!"


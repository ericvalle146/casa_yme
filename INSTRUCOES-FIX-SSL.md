# 🔧 Como Resolver o Problema de SSL Auto-Assinado

## ⚠️ Problema Atual

Os serviços estão rodando, mas os certificados SSL ainda estão auto-assinados:
- ❌ `apiapi.jyze.space` - Certificado auto-assinado
- ❌ `imob.locusup.shop` - Certificado auto-assinado

## 🔍 Diagnóstico

Execute o script de diagnóstico:

```bash
chmod +x fix-traefik-ssl.sh
./fix-traefik-ssl.sh
```

Este script vai:
- ✅ Verificar se o Traefik tem Let's Encrypt configurado
- ✅ Verificar diretório de certificados
- ✅ Verificar configuração do Traefik
- ✅ Verificar labels dos serviços
- ✅ Mostrar logs do Traefik
- ✅ Dar instruções específicas para resolver

## 🚀 Solução Rápida

### Opção 1: Verificar e Configurar Traefik Manualmente

1. **Encontrar o serviço do Traefik:**
   ```bash
   docker service ls | grep traefik
   ```

2. **Ver a configuração do Traefik:**
   ```bash
   docker service inspect traefik_traefik --pretty
   ```

3. **Verificar se tem ACME configurado:**
   ```bash
   docker service inspect traefik_traefik | grep -i acme
   ```

4. **Se NÃO tiver ACME configurado, você precisa:**
   - Acessar o stack/compose do Traefik
   - Adicionar configuração de Let's Encrypt
   - Reiniciar o Traefik

### Opção 2: Usar o Script de Configuração

```bash
chmod +x configurar-traefik-acme.sh
./configurar-traefik-acme.sh
```

## 📋 Configuração Necessária do Traefik

O Traefik precisa ter esta configuração:

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: seu-email@exemplo.com
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
```

E o volume montado:

```yaml
volumes:
  - ./letsencrypt:/letsencrypt
```

## 🔄 Reiniciar o Traefik

Após configurar, reinicie o Traefik:

```bash
# Se estiver em Swarm
docker service update --force traefik_traefik

# Se estiver em Compose
docker restart <nome-do-container-traefik>
```

## ⏱️ Aguardar Geração dos Certificados

Após reiniciar, aguarde 2-5 minutos para o Let's Encrypt gerar os certificados.

Verifique os logs:

```bash
docker logs -f traefik_traefik.1.om5cx98abkgjdgkq8zw4yrrs9
```

Procure por mensagens como:
- "Certificate obtained"
- "Certificate renewed"
- "ACME challenge"

## ✅ Verificar se Funcionou

Após alguns minutos, verifique:

```bash
# Verificar certificado do backend
echo | openssl s_client -connect apiapi.jyze.space:443 -servername apiapi.jyze.space 2>&1 | grep "CN ="

# Verificar certificado do frontend
echo | openssl s_client -connect imob.locusup.shop:443 -servername imob.locusup.shop 2>&1 | grep "CN ="
```

**Se aparecer o domínio ou "Let's Encrypt" ao invés de "TRAEFIK DEFAULT CERT", está funcionando!**

## 🆘 Se Ainda Não Funcionar

1. **Verifique se a porta 80 está acessível:**
   ```bash
   curl -I http://apiapi.jyze.space/.well-known/acme-challenge/test
   ```

2. **Verifique se os domínios estão apontando corretamente:**
   ```bash
   nslookup apiapi.jyze.space
   nslookup imob.locusup.shop
   ```

3. **Verifique os logs do Traefik para erros:**
   ```bash
   docker logs traefik_traefik.1.om5cx98abkgjdgkq8zw4yrrs9 | grep -i error
   ```

4. **Verifique se o Traefik está na mesma network:**
   ```bash
   docker network inspect vpsnet | grep -A 5 traefik
   ```

## 📞 Próximos Passos

1. Execute `./fix-traefik-ssl.sh` para diagnóstico completo
2. Siga as instruções que aparecerem
3. Aguarde alguns minutos
4. Verifique novamente os certificados


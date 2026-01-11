# Sistema de Alertas - Configuração WhatsApp (N8N/Make)

## Visão Geral

O sistema de alertas processa automaticamente alertas de usuários a cada 6 horas e envia notificações via WhatsApp usando N8N ou Make.com.

## Variáveis de Ambiente

Adicione ao seu `.env`:

```env
# URL do webhook N8N para alertas de imóveis
N8N_ALERT_WEBHOOK_URL=https://seu-n8n.com/webhook/alertas-imoveis

# URL do frontend (para gerar links nos alertas)
FRONTEND_URL=https://casayme.com.br
```

## Opção 1: Configuração com N8N

### 1. Criar Workflow no N8N

1. Acesse seu N8N e crie um novo workflow
2. Adicione um node **Webhook** como trigger:
   - Método: POST
   - Path: `/alertas-imoveis`
   - Copie a URL do webhook gerada

### 2. Configurar WhatsApp Business

Escolha uma das opções:

#### Opção A: Twilio (Recomendado - Mais Estável)
1. Adicione um node **Twilio** após o webhook
2. Configure:
   - Operation: Send Message
   - WhatsApp From Number: Seu número Twilio WhatsApp
   - To Number: `{{$json.user.phone}}`
   - Message:
   ```
   🏠 *Casa YME - Novos Imóveis!*

   Olá {{$json.user.name}}!

   Encontramos *{{$json.totalProperties}}* novos imóveis que correspondem ao seu alerta "{{$json.alert.name}}":

   {{#each $json.properties}}
   📍 *{{this.title}}*
   💰 R$ {{this.price}}
   🛏️ {{this.bedrooms}} quartos | 🛁 {{this.bathrooms}} banheiros
   📏 {{this.area}} m²
   📌 {{this.neighborhood}}, {{this.city}} - {{this.state}}
   🔗 {{this.url}}

   {{/each}}

   Acesse o site para mais detalhes!
   ```

#### Opção B: Evolution API (WhatsApp Não Oficial)
1. Configure uma instância Evolution API
2. Adicione um node **HTTP Request**:
   - Method: POST
   - URL: `https://sua-evolution-api/message/sendText/{instance}`
   - Headers: `apikey: SUA_API_KEY`
   - Body:
   ```json
   {
     "number": "{{$json.user.phone}}",
     "text": "🏠 Casa YME...(mensagem)"
   }
   ```

#### Opção C: MessageBird
1. Adicione node **MessageBird**
2. Configure como Twilio

### 3. Adicionar Node de Log (Opcional)
1. Adicione um node **Set** para registrar envio:
   - Nome: `Log Envio`
   - Campos:
     - alertId: `{{$json.alert.id}}`
     - userId: `{{$json.user.email}}`
     - propertiesCount: `{{$json.totalProperties}}`
     - sentAt: `{{$now}}`

### 4. Testar Workflow
Use o payload de exemplo:
```json
{
  "alert": {
    "id": "uuid",
    "name": "Apartamento 2 quartos no Centro"
  },
  "user": {
    "name": "João Silva",
    "email": "joao@example.com",
    "phone": "5511999999999"
  },
  "properties": [
    {
      "id": "uuid",
      "title": "Apartamento 2 quartos",
      "price": 350000,
      "bedrooms": 2,
      "bathrooms": 2,
      "area": 65,
      "neighborhood": "Centro",
      "city": "São Paulo",
      "state": "SP",
      "transaction": "VENDA",
      "url": "https://casayme.com.br/propriedade/uuid"
    }
  ],
  "totalProperties": 1
}
```

---

## Opção 2: Configuração com Make.com

### 1. Criar Scenario

1. Acesse Make.com e crie um novo scenario
2. Adicione um module **Webhooks - Custom Webhook**:
   - Copie a URL gerada

### 2. Processar Dados

1. Adicione module **Tools - Set Multiple Variables**:
   - userName: `{{1.user.name}}`
   - userPhone: `{{1.user.phone}}`
   - totalProps: `{{1.totalProperties}}`

### 3. Iterar Imóveis

1. Adicione module **Flow Control - Iterator**:
   - Array: `{{1.properties}}`

### 4. Enviar WhatsApp

Escolha o provedor e configure como no N8N.

---

## Frequências Disponíveis

O sistema suporta estas frequências (configurável na criação do alerta):

- **INSTANT**: Notificação imediata (quando implementado)
- **DAILY**: Uma vez por dia (padrão)
- **WEEKLY**: Uma vez por semana

**Nota**: Atualmente o cron executa a cada 6 horas. Para mudar:

```javascript
// backend/src/jobs/alertProcessor.js
const cronExpression = '0 */6 * * *'; // A cada 6 horas
// Ou para testes: '*/5 * * * *' // A cada 5 minutos
```

## Formato do Payload Enviado ao Webhook

```typescript
{
  alert: {
    id: string;
    name: string;
  },
  user: {
    name: string;
    email: string;
    phone: string;
  },
  properties: [
    {
      id: string;
      title: string;
      price: number;
      bedrooms: number;
      bathrooms: number;
      area: number;
      neighborhood: string;
      city: string;
      state: string;
      transaction: 'VENDA' | 'ALUGUEL';
      url: string;
    }
  ],
  totalProperties: number;
}
```

## Executar Manualmente (Testes)

Para testar sem esperar o cron:

```javascript
import { runAlertProcessorManually } from './jobs/alertProcessor.js';

// Executar imediatamente
await runAlertProcessorManually();
```

Ou crie um endpoint de teste:

```javascript
// backend/src/routes/alertRoutes.js
router.post('/process-now', authenticate, requireRole('ADMIN'), async (req, res) => {
  await runAlertProcessorManually();
  res.json({ message: 'Processamento iniciado' });
});
```

## Monitoramento

Logs do processador:

```bash
# Ver logs em tempo real
tail -f logs/app.log | grep AlertProcessor

# Ver apenas alertas processados
tail -f logs/app.log | grep "Encontrados.*novos imóveis"
```

## Troubleshooting

### Webhook não recebe dados
- Verifique se `N8N_ALERT_WEBHOOK_URL` está configurado
- Teste o webhook com cURL:
```bash
curl -X POST https://seu-n8n.com/webhook/alertas-imoveis \
  -H "Content-Type: application/json" \
  -d '{"test": true}'
```

### Nenhum imóvel encontrado
- Verifique se há alertas ativos: `SELECT * FROM property_alerts WHERE is_active = true`
- Verifique se há imóveis novos desde `last_sent_at`
- Ajuste os filtros do alerta

### WhatsApp não envia
- Verifique credenciais do provedor
- Formato do número deve ser: `5511999999999` (sem +, espaços ou ()
- Teste o envio manualmente no N8N

## Custos Estimados

| Provedor | Custo/Mensagem | Observações |
|----------|----------------|-------------|
| Twilio | ~$0.005 | Mais estável, requer aprovação |
| MessageBird | ~$0.004 | Similar ao Twilio |
| Evolution API | Gratuito | Não oficial, risco de ban |

## Próximos Passos

1. ✅ Backend de alertas implementado
2. ✅ Cron job configurado
3. ⬜ Criar workflow no N8N
4. ⬜ Configurar provedor WhatsApp
5. ⬜ Testar com alertas reais
6. ⬜ Monitorar logs e ajustar frequência

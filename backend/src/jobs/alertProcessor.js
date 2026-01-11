import cron from 'node-cron';
import { alertRepository } from '../repositories/alertRepository.js';
import { propertyRepository } from '../repositories/propertyRepository.js';
import { logger } from '../config/logger.js';
import { env } from '../config/env.js';

/**
 * Processa alertas e envia notificações para webhook N8N
 */
const processAlerts = async () => {
  try {
    logger.info('[AlertProcessor] Iniciando processamento de alertas');

    const activeAlerts = await alertRepository.findActive();
    logger.info(`[AlertProcessor] Encontrados ${activeAlerts.length} alertas ativos`);

    for (const alert of activeAlerts) {
      try {
        // Construir filtros da busca baseado no alerta
        const searchFilters = {
          transaction: alert.transaction,
          city: alert.city,
          state: alert.state,
          neighborhood: alert.neighborhood,
          type: alert.type,
          minPrice: alert.min_price,
          maxPrice: alert.max_price,
          minBedrooms: alert.min_bedrooms,
          minArea: alert.min_area,
          limit: 10, // Máximo 10 imóveis por alerta
        };

        // Filtrar apenas imóveis criados após o último envio
        const createdAfter = alert.last_sent_at || alert.created_at;

        // Buscar imóveis que correspondem aos critérios
        const properties = await propertyRepository.search(searchFilters);

        // Filtrar apenas imóveis novos (criados após last_sent_at)
        const newProperties = properties.filter(
          (p) => new Date(p.createdAt) > new Date(createdAfter)
        );

        if (newProperties.length > 0) {
          logger.info(
            `[AlertProcessor] Encontrados ${newProperties.length} novos imóveis para alerta ${alert.id}`
          );

          // Preparar dados para webhook N8N
          const webhookData = {
            alert: {
              id: alert.id,
              name: alert.name,
            },
            user: {
              name: alert.user_name,
              email: alert.email,
              phone: alert.phone,
            },
            properties: newProperties.map((p) => ({
              id: p.id,
              title: p.title,
              price: p.price,
              bedrooms: p.bedrooms,
              bathrooms: p.bathrooms,
              area: p.area,
              neighborhood: p.neighborhood,
              city: p.city,
              state: p.state,
              transaction: p.transaction,
              url: `${env.frontendUrl || 'http://localhost:5173'}/propriedade/${p.id}`,
            })),
            totalProperties: newProperties.length,
          };

          // Enviar para webhook N8N (se configurado)
          if (env.n8nAlertWebhookUrl) {
            try {
              const response = await fetch(env.n8nAlertWebhookUrl, {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                },
                body: JSON.stringify(webhookData),
              });

              if (response.ok) {
                logger.info(
                  `[AlertProcessor] Webhook enviado com sucesso para alerta ${alert.id}`
                );
              } else {
                logger.error(
                  `[AlertProcessor] Erro ao enviar webhook: ${response.status} ${response.statusText}`
                );
              }
            } catch (webhookError) {
              logger.error(
                `[AlertProcessor] Erro ao enviar webhook para alerta ${alert.id}:`,
                webhookError
              );
            }
          } else {
            logger.warn('[AlertProcessor] N8N_ALERT_WEBHOOK_URL não configurado, pulando envio');
            // Em desenvolvimento, logar os dados que seriam enviados
            logger.info('[AlertProcessor] Dados do webhook:', JSON.stringify(webhookData, null, 2));
          }

          // Atualizar last_sent_at do alerta
          await alertRepository.updateLastSent(alert.id);
        } else {
          logger.info(`[AlertProcessor] Nenhum imóvel novo encontrado para alerta ${alert.id}`);
        }
      } catch (alertError) {
        logger.error(
          `[AlertProcessor] Erro ao processar alerta ${alert.id}:`,
          alertError
        );
      }
    }

    logger.info('[AlertProcessor] Processamento de alertas finalizado');
  } catch (error) {
    logger.error('[AlertProcessor] Erro geral no processamento de alertas:', error);
  }
};

/**
 * Inicia o cron job para processar alertas.
 */
export const startAlertProcessor = () => {
  // Executar a cada 6 horas
  const cronExpression = '0 */6 * * *';

  // Para desenvolvimento/testes, usar: */5 * * * * (a cada 5 minutos)
  // const cronExpression = '*/5 * * * *';

  logger.info(`[AlertProcessor] Iniciando cron job com expressão: ${cronExpression}`);

  cron.schedule(cronExpression, async () => {
    logger.info('[AlertProcessor] Executando job agendado');
    await processAlerts();
  });

  logger.info('[AlertProcessor] Cron job configurado e ativo');
};

/**
 * Processa alertas manualmente (para testes ou execução via endpoint)
 */
export const runAlertProcessorManually = async () => {
  logger.info('[AlertProcessor] Execução manual solicitada');
  await processAlerts();
};

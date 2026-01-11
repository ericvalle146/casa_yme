import { alertRepository } from '../repositories/alertRepository.js';
import { HttpError } from '../utils/errors.js';

/**
 * Formata um alerta para resposta da API
 */
const toAlertResponse = (alert) => ({
  id: alert.id,
  name: alert.name,
  transaction: alert.transaction,
  city: alert.city,
  state: alert.state,
  neighborhood: alert.neighborhood,
  type: alert.type,
  minPrice: alert.min_price ? Number(alert.min_price) : null,
  maxPrice: alert.max_price ? Number(alert.max_price) : null,
  minBedrooms: alert.min_bedrooms,
  minArea: alert.min_area,
  frequency: alert.frequency,
  isActive: alert.is_active,
  lastSentAt: alert.last_sent_at,
  createdAt: alert.created_at,
  updatedAt: alert.updated_at,
});

export const alertService = {
  /**
   * Cria um novo alerta
   */
  create: async (userId, alertData) => {
    if (!alertData.name || alertData.name.trim() === '') {
      throw new HttpError(400, 'Nome do alerta é obrigatório');
    }

    // Validar que pelo menos um filtro foi especificado
    const hasFilters =
      alertData.transaction ||
      alertData.city ||
      alertData.state ||
      alertData.neighborhood ||
      alertData.type ||
      alertData.minPrice ||
      alertData.maxPrice ||
      alertData.minBedrooms ||
      alertData.minArea;

    if (!hasFilters) {
      throw new HttpError(400, 'Pelo menos um filtro deve ser especificado');
    }

    const alert = await alertRepository.create({
      userId,
      ...alertData,
    });

    return toAlertResponse(alert);
  },

  /**
   * Lista todos os alertas de um usuário
   */
  listByUser: async (userId) => {
    const alerts = await alertRepository.findByUser(userId);
    return alerts.map(toAlertResponse);
  },

  /**
   * Busca um alerta por ID
   */
  getById: async (alertId, userId) => {
    const alert = await alertRepository.findById(alertId);

    if (!alert) {
      throw new HttpError(404, 'Alerta não encontrado');
    }

    // Verificar se o alerta pertence ao usuário
    if (alert.user_id !== userId) {
      throw new HttpError(403, 'Acesso negado a este alerta');
    }

    return toAlertResponse(alert);
  },

  /**
   * Atualiza um alerta
   */
  update: async (alertId, userId, alertData) => {
    const existing = await alertRepository.findById(alertId);

    if (!existing) {
      throw new HttpError(404, 'Alerta não encontrado');
    }

    if (existing.user_id !== userId) {
      throw new HttpError(403, 'Acesso negado a este alerta');
    }

    if (alertData.name && alertData.name.trim() === '') {
      throw new HttpError(400, 'Nome do alerta não pode ser vazio');
    }

    const updated = await alertRepository.update(alertId, {
      name: alertData.name || existing.name,
      transaction: alertData.transaction !== undefined ? alertData.transaction : existing.transaction,
      city: alertData.city !== undefined ? alertData.city : existing.city,
      state: alertData.state !== undefined ? alertData.state : existing.state,
      neighborhood: alertData.neighborhood !== undefined ? alertData.neighborhood : existing.neighborhood,
      type: alertData.type !== undefined ? alertData.type : existing.type,
      minPrice: alertData.minPrice !== undefined ? alertData.minPrice : existing.min_price,
      maxPrice: alertData.maxPrice !== undefined ? alertData.maxPrice : existing.max_price,
      minBedrooms: alertData.minBedrooms !== undefined ? alertData.minBedrooms : existing.min_bedrooms,
      minArea: alertData.minArea !== undefined ? alertData.minArea : existing.min_area,
      frequency: alertData.frequency || existing.frequency,
      isActive: alertData.isActive !== undefined ? alertData.isActive : existing.is_active,
    });

    return toAlertResponse(updated);
  },

  /**
   * Deleta um alerta
   */
  delete: async (alertId, userId) => {
    const existing = await alertRepository.findById(alertId);

    if (!existing) {
      throw new HttpError(404, 'Alerta não encontrado');
    }

    if (existing.user_id !== userId) {
      throw new HttpError(403, 'Acesso negado a este alerta');
    }

    await alertRepository.delete(alertId);
  },

  /**
   * Conta quantos alertas um usuário tem
   */
  countByUser: async (userId) => {
    return await alertRepository.countByUser(userId);
  },
};

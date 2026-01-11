import { query } from '../db/pool.js';

/**
 * Repository para gerenciar alertas de novos imóveis
 */
export const alertRepository = {
  /**
   * Cria um novo alerta
   * @param {Object} alertData - Dados do alerta
   * @returns {Promise<object>}
   */
  create: async (alertData) => {
    const result = await query(
      `INSERT INTO property_alerts (
        user_id,
        name,
        transaction,
        city,
        state,
        neighborhood,
        type,
        min_price,
        max_price,
        min_bedrooms,
        min_area,
        frequency,
        is_active
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      RETURNING *`,
      [
        alertData.userId,
        alertData.name,
        alertData.transaction || null,
        alertData.city || null,
        alertData.state || null,
        alertData.neighborhood || null,
        alertData.type || null,
        alertData.minPrice || null,
        alertData.maxPrice || null,
        alertData.minBedrooms || null,
        alertData.minArea || null,
        alertData.frequency || 'DAILY',
        alertData.isActive !== false,
      ]
    );
    return result.rows[0];
  },

  /**
   * Lista todos os alertas de um usuário
   * @param {string} userId - ID do usuário
   * @returns {Promise<Array>}
   */
  findByUser: async (userId) => {
    const result = await query(
      `SELECT * FROM property_alerts
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [userId]
    );
    return result.rows;
  },

  /**
   * Busca um alerta por ID
   * @param {string} alertId - ID do alerta
   * @returns {Promise<object|null>}
   */
  findById: async (alertId) => {
    const result = await query(
      `SELECT * FROM property_alerts WHERE id = $1`,
      [alertId]
    );
    return result.rows[0] || null;
  },

  /**
   * Atualiza um alerta
   * @param {string} alertId - ID do alerta
   * @param {Object} alertData - Dados atualizados
   * @returns {Promise<object|null>}
   */
  update: async (alertId, alertData) => {
    const result = await query(
      `UPDATE property_alerts
       SET name = $1,
           transaction = $2,
           city = $3,
           state = $4,
           neighborhood = $5,
           type = $6,
           min_price = $7,
           max_price = $8,
           min_bedrooms = $9,
           min_area = $10,
           frequency = $11,
           is_active = $12,
           updated_at = now()
       WHERE id = $13
       RETURNING *`,
      [
        alertData.name,
        alertData.transaction || null,
        alertData.city || null,
        alertData.state || null,
        alertData.neighborhood || null,
        alertData.type || null,
        alertData.minPrice || null,
        alertData.maxPrice || null,
        alertData.minBedrooms || null,
        alertData.minArea || null,
        alertData.frequency || 'DAILY',
        alertData.isActive !== false,
        alertId,
      ]
    );
    return result.rows[0] || null;
  },

  /**
   * Deleta um alerta
   * @param {string} alertId - ID do alerta
   */
  delete: async (alertId) => {
    await query('DELETE FROM property_alerts WHERE id = $1', [alertId]);
  },

  /**
   * Lista todos os alertas ativos (para processamento)
   * @returns {Promise<Array>}
   */
  findActive: async () => {
    const result = await query(
      `SELECT a.*, u.email, u.phone, u.name as user_name
       FROM property_alerts a
       INNER JOIN users u ON u.id = a.user_id
       WHERE a.is_active = TRUE
       ORDER BY a.created_at ASC`
    );
    return result.rows;
  },

  /**
   * Atualiza a data do último envio de um alerta
   * @param {string} alertId - ID do alerta
   */
  updateLastSent: async (alertId) => {
    await query(
      `UPDATE property_alerts
       SET last_sent_at = now()
       WHERE id = $1`,
      [alertId]
    );
  },

  /**
   * Conta quantos alertas um usuário tem
   * @param {string} userId - ID do usuário
   * @returns {Promise<number>}
   */
  countByUser: async (userId) => {
    const result = await query(
      'SELECT COUNT(*) as total FROM property_alerts WHERE user_id = $1',
      [userId]
    );
    return parseInt(result.rows[0].total, 10);
  },
};

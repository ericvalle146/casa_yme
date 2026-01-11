import { query } from '../db/pool.js';

/**
 * Repository para gerenciar favoritos de imóveis
 */
export const favoriteRepository = {
  /**
   * Verifica se um imóvel está favoritado por um usuário
   * @param {string} userId - ID do usuário
   * @param {string} propertyId - ID do imóvel
   * @returns {Promise<object|null>}
   */
  findByUserAndProperty: async (userId, propertyId) => {
    const result = await query(
      'SELECT * FROM favorites WHERE user_id = $1 AND property_id = $2',
      [userId, propertyId]
    );
    return result.rows[0] || null;
  },

  /**
   * Cria um favorito
   * @param {string} userId - ID do usuário
   * @param {string} propertyId - ID do imóvel
   * @returns {Promise<object>}
   */
  create: async (userId, propertyId) => {
    const result = await query(
      'INSERT INTO favorites (user_id, property_id) VALUES ($1, $2) RETURNING *',
      [userId, propertyId]
    );
    return result.rows[0];
  },

  /**
   * Remove um favorito
   * @param {string} userId - ID do usuário
   * @param {string} propertyId - ID do imóvel
   */
  delete: async (userId, propertyId) => {
    await query(
      'DELETE FROM favorites WHERE user_id = $1 AND property_id = $2',
      [userId, propertyId]
    );
  },

  /**
   * Lista todos os favoritos de um usuário com dados dos imóveis
   * @param {string} userId - ID do usuário
   * @returns {Promise<Array>}
   */
  listByUser: async (userId) => {
    const result = await query(
      `SELECT
        f.id as favorite_id,
        f.created_at as favorited_at,
        p.*,
        cover.url AS cover_url
      FROM favorites f
      INNER JOIN properties p ON p.id = f.property_id
      LEFT JOIN LATERAL (
        SELECT url
        FROM property_media
        WHERE property_id = p.id AND is_active = TRUE
        ORDER BY is_cover DESC, position ASC
        LIMIT 1
      ) cover ON true
      WHERE f.user_id = $1 AND p.is_active = TRUE
      ORDER BY f.created_at DESC`,
      [userId]
    );
    return result.rows;
  },

  /**
   * Conta quantos favoritos um usuário tem
   * @param {string} userId - ID do usuário
   * @returns {Promise<number>}
   */
  countByUser: async (userId) => {
    const result = await query(
      'SELECT COUNT(*) as total FROM favorites WHERE user_id = $1',
      [userId]
    );
    return parseInt(result.rows[0].total, 10);
  },

  /**
   * Conta quantos favoritos um imóvel tem
   * @param {string} propertyId - ID do imóvel
   * @returns {Promise<number>}
   */
  countByProperty: async (propertyId) => {
    const result = await query(
      'SELECT COUNT(*) as total FROM favorites WHERE property_id = $1',
      [propertyId]
    );
    return parseInt(result.rows[0].total, 10);
  }
};

import { favoriteRepository } from '../repositories/favoriteRepository.js';
import { propertyRepository } from '../repositories/propertyRepository.js';
import { HttpError } from '../utils/errors.js';
import { logger } from '../config/logger.js';

/**
 * Serviço de gerenciamento de favoritos
 */
export const favoriteService = {
  /**
   * Adiciona ou remove um imóvel dos favoritos (toggle)
   * @param {string} userId - ID do usuário
   * @param {string} propertyId - ID do imóvel
   * @returns {Promise<{isFavorited: boolean, message: string}>}
   */
  toggle: async (userId, propertyId) => {
    // Verificar se o imóvel existe
    const property = await propertyRepository.findById(propertyId);
    if (!property) {
      throw new HttpError(404, 'Imovel nao encontrado.');
    }

    // Verificar se já está favoritado
    const existing = await favoriteRepository.findByUserAndProperty(userId, propertyId);

    if (existing) {
      // Remove favorito
      await favoriteRepository.delete(userId, propertyId);
      logger.info({ userId, propertyId }, 'Favorito removido');
      return {
        isFavorited: false,
        message: 'Imovel removido dos favoritos.'
      };
    } else {
      // Adiciona favorito
      await favoriteRepository.create(userId, propertyId);
      logger.info({ userId, propertyId }, 'Favorito adicionado');
      return {
        isFavorited: true,
        message: 'Imovel adicionado aos favoritos.'
      };
    }
  },

  /**
   * Lista todos os favoritos de um usuário
   * @param {string} userId - ID do usuário
   * @returns {Promise<Array>}
   */
  listByUser: async (userId) => {
    const favorites = await favoriteRepository.listByUser(userId);

    return favorites.map((fav) => ({
      id: fav.id,
      title: fav.title,
      type: fav.type,
      transaction: fav.transaction,
      price: Number(fav.price),
      bedrooms: Number(fav.bedrooms),
      bathrooms: Number(fav.bathrooms),
      area: Number(fav.area),
      neighborhood: fav.neighborhood,
      city: fav.city,
      state: fav.state,
      description: fav.description,
      amenities: fav.amenities || [],
      image: fav.cover_url || null,
      iptu: fav.iptu ? Number(fav.iptu) : 0,
      condominio: fav.condominio ? Number(fav.condominio) : 0,
      vagas: fav.vagas || 0,
      favoritedAt: fav.favorited_at,
      createdAt: fav.created_at,
      updatedAt: fav.updated_at
    }));
  },

  /**
   * Verifica se um imóvel está favoritado por um usuário
   * @param {string} userId - ID do usuário
   * @param {string} propertyId - ID do imóvel
   * @returns {Promise<boolean>}
   */
  isFavorited: async (userId, propertyId) => {
    const favorite = await favoriteRepository.findByUserAndProperty(userId, propertyId);
    return !!favorite;
  },

  /**
   * Remove todos os favoritos de um usuário
   * @param {string} userId - ID do usuário
   */
  clearAll: async (userId) => {
    await query('DELETE FROM favorites WHERE user_id = $1', [userId]);
    logger.info({ userId }, 'Todos os favoritos removidos');
  }
};

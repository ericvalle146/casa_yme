import { favoriteService } from '../services/favoriteService.js';
import { HttpError } from '../utils/errors.js';

/**
 * Controller para gerenciar favoritos
 */
export const favoriteController = {
  /**
   * POST /api/favorites/toggle
   * Adiciona ou remove um imóvel dos favoritos
   */
  toggle: async (req, res) => {
    const { propertyId } = req.body;

    if (!propertyId) {
      throw new HttpError(400, 'propertyId e obrigatorio.');
    }

    const result = await favoriteService.toggle(req.user.id, propertyId);

    res.status(200).json(result);
  },

  /**
   * GET /api/favorites
   * Lista todos os favoritos do usuário autenticado
   */
  list: async (req, res) => {
    const favorites = await favoriteService.listByUser(req.user.id);
    res.status(200).json(favorites);
  },

  /**
   * GET /api/favorites/check/:propertyId
   * Verifica se um imóvel está favoritado
   */
  check: async (req, res) => {
    const { propertyId } = req.params;

    if (!propertyId) {
      throw new HttpError(400, 'propertyId e obrigatorio.');
    }

    const isFavorited = await favoriteService.isFavorited(req.user.id, propertyId);

    res.status(200).json({ isFavorited });
  },

  /**
   * DELETE /api/favorites
   * Remove todos os favoritos do usuário
   */
  clearAll: async (req, res) => {
    await favoriteService.clearAll(req.user.id);
    res.status(200).json({ message: 'Todos os favoritos removidos.' });
  }
};

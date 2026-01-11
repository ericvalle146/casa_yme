import { Router } from 'express';
import { favoriteController } from '../controllers/favoriteController.js';
import { authenticate } from '../middlewares/authenticate.js';
import { asyncHandler } from '../middlewares/asyncHandler.js';

const router = Router();

// Todas as rotas de favoritos requerem autenticação
router.use(authenticate);

// POST /api/favorites/toggle - Adiciona ou remove favorito
router.post('/toggle', asyncHandler(favoriteController.toggle));

// GET /api/favorites - Lista todos os favoritos do usuário
router.get('/', asyncHandler(favoriteController.list));

// GET /api/favorites/check/:propertyId - Verifica se está favoritado
router.get('/check/:propertyId', asyncHandler(favoriteController.check));

// DELETE /api/favorites - Remove todos os favoritos
router.delete('/', asyncHandler(favoriteController.clearAll));

export default router;

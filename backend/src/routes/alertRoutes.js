import { Router } from 'express';
import { alertController } from '../controllers/alertController.js';
import { asyncHandler } from '../middlewares/asyncHandler.js';
import { authenticate } from '../middlewares/authenticate.js';

const router = Router();

// Todas as rotas de alertas requerem autenticação
router.post('/', authenticate, asyncHandler(alertController.create));
router.get('/', authenticate, asyncHandler(alertController.list));
router.get('/:id', authenticate, asyncHandler(alertController.getById));
router.put('/:id', authenticate, asyncHandler(alertController.update));
router.delete('/:id', authenticate, asyncHandler(alertController.delete));

export default router;

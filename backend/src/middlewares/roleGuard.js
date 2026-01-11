import { HttpError } from '../utils/errors.js';

/**
 * Middleware para verificar se o usuário tem uma das roles permitidas
 * @param {...string} allowedRoles - Lista de roles permitidas (VISITANTE, CORRETOR, ADMIN)
 * @returns {Function} Middleware function
 *
 * @example
 * // Permitir apenas CORRETOR e ADMIN
 * router.post('/properties', authenticate, requireRole('CORRETOR', 'ADMIN'), createProperty);
 *
 * @example
 * // Permitir apenas ADMIN
 * router.delete('/users/:id', authenticate, requireRole('ADMIN'), deleteUser);
 */
export const requireRole = (...allowedRoles) => {
  return (req, _res, next) => {
    // Verificar se o usuário está autenticado
    if (!req.user) {
      return next(new HttpError(401, 'Autenticação necessária'));
    }

    // Verificar se o usuário tem uma das roles permitidas
    const userType = req.user.userType || 'VISITANTE';

    if (!allowedRoles.includes(userType)) {
      return next(
        new HttpError(
          403,
          `Acesso negado. Permissões necessárias: ${allowedRoles.join(', ')}`
        )
      );
    }

    next();
  };
};

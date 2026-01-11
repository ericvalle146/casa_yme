import { alertService } from '../services/alertService.js';

const parseNumber = (value) => {
  if (value === undefined || value === null || value === '') return undefined;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : undefined;
};

export const alertController = {
  /**
   * POST /api/alerts
   * Cria um novo alerta
   */
  create: async (req, res) => {
    const alertData = {
      name: req.body.name,
      transaction: req.body.transaction,
      city: req.body.city,
      state: req.body.state,
      neighborhood: req.body.neighborhood,
      type: req.body.type,
      minPrice: parseNumber(req.body.minPrice),
      maxPrice: parseNumber(req.body.maxPrice),
      minBedrooms: parseNumber(req.body.minBedrooms),
      minArea: parseNumber(req.body.minArea),
      frequency: req.body.frequency || 'DAILY',
      isActive: req.body.isActive !== false,
    };

    const alert = await alertService.create(req.user.id, alertData);
    res.status(201).json(alert);
  },

  /**
   * GET /api/alerts
   * Lista todos os alertas do usuário
   */
  list: async (req, res) => {
    const alerts = await alertService.listByUser(req.user.id);
    res.status(200).json(alerts);
  },

  /**
   * GET /api/alerts/:id
   * Busca um alerta por ID
   */
  getById: async (req, res) => {
    const alert = await alertService.getById(req.params.id, req.user.id);
    res.status(200).json(alert);
  },

  /**
   * PUT /api/alerts/:id
   * Atualiza um alerta
   */
  update: async (req, res) => {
    const alertData = {
      name: req.body.name,
      transaction: req.body.transaction,
      city: req.body.city,
      state: req.body.state,
      neighborhood: req.body.neighborhood,
      type: req.body.type,
      minPrice: parseNumber(req.body.minPrice),
      maxPrice: parseNumber(req.body.maxPrice),
      minBedrooms: parseNumber(req.body.minBedrooms),
      minArea: parseNumber(req.body.minArea),
      frequency: req.body.frequency,
      isActive: req.body.isActive,
    };

    const alert = await alertService.update(req.params.id, req.user.id, alertData);
    res.status(200).json(alert);
  },

  /**
   * DELETE /api/alerts/:id
   * Deleta um alerta
   */
  delete: async (req, res) => {
    await alertService.delete(req.params.id, req.user.id);
    res.status(200).json({ message: 'Alerta deletado com sucesso' });
  },
};

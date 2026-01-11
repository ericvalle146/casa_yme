import { propertyService } from "../services/propertyService.js";
import { HttpError } from "../utils/errors.js";

const parseJson = (value, fallback) => {
  if (!value) return fallback;
  try {
    return JSON.parse(value);
  } catch (error) {
    return fallback;
  }
};

const parseNumber = (value, field) => {
  if (value === undefined || value === null || value === "") return undefined;
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) {
    throw new HttpError(400, `Campo invalido: ${field}.`);
  }
  return parsed;
};

const parseAmenities = (value) => {
  if (value === undefined || value === null) return undefined;
  const parsed = parseJson(value, null);
  if (Array.isArray(parsed)) {
    return parsed;
  }
  if (typeof value === "string") {
    return value
      .split(",")
      .map((item) => item.trim())
      .filter(Boolean);
  }
  return [];
};

const parseMediaUrls = (value) => {
  const parsed = parseJson(value, []);
  if (!Array.isArray(parsed)) return [];
  return parsed
    .map((item) => ({
      url: item?.url ? String(item.url) : "",
      alt: item?.alt ? String(item.alt) : "",
      isCover: Boolean(item?.isCover),
    }))
    .filter((item) => item.url);
};

const parseMediaFilesMeta = (value) => {
  const parsed = parseJson(value, []);
  if (!Array.isArray(parsed)) return [];
  return parsed.map((item) => ({
    alt: item?.alt ? String(item.alt) : "",
    isCover: Boolean(item?.isCover),
  }));
};

const buildPayload = (body) => ({
  title: body.title,
  type: body.type,
  transaction: body.transaction,
  price: parseNumber(body.price, "price"),
  isActive: body.is_active !== undefined ? String(body.is_active) === "true" : true,
  bedrooms: parseNumber(body.bedrooms, "bedrooms"),
  bathrooms: parseNumber(body.bathrooms, "bathrooms"),
  suites: parseNumber(body.suites, "suites") || 0,
  area: parseNumber(body.area, "area"),
  vagas: parseNumber(body.vagas, "vagas") || 0,
  zipCode: body.zip_code || body.zipCode,
  street: body.street,
  number: body.number,
  complement: body.complement,
  neighborhood: body.neighborhood,
  city: body.city,
  state: body.state,
  iptu: parseNumber(body.iptu, "iptu") || 0,
  condominio: parseNumber(body.condominio, "condominio") || 0,
  description: body.description,
  amenities: parseAmenities(body.amenities),
});

export const propertyController = {
  list: async (_req, res) => {
    const properties = await propertyService.list();
    res.status(200).json(properties);
  },

  getById: async (req, res) => {
    const property = await propertyService.getById(req.params.id);
    res.status(200).json(property);
  },

  create: async (req, res) => {
    const payload = buildPayload(req.body || {});
    const mediaUrls = parseMediaUrls(req.body?.mediaUrls);
    const mediaFilesMeta = parseMediaFilesMeta(req.body?.mediaFilesMeta);
    const mediaFiles = req.files || [];

    const property = await propertyService.create({
      payload,
      mediaUrls,
      mediaFiles,
      mediaFilesMeta,
      createdBy: req.user.id,
    });

    res.status(201).json(property);
  },

  update: async (req, res) => {
    const payload = buildPayload(req.body || {});
    const mediaUrls = parseMediaUrls(req.body?.mediaUrls);
    const mediaFilesMeta = parseMediaFilesMeta(req.body?.mediaFilesMeta);
    const mediaFiles = req.files || [];
    const replaceMedia = String(req.body?.replaceMedia) === "true";

    const property = await propertyService.update({
      id: req.params.id,
      payload,
      mediaUrls,
      mediaFiles,
      mediaFilesMeta,
      replaceMedia,
    });

    res.status(200).json(property);
  },

  remove: async (req, res) => {
    await propertyService.remove(req.params.id);
    res.status(200).json({ message: "Imovel removido." });
  },

  /**
   * GET /api/properties/search
   * Busca avançada com filtros
   */
  search: async (req, res) => {
    const filters = {
      transaction: req.query.transaction,
      type: req.query.type,
      city: req.query.city,
      state: req.query.state,
      neighborhood: req.query.neighborhood,
      minPrice: parseNumber(req.query.minPrice, "minPrice"),
      maxPrice: parseNumber(req.query.maxPrice, "maxPrice"),
      minBedrooms: parseNumber(req.query.minBedrooms, "minBedrooms"),
      minArea: parseNumber(req.query.minArea, "minArea"),
      minVagas: parseNumber(req.query.minVagas, "minVagas"),
      latitude: parseNumber(req.query.latitude, "latitude"),
      longitude: parseNumber(req.query.longitude, "longitude"),
      radius: parseNumber(req.query.radius, "radius"),
      query: req.query.q || req.query.query,
      limit: parseNumber(req.query.limit, "limit") || 20,
      offset: parseNumber(req.query.offset, "offset") || 0,
    };

    // Remover valores undefined
    Object.keys(filters).forEach(key => {
      if (filters[key] === undefined) delete filters[key];
    });

    const properties = await propertyService.search(filters);
    res.status(200).json(properties);
  },

  /**
   * GET /api/properties/autocomplete/locations
   * Autocomplete de localizações
   */
  autocompleteLocations: async (req, res) => {
    const searchTerm = req.query.q || req.query.query || "";
    const locations = await propertyService.autocompleteLocations(searchTerm);
    res.status(200).json(locations);
  },

  /**
   * GET /api/properties/:id/nearby
   * Imóveis próximos ao imóvel especificado
   */
  findNearby: async (req, res) => {
    const propertyId = req.params.id;
    const limit = parseNumber(req.query.limit, "limit") || 6;
    const properties = await propertyService.findNearby(propertyId, limit);
    res.status(200).json(properties);
  },
};

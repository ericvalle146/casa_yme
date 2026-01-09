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
  bedrooms: parseNumber(body.bedrooms, "bedrooms"),
  bathrooms: parseNumber(body.bathrooms, "bathrooms"),
  area: parseNumber(body.area, "area"),
  neighborhood: body.neighborhood,
  city: body.city,
  state: body.state,
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
};

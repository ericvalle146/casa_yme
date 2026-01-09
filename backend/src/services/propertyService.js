import { propertyRepository } from "../repositories/propertyRepository.js";
import { HttpError } from "../utils/errors.js";
import { removeUploadFile } from "../utils/files.js";

const normalizeAmenities = (amenities) =>
  Array.isArray(amenities)
    ? amenities.map((item) => String(item).trim()).filter(Boolean)
    : [];

const toPropertyResponse = (property, media = []) => {
  const cover = media.find((item) => item.is_cover) || media[0];
  return {
    id: property.id,
    title: property.title,
    type: property.type,
    transaction: property.transaction,
    price: Number(property.price),
    bedrooms: Number(property.bedrooms),
    bathrooms: Number(property.bathrooms),
    area: Number(property.area),
    neighborhood: property.neighborhood,
    city: property.city,
    state: property.state,
    description: property.description,
    amenities: property.amenities || [],
    image: cover ? cover.url : null,
    gallery: media.map((item) => ({
      id: item.id,
      url: item.url,
      alt: item.alt || "",
      position: item.position,
      isCover: item.is_cover,
    })),
    createdBy: property.created_by,
    createdAt: property.created_at,
    updatedAt: property.updated_at,
  };
};

const buildMediaItems = ({
  propertyId,
  mediaUrls = [],
  mediaFiles = [],
  mediaFilesMeta = [],
}) => {
  const items = [];

  mediaUrls.forEach((item, index) => {
    if (!item || !item.url) return;
    items.push({
      propertyId,
      url: item.url,
      alt: item.alt || "",
      isCover: Boolean(item.isCover),
      position: items.length,
      storageKey: null,
    });
  });

  mediaFiles.forEach((file, index) => {
    const meta = mediaFilesMeta[index] || {};
    items.push({
      propertyId,
      url: `/uploads/${file.filename}`,
      alt: meta.alt || file.originalname || "",
      isCover: Boolean(meta.isCover),
      position: items.length,
      storageKey: file.filename,
    });
  });

  if (items.length && !items.some((item) => item.isCover)) {
    items[0].isCover = true;
  }

  return items.map((item, index) => ({ ...item, position: index }));
};

const validatePropertyPayload = (payload) => {
  const required = [
    "title",
    "type",
    "transaction",
    "price",
    "bedrooms",
    "bathrooms",
    "area",
    "neighborhood",
    "city",
    "state",
    "description",
  ];

  required.forEach((field) => {
    if (payload[field] === undefined || payload[field] === null || payload[field] === "") {
      throw new HttpError(400, `Campo obrigatorio: ${field}.`);
    }
  });

  if (!['VENDA', 'ALUGUEL'].includes(payload.transaction)) {
    throw new HttpError(400, "Transacao invalida.");
  }
};

export const propertyService = {
  list: async () => {
    const rows = await propertyRepository.list();
    return rows.map((row) => ({
      id: row.id,
      title: row.title,
      type: row.type,
      transaction: row.transaction,
      price: Number(row.price),
      bedrooms: Number(row.bedrooms),
      bathrooms: Number(row.bathrooms),
      area: Number(row.area),
      neighborhood: row.neighborhood,
      city: row.city,
      state: row.state,
      description: row.description,
      amenities: row.amenities || [],
      image: row.cover_url || null,
      createdBy: row.created_by,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }));
  },

  getById: async (id) => {
    const property = await propertyRepository.findById(id);
    if (!property) {
      throw new HttpError(404, "Imovel nao encontrado.");
    }

    const media = await propertyRepository.listMediaByProperty(id);
    return toPropertyResponse(property, media);
  },

  create: async ({ payload, mediaUrls, mediaFiles, mediaFilesMeta, createdBy }) => {
    validatePropertyPayload(payload);

    const property = await propertyRepository.create({
      ...payload,
      amenities: normalizeAmenities(payload.amenities),
      createdBy,
    });

    const mediaItems = buildMediaItems({
      propertyId: property.id,
      mediaUrls,
      mediaFiles,
      mediaFilesMeta,
    });

    const media = await propertyRepository.insertMediaBulk(mediaItems);

    return toPropertyResponse(property, media);
  },

  update: async ({ id, payload, mediaUrls, mediaFiles, mediaFilesMeta, replaceMedia }) => {
    const existing = await propertyRepository.findById(id);
    if (!existing) {
      throw new HttpError(404, "Imovel nao encontrado.");
    }

    const mergedPayload = {
      title: payload.title ?? existing.title,
      type: payload.type ?? existing.type,
      transaction: payload.transaction ?? existing.transaction,
      price: payload.price ?? existing.price,
      bedrooms: payload.bedrooms ?? existing.bedrooms,
      bathrooms: payload.bathrooms ?? existing.bathrooms,
      area: payload.area ?? existing.area,
      neighborhood: payload.neighborhood ?? existing.neighborhood,
      city: payload.city ?? existing.city,
      state: payload.state ?? existing.state,
      description: payload.description ?? existing.description,
      amenities: payload.amenities ?? existing.amenities,
    };

    validatePropertyPayload(mergedPayload);

    const property = await propertyRepository.update(id, {
      ...mergedPayload,
      amenities: normalizeAmenities(mergedPayload.amenities),
    });

    let media = await propertyRepository.listMediaByProperty(id);

    if (replaceMedia) {
      await propertyRepository.deleteMediaByProperty(id);
      const mediaItems = buildMediaItems({
        propertyId: id,
        mediaUrls,
        mediaFiles,
        mediaFilesMeta,
      });
      media = await propertyRepository.insertMediaBulk(mediaItems);
    }

    return toPropertyResponse(property, media);
  },

  remove: async (id) => {
    const media = await propertyRepository.listMediaByProperty(id);
    await propertyRepository.deleteById(id);

    media.forEach((item) => {
      if (item.storage_key) {
        removeUploadFile(item.storage_key);
      }
    });
  },
};

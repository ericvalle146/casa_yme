import { propertyRepository } from "../repositories/propertyRepository.js";
import { HttpError } from "../utils/errors.js";
import { removeUploadFile } from "../utils/files.js";
import { geocodingService } from "./geocodingService.js";

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
    // Novos campos adicionados
    iptu: property.iptu ? Number(property.iptu) : 0,
    condominio: property.condominio ? Number(property.condominio) : 0,
    vagas: property.vagas || 0,
    latitude: property.latitude ? Number(property.latitude) : null,
    longitude: property.longitude ? Number(property.longitude) : null,
    fullAddress: property.full_address || null,
    street: property.street || null,
    number: property.number || null,
    complement: property.complement || null,
    zipCode: property.zip_code || null,
    areaTotal: property.area_total || 0,
    suites: property.suites || 0,
    isActive: property.is_active !== false,
    viewsCount: property.views_count || 0,
    contactsCount: property.contacts_count || 0,
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
      // Novos campos
      iptu: row.iptu ? Number(row.iptu) : 0,
      condominio: row.condominio ? Number(row.condominio) : 0,
      vagas: row.vagas || 0,
      latitude: row.latitude ? Number(row.latitude) : null,
      longitude: row.longitude ? Number(row.longitude) : null,
      fullAddress: row.full_address || null,
      isActive: row.is_active !== false,
      viewsCount: row.views_count || 0,
      contactsCount: row.contacts_count || 0,
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

    // Geocoding: converter endereço em coordenadas GPS
    let latitude = null;
    let longitude = null;
    let fullAddress = null;

    if (payload.street || payload.city) {
      const addressComponents = {
        street: payload.street,
        number: payload.number,
        neighborhood: payload.neighborhood,
        city: payload.city,
        state: payload.state,
        zipCode: payload.zipCode
      };

      fullAddress = geocodingService.buildFullAddress(addressComponents);

      const geocodeResult = await geocodingService.geocodeAddress(fullAddress);
      latitude = geocodeResult.latitude;
      longitude = geocodeResult.longitude;
      if (geocodeResult.formattedAddress) {
        fullAddress = geocodeResult.formattedAddress;
      }
    }

    const property = await propertyRepository.create({
      ...payload,
      amenities: normalizeAmenities(payload.amenities),
      latitude,
      longitude,
      fullAddress,
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
      iptu: payload.iptu ?? existing.iptu,
      condominio: payload.condominio ?? existing.condominio,
      vagas: payload.vagas ?? existing.vagas,
      street: payload.street ?? existing.street,
      number: payload.number ?? existing.number,
      complement: payload.complement ?? existing.complement,
      zipCode: payload.zipCode ?? existing.zip_code,
      areaTotal: payload.areaTotal ?? existing.area_total,
      suites: payload.suites ?? existing.suites,
      isActive: payload.isActive ?? existing.is_active,
    };

    validatePropertyPayload(mergedPayload);

    // Re-fazer geocoding se os campos de endereço mudaram
    const addressChanged =
      payload.street !== undefined ||
      payload.number !== undefined ||
      payload.neighborhood !== undefined ||
      payload.city !== undefined ||
      payload.state !== undefined ||
      payload.zipCode !== undefined;

    let updateData = {
      ...mergedPayload,
      amenities: normalizeAmenities(mergedPayload.amenities),
    };

    if (addressChanged) {
      const addressComponents = {
        street: mergedPayload.street,
        number: mergedPayload.number,
        neighborhood: mergedPayload.neighborhood,
        city: mergedPayload.city,
        state: mergedPayload.state,
        zipCode: mergedPayload.zipCode
      };

      const fullAddress = geocodingService.buildFullAddress(addressComponents);
      const geocodeResult = await geocodingService.geocodeAddress(fullAddress);

      updateData.latitude = geocodeResult.latitude;
      updateData.longitude = geocodeResult.longitude;
      updateData.fullAddress = geocodeResult.formattedAddress || fullAddress;
    }

    const property = await propertyRepository.update(id, updateData);

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

  /**
   * Busca avançada de imóveis com filtros
   */
  search: async (filters) => {
    const rows = await propertyRepository.search(filters);
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
      iptu: row.iptu ? Number(row.iptu) : 0,
      condominio: row.condominio ? Number(row.condominio) : 0,
      vagas: row.vagas || 0,
      latitude: row.latitude ? Number(row.latitude) : null,
      longitude: row.longitude ? Number(row.longitude) : null,
      fullAddress: row.full_address || null,
      createdAt: row.created_at,
      distance: row.distance ? Number(row.distance) : null, // Distância em km (se busca por proximidade)
    }));
  },

  /**
   * Autocomplete de localizações
   */
  autocompleteLocations: async (searchTerm) => {
    return await propertyRepository.autocompleteLocations(searchTerm);
  },

  /**
   * Encontra imóveis próximos
   */
  findNearby: async (propertyId, limit = 6) => {
    const rows = await propertyRepository.findNearby(propertyId, limit);
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
      image: row.cover_url || null,
      iptu: row.iptu ? Number(row.iptu) : 0,
      condominio: row.condominio ? Number(row.condominio) : 0,
      vagas: row.vagas || 0,
      latitude: row.latitude ? Number(row.latitude) : null,
      longitude: row.longitude ? Number(row.longitude) : null,
      distance: row.distance ? Number(row.distance).toFixed(2) : null, // Distância em km com 2 casas decimais
    }));
  },
};

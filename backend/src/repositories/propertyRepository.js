import { query } from "../db/pool.js";

export const propertyRepository = {
  list: async () => {
    const result = await query(
      `SELECT
        p.id,
        p.title,
        p.type,
        p.transaction,
        p.price,
        p.bedrooms,
        p.bathrooms,
        p.suites,
        p.area,
        p.vagas,
        p.neighborhood,
        p.city,
        p.state,
        p.description,
        p.amenities,
        p.iptu,
        p.condominio,
        p.latitude,
        p.longitude,
        p.full_address,
        p.is_active,
        p.views_count,
        p.contacts_count,
        p.created_by,
        p.created_at,
        p.updated_at,
        cover.url AS cover_url
      FROM properties p
      LEFT JOIN LATERAL (
        SELECT url
        FROM property_media
        WHERE property_id = p.id
        ORDER BY is_cover DESC, position ASC
        LIMIT 1
      ) cover ON true
      ORDER BY p.created_at DESC`,
    );

    return result.rows;
  },

  findById: async (id) => {
    const result = await query(
      `SELECT
        id,
        title,
        type,
        transaction,
        price,
        bedrooms,
        bathrooms,
        suites,
        area,
        vagas,
        iptu,
        condominio,
        street,
        number,
        complement,
        zip_code,
        neighborhood,
        city,
        state,
        latitude,
        longitude,
        full_address,
        area_total,
        is_active,
        views_count,
        contacts_count,
        description,
        amenities,
        created_by,
        created_at,
        updated_at
      FROM properties
      WHERE id = $1`,
      [id],
    );

    return result.rows[0] || null;
  },

  create: async ({
    title,
    type,
    transaction,
    price,
    bedrooms,
    bathrooms,
    suites,
    area,
    vagas,
    iptu,
    condominio,
    street,
    number,
    complement,
    zipCode,
    neighborhood,
    city,
    state,
    latitude,
    longitude,
    fullAddress,
    isActive,
    description,
    amenities,
    createdBy,
  }) => {
    const result = await query(
      `INSERT INTO properties (
        title,
        type,
        transaction,
        price,
        bedrooms,
        bathrooms,
        suites,
        area,
        vagas,
        iptu,
        condominio,
        street,
        number,
        complement,
        zip_code,
        neighborhood,
        city,
        state,
        latitude,
        longitude,
        full_address,
        is_active,
        description,
        amenities,
        created_by
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25)
      RETURNING *`,
      [
        title,
        type,
        transaction,
        price,
        bedrooms,
        bathrooms,
        suites || 0,
        area,
        vagas || 0,
        iptu || 0,
        condominio || 0,
        street,
        number,
        complement,
        zipCode,
        neighborhood,
        city,
        state,
        latitude,
        longitude,
        fullAddress,
        isActive !== undefined ? isActive : true,
        description,
        amenities,
        createdBy,
      ],
    );

    return result.rows[0];
  },

  update: async (id, fields) => {
    const result = await query(
      `UPDATE properties
       SET title = $1,
           type = $2,
           transaction = $3,
           price = $4,
           bedrooms = $5,
           bathrooms = $6,
           suites = $7,
           area = $8,
           vagas = $9,
           iptu = $10,
           condominio = $11,
           street = $12,
           number = $13,
           complement = $14,
           zip_code = $15,
           neighborhood = $16,
           city = $17,
           state = $18,
           latitude = $19,
           longitude = $20,
           full_address = $21,
           is_active = $22,
           description = $23,
           amenities = $24
       WHERE id = $25
       RETURNING *`,
      [
        fields.title,
        fields.type,
        fields.transaction,
        fields.price,
        fields.bedrooms,
        fields.bathrooms,
        fields.suites || 0,
        fields.area,
        fields.vagas || 0,
        fields.iptu || 0,
        fields.condominio || 0,
        fields.street,
        fields.number,
        fields.complement,
        fields.zipCode,
        fields.neighborhood,
        fields.city,
        fields.state,
        fields.latitude,
        fields.longitude,
        fields.fullAddress,
        fields.isActive !== undefined ? fields.isActive : true,
        fields.description,
        fields.amenities,
        id,
      ],
    );

    return result.rows[0] || null;
  },

  listMediaByProperty: async (propertyId) => {
    const result = await query(
      `SELECT id, property_id, url, alt, position, is_cover, storage_key
       FROM property_media
       WHERE property_id = $1
       ORDER BY position ASC`,
      [propertyId],
    );

    return result.rows;
  },

  deleteMediaByProperty: async (propertyId) => {
    const result = await query(
      `DELETE FROM property_media
       WHERE property_id = $1
       RETURNING storage_key`,
      [propertyId],
    );

    return result.rows;
  },

  insertMediaBulk: async (items) => {
    if (!items.length) return [];

    const values = [];
    const placeholders = items.map((item, index) => {
      const base = index * 6;
      values.push(
        item.propertyId,
        item.url,
        item.alt || null,
        item.position,
        item.isCover,
        item.storageKey || null,
      );
      return `($${base + 1}, $${base + 2}, $${base + 3}, $${base + 4}, $${base + 5}, $${base + 6})`;
    });

    const result = await query(
      `INSERT INTO property_media (property_id, url, alt, position, is_cover, storage_key)
       VALUES ${placeholders.join(", ")}
       RETURNING id, property_id, url, alt, position, is_cover`,
      values,
    );

    return result.rows;
  },

  deleteById: async (id) => {
    await query("DELETE FROM properties WHERE id = $1", [id]);
  },

  /**
   * Busca avançada de imóveis com múltiplos filtros
   * @param {Object} filters - Filtros de busca
   * @returns {Promise<Array>}
   */
  search: async (filters) => {
    const conditions = [];
    const values = [];
    let paramCount = 1;

    // Filtro: is_active (sempre ativo por padrão)
    conditions.push(`p.is_active = true`);

    // Filtro: transaction (VENDA, ALUGUEL)
    if (filters.transaction) {
      conditions.push(`p.transaction = $${paramCount}`);
      values.push(filters.transaction);
      paramCount++;
    }

    // Filtro: type (CASA, APARTAMENTO, etc)
    if (filters.type) {
      conditions.push(`p.type = $${paramCount}`);
      values.push(filters.type);
      paramCount++;
    }

    // Filtro: city
    if (filters.city) {
      conditions.push(`LOWER(p.city) = LOWER($${paramCount})`);
      values.push(filters.city);
      paramCount++;
    }

    // Filtro: state
    if (filters.state) {
      conditions.push(`LOWER(p.state) = LOWER($${paramCount})`);
      values.push(filters.state);
      paramCount++;
    }

    // Filtro: neighborhood
    if (filters.neighborhood) {
      conditions.push(`LOWER(p.neighborhood) = LOWER($${paramCount})`);
      values.push(filters.neighborhood);
      paramCount++;
    }

    // Filtro: minPrice
    if (filters.minPrice) {
      conditions.push(`p.price >= $${paramCount}`);
      values.push(filters.minPrice);
      paramCount++;
    }

    // Filtro: maxPrice
    if (filters.maxPrice) {
      conditions.push(`p.price <= $${paramCount}`);
      values.push(filters.maxPrice);
      paramCount++;
    }

    // Filtro: minBedrooms
    if (filters.minBedrooms) {
      conditions.push(`p.bedrooms >= $${paramCount}`);
      values.push(filters.minBedrooms);
      paramCount++;
    }

    // Filtro: minArea
    if (filters.minArea) {
      conditions.push(`p.area >= $${paramCount}`);
      values.push(filters.minArea);
      paramCount++;
    }

    // Filtro: minVagas
    if (filters.minVagas) {
      conditions.push(`p.vagas >= $${paramCount}`);
      values.push(filters.minVagas);
      paramCount++;
    }

    // Filtro de proximidade (latitude, longitude, radius em km)
    let distanceSelect = '';
    if (filters.latitude && filters.longitude && filters.radius) {
      distanceSelect = `, (
        6371 * acos(
          cos(radians($${paramCount})) *
          cos(radians(p.latitude)) *
          cos(radians(p.longitude) - radians($${paramCount + 1})) +
          sin(radians($${paramCount})) *
          sin(radians(p.latitude))
        )
      ) AS distance`;
      values.push(filters.latitude, filters.longitude, filters.radius);
      conditions.push(`p.latitude IS NOT NULL AND p.longitude IS NOT NULL`);
      conditions.push(`(
        6371 * acos(
          cos(radians($${paramCount})) *
          cos(radians(p.latitude)) *
          cos(radians(p.longitude) - radians($${paramCount + 1})) +
          sin(radians($${paramCount})) *
          sin(radians(p.latitude))
        )
      ) <= $${paramCount + 2}`);
      paramCount += 3;
    }

    // Busca por texto (título ou descrição)
    if (filters.query) {
      conditions.push(`(
        LOWER(p.title) LIKE LOWER($${paramCount}) OR
        LOWER(p.description) LIKE LOWER($${paramCount})
      )`);
      values.push(`%${filters.query}%`);
      paramCount++;
    }

    // Construir WHERE clause
    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    // Ordenação
    let orderBy = 'ORDER BY p.created_at DESC';
    if (distanceSelect) {
      orderBy = 'ORDER BY distance ASC, p.created_at DESC';
    }

    // Paginação
    const limit = filters.limit || 20;
    const offset = filters.offset || 0;
    values.push(limit, offset);

    const sql = `
      SELECT
        p.id,
        p.title,
        p.type,
        p.transaction,
        p.price,
        p.bedrooms,
        p.bathrooms,
        p.area,
        p.neighborhood,
        p.city,
        p.state,
        p.description,
        p.amenities,
        p.iptu,
        p.condominio,
        p.vagas,
        p.latitude,
        p.longitude,
        p.full_address,
        p.created_at,
        cover.url AS cover_url
        ${distanceSelect}
      FROM properties p
      LEFT JOIN LATERAL (
        SELECT url
        FROM property_media
        WHERE property_id = p.id AND is_active = TRUE
        ORDER BY is_cover DESC, position ASC
        LIMIT 1
      ) cover ON true
      ${whereClause}
      ${orderBy}
      LIMIT $${paramCount} OFFSET $${paramCount + 1}
    `;

    const result = await query(sql, values);
    return result.rows;
  },

  /**
   * Autocomplete de localizações (cidade, estado, bairro)
   * @param {string} searchTerm - Termo de busca
   * @returns {Promise<Array>}
   */
  autocompleteLocations: async (searchTerm) => {
    if (!searchTerm || searchTerm.length < 2) {
      return [];
    }

    const result = await query(
      `SELECT DISTINCT
        city,
        state,
        neighborhood
      FROM properties
      WHERE is_active = true
        AND (
          LOWER(city) LIKE LOWER($1) OR
          LOWER(neighborhood) LIKE LOWER($1) OR
          LOWER(state) LIKE LOWER($1)
        )
      ORDER BY city, neighborhood
      LIMIT 10`,
      [`%${searchTerm}%`]
    );

    return result.rows;
  },

  /**
   * Encontra imóveis próximos usando fórmula de Haversine
   * @param {string} propertyId - ID do imóvel de referência
   * @param {number} limit - Número máximo de resultados (padrão: 6)
   * @returns {Promise<Array>}
   */
  findNearby: async (propertyId, limit = 6) => {
    const result = await query(
      `SELECT
        p.id,
        p.title,
        p.type,
        p.transaction,
        p.price,
        p.bedrooms,
        p.bathrooms,
        p.area,
        p.neighborhood,
        p.city,
        p.state,
        p.iptu,
        p.condominio,
        p.vagas,
        p.latitude,
        p.longitude,
        cover.url AS cover_url,
        (
          6371 * acos(
            cos(radians(ref.latitude)) *
            cos(radians(p.latitude)) *
            cos(radians(p.longitude) - radians(ref.longitude)) +
            sin(radians(ref.latitude)) *
            sin(radians(p.latitude))
          )
        ) AS distance
      FROM properties p
      CROSS JOIN (
        SELECT latitude, longitude
        FROM properties
        WHERE id = $1
      ) ref
      LEFT JOIN LATERAL (
        SELECT url
        FROM property_media
        WHERE property_id = p.id AND is_active = TRUE
        ORDER BY is_cover DESC, position ASC
        LIMIT 1
      ) cover ON true
      WHERE p.id != $1
        AND p.is_active = true
        AND p.latitude IS NOT NULL
        AND p.longitude IS NOT NULL
        AND ref.latitude IS NOT NULL
        AND ref.longitude IS NOT NULL
      ORDER BY distance ASC
      LIMIT $2`,
      [propertyId, limit]
    );

    return result.rows;
  },
};

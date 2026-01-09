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
        p.area,
        p.neighborhood,
        p.city,
        p.state,
        p.description,
        p.amenities,
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
        area,
        neighborhood,
        city,
        state,
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
    area,
    neighborhood,
    city,
    state,
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
        area,
        neighborhood,
        city,
        state,
        description,
        amenities,
        created_by
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
      RETURNING id, title, type, transaction, price, bedrooms, bathrooms, area, neighborhood, city, state, description, amenities, created_by, created_at, updated_at`,
      [
        title,
        type,
        transaction,
        price,
        bedrooms,
        bathrooms,
        area,
        neighborhood,
        city,
        state,
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
           area = $7,
           neighborhood = $8,
           city = $9,
           state = $10,
           description = $11,
           amenities = $12
       WHERE id = $13
       RETURNING id, title, type, transaction, price, bedrooms, bathrooms, area, neighborhood, city, state, description, amenities, created_by, created_at, updated_at`,
      [
        fields.title,
        fields.type,
        fields.transaction,
        fields.price,
        fields.bedrooms,
        fields.bathrooms,
        fields.area,
        fields.neighborhood,
        fields.city,
        fields.state,
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
};

import { query } from "../db/pool.js";

export const userRepository = {
  findByEmail: async (email) => {
    const result = await query(
      "SELECT id, name, email, password_hash, created_at, updated_at, last_login_at FROM users WHERE email = $1",
      [email],
    );
    return result.rows[0] || null;
  },

  findById: async (id) => {
    const result = await query(
      "SELECT id, name, email, created_at, updated_at, last_login_at FROM users WHERE id = $1",
      [id],
    );
    return result.rows[0] || null;
  },

  createUser: async ({ name, email, passwordHash }) => {
    const result = await query(
      `INSERT INTO users (name, email, password_hash)
       VALUES ($1, $2, $3)
       RETURNING id, name, email, created_at, updated_at, last_login_at`,
      [name, email, passwordHash],
    );
    return result.rows[0];
  },

  updateLastLogin: async (id) => {
    const result = await query(
      "UPDATE users SET last_login_at = now() WHERE id = $1 RETURNING last_login_at",
      [id],
    );
    return result.rows[0]?.last_login_at || null;
  },
};

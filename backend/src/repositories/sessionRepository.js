import { query } from "../db/pool.js";

export const sessionRepository = {
  createSession: async ({ userId, refreshTokenHash, expiresAt, ipAddress, userAgent }) => {
    const result = await query(
      `INSERT INTO auth_sessions (user_id, refresh_token_hash, expires_at, ip_address, user_agent, last_used_at)
       VALUES ($1, $2, $3, $4, $5, now())
       RETURNING id, user_id, refresh_token_hash, created_at, last_used_at, expires_at, revoked_at`,
      [userId, refreshTokenHash, expiresAt, ipAddress || null, userAgent || null],
    );
    return result.rows[0];
  },

  findByRefreshTokenHash: async (refreshTokenHash) => {
    const result = await query(
      `SELECT id, user_id, refresh_token_hash, created_at, last_used_at, expires_at, revoked_at
       FROM auth_sessions
       WHERE refresh_token_hash = $1`,
      [refreshTokenHash],
    );
    return result.rows[0] || null;
  },

  rotateSession: async ({ sessionId, refreshTokenHash, expiresAt, ipAddress, userAgent }) => {
    const result = await query(
      `UPDATE auth_sessions
       SET refresh_token_hash = $1,
           expires_at = $2,
           last_used_at = now(),
           ip_address = $3,
           user_agent = $4
       WHERE id = $5
       RETURNING id, user_id, refresh_token_hash, created_at, last_used_at, expires_at, revoked_at`,
      [refreshTokenHash, expiresAt, ipAddress || null, userAgent || null, sessionId],
    );
    return result.rows[0] || null;
  },

  revokeSession: async (sessionId) => {
    await query(
      "UPDATE auth_sessions SET revoked_at = now() WHERE id = $1",
      [sessionId],
    );
  },
};

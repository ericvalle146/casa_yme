import { env } from "../config/env.js";
import { userRepository } from "../repositories/userRepository.js";
import { sessionRepository } from "../repositories/sessionRepository.js";
import { comparePassword, createRefreshToken, hashPassword, hashToken } from "../utils/crypto.js";
import { HttpError } from "../utils/errors.js";
import { signAccessToken } from "../utils/jwt.js";

const normalizeEmail = (email) => email.trim().toLowerCase();

const toUserResponse = (user) => ({
  id: user.id,
  name: user.name,
  email: user.email,
  userType: user.user_type || 'VISITANTE',
  createdAt: user.created_at,
  lastLoginAt: user.last_login_at,
});

const addDays = (date, days) => {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next;
};

const createSessionTokens = async ({ user, ipAddress, userAgent }) => {
  const refreshToken = createRefreshToken();
  const refreshTokenHash = hashToken(refreshToken);
  const expiresAt = addDays(new Date(), env.refreshTokenTtlDays);

  await sessionRepository.createSession({
    userId: user.id,
    refreshTokenHash,
    expiresAt,
    ipAddress,
    userAgent,
  });

  const accessToken = signAccessToken({
    sub: user.id,
    email: user.email,
    userType: user.user_type || 'VISITANTE',
  });

  return {
    accessToken,
    refreshToken,
    expiresIn: env.accessTokenTtlMinutes * 60,
  };
};

export const authService = {
  register: async ({ name, email, password, ipAddress, userAgent }) => {
    const normalizedEmail = normalizeEmail(email);
    const existing = await userRepository.findByEmail(normalizedEmail);

    if (existing) {
      throw new HttpError(409, "E-mail ja cadastrado.");
    }

    const passwordHash = await hashPassword(password);
    const user = await userRepository.createUser({
      name: name.trim(),
      email: normalizedEmail,
      passwordHash,
    });

    const lastLoginAt = await userRepository.updateLastLogin(user.id);
    const hydratedUser = { ...user, last_login_at: lastLoginAt };

    const tokens = await createSessionTokens({ user: hydratedUser, ipAddress, userAgent });

    return {
      user: toUserResponse(hydratedUser),
      ...tokens,
    };
  },

  login: async ({ email, password, ipAddress, userAgent }) => {
    const normalizedEmail = normalizeEmail(email);
    const user = await userRepository.findByEmail(normalizedEmail);

    if (!user) {
      throw new HttpError(401, "Credenciais invalidas.");
    }

    const isValid = await comparePassword(password, user.password_hash);
    if (!isValid) {
      throw new HttpError(401, "Credenciais invalidas.");
    }

    const lastLoginAt = await userRepository.updateLastLogin(user.id);
    const hydratedUser = { ...user, last_login_at: lastLoginAt };

    const tokens = await createSessionTokens({ user: hydratedUser, ipAddress, userAgent });

    return {
      user: toUserResponse(hydratedUser),
      ...tokens,
    };
  },

  refresh: async ({ refreshToken, ipAddress, userAgent }) => {
    const refreshTokenHash = hashToken(refreshToken);
    const session = await sessionRepository.findByRefreshTokenHash(refreshTokenHash);

    if (!session) {
      throw new HttpError(401, "Sessao invalida.");
    }

    if (session.revoked_at) {
      throw new HttpError(401, "Sessao revogada.");
    }

    if (new Date(session.expires_at) < new Date()) {
      throw new HttpError(401, "Sessao expirada.");
    }

    const user = await userRepository.findById(session.user_id);
    if (!user) {
      throw new HttpError(401, "Usuario nao encontrado para esta sessao.");
    }

    const newRefreshToken = createRefreshToken();
    const newRefreshTokenHash = hashToken(newRefreshToken);
    const newExpiresAt = addDays(new Date(), env.refreshTokenTtlDays);

    await sessionRepository.rotateSession({
      sessionId: session.id,
      refreshTokenHash: newRefreshTokenHash,
      expiresAt: newExpiresAt,
      ipAddress,
      userAgent,
    });

    const accessToken = signAccessToken({
      sub: user.id,
      email: user.email,
      userType: user.user_type || 'VISITANTE',
    });

    return {
      user: toUserResponse(user),
      accessToken,
      refreshToken: newRefreshToken,
      expiresIn: env.accessTokenTtlMinutes * 60,
    };
  },

  logout: async ({ refreshToken }) => {
    const refreshTokenHash = hashToken(refreshToken);
    const session = await sessionRepository.findByRefreshTokenHash(refreshTokenHash);

    if (!session) {
      return;
    }

    if (!session.revoked_at) {
      await sessionRepository.revokeSession(session.id);
    }
  },

  me: async ({ userId }) => {
    const user = await userRepository.findById(userId);
    if (!user) {
      throw new HttpError(404, "Usuario nao encontrado.");
    }
    return toUserResponse(user);
  },
};

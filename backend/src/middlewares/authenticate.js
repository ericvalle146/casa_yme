import { verifyAccessToken } from "../utils/jwt.js";
import { HttpError } from "../utils/errors.js";

export const authenticate = (req, _res, next) => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    return next(new HttpError(401, "Token de acesso ausente."));
  }

  const token = header.replace("Bearer ", "").trim();
  if (!token) {
    return next(new HttpError(401, "Token de acesso invalido."));
  }

  try {
    const payload = verifyAccessToken(token);
    if (!payload || typeof payload !== "object" || !payload.sub) {
      throw new HttpError(401, "Token de acesso invalido.");
    }
    req.user = {
      id: payload.sub,
      email: payload.email,
    };
    return next();
  } catch (error) {
    return next(new HttpError(401, "Token de acesso invalido."));
  }
};

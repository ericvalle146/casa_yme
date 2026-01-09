import { authService } from "../services/authService.js";
import { HttpError } from "../utils/errors.js";

const isValidEmail = (email) => /\S+@\S+\.\S+/.test(email);

const extractMeta = (req) => ({
  ipAddress: req.ip,
  userAgent: req.get("user-agent") || "",
});

export const authController = {
  register: async (req, res) => {
    const { name, email, password } = req.body || {};

    if (!name || !email || !password) {
      throw new HttpError(400, "Nome, e-mail e senha sao obrigatorios.");
    }

    if (!isValidEmail(email)) {
      throw new HttpError(400, "E-mail invalido.");
    }

    if (password.length < 8) {
      throw new HttpError(400, "A senha deve ter pelo menos 8 caracteres.");
    }

    const result = await authService.register({
      name,
      email,
      password,
      ...extractMeta(req),
    });

    res.status(201).json(result);
  },

  login: async (req, res) => {
    const { email, password } = req.body || {};

    if (!email || !password) {
      throw new HttpError(400, "E-mail e senha sao obrigatorios.");
    }

    if (!isValidEmail(email)) {
      throw new HttpError(400, "E-mail invalido.");
    }

    const result = await authService.login({
      email,
      password,
      ...extractMeta(req),
    });

    res.status(200).json(result);
  },

  refresh: async (req, res) => {
    const { refreshToken } = req.body || {};

    if (!refreshToken) {
      throw new HttpError(400, "Refresh token obrigatorio.");
    }

    const result = await authService.refresh({
      refreshToken,
      ...extractMeta(req),
    });

    res.status(200).json(result);
  },

  logout: async (req, res) => {
    const { refreshToken } = req.body || {};

    if (!refreshToken) {
      throw new HttpError(400, "Refresh token obrigatorio.");
    }

    await authService.logout({ refreshToken });

    res.status(200).json({ message: "Sessao encerrada." });
  },

  me: async (req, res) => {
    const result = await authService.me({ userId: req.user.id });
    res.status(200).json(result);
  },
};

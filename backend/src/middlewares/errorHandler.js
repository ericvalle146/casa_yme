import { logger } from "../config/logger.js";
import { HttpError } from "../utils/errors.js";

export const errorHandler = (err, _req, res, _next) => {
  if (err instanceof HttpError) {
    if (err.details) {
      logger.warn({ err: err.details }, err.message);
    }
    return res.status(err.status).json({ error: err.message });
  }

  if (err?.name === "MulterError") {
    if (err.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({ error: "Arquivo muito grande." });
    }
    return res.status(400).json({ error: "Erro ao enviar arquivo." });
  }

  if (err?.message?.includes("Arquivo invalido")) {
    return res.status(400).json({ error: "Arquivo invalido. Somente imagens sao permitidas." });
  }

  logger.error({ err }, "Erro inesperado");
  return res.status(500).json({ error: "Erro interno ao processar solicitacao." });
};

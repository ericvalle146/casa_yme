import fetch from "node-fetch";
import { env } from "../config/env.js";
import { logger } from "../config/logger.js";
import { HttpError } from "../utils/errors.js";

export const contactController = async (req, res) => {
  const { name, email, phone, message } = req.body || {};

  if (!name || !email || !phone || !message) {
    throw new HttpError(400, "Todos os campos sao obrigatorios.");
  }

  if (!env.n8nWebhookUrl) {
    logger.error("N8N_WEBHOOK_URL nao configurado");
    throw new HttpError(500, "Webhook nao configurado.");
  }

  const response = await fetch(env.n8nWebhookUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      name,
      email,
      phone,
      message,
      submittedAt: new Date().toISOString(),
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    logger.error(
      {
        status: response.status,
        body: text,
      },
      "Erro ao chamar webhook",
    );
    throw new HttpError(502, "Falha ao enviar dados para o webhook.");
  }

  logger.info({ name, email }, "Lead enviado com sucesso");
  res.status(200).json({ message: "Lead enviado com sucesso." });
};

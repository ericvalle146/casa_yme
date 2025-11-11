import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import fetch from "node-fetch";
import pino from "pino";

dotenv.config();

// Configurar logger
// Em produção (Docker), usa pino padrão (logs JSON)
// Em desenvolvimento, pino-pretty é usado via NODE_ENV
const logger = pino({
  ...(process.env.NODE_ENV !== "production" && {
    transport: {
      target: "pino-pretty",
      options: {
        colorize: true,
        translateTime: "SYS:standard",
      },
    },
  }),
});

const app = express();

const allowedOrigins = process.env.CORS_ORIGINS
  ? process.env.CORS_ORIGINS.split(",").map((origin) => origin.trim())
  : ["http://localhost:5173"];

app.use(
  cors({
    origin: allowedOrigins,
  }),
);
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

app.post("/api/contact", async (req, res) => {
  const { name, email, phone, message } = req.body || {};

  if (!name || !email || !phone || !message) {
    return res.status(400).json({
      error: "Todos os campos são obrigatórios.",
    });
  }

  const webhookUrl = process.env.N8N_WEBHOOK_URL;
  if (!webhookUrl) {
    logger.error("N8N_WEBHOOK_URL não configurado");
    return res.status(500).json({ error: "Webhook não configurado." });
  }

  try {
    const response = await fetch(webhookUrl, {
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
      return res
        .status(502)
        .json({ error: "Falha ao enviar dados para o webhook." });
    }

    logger.info({ name, email }, "Lead enviado com sucesso");
    return res.status(200).json({ message: "Lead enviado com sucesso." });
  } catch (error) {
    logger.error({ err: error }, "Erro inesperado ao chamar webhook");
    return res.status(500).json({ error: "Erro interno ao processar pedido." });
  }
});

const port = Number(process.env.PORT) || 4000;
app.listen(port, () => {
  logger.info(`Servidor ouvindo na porta ${port}`);
});


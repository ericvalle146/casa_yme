import dotenv from "dotenv";

dotenv.config();

const toNumber = (value, fallback) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const listFromEnv = (value, fallback) => {
  if (!value) return fallback;
  return value.split(",").map((origin) => origin.trim()).filter(Boolean);
};

export const env = {
  nodeEnv: process.env.NODE_ENV || "development",
  port: toNumber(process.env.PORT, 4000),
  corsOrigins: listFromEnv(process.env.CORS_ORIGINS, ["http://localhost:5173"]),
  n8nWebhookUrl: process.env.N8N_WEBHOOK_URL || "",
  databaseUrl: process.env.DATABASE_URL || "",
  db: {
    host: process.env.DB_HOST || "",
    port: toNumber(process.env.DB_PORT, 5432),
    user: process.env.DB_USER || "",
    password: process.env.DB_PASSWORD || "",
    name: process.env.DB_NAME || "",
  },
  accessTokenSecret: process.env.ACCESS_TOKEN_SECRET || "",
  accessTokenTtlMinutes: toNumber(process.env.ACCESS_TOKEN_TTL_MINUTES, 15),
  refreshTokenTtlDays: toNumber(process.env.REFRESH_TOKEN_TTL_DAYS, 7),
  passwordSaltRounds: toNumber(process.env.PASSWORD_SALT_ROUNDS, 12),
};

export const validateEnv = () => {
  const missing = [];

  if (!process.env.ACCESS_TOKEN_SECRET) {
    missing.push("ACCESS_TOKEN_SECRET");
  }

  const hasDatabaseUrl = Boolean(process.env.DATABASE_URL);
  const hasDbParts = Boolean(process.env.DB_HOST && process.env.DB_USER && process.env.DB_NAME);

  if (!hasDatabaseUrl && !hasDbParts) {
    missing.push("DB_HOST/DB_USER/DB_NAME ou DATABASE_URL");
  }

  if (missing.length) {
    throw new Error(`Variaveis obrigatorias ausentes: ${missing.join(", ")}`);
  }
};

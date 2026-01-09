import pg from "pg";
import { env } from "../config/env.js";
import { logger } from "../config/logger.js";

const { Pool } = pg;

const baseConfig = {
  max: 10,
  idleTimeoutMillis: 30000,
};

const connectionConfig = env.databaseUrl
  ? { connectionString: env.databaseUrl }
  : {
      host: env.db.host,
      port: env.db.port,
      user: env.db.user,
      password: env.db.password,
      database: env.db.name,
    };

export const pool = new Pool({
  ...baseConfig,
  ...connectionConfig,
});

pool.on("error", (err) => {
  logger.error({ err }, "Erro inesperado no pool do Postgres");
});

export const query = (text, params) => pool.query(text, params);

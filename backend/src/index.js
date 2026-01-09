import { createApp } from "./app.js";
import { env, validateEnv } from "./config/env.js";
import { logger } from "./config/logger.js";

try {
  validateEnv();
} catch (error) {
  logger.error({ err: error }, "Falha ao carregar variaveis de ambiente");
  process.exit(1);
}

const app = createApp();

app.listen(env.port, () => {
  logger.info(`Servidor ouvindo na porta ${env.port}`);
});

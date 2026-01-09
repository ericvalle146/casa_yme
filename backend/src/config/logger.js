import pino from "pino";
import { env } from "./env.js";

export const logger = pino({
  ...(env.nodeEnv !== "production" && {
    transport: {
      target: "pino-pretty",
      options: {
        colorize: true,
        translateTime: "SYS:standard",
      },
    },
  }),
});

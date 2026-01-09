import express from "express";
import cors from "cors";
import { env } from "./config/env.js";
import { uploadDir } from "./config/paths.js";
import { errorHandler } from "./middlewares/errorHandler.js";
import authRoutes from "./routes/authRoutes.js";
import contactRoutes from "./routes/contactRoutes.js";
import healthRoutes from "./routes/healthRoutes.js";
import propertyRoutes from "./routes/propertyRoutes.js";

export const createApp = () => {
  const app = express();

  app.use(
    cors({
      origin: env.corsOrigins,
    }),
  );
  app.use(express.json());
  app.use("/uploads", express.static(uploadDir));

  app.use("/health", healthRoutes);
  app.use("/api/contact", contactRoutes);
  app.use("/api/auth", authRoutes);
  app.use("/api/properties", propertyRoutes);

  app.use(errorHandler);

  return app;
};

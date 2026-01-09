import fs from "fs";
import path from "path";
import { uploadDir } from "../config/paths.js";
import { logger } from "../config/logger.js";

export const ensureUploadDir = () => {
  if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
  }
};

export const removeUploadFile = (storageKey) => {
  if (!storageKey) return;
  const filePath = path.join(uploadDir, storageKey);
  if (!fs.existsSync(filePath)) return;
  try {
    fs.unlinkSync(filePath);
  } catch (error) {
    logger.warn({ err: error, storageKey }, "Falha ao remover arquivo de upload");
  }
};

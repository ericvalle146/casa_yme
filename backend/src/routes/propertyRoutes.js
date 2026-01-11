import { Router } from "express";
import multer from "multer";
import path from "path";
import crypto from "crypto";
import { propertyController } from "../controllers/propertyController.js";
import { asyncHandler } from "../middlewares/asyncHandler.js";
import { authenticate } from "../middlewares/authenticate.js";
import { requireRole } from "../middlewares/roleGuard.js";
import { uploadDir } from "../config/paths.js";
import { ensureUploadDir } from "../utils/files.js";

ensureUploadDir();

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, uploadDir);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname || "");
    const name = crypto.randomUUID();
    cb(null, `${name}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (!file.mimetype.startsWith("image/")) {
      cb(new Error("Arquivo invalido. Somente imagens sao permitidas."));
      return;
    }
    cb(null, true);
  },
});

const router = Router();

router.get("/", asyncHandler(propertyController.list));
// Rotas específicas devem vir ANTES de rotas parametrizadas (/:id)
router.get("/search", asyncHandler(propertyController.search));
router.get("/autocomplete/locations", asyncHandler(propertyController.autocompleteLocations));
router.get("/:id/nearby", asyncHandler(propertyController.findNearby));
router.get("/:id", asyncHandler(propertyController.getById));

// Rotas protegidas: Apenas CORRETOR e ADMIN podem criar/editar/deletar imóveis
router.post(
  "/",
  authenticate,
  requireRole('CORRETOR', 'ADMIN'),
  upload.array("mediaFiles", 12),
  asyncHandler(propertyController.create)
);
router.put(
  "/:id",
  authenticate,
  requireRole('CORRETOR', 'ADMIN'),
  upload.array("mediaFiles", 12),
  asyncHandler(propertyController.update)
);
router.delete(
  "/:id",
  authenticate,
  requireRole('CORRETOR', 'ADMIN'),
  asyncHandler(propertyController.remove)
);

export default router;

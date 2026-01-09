import { Router } from "express";
import { contactController } from "../controllers/contactController.js";
import { asyncHandler } from "../middlewares/asyncHandler.js";

const router = Router();

router.post("/", asyncHandler(contactController));

export default router;

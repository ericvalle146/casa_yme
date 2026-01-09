import bcrypt from "bcryptjs";
import crypto from "crypto";
import { env } from "../config/env.js";

export const hashPassword = async (password) => bcrypt.hash(password, env.passwordSaltRounds);

export const comparePassword = async (password, hash) => bcrypt.compare(password, hash);

export const createRefreshToken = () => crypto.randomBytes(64).toString("hex");

export const hashToken = (token) => crypto.createHash("sha256").update(token).digest("hex");

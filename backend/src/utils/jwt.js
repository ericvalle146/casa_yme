import jwt from "jsonwebtoken";
import { env } from "../config/env.js";

export const signAccessToken = (payload) =>
  jwt.sign(payload, env.accessTokenSecret, {
    expiresIn: `${env.accessTokenTtlMinutes}m`,
  });

export const verifyAccessToken = (token) => jwt.verify(token, env.accessTokenSecret);

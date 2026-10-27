'use strict';

const { z } = require('zod');

/** Validates registration credentials. */
const registerSchema = z.object({
  email: z.string().trim().toLowerCase().email(),
  password: z.string().min(12).max(128),
});

/** Validates login credentials. */
const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email(),
  password: z.string().min(1).max(128),
});

/** Validates an opaque refresh token. */
const refreshSchema = z.object({
  refreshToken: z.string().min(20).max(200),
});

module.exports = { registerSchema, loginSchema, refreshSchema };

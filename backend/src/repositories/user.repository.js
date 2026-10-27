'use strict';

const { prisma } = require('./task.repository');

/**
 * Finds a user by normalized email address.
 *
 * @param {string} email - Lower-cased email address.
 * @returns {Promise<import('@prisma/client').User|null>} Matching user or null.
 */
function findByEmail(email) {
  return prisma.user.findUnique({ where: { email } });
}

/**
 * Creates a user with an already-hashed password.
 *
 * @param {{email: string, passwordHash: string}} data - User fields.
 * @returns {Promise<import('@prisma/client').User>} Created user.
 */
function create(data) {
  return prisma.user.create({ data });
}

module.exports = { findByEmail, create };

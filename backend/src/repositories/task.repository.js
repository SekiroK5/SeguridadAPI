'use strict';

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * Lists only one user's tasks with bounded pagination.
 *
 * @param {string} ownerId - Authenticated user identifier.
 * @param {number} skip - Number of records to skip.
 * @param {number} take - Maximum number of records.
 * @returns {Promise<import('@prisma/client').Task[]>} Matching tasks.
 */
function listByOwner(ownerId, skip, take) {
  return prisma.task.findMany({
    where: { ownerId },
    orderBy: { createdAt: 'desc' },
    skip,
    take,
  });
}

/**
 * Finds a task only when it belongs to the given user.
 *
 * @param {string} ownerId - Authenticated user identifier.
 * @param {string} taskId - Task identifier from the route.
 * @returns {Promise<import('@prisma/client').Task|null>} Owned task or null.
 */
function findOwned(ownerId, taskId) {
  return prisma.task.findFirst({ where: { id: taskId, ownerId } });
}

/**
 * Creates a task for one user.
 *
 * @param {string} ownerId - Authenticated user identifier.
 * @param {{title: string, description?: string}} data - Validated task data.
 * @returns {Promise<import('@prisma/client').Task>} Created task.
 */
function create(ownerId, data) {
  return prisma.task.create({ data: { ...data, ownerId } });
}

/**
 * Updates a task only when it belongs to the given user.
 *
 * @param {string} ownerId - Authenticated user identifier.
 * @param {string} taskId - Task identifier.
 * @param {object} data - Validated fields to update.
 * @returns {Promise<import('@prisma/client').Task|null>} Updated task or null.
 */
async function updateOwned(ownerId, taskId, data) {
  const result = await prisma.task.updateMany({
    where: { id: taskId, ownerId },
    data,
  });
  if (result.count === 0) return null;
  return findOwned(ownerId, taskId);
}

/**
 * Deletes a task only when it belongs to the given user.
 *
 * @param {string} ownerId - Authenticated user identifier.
 * @param {string} taskId - Task identifier.
 * @returns {Promise<boolean>} Whether a matching task was deleted.
 */
async function deleteOwned(ownerId, taskId) {
  const result = await prisma.task.deleteMany({
    where: { id: taskId, ownerId },
  });
  return result.count === 1;
}

module.exports = { prisma, listByOwner, findOwned, create, updateOwned, deleteOwned };

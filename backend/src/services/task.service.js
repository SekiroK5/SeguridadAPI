'use strict';

const repository = require('../repositories/task.repository');

/**
 * Creates task business operations with ownership enforcement.
 */
class TaskService {
  /**
   * Lists the user's tasks with pagination.
   *
   * @param {string} userId - Authenticated user ID.
   * @param {{page: number, limit: number}} pagination - Validated page options.
   * @returns {Promise<object>} Paginated task result.
   */
  async list(userId, { page, limit }) {
    const items = await repository.listByOwner(userId, (page - 1) * limit, limit);
    return { items, page, limit };
  }

  /**
   * Creates a task owned by the authenticated user.
   *
   * @param {string} userId - Authenticated user ID.
   * @param {object} data - Validated create payload.
   * @returns {Promise<object>} Created task.
   */
  create(userId, data) {
    return repository.create(userId, data);
  }

  /**
   * Updates one task owned by the authenticated user.
   *
   * @param {string} userId - Authenticated user ID.
   * @param {string} taskId - Task ID.
   * @param {object} data - Validated update payload.
   * @returns {Promise<object>} Updated task.
   * @throws {Error} When the owned task does not exist.
   */
  async update(userId, taskId, data) {
    const updated = await repository.updateOwned(userId, taskId, data);
    if (!updated) {
      const error = new Error('Task not found.');
      error.status = 404;
      error.code = 'NOT_FOUND';
      throw error;
    }
    return updated;
  }

  /**
   * Deletes one task owned by the authenticated user.
   *
   * @param {string} userId - Authenticated user ID.
   * @param {string} taskId - Task ID.
   * @returns {Promise<void>} Resolves when deleted.
   * @throws {Error} When the owned task does not exist.
   */
  async delete(userId, taskId) {
    const deleted = await repository.deleteOwned(userId, taskId);
    if (!deleted) {
      const error = new Error('Task not found.');
      error.status = 404;
      error.code = 'NOT_FOUND';
      throw error;
    }
  }
}

module.exports = { TaskService };

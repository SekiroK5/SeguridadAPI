'use strict';

const express = require('express');
const { requireAuth } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validate.middleware');
const {
  createTaskSchema,
  updateTaskSchema,
  listTasksSchema,
  taskIdParamsSchema,
} = require('../schemas/task.schema');
const controller = require('../controllers/task.controller');

const router = express.Router();

/**
 * Wraps an async route handler and forwards failures to Express error handling.
 *
 * @param {Function} handler - Async Express route handler.
 * @returns {import('express').RequestHandler} Wrapped handler.
 */
const asyncRoute = (handler) => (req, res, next) =>
  Promise.resolve(handler(req, res, next)).catch(next);

router.use(requireAuth);

router.get('/', validate(listTasksSchema, 'query'), asyncRoute(controller.list));

router.post('/', validate(createTaskSchema, 'body'), asyncRoute(controller.create));

router.patch(
  '/:taskId',
  validate(taskIdParamsSchema, 'params'),
  validate(updateTaskSchema, 'body'),
  asyncRoute(controller.update),
);

router.delete('/:taskId', validate(taskIdParamsSchema, 'params'), asyncRoute(controller.remove));

module.exports = router;

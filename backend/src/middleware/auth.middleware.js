'use strict';

const jwt = require('jsonwebtoken');
const { env } = require('../config');

/**
 * Verifies a short-lived access token and sets req.user.
 *
 * @param {import('express').Request} req - Express request.
 * @param {import('express').Response} res - Express response.
 * @param {import('express').NextFunction} next - Express continuation.
 * @returns {void}
 */
function requireAuth(req, res, next) {
  const header = req.get('authorization') || '';
  const match = /^Bearer ([^\s]+)$/.exec(header);

  if (!match) {
    return res.status(401).json({
      error: { code: 'UNAUTHENTICATED', message: 'Sign in to continue.' },
    });
  }

  try {
    const payload = jwt.verify(match[1], env.JWT_ACCESS_SECRET, {
      algorithms: ['HS256'],
      issuer: 'task-manager-api',
      audience: 'task-manager-client',
    });

    if (typeof payload === 'string' || payload.type !== 'access' || !payload.sub) {
      throw new Error('Invalid token.');
    }

    req.user = { id: payload.sub };
    next();
  } catch {
    res.status(401).json({
      error: { code: 'UNAUTHENTICATED', message: 'Sign in again to continue.' },
    });
  }
}

module.exports = { requireAuth };

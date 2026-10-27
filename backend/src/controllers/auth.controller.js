'use strict';

const authService = require('../services/auth.service');

/** Registers an account and returns its initial token pair. */
async function register(req, res) {
  res.status(201).json(await authService.register(req.body));
}

/** Authenticates an account and returns its token pair. */
async function login(req, res) {
  res.json(await authService.login(req.body));
}

/** Rotates a refresh token and returns the replacement pair. */
async function refresh(req, res) {
  res.json(await authService.refresh(req.body.refreshToken));
}

/** Revokes the refresh-token family supplied by the client. */
async function logout(req, res) {
  await authService.logout(req.body.refreshToken);
  res.status(204).end();
}

/** Revokes all refresh tokens belonging to the authenticated user. */
async function logoutAll(req, res) {
  await authService.logoutAll(req.user.id);
  res.status(204).end();
}

module.exports = { register, login, refresh, logout, logoutAll };

'use strict';

const request = require('supertest');
const { app } = require('../src/app');

describe('health endpoint', () => {
  test('returns a healthy status', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('ok');
  });

  test('does not advertise the framework', async () => {
    const response = await request(app).get('/health');
    expect(response.headers['x-powered-by']).toBeUndefined();
  });
});

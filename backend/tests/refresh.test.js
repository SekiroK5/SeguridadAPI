'use strict';

const request = require('supertest');
const { app } = require('../src/app');
const { prisma } = require('../src/repositories/task.repository');

afterAll(async () => {
  await prisma.user.deleteMany({ where: { email: { startsWith: 'refresh-' } } });
  await prisma.$disconnect();
});

describe('refresh-token lifecycle', () => {
  const password = 'a-long-test-password';
  let counter = 0;

  async function register() {
    counter += 1;
    const email = `refresh-${Date.now()}-${counter}@example.test`;
    const response = await request(app).post('/api/v1/auth/register')
      .send({ email, password });
    expect(response.status).toBe(201);
    return { email, ...response.body };
  }

  test('rotation returns a different refresh token', async () => {
    const initial = await register();
    const response = await request(app).post('/api/v1/auth/refresh')
      .send({ refreshToken: initial.refreshToken });
    expect(response.status).toBe(200);
    expect(response.body.refreshToken).not.toBe(initial.refreshToken);
  });

  test('reuse of an old token revokes the newer token family token', async () => {
    const initial = await register();
    const rotated = await request(app).post('/api/v1/auth/refresh')
      .send({ refreshToken: initial.refreshToken });
    expect(rotated.status).toBe(200);

    const reuse = await request(app).post('/api/v1/auth/refresh')
      .send({ refreshToken: initial.refreshToken });
    expect(reuse.status).toBe(401);

    const newer = await request(app).post('/api/v1/auth/refresh')
      .send({ refreshToken: rotated.body.refreshToken });
    expect(newer.status).toBe(401);
  });

  test('logout makes the refresh token unusable', async () => {
    const tokens = await register();
    const logout = await request(app).post('/api/v1/auth/logout')
      .send({ refreshToken: tokens.refreshToken });
    expect(logout.status).toBe(204);

    const refresh = await request(app).post('/api/v1/auth/refresh')
      .send({ refreshToken: tokens.refreshToken });
    expect(refresh.status).toBe(401);
  });

  test('logout-all revokes every session of the user', async () => {
    const first = await register();
    const login = await request(app).post('/api/v1/auth/login')
      .send({ email: first.email, password });
    expect(login.status).toBe(200);

    const all = await request(app).post('/api/v1/auth/logout-all')
      .set('Authorization', `Bearer ${first.accessToken}`);
    expect(all.status).toBe(204);

    for (const token of [first.refreshToken, login.body.refreshToken]) {
      const refresh = await request(app).post('/api/v1/auth/refresh').send({ refreshToken: token });
      expect(refresh.status).toBe(401);
    }
  });
});

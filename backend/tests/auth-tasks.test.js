'use strict';

const request = require('supertest');
const { app } = require('../src/app');
const { prisma } = require('../src/repositories/task.repository');

const password = 'a-long-test-password';
let counter = 0;

/** Registers a fresh test account and returns its email and tokens. */
async function newUser() {
  counter += 1;
  const email = `authz-${Date.now()}-${counter}@example.test`;
  const response = await request(app).post('/api/v1/auth/register').send({ email, password });
  expect(response.status).toBe(201);
  return { email, ...response.body };
}

afterAll(async () => {
  await prisma.user.deleteMany({ where: { email: { startsWith: 'authz-' } } });
  await prisma.$disconnect();
});

describe('authentication', () => {
  test('registration rejects short passwords and invalid emails', async () => {
    const response = await request(app).post('/api/v1/auth/register')
      .send({ email: 'not-an-email', password: 'short' });
    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('VALIDATION_ERROR');
  });

  test('duplicate registration returns 409', async () => {
    const user = await newUser();
    const response = await request(app).post('/api/v1/auth/register')
      .send({ email: user.email, password });
    expect(response.status).toBe(409);
  });

  test('wrong password and unknown email return the same generic 401', async () => {
    const user = await newUser();
    const wrong = await request(app).post('/api/v1/auth/login')
      .send({ email: user.email, password: 'definitely-wrong-password' });
    const unknown = await request(app).post('/api/v1/auth/login')
      .send({ email: 'nobody-here@example.test', password: 'definitely-wrong-password' });
    expect(wrong.status).toBe(401);
    expect(unknown.status).toBe(401);
    expect(wrong.body).toEqual(unknown.body);
  });

  test('protected routes require a bearer token', async () => {
    const missing = await request(app).get('/api/v1/tasks');
    const forged = await request(app).get('/api/v1/tasks').set('Authorization', 'Bearer forged.token.value');
    expect(missing.status).toBe(401);
    expect(forged.status).toBe(401);
  });
});

describe('tasks', () => {
  test('CRUD on own tasks and pagination bounds', async () => {
    const user = await newUser();
    const auth = { Authorization: `Bearer ${user.accessToken}` };

    const created = await request(app).post('/api/v1/tasks').set(auth)
      .send({ title: 'Review API security', description: 'Check ownership and validation' });
    expect(created.status).toBe(201);
    const id = created.body.item.id;

    const list = await request(app).get('/api/v1/tasks?page=1&limit=20').set(auth);
    expect(list.status).toBe(200);
    expect(list.body.items).toHaveLength(1);

    const tooMany = await request(app).get('/api/v1/tasks?limit=1000').set(auth);
    expect(tooMany.status).toBe(400);

    const patched = await request(app).patch(`/api/v1/tasks/${id}`).set(auth).send({ completed: true });
    expect(patched.status).toBe(200);
    expect(patched.body.item.completed).toBe(true);

    const removed = await request(app).delete(`/api/v1/tasks/${id}`).set(auth);
    expect(removed.status).toBe(204);
  });

  test('ignores a client-supplied ownerId', async () => {
    const owner = await newUser();
    const other = await newUser();
    const otherId = (await prisma.user.findUnique({ where: { email: other.email } })).id;
    const created = await request(app).post('/api/v1/tasks')
      .set('Authorization', `Bearer ${owner.accessToken}`)
      .send({ title: 'Mine', ownerId: otherId });
    expect(created.status).toBe(201);
    expect(created.body.item.ownerId).not.toBe(otherId);
  });

  test('User A cannot read, update, or delete User B task (IDOR)', async () => {
    const a = await newUser();
    const b = await newUser();
    const created = await request(app).post('/api/v1/tasks')
      .set('Authorization', `Bearer ${b.accessToken}`).send({ title: 'B private task' });
    const id = created.body.item.id;
    const asA = { Authorization: `Bearer ${a.accessToken}` };

    const list = await request(app).get('/api/v1/tasks').set(asA);
    expect(list.body.items.find((task) => task.id === id)).toBeUndefined();

    const update = await request(app).patch(`/api/v1/tasks/${id}`).set(asA).send({ title: 'hacked' });
    expect(update.status).toBe(404);

    const remove = await request(app).delete(`/api/v1/tasks/${id}`).set(asA);
    expect(remove.status).toBe(404);
  });

  test('malformed ids receive a safe 400 without database details', async () => {
    const user = await newUser();
    const response = await request(app).delete("/api/v1/tasks/'%20OR%201=1--")
      .set('Authorization', `Bearer ${user.accessToken}`);
    expect(response.status).toBe(400);
    expect(JSON.stringify(response.body)).not.toMatch(/prisma|sql|stack/i);
  });
});

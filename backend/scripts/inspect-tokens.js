'use strict';

// Lists the most recent refresh-token rows without ever selecting tokenHash.
require('dotenv').config({ quiet: true });
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
  const rows = await prisma.refreshToken.findMany({
    select: { id: true, familyId: true, revokedAt: true, expiresAt: true, createdAt: true },
    orderBy: { createdAt: 'desc' },
    take: Number(process.argv[2] || 12),
  });
  console.table(rows.map((row) => ({
    id: row.id.slice(0, 12) + '…',
    familyId: row.familyId.slice(0, 8) + '…',
    revokedAt: row.revokedAt ? row.revokedAt.toISOString().slice(0, 19) : 'active',
    expiresAt: row.expiresAt.toISOString().slice(0, 10),
  })));
  const [users, tasks, tokens] = await Promise.all([
    prisma.user.count(), prisma.task.count(), prisma.refreshToken.count(),
  ]);
  console.log(`users=${users} tasks=${tasks} refreshTokens=${tokens}`);
}

main().finally(() => prisma.$disconnect());

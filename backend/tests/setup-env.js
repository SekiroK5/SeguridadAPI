'use strict';

// Loads local configuration for tests. Point DATABASE_URL at a local, disposable database only.
require('dotenv').config({ quiet: true });

process.env.NODE_ENV = 'test';

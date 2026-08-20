'use strict';

const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');

const USERS_FILE = path.join(__dirname, '..', 'data', 'users.json');

function loadUsers() {
  if (!fs.existsSync(USERS_FILE)) return [];
  try {
    return JSON.parse(fs.readFileSync(USERS_FILE, 'utf8')).users || [];
  } catch (_) {
    return [];
  }
}

function saveUsers(users) {
  fs.mkdirSync(path.dirname(USERS_FILE), { recursive: true });
  fs.writeFileSync(USERS_FILE, JSON.stringify({ users }, null, 2) + '\n', 'utf8');
}

/**
 * Admin utility: creates (or resets the password of) a single user.
 *
 *   node scripts/seed.js <username> <password>
 *
 * Only the admin/developer runs this. There is no self-service sign-up.
 */
async function main() {
  const [username, password] = process.argv.slice(2);
  if (!username || !password) {
    console.error('Usage: npm run seed -- <username> <password>');
    process.exit(1);
  }
  if (password.length < 6) {
    console.error('Password must be at least 6 characters.');
    process.exit(1);
  }

  const users = loadUsers();
  const existing = users.find((u) => u.username === username);
  const hash = await bcrypt.hash(password, 10);

  if (existing) {
    existing.passwordHash = hash;
  } else {
    users.push({ username, passwordHash: hash });
  }
  saveUsers(users);
  console.log(`Saved user "${username}" (${existing ? 'password updated' : 'created'}).`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
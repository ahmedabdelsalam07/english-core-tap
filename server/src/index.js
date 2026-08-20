'use strict';

const express = require('express');
const rateLimit = require('express-rate-limit');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const USERS_FILE = path.join(__dirname, '..', 'data', 'users.json');
const ADMIN_PAGE = path.join(__dirname, '..', 'admin', 'index.html');
const PORT = process.env.PORT || 8080;
// In production, set JWT_SECRET (e.g. via environment / secret manager).
const JWT_SECRET = process.env.JWT_SECRET || 'dev-only-secret-change-me';
const TOKEN_TTL = process.env.TOKEN_TTL || '30d';
// Admin dashboard password. If unset, the admin dashboard is disabled.
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || '';

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

function signToken(username) {
  return jwt.sign({ sub: username }, JWT_SECRET, { expiresIn: TOKEN_TTL });
}

function authRequired(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'missing_token' });
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.username = payload.sub;
    return next();
  } catch (_) {
    return res.status(401).json({ error: 'invalid_token' });
  }
}

const app = express();
app.use(cors());
app.use(express.json());

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'too_many_attempts' },
});

const adminLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'too_many_attempts' },
});

app.post('/api/auth/login', loginLimiter, async (req, res) => {
  const username = String(req.body?.username || '').trim();
  const password = String(req.body?.password || '');
  if (!username || !password) {
    return res.status(400).json({ error: 'missing_credentials' });
  }

  const user = loadUsers().find((u) => u.username === username);
  const ok = user ? await bcrypt.compare(password, user.passwordHash) : false;
  if (!ok) return res.status(401).json({ error: 'invalid_credentials' });

  return res.json({
    token: signToken(username),
    user: { username },
  });
});

app.get('/api/auth/me', authRequired, (req, res) => {
  res.json({ user: { username: req.username } });
});

app.post('/api/auth/logout', authRequired, (req, res) => {
  // Stateless JWT: nothing to revoke server-side. The client clears its
  // secure storage token. Endpoint exists for contract completeness.
  res.status(204).end();
});

// --- Admin dashboard (user management) ---------------------------------
// Only active when ADMIN_PASSWORD is set. The dashboard is a single
// self-contained HTML page served at /admin.

function adminEnabled(req, res, next) {
  if (!ADMIN_PASSWORD) {
    return res.status(503).json({
      error: 'admin_disabled',
      message: 'Set the ADMIN_PASSWORD environment variable to enable the dashboard.',
    });
  }
  return next();
}

function adminRequired(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'missing_token' });
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    if (payload.admin !== true) return res.status(403).json({ error: 'forbidden' });
    return next();
  } catch (_) {
    return res.status(401).json({ error: 'invalid_token' });
  }
}

app.get('/admin', (_req, res) => res.sendFile(ADMIN_PAGE));

app.post('/api/admin/login', adminLimiter, adminEnabled, (req, res) => {
  const password = String(req.body?.password || '');
  if (!ADMIN_PASSWORD || password !== ADMIN_PASSWORD) {
    return res.status(401).json({ error: 'invalid_admin_password' });
  }
  const token = jwt.sign({ admin: true }, JWT_SECRET, { expiresIn: '2h' });
  return res.json({ token });
});

app.get('/api/admin/users', adminEnabled, adminRequired, (_req, res) => {
  const users = loadUsers().map((u) => ({ username: u.username }));
  res.json({ users });
});

app.post('/api/admin/users', adminEnabled, adminRequired, async (req, res) => {
  const username = String(req.body?.username || '').trim();
  const password = String(req.body?.password || '');
  if (!username || !password) {
    return res.status(400).json({ error: 'missing_credentials' });
  }
  if (password.length < 6) {
    return res.status(400).json({ error: 'password_too_short' });
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
  res.json({ user: { username }, created: !existing });
});

app.delete('/api/admin/users/:username', adminEnabled, adminRequired, (req, res) => {
  const username = String(req.params.username || '');
  const users = loadUsers();
  const before = users.length;
  const kept = users.filter((u) => u.username !== username);
  if (kept.length === before) {
    return res.status(404).json({ error: 'user_not_found' });
  }
  saveUsers(kept);
  res.json({ deleted: username });
});

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.listen(PORT, () => {
  console.log(`English Core TaP server listening on :${PORT}`);
});
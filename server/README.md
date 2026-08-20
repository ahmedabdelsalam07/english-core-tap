# English Core TaP — Backend (reference)

Private authentication for the app. There is **no public registration**
by design: an admin creates users with the seed script.

## Setup

```sh
npm install
npm run seed -- <username> <password>   # creates/updates one user (bcrypt)
JWT_SECRET=<long-random-string> npm start
```

- Default port: `8080` (`PORT` to change).
- `JWT_SECRET` is required in production (dev falls back to a placeholder).
- Users live in `server/data/users.json` (git-ignored; hashes only).

## Admin dashboard (add / remove users from the browser)

The server ships a small built-in dashboard at `http://localhost:8080/admin`.

1. Start the server with a dashboard password:
   ```sh
   ADMIN_PASSWORD=<your-admin-password> JWT_SECRET=<long-random-string> npm start
   ```
2. Open `http://localhost:8080/admin`, log in with the admin password.
3. From there you can **create users, reset passwords, and delete users**.

> Without `ADMIN_PASSWORD` the dashboard endpoints are disabled (503).

## Endpoints

| Method | Path                | Auth        | Notes                                  |
| ------ | ------------------- | ----------- | -------------------------------------- |
| POST   | `/api/auth/login`   | —           | `{username,password}` → `{token,user}` |
| GET    | `/api/auth/me`      | Bearer      | → `{user:{username}}`                  |
| POST   | `/api/auth/logout`  | Bearer      | stateless; returns 204                 |
| GET    | `/admin`            | —           | admin dashboard page                   |
| POST   | `/api/admin/login`  | admin token | `{password}` → `{token}`               |
| GET    | `/api/admin/users`  | admin token | → `{users:[{username}]}`               |
| POST   | `/api/admin/users`  | admin token | `{username,password}` create/reset      |
| DELETE | `/api/admin/users/:username` | admin token | remove user                |
| GET    | `/health`           | —           | liveness                               |

Login is rate-limited (10 attempts / 15 min). Passwords are bcrypt-hashed
(`bcryptjs`, no native build step).

## Pointing the app at it

```sh
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

For a physical device use your machine's LAN IP instead of `localhost`.

## Production notes

- Terminate TLS at a reverse proxy (nginx/caddy) in front of Express.
- Keep `JWT_SECRET` in a secret manager; rotate periodically.
- For horizontal scaling, move users to a real database
  (the storage layer here is intentionally a single JSON file).
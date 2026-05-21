# Railway Deployment Guide — Neighborly Fleet Management
**Last updated:** 2026-05-21

---

## Architecture on Railway

```
Railway Project: neighborly-fleet
│
├── [Service] fleet-backend          ← Standalone NestJS API (THIS repo, /backend dir)
│   ├── Plugin: PostgreSQL           ← managed by Railway
│   └── Plugin: Redis                ← managed by Railway
│
└── [Service] fleet-frontend         ← Flutter web (THIS repo, /frontend dir)
```

Both services are deployed from this single repo (`neighborly-fleet-management`).
The backend is a **standalone NestJS application** — no changes to `neighborly-backend` are required.

---

## Step 1 — Create the Railway Project

1. Go to [railway.app](https://railway.app) → **New Project**
2. Select **Empty project**
3. Name it `neighborly-fleet`

---

## Step 2 — Add PostgreSQL

Inside the project:
1. Click **+ New** → **Database** → **PostgreSQL**
2. Railway provisions it and injects `DATABASE_URL` automatically

---

## Step 3 — Add Redis

1. Click **+ New** → **Database** → **Redis**
2. Railway provisions it and injects `REDIS_URL` automatically

---

## Step 4 — Deploy the Backend

1. Click **+ New** → **GitHub Repo**
2. Select the `neighborly-fleet-management` repository
3. Set **Root Directory** to `backend`
4. Railway picks up `backend/railway.toml` and uses `backend/Dockerfile`

### Configure backend environment variables

In the backend service → **Variables** tab:

```env
# ── App ──────────────────────────────────────────────────────
NODE_ENV=production
PORT=3000
APP_BASE_URL=https://<your-backend-railway-domain>

# ── Database (Railway injects DATABASE_URL automatically) ────
DATABASE_URL=${{Postgres.DATABASE_URL}}
DB_HOST=${{Postgres.PGHOST}}
DB_PORT=${{Postgres.PGPORT}}
DB_USERNAME=${{Postgres.PGUSER}}
DB_PASSWORD=${{Postgres.PGPASSWORD}}
DB_NAME=${{Postgres.PGDATABASE}}
SSL_MODE=true

# ── Redis ────────────────────────────────────────────────────
REDIS_URL=${{Redis.REDIS_URL}}

# ── Auth ─────────────────────────────────────────────────────
SECRET_KEY=<generate: openssl rand -hex 32>
REFRESH_SECRET_KEY=<generate: openssl rand -hex 32>
SALT_KEY=<generate: openssl rand -hex 16>
SALT_ROUNDS=12

# ── AWS SES (email) ──────────────────────────────────────────
AWS_ACCESS_KEY=<your key>
AWS_SECRET_KEY=<your secret>
AWS_REGION=us-east-1
AWS_SES_FROM_EMAIL=noreply@yourdomain.com
AWS_SES_REPLY_TO_EMAIL=support@yourdomain.com

# ── Google Maps ───────────────────────────────────────────────
GOOGLE_MAPS_API_KEY=<your key>

# ── Stripe ───────────────────────────────────────────────────
STRIPE_SECRET_KEY=sk_live_...
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_CONNECT_WEBHOOK_SECRET=whsec_...
STRIPE_CONNECT_CLIENT_ID=ca_...
STRIPE_PLATFORM_FEE_PERCENTAGE=2.9
STRIPE_PLATFORM_FEE_FIXED=30
STRIPE_REFRESH_URL=https://<backend-url>/stripe/connect/refresh
STRIPE_RETURN_URL=https://<backend-url>/stripe/connect/return

# ── Firebase (push notifications) ────────────────────────────
FIREBASE_PROJECT_ID=<your project>
FIREBASE_CLIENT_EMAIL=<service account email>
FIREBASE_PRIVATE_KEY=<paste key with literal \n characters>

# ── Fleet-specific ────────────────────────────────────────────
BGC_WEBHOOK_SECRET=<generate: openssl rand -hex 32>
CRON_JOBS_ENABLED=true
```

### Run migrations on first deploy

After the first deploy, open the Railway shell for the backend service:
```bash
npx typeorm-ts-node-commonjs migration:run -d src/config/typeorm.ts
```

Or build first and run:
```bash
npm run build && node dist/src/main &
npx typeorm migration:run -d dist/src/config/typeorm.js
```

---

## Step 5 — Deploy the Frontend

1. Click **+ New** → **GitHub Repo**
2. Select the `neighborly-fleet-management` repository
3. Leave **Root Directory** as `/` (the `railway.toml` at the repo root points to `frontend/Dockerfile`)

### Configure frontend environment variable

```env
BASE_URL=https://<your-backend-railway-domain>
```

---

## Step 6 — Configure Stripe Webhooks

In the [Stripe Dashboard](https://dashboard.stripe.com/webhooks):

1. Add endpoint: `https://<backend-url>/api/fleet/stripe/webhook`
   - Events: `account.updated`
   - Copy the signing secret → set as `STRIPE_CONNECT_WEBHOOK_SECRET` in Railway

2. Add endpoint: `https://<backend-url>/api/stripe/webhooks` (if you add standard payment webhooks later)
   - Events: `payment_intent.succeeded`, `payment_intent.payment_failed`
   - Copy the signing secret → set as `STRIPE_WEBHOOK_SECRET` in Railway

---

## Step 7 — Configure Firebase for Push Notifications

The `FIREBASE_PRIVATE_KEY` env var must have literal `\n` characters, not actual newlines:
```
-----BEGIN PRIVATE KEY-----\nMIIEvA...\n-----END PRIVATE KEY-----\n
```

---

## Deployment Checklist

- [ ] PostgreSQL plugin added to Railway project
- [ ] Redis plugin added to Railway project
- [ ] Backend service connected to this repo with Root Directory = `backend`
- [ ] All backend env vars set (especially `SECRET_KEY`, Stripe, Firebase, Google Maps)
- [ ] Database migrations run via Railway shell
- [ ] Frontend service connected to this repo with Root Directory = `/`
- [ ] `BASE_URL` set in frontend service variables
- [ ] Stripe webhook endpoints configured with correct signing secrets
- [ ] Backend health check passing: `GET <backend-url>/api/health`
- [ ] Frontend loads: `GET <frontend-url>/`

---

## Common Issues

| Issue | Fix |
|---|---|
| `JWT_SECRET` errors on startup | Set `SECRET_KEY` and `REFRESH_SECRET_KEY` in backend vars |
| Stripe webhook `400 Invalid signature` | Ensure `STRIPE_CONNECT_WEBHOOK_SECRET` matches the Stripe dashboard endpoint's secret |
| Push notifications not received | Confirm `FIREBASE_PRIVATE_KEY` has `\n` not real newlines |
| Database connection refused | Check `SSL_MODE=true` is set; Railway PostgreSQL requires SSL |
| Migrations fail | Run `npx typeorm migration:run` in the Railway shell after first deploy |
| Build fails: `Cannot find module` | Verify all imports resolve — run `npm run build` locally to check |

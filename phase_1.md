### Phase 1 — Environment secret setup and Docker image compilation for Next.js (standalone)

This guide explains how this Next.js app reads an environment key at runtime and how the Docker image is built to avoid baking secrets into the image.

### What the code does
- `src/app/api/secret-check/route.ts`: Server endpoint that returns whether a secret is present.
- `src/app/page.tsx`: Minimal page that renders dynamically at runtime and displays the current env and `NEXT_PUBLIC_SECRET`.
- `next.config.ts`: Uses `output: "standalone"` so Docker can copy only the minimal runtime.

### Env variables used
- `NEXT_PUBLIC_SECRET`: Demo secret surfaced to the client (public). Do not use `NEXT_PUBLIC_*` for real secrets.
  - Local defaults in `.env.local`
  - Production defaults in `.env.production`

Both env files are ignored by Docker and git via `.dockerignore` and `.gitignore`.

### Relevant files
- `src/app/api/secret-check/route.ts` — responds with `{ ok, env, secretPresent }` based on `process.env.NEXT_PUBLIC_SECRET`.
- `src/app/page.tsx` — uses `export const dynamic = "force-dynamic";` so `process.env` is read at runtime.
- `.env.local` — example local value for `NEXT_PUBLIC_SECRET`.
- `.env.production` — example production value for `NEXT_PUBLIC_SECRET`.
- `next.config.ts` — `output: "standalone"` for compact runtime.
- `.dockerignore` — excludes `.env*`, `.git`, `.next`, `node_modules`, etc. from the Docker build context.
- `Dockerfile` — multi-stage build and non-root runtime, copies only `.next/standalone`, `.next/static`, and `public`.
- `docker-compose.yml` — defines two services with identical production-style runtime:
  - `web` (prod) → host port `3001`
  - `dev` (internal use) → host port `3000`

### Build-time vs runtime env in Next.js
- Anything prefixed with `NEXT_PUBLIC_` is embedded in client bundles and exposed to the browser.
- This project sets `page.tsx` to be dynamic so `process.env` is read at request time inside the container.
- Secrets should be injected at runtime (container `environment:`) rather than from files, so they are not baked into the image.

### How to configure the secret
1) Local defaults (optional)
   - `.env.local`:
     - `NEXT_PUBLIC_SECRET=dev_secret_value_change_me`
   - `.env.production`:
     - `NEXT_PUBLIC_SECRET=prod_secret_value_change_me`

2) Docker image build inputs
   - `.dockerignore` contains `.env*` so env files are not sent to the Docker daemon or baked into the image.
   - `next.config.ts` has `output: "standalone"` to minimize the runtime copied in the final image.

3) Runtime injection (recommended)
   - `docker-compose.yml` sets `environment:` for both services:
     - Prod `web`: `NEXT_PUBLIC_SECRET=Production_Secret_Value` (mapped to host `3001`)
     - Dev `dev`: `NEXT_PUBLIC_SECRET=Development_Secret_Value` (mapped to host `3000`)
   - You can override at run time without editing files:
     ```bash
     NEXT_PUBLIC_SECRET=override_value docker compose up -d --build
     ```

### Build and run
- Using Compose (both services):
  ```bash
  docker compose up -d --build
  ```

- Or build the image directly:
  ```bash
  docker build -t nextjs-docker-sample:latest .
  # Prod
  docker run --rm -p 3001:3000 -e NODE_ENV=production -e NEXT_PUBLIC_SECRET=prod-secret nextjs-docker-sample:latest
  # Dev (internal use)
  docker run --rm -p 3000:3000 -e NODE_ENV=development -e NEXT_PUBLIC_SECRET=dev-secret nextjs-docker-sample:latest
  ```

### Verify
- API: `curl http://localhost:3001/api/secret-check` (prod) or `http://localhost:3000/api/secret-check` (dev)
  - Expect `{ ok: true, env: "production"|"development", secretPresent: true }` when `NEXT_PUBLIC_SECRET` is provided.
- Page: open `http://localhost:3001` (prod) or `http://localhost:3000` (dev) to see `NEXT_PUBLIC_SECRET` rendered.

### Security notes
- `NEXT_PUBLIC_*` values are public by design and will be visible in the browser and HTML. Use only for demo/config intended for clients.
- For real secrets, use server-only envs (no `NEXT_PUBLIC_` prefix) and never render them in client components.
- Keep `.env*` out of images and git (already handled by `.dockerignore` and `.gitignore`).



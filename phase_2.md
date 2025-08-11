### Phase 2 — CI/CD pipeline to build and push Docker images

This phase documents the GitHub Actions CI/CD that builds and pushes the app image to Docker Hub on branch pushes. It builds on Phase 1; see `phase_1.md` for how envs are handled at build/runtime to avoid duplication.

### Branch strategy
- **development**: pushes an image tagged `mcsgms/nextjs-docker-sample:development`
- **production**: pushes an image tagged `mcsgms/nextjs-docker-sample:production`

### Environments and secrets
- GitHub Environments: `Development`, `Production`
- Required environment-level secrets in each environment:
  - `DOCKERHUB_USERNAME`: Docker Hub username
  - `DOCKERHUB_TOKEN`: Docker Hub access token or password
  - `NEXT_PUBLIC_SECRET`: public demo secret for the app (Phase 1 explains why this is public)

### Workflow overview
- File: `.github/workflows/docker-publish.yml`
- Trigger: `push` to `development` or `production`
- Jobs (one per branch) perform:
  - Checkout
  - Set up Buildx
  - Login to Docker Hub using environment secrets
  - Build and push with tags per branch
  - Pass `NEXT_PUBLIC_SECRET` as a build-arg into the Next.js build

Key parts:

```yaml
# Branch-specific jobs and tags
jobs:
  build-and-push-production:
    if: github.ref_name == 'production'
    environment: { name: Production }
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      - uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: mcsgms/nextjs-docker-sample:production
          build-args: |
            NEXT_PUBLIC_SECRET=${{ secrets.NEXT_PUBLIC_SECRET }}

  build-and-push-development:
    if: github.ref_name == 'development'
    environment: { name: Development }
    steps: [ ... same as above, tag: development ... ]
```

Notes:
- Default GitHub runners are amd64, so pushed images are amd64. Multi-arch can be enabled later with `platforms: linux/amd64,linux/arm64` if needed.
- The `NEXT_PUBLIC_SECRET` is intentionally public in this demo. Do not treat it as a private secret in real systems.

### Dockerfile changes relevant to CI/CD
To support injecting the environment value during the build and to expose it at runtime (for this demo), the following were added:
- `ARG NEXT_PUBLIC_SECRET` and `ENV NEXT_PUBLIC_SECRET=$NEXT_PUBLIC_SECRET` in the **builder** stage so Next.js can access the value during `npm run build` when needed.
- The same in the **runner** stage to ensure the value is available at runtime (because the app reads `process.env` dynamically; see Phase 1).

Security note: In real scenarios, avoid `NEXT_PUBLIC_*` for sensitive values. Use server-only envs and avoid exposing them to the client.

### Compose changes (pulling published images)
The compose file was adjusted to pull images pushed by the workflow and to pin the platform to amd64 for local testing:
- `prod`: pulls `mcsgms/nextjs-docker-sample:production`, exposes host `3001`
- `dev`: pulls `mcsgms/nextjs-docker-sample:development`, exposes host `3000`

Run:

```bash
docker compose up -d prod   # production image on port 3001
docker compose up -d dev    # development image on port 3000
```

### What changed in commit 007e8bf6 (CI/CD-related files)
- `.github/workflows/docker-publish.yml`: Added a new workflow that:
  - Triggers on `development`/`production` pushes
  - Uses per-branch jobs mapped to `Development`/`Production` environments
  - Logs in to Docker Hub and pushes tags `:development` and `:production`
  - Passes `NEXT_PUBLIC_SECRET` via `build-args`
- `Dockerfile`:
  - Added `ARG NEXT_PUBLIC_SECRET` and `ENV NEXT_PUBLIC_SECRET` in both `builder` and `runner` stages
  - No other build behavior changed; still uses Next.js `standalone` output
- `docker-compose.yml`:
  - Commented out local build services
  - Added `prod` and `dev` services that pull from Docker Hub
  - Both specify `platform: linux/amd64` for consistent local runs on amd64
- `.gitignore`: Added `.idea/` (editor config) to ignore list

### Verify CI/CD
1) Push to `development` or `production` branches
2) Open GitHub Actions → workflow "Docker Build and Push"
3) Confirm a successful run published:
   - `mcsgms/nextjs-docker-sample:development` (or `:production`)
4) Pull and run with Compose as above and hit:
   - `curl http://localhost:3001/api/secret-check` (prod)
   - `curl http://localhost:3000/api/secret-check` (dev)

### Optional: multi-arch builds (amd64 + arm64)
If you need Apple Silicon users or arm64 nodes to pull native images, update the build step:

```yaml
      - uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          platforms: linux/amd64,linux/arm64
          tags: mcsgms/nextjs-docker-sample:production
          build-args: |
            NEXT_PUBLIC_SECRET=${{ secrets.NEXT_PUBLIC_SECRET }}
```



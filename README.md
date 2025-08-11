### Next.js Docker Sample

A minimal Next.js app packaged for Docker, with environment handling and CI/CD to Docker Hub.

### Phases
- [Phase 1 — Environment secret setup and Docker image compilation](./phase_1.md)
- [Phase 2 — CI/CD pipeline to build and push Docker images](./phase_2.md)

### Quick start
- **Local dev (Node)**
  ```bash
  npm install
  npm run dev
  # open http://localhost:3000
  ```
- **Run published Docker images (amd64)**
  ```bash
  docker compose up -d dev    # mcsgms/nextjs-docker-sample:development → http://localhost:3000
  docker compose up -d prod   # mcsgms/nextjs-docker-sample:production  → http://localhost:3001
  ```
- **Verify**
  ```bash
  curl http://localhost:3000/api/secret-check   # dev
  curl http://localhost:3001/api/secret-check   # prod
  ```

### CI/CD summary
- **Branches**: `development` → `mcsgms/nextjs-docker-sample:development`, `production` → `:production`
- **Workflow**: `.github/workflows/docker-publish.yml`
- **Secrets (per GitHub Environment)**: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `NEXT_PUBLIC_SECRET`

### Notes
- Images are built on GitHub-hosted runners (amd64). See `phase_2.md` for optional multi-arch.

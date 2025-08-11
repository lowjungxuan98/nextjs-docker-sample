# ---------- Builder ----------
FROM node:20-bookworm-slim AS builder
WORKDIR /app

# Install OS deps only if your project needs them (e.g. sharp)
# RUN apt-get update && apt-get install -y build-essential python3 && rm -rf /var/lib/apt/lists/*

# Install deps (uses npm; switch to pnpm/yarn if preferred)
COPY package.json package-lock.json* ./
RUN npm ci

# Copy the rest of the app source and build
COPY . .
# next.config.ts has: output: 'standalone'
RUN npm run build

# ---------- Runner ----------
FROM node:20-bookworm-slim AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000

# Create non-root user
RUN useradd -m nextjs
USER nextjs

# Copy only the standalone server, static files, and public assets
COPY --chown=nextjs:nextjs --from=builder /app/.next/standalone ./
COPY --chown=nextjs:nextjs --from=builder /app/.next/static ./.next/static
COPY --chown=nextjs:nextjs --from=builder /app/public ./public

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s CMD node -e "require('http').get('http://localhost:' + (process.env.PORT||3000), r=>{if(r.statusCode!==200)process.exit(1)}).on('error',()=>process.exit(1))"

# The standalone output includes server.js at the root we copied
CMD ["node", "server.js"]



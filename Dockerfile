# syntax=docker/dockerfile:1

# ==========================================================================
#  AgriPulse — Crop Price Tracker
#  Multi-stage build: a "deps" stage installs production dependencies,
#  then a lean "runtime" stage copies only what's needed to run the app.
#  Keeping the two apart means build tooling and npm cache never ship
#  in the final image.
# ==========================================================================

# ---- Stage 1: install production dependencies ----------------------------
# Pinned to Node 18 (the app requires v18+) on Alpine for a small footprint.
FROM node:22-alpine AS deps

# All backend code lives under /app/Backend, so install deps there.
WORKDIR /app/Backend

# Copy only the manifests first. Docker caches this layer and reruns
# `npm ci` only when these files change — not on every source edit.
COPY Backend/package.json Backend/package-lock.json ./

# `npm ci` gives a clean, reproducible install from the lockfile.
# `--omit=dev` skips devDependencies (e.g. nodemon) we don't need in prod.
RUN npm ci --omit=dev


# ---- Stage 2: runtime ----------------------------------------------------
FROM node:22-alpine AS runtime

# Production defaults; PORT can be overridden by docker-compose or `-e`.
ENV NODE_ENV=production \
    PORT=3000

WORKDIR /app

# Copy the application source. `server.js` serves ../Frontend statically,
# so both folders must keep their relative layout inside the image.
# `--chown=node` hands ownership to the built-in non-root `node` user so it
# can write the SQLite file (Backend/agripulse.db) at runtime.
COPY --chown=node:node Backend ./Backend
COPY --chown=node:node Frontend ./Frontend

# Bring in the production node_modules built in the deps stage. Copied last
# so it always wins over anything that may have tagged along with the source.
COPY --chown=node:node --from=deps /app/Backend/node_modules ./Backend/node_modules

# Create a writable data directory for the SQLite database. Owned by `node`
# so it stays writable once the compose named volume is mounted here.
RUN mkdir -p /app/data && chown node:node /app/data

# Drop root: run everything as the unprivileged `node` user for security.
USER node

# Run from the Backend folder so `node server.js` resolves cleanly.
WORKDIR /app/Backend

# The Express server listens on this port.
EXPOSE 3000

# Poll the real API endpoint so the container is only "healthy" once the
# database has initialised and requests are being served. Uses Node itself,
# so there's no need to add curl/wget to the image.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "const p=process.env.PORT||3000; require('http').get('http://localhost:'+p+'/api/prices', r => process.exit(r.statusCode < 400 ? 0 : 1)).on('error', () => process.exit(1))"

# Start the server directly (no shell wrapper) so it receives OS signals
# and shuts down cleanly.
CMD ["node", "server.js"]

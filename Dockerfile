# ---------- Base ----------
ARG BASE=node:20.18.0
FROM ${BASE} AS base
WORKDIR /app

# pnpm + outils utiles
RUN npm i -g pnpm && \
    apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/* || true

# Eviter les hooks husky pendant l'install
ENV HUSKY=0
# Limiter la RAM de Node pendant install/build
ENV NODE_OPTIONS="--max-old-space-size=2048"

# Dépendances (cache tant que package.json/pnpm-lock.yaml ne changent pas)
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prefer-offline

# Code
COPY . .

# ---------- Build ----------
FROM base AS build
WORKDIR /app
# ⚠️ Ne PAS passer --no-sourcemap à remix vite:build
RUN pnpm run build

# ---------- Runtime ----------
FROM ${BASE} AS runtime
WORKDIR /app

# pnpm pour exécuter les scripts
RUN npm i -g pnpm

# Copier l'app buildée (inclut ./build et node_modules nécessaires à wrangler)
COPY --from=build /app /app

# Variables (tu peux en définir d'autres dans Coolify)
ENV NODE_ENV=production
ENV WRANGLER_SEND_METRICS=false
ENV PORT=3000

# Port public
EXPOSE 3000

# Démarrage : équivalent de "dockerstart" mais sur 3000
# (wrangler pages dev ./build/client + bindings)
CMD sh -lc 'bindings=$(./bindings.sh) && wrangler pages dev ./build/client $bindings --ip 0.0.0.0 --port $PORT --no-show-interactive-dev-session'

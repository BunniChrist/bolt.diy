# ---------- Base ----------
ARG BASE=node:20.18.0
FROM ${BASE} AS base
WORKDIR /app

# pnpm + outils utiles
RUN npm i -g pnpm && \
    apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/* || true

# Eviter les hooks git/husky durant l'install
ENV HUSKY=0
# Limiter la RAM de Node pendant install/build (2 Go)
ENV NODE_OPTIONS="--max-old-space-size=2048"

# Dépendances (cache tant que package.json/pnpm-lock.yaml ne changent pas)
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prefer-offline

# Code
COPY . .

# ---------- Build (Remix/Vite) ----------
FROM base AS build
WORKDIR /app
# build prod (sans sourcemaps pour baisser la RAM)
RUN pnpm run build -- --no-sourcemap

# ---------- Runtime ----------
FROM ${BASE} AS runtime
WORKDIR /app

# pnpm pour exécuter les scripts
RUN npm i -g pnpm

# Copier ce qu'il faut
COPY --from=build /app /app

# Vars (tu peux en passer d'autres via Coolify au besoin)
ENV NODE_ENV=production
ENV PORT=3000

# Expose le port public
EXPOSE 3000

# Lance le serveur de prévisualisation Cloudflare Pages
# (équivalent de "dockerstart" mais sur le port 3000 et bind 0.0.0.0)
CMD sh -lc 'bindings=$(./bindings.sh) && wrangler pages dev ./build/client $bindings --ip 0.0.0.0 --port $PORT --no-show-interactive-dev-session'

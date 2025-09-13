# ---------- Build stage ----------
FROM node:20-alpine AS builder
WORKDIR /app

# Outils utiles pour certains packages natifs
RUN apk add --no-cache git libc6-compat

# pnpm
RUN npm i -g pnpm

# Limiter la RAM de Node pendant install/build (2 Go)
ENV NODE_OPTIONS="--max-old-space-size=2048"
ENV NODE_ENV=production

# Dépendances
COPY package.json pnpm-lock.yaml* ./
# Utilise le cache pnpm si possible, et fige la lockfile
RUN pnpm install --frozen-lockfile --prefer-offline

# Sources & build
COPY . .
# Build Vite plus léger (pas de sourcemap -> moins de RAM)
RUN pnpm run build -- --no-sourcemap


# ---------- Runtime stage ----------
FROM node:20-alpine AS runner
WORKDIR /app

# pnpm pour exécuter les scripts
RUN npm i -g pnpm

# On copie tout depuis le builder (inclut dist/ et node_modules/
# -> nécessaire car `vite preview` est une devDependency)
COPY --from=builder /app ./

# Le serveur écoutera en 0.0.0.0:3000
ENV PORT=3000
EXPOSE 3000

# Serveur "prod-like" de Vite (pas le mode dev)
CMD ["pnpm", "run", "preview", "--", "--host", "0.0.0.0", "--port", "3000"]

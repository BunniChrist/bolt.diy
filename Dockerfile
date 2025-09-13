# ---------- Build stage ----------
FROM node:20-alpine AS builder
WORKDIR /app

# Outils utiles
RUN apk add --no-cache git libc6-compat

# pnpm
RUN npm i -g pnpm

# 1) Ne PAS mettre NODE_ENV=production ici (on a besoin des devDeps pour build)
# 2) Désactiver husky pendant l'install (évite "husky: not found" sur le script prepare)
ENV HUSKY=0
# Limiter la conso mémoire de Node pendant install/build
ENV NODE_OPTIONS="--max-old-space-size=2048"

# Dépendances
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile --prefer-offline

# Sources & build
COPY . .
# Build Vite plus léger
RUN pnpm run build -- --no-sourcemap


# ---------- Runtime stage ----------
FROM node:20-alpine AS runner
WORKDIR /app

RUN npm i -g pnpm

# Copier l'appli buildée
COPY --from=builder /app ./

# Maintenant seulement on met l'environnement en production
ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

# Servir le build (prod-like) sur 0.0.0.0:3000
CMD ["pnpm", "run", "preview", "--", "--host", "0.0.0.0", "--port", "3000"]

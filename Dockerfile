# ========= Base commune =========
ARG BASE=node:20.18.0
FROM ${BASE} AS base

WORKDIR /app

# pnpm global
RUN npm install -g pnpm

# Éviter les hooks Husky pendant l'installation
ENV HUSKY=0

# Copie des manifests + install (cache tant que ces fichiers ne changent pas)
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prefer-offline

# Copie du code
COPY . .

# Port utilisé par le script `dockerstart`
EXPOSE 5173


# ========= Image production =========
FROM base AS bolt-ai-production

# Autoriser plus de mémoire à Node pour le build (utilisera ta RAM + swap)
ENV NODE_OPTIONS="--max-old-space-size=6144 --max-semi-space-size=128"

# Variables optionnelles (passables en build-args)
ARG GROQ_API_KEY
ARG HuggingFace_API_KEY
ARG OPENAI_API_KEY
ARG ANTHROPIC_API_KEY
ARG OPEN_ROUTER_API_KEY
ARG GOOGLE_GENERATIVE_AI_API_KEY
ARG OLLAMA_API_BASE_URL
ARG XAI_API_KEY
ARG TOGETHER_API_KEY
ARG TOGETHER_API_BASE_URL
ARG AWS_BEDROCK_CONFIG
ARG VITE_LOG_LEVEL=debug
ARG DEFAULT_NUM_CTX

# (corrigé: HuggingFace_API_KEY, pas HuggingFace_KEY)
ENV WRANGLER_SEND_METRICS=false \
    GROQ_API_KEY=${GROQ_API_KEY} \
    HuggingFace_API_KEY=${HuggingFace_API_KEY} \
    OPENAI_API_KEY=${OPENAI_API_KEY} \
    ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY} \
    OPEN_ROUTER_API_KEY=${OPEN_ROUTER_API_KEY} \
    GOOGLE_GENERATIVE_AI_API_KEY=${GOOGLE_GENERATIVE_AI_API_KEY} \
    OLLAMA_API_BASE_URL=${OLLAMA_API_BASE_URL} \
    XAI_API_KEY=${XAI_API_KEY} \
    TOGETHER_API_KEY=${TOGETHER_API_KEY} \
    TOGETHER_API_BASE_URL=${TOGETHER_API_BASE_URL} \
    AWS_BEDROCK_CONFIG=${AWS_BEDROCK_CONFIG} \
    VITE_LOG_LEVEL=${VITE_LOG_LEVEL} \
    DEFAULT_NUM_CTX=${DEFAULT_NUM_CTX} \
    RUNNING_IN_DOCKER=true

# Désactiver les métriques Wrangler (comme l’original)
RUN mkdir -p /root/.config/.wrangler && \
    echo '{"enabled":false}' > /root/.config/.wrangler/metrics.json

# --- Build propre (évite les artefacts cassés .vite) ---
# 1) nettoyer les caches Vite
# 2) s'assurer que les deps sont bien présentes
# 3) fournir un commit par défaut si .git absent
RUN rm -rf node_modules/.vite .vite && \
    pnpm prune --prod=false && pnpm install --frozen-lockfile --prefer-offline && \
    echo "no-git-info" > .git-commit-version

# Build (Remix + Vite)
RUN pnpm run build

# Démarrage : script du repo (écoute 0.0.0.0:5173)
CMD [ "pnpm", "run", "dockerstart" ]


# ========= Image développement (optionnel) =========
FROM base AS bolt-ai-development

ARG GROQ_API_KEY
ARG HuggingFace_API_KEY
ARG OPENAI_API_KEY
ARG ANTHROPIC_API_KEY
ARG OPEN_ROUTER_API_KEY
ARG GOOGLE_GENERATIVE_AI_API_KEY
ARG OLLAMA_API_BASE_URL
ARG XAI_API_KEY
ARG TOGETHER_API_KEY
ARG TOGETHER_API_BASE_URL
ARG AWS_BEDROCK_CONFIG
ARG VITE_LOG_LEVEL=debug
ARG DEFAULT_NUM_CTX

ENV GROQ_API_KEY=${GROQ_API_KEY} \
    HuggingFace_API_KEY=${HuggingFace_API_KEY} \
    OPENAI_API_KEY=${OPENAI_API_KEY} \
    ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY} \
    OPEN_ROUTER_API_KEY=${OPEN_ROUTER_API_KEY} \
    GOOGLE_GENERATIVE_AI_API_KEY=${GOOGLE_GENERATIVE_AI_API_KEY} \
    OLLAMA_API_BASE_URL=${OLLAMA_API_BASE_URL} \
    XAI_API_KEY=${XAI_API_KEY} \
    TOGETHER_API_KEY=${TOGETHER_API_KEY} \
    TOGETHER_API_BASE_URL=${TOGETHER_API_BASE_URL} \
    AWS_BEDROCK_CONFIG=${AWS_BEDROCK_CONFIG} \
    VITE_LOG_LEVEL=${VITE_LOG_LEVEL} \
    DEFAULT_NUM_CTX=${DEFAULT_NUM_CTX} \
    RUNNING_IN_DOCKER=true

RUN mkdir -p ${WORKDIR}/run
CMD ["pnpm", "run", "dev", "--host"]

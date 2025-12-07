# Dockerfile for Next.js app in a pnpm monorepo
# This Dockerfile should be built from the root of the monorepo:

# -----------------
# Base stage
# -----------------
FROM node:20-alpine AS base
WORKDIR /app
RUN corepack enable

# -----------------
# Builder stage
# -----------------
FROM base AS builder

RUN apk update && apk add --no-cache git perl python3 make g++ postgresql-dev

RUN git clone https://github.com/Afilmory/Afilmory --depth 1 .
COPY config.json ./
COPY builder.config.ts ./

# S3 配置
ARG S3_BUCKET_NAME
ARG S3_REGION
ARG S3_ENDPOINT
ARG S3_ACCESS_KEY_ID
ARG S3_SECRET_ACCESS_KEY
ARG S3_PREFIX
ARG S3_CUSTOM_DOMAIN
ARG S3_EXCLUDE_REGEX

# 其他配置
ARG GIT_TOKEN
ARG PG_CONNECTION_STRING

# 将 ARG 转换为 ENV，构建脚本需要读取环境变量
ENV S3_BUCKET_NAME=$S3_BUCKET_NAME \
    S3_REGION=$S3_REGION \
    S3_ENDPOINT=$S3_ENDPOINT \
    S3_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID \
    S3_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY \
    S3_PREFIX=$S3_PREFIX \
    S3_CUSTOM_DOMAIN=$S3_CUSTOM_DOMAIN \
    S3_EXCLUDE_REGEX=$S3_EXCLUDE_REGEX

RUN sh ./scripts/preinstall.sh
# Install all dependencies
RUN pnpm install --frozen-lockfile

# Build the app.
# The build script in the ssr package.json handles building the web app first.
RUN pnpm --filter=@afilmory/ssr build

# -----------------
# Runner stage
# -----------------
FROM base AS runner

WORKDIR /app

ENV NODE_ENV=production
# ENV PORT and other configurations are now in the config files
# and passed through environment variables during runtime.
RUN apk add --no-cache curl wget
# Create a non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

USER nextjs

COPY --from=builder --chown=nextjs:nodejs /app/apps/ssr/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/apps/ssr/.next/static /app/apps/ssr/.next/static
COPY --from=builder --chown=nextjs:nodejs /app/apps/ssr/public /app/apps/ssr/public

# The standalone output includes the server.js file.
# The PORT environment variable is automatically used by Next.js.
EXPOSE 3000

CMD ["node", "apps/ssr/server.js"]

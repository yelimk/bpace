# Node.js 20 LTS Lightweight Alpine Base Image
FROM node:20-alpine

# Set Working Directory inside container
WORKDIR /app

# Copy Package Files
COPY package*.json ./
COPY prisma ./prisma/

# Install Production Dependencies & Generate Prisma Client
RUN npm ci --only=production
RUN npx prisma generate

# Copy Source Code
COPY . .

# Expose Default Port 3000
EXPOSE 3000

# Environment variables default
ENV NODE_ENV=production
ENV PORT=3000

# Health check command
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/api/health || exit 1

# Start Server
CMD ["node", "src/server.js"]

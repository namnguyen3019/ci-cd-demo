FROM node:18-alpine

WORKDIR /app

# Install curl for health checks
RUN apk add --no-cache curl

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Copy package files
COPY package*.json ./

# Install all dependencies (including devDependencies for build)
# Don't set NODE_ENV=production yet as we need devDependencies for build
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Now set production environment and remove devDependencies
ENV NODE_ENV=production
RUN npm prune --production

# Change ownership of the app directory
RUN chown -R nextjs:nodejs /app

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000 || exit 1

# Start the application
CMD ["npm", "start"] 
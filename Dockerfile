# Use Node 22 for building React app
FROM node:22-alpine AS build

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json first (for caching layers)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy all source files
COPY . .

# Build React app
RUN npm run build

# -------------------------
# Stage 2: Serve with nginx
# -------------------------
FROM nginx:alpine

# Copy built files from build stage
COPY --from=build /app/build /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]

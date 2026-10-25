
# Use Node.js
FROM node:22-alpine

# Set working folder
WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install dependencies
RUN npm ci --omit=dev

# Copy backend code
COPY server.js .

# Backend port
EXPOSE 3000

# Start the backend
CMD ["node", "server.js"]

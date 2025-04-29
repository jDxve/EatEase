FROM node:18
WORKDIR /app
COPY package*.json ./
COPY . .
RUN npm install
EXPOSE 5001
CMD ["node", "backend/server.js"]
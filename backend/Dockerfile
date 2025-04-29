FROM node:14
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5001
ENV NAME World
CMD ["node", "server.js"]

FROM node:22-alpine

WORKDIR /app

COPY package*.json ./

RUN npm config set fetch-retry-maxtimeout 600000 && \
    npm config set fetch-retry-mintimeout 10000 && \
    npm config set maxsockets 5 && \
    npm ci

COPY tsconfig.json ./
COPY src ./src
COPY prisma ./prisma

RUN npx prisma generate && npm run build

EXPOSE 3000

CMD ["npm", "run", "start:prod"]
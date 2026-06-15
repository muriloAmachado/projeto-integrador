#!/bin/sh

echo "Aplicando migrations..."
npx prisma migrate deploy

echo "Iniciando aplicação..."
node dist/server.js
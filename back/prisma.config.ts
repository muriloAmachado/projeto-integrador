
import "dotenv/config";
import { defineConfig } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema.prisma",
  migrations: {
    path: "prisma/migrations",
    seed: 'ts-node --transpile-only ./prisma/seed.ts',
  },
  datasource: {
    url: process.env.DATABASE_URL || "postgresql://postgres:1234@localhost:5432/lab?schema=public",
  },
});

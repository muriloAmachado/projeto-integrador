import type { Role, User as PrismaUser } from '@prisma/client';
import prisma from '../lib/prisma';

export class UserRepository {
  async findById(id: string): Promise<PrismaUser | null> {
    return prisma.user.findUnique({ where: { id } });
  }

  async findByEmail(email: string): Promise<PrismaUser | null> {
    return prisma.user.findUnique({ where: { email } });
  }

  async create(data: { nome: string; email: string; senha_hash: string; role?: Role }): Promise<PrismaUser> {
    return prisma.user.create({
      data: {
        nome: data.nome,
        email: data.email,
        senha_hash: data.senha_hash,
        role: data.role ?? 'CLIENTE',
      },
    });
  }

  async getAll(): Promise<PrismaUser[]> {
    return prisma.user.findMany({ orderBy: { criado_em: 'desc' } });
  }
}

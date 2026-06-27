import prisma from '../lib/prisma';
import { CreateNotificationInput } from '../models/Notification';
import type { Prisma } from '@prisma/client';

export class NotificationRepository {
  async create(data: CreateNotificationInput) {
    return prisma.notification.create({
      data: {
        userId: data.userId,
        tipo: data.tipo,
        titulo: data.titulo,
        mensagem: data.mensagem,
        data: (data.data ?? undefined) as Prisma.InputJsonValue | undefined,
      },
    });
  }

  async createMany(items: CreateNotificationInput[]) {
    if (items.length === 0) return { count: 0 };
    return prisma.notification.createMany({
      data: items.map((item) => ({
        userId: item.userId,
        tipo: item.tipo,
        titulo: item.titulo,
        mensagem: item.mensagem,
        data: (item.data ?? undefined) as Prisma.InputJsonValue | undefined,
      })),
    });
  }

  async findByUser(userId: string, onlyUnread = false) {
    return prisma.notification.findMany({
      where: {
        userId,
        ...(onlyUnread ? { lida: false } : {}),
      },
      orderBy: { criado_em: 'desc' },
    });
  }

  async countUnread(userId: string) {
    return prisma.notification.count({
      where: { userId, lida: false },
    });
  }

  async markAsRead(id: string, userId: string) {
    // updateMany garante que o usuário só marque as próprias notificações
    return prisma.notification.updateMany({
      where: { id, userId },
      data: { lida: true },
    });
  }

  async markAllAsRead(userId: string) {
    return prisma.notification.updateMany({
      where: { userId, lida: false },
      data: { lida: true },
    });
  }
}

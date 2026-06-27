import { Request, Response } from 'express';
import NotificationService from '../services/NotificationService';

export class NotificationController {
  async list(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.id;
      if (!userId) {
        return res.status(401).json({ message: 'Unauthorized' });
      }

      const onlyUnread =
        req.query.lida === 'false' || req.query.unread === 'true';

      const notifications = await NotificationService.listForUser(
        userId,
        onlyUnread
      );
      res.json(notifications);
    } catch (error: any) {
      res.status(500).json({ message: error.message });
    }
  }

  async unreadCount(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.id;
      if (!userId) {
        return res.status(401).json({ message: 'Unauthorized' });
      }

      const count = await NotificationService.countUnread(userId);
      res.json({ count });
    } catch (error: any) {
      res.status(500).json({ message: error.message });
    }
  }

  async markAsRead(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.id;
      if (!userId) {
        return res.status(401).json({ message: 'Unauthorized' });
      }

      const { id } = req.params;
      const updated = await NotificationService.markAsRead(id, userId);
      if (!updated) {
        return res.status(404).json({ message: 'Notification not found' });
      }
      res.json({ success: true });
    } catch (error: any) {
      res.status(400).json({ message: error.message });
    }
  }

  async markAllAsRead(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.id;
      if (!userId) {
        return res.status(401).json({ message: 'Unauthorized' });
      }

      const count = await NotificationService.markAllAsRead(userId);
      res.json({ success: true, count });
    } catch (error: any) {
      res.status(400).json({ message: error.message });
    }
  }
}

import { Router } from 'express';
import { authenticateToken } from '../middleware/auth';
import { NotificationController } from '../controllers/NotificationController';

const router = Router();
const controller = new NotificationController();

router.get('/', authenticateToken, controller.list.bind(controller));
router.get('/unread-count', authenticateToken, controller.unreadCount.bind(controller));
router.patch('/read-all', authenticateToken, controller.markAllAsRead.bind(controller));
router.patch('/:id/read', authenticateToken, controller.markAsRead.bind(controller));

export default router;

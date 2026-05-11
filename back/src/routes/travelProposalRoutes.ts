import { Router } from 'express';
import { authenticateToken } from '../middleware/auth';
import { TravelProposalController } from '../controllers/TravelProposalController';

const router = Router();
const controller = new TravelProposalController();

router.post('/', authenticateToken, controller.create.bind(controller));
router.get('/', authenticateToken, controller.getAll.bind(controller));
router.get('/client', authenticateToken, controller.getByClient.bind(controller));
router.get('/:id', authenticateToken, controller.getById.bind(controller));
router.patch('/:id/status', authenticateToken, controller.updateStatus.bind(controller));

export default router;

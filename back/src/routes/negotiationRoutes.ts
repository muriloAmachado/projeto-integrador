import { Router } from 'express';
import { authenticateToken } from '../middleware/auth';
import { NegotiationController } from '../controllers/NegotiationController';

const router = Router();
const controller = new NegotiationController();

router.post('/', authenticateToken, controller.create.bind(controller));
router.get('/proposal/:propostaId', authenticateToken, controller.getByProposal.bind(controller));
router.patch('/:id/accept', authenticateToken, controller.accept.bind(controller));
router.patch('/:id/status', authenticateToken, controller.updateStatus.bind(controller));

export default router;

import { Router } from 'express';
import { authenticateToken } from '../middleware/auth';
import { NegotiationController } from '../controllers/NegotiationController';

const router = Router();
const controller = new NegotiationController();

router.post('/', controller.create.bind(controller));
router.get('/proposal/:propostaId', controller.getByProposal.bind(controller));
router.patch('/:id/status', controller.updateStatus.bind(controller));

export default router;

import { Router } from 'express';
import { CompletedTripController } from '../controllers/CompletedTripController';
import { authenticateToken } from '../middleware/auth';

const router = Router();
const controller = new CompletedTripController();

// Rotas específicas primeiro (evitar conflito com /:id)
router.get('/driver', authenticateToken, controller.getDriverTrips.bind(controller));
router.get('/code/:propostaId', authenticateToken, controller.getCode.bind(controller));
router.post('/finalize', authenticateToken, controller.finalizeByCode.bind(controller));

router.post('/', controller.completeTrip.bind(controller));
router.get('/:id', controller.getById.bind(controller));

export default router;

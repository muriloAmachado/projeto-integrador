import { Router } from 'express';
import { CompletedTripController } from '../controllers/CompletedTripController';

const router = Router();
const controller = new CompletedTripController();

router.post('/', controller.completeTrip.bind(controller));
router.get('/:id', controller.getById.bind(controller));

export default router;

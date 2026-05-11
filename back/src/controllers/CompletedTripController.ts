import { Request, Response } from 'express';
import { CompletedTripService } from '../services/CompletedTripService';

export class CompletedTripController {
  private completedTripService: CompletedTripService;

  constructor() {
    this.completedTripService = new CompletedTripService();
  }

  async completeTrip(req: Request, res: Response) {
    try {
      const motoristaId = (req as any).user?.id;
      const { propostaId, valor_final, codigo_confirma } = req.body;

      if (!motoristaId) {
        return res.status(401).json({ message: 'Unauthorized' });
      }

      const trip = await this.completedTripService.completeTrip(
        propostaId,
        motoristaId,
        valor_final,
        codigo_confirma
      );

      res.status(201).json(trip);
    } catch (error: any) {
      res.status(400).json({ message: error.message });
    }
  }

  async getById(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const trip = await this.completedTripService.getTripById(id);
      if (!trip) {
        return res.status(404).json({ message: 'Completed trip not found' });
      }
      res.json(trip);
    } catch (error: any) {
      res.status(500).json({ message: error.message });
    }
  }
}

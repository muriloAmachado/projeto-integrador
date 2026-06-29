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
      if (!motoristaId) return res.status(401).json({ message: 'Unauthorized' });

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
      if (!trip) return res.status(404).json({ message: 'Completed trip not found' });
      res.json(trip);
    } catch (error: any) {
      res.status(500).json({ message: error.message });
    }
  }

  // Cliente busca o código de encerramento da viagem
  async getCode(req: Request, res: Response) {
    try {
      const clienteId = (req as any).user?.id;
      const { propostaId } = req.params;
      if (!clienteId) return res.status(401).json({ message: 'Unauthorized' });

      const result = await this.completedTripService.getCodeForClient(propostaId, clienteId);
      res.json(result);
    } catch (error: any) {
      res.status(400).json({ message: error.message });
    }
  }

  // Motorista finaliza a viagem informando o código
  async finalizeByCode(req: Request, res: Response) {
    try {
      const motoristaId = (req as any).user?.id;
      const { codigo } = req.body;
      if (!motoristaId) return res.status(401).json({ message: 'Unauthorized' });

      const trip = await this.completedTripService.finalizeByCode(codigo, motoristaId);
      res.json(trip);
    } catch (error: any) {
      res.status(400).json({ message: error.message });
    }
  }

  // Motorista lista suas viagens confirmadas
  async getDriverTrips(req: Request, res: Response) {
    try {
      const motoristaId = (req as any).user?.id;
      if (!motoristaId) return res.status(401).json({ message: 'Unauthorized' });

      const trips = await this.completedTripService.getTripsByMotorista(motoristaId);
      res.json(trips);
    } catch (error: any) {
      res.status(500).json({ message: error.message });
    }
  }
}

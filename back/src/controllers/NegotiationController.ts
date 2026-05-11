import { Request, Response } from 'express';
import { NegotiationService } from '../services/NegotiationService';

export class NegotiationController {
  private negotiationService: NegotiationService;

  constructor() {
    this.negotiationService = new NegotiationService();
  }

  async create(req: Request, res: Response) {
    try {
      const motoristaId = (req as any).user?.id;
      const { propostaId, valor_ofertado } = req.body;

      if (!motoristaId) {
        return res.status(401).json({ message: 'Unauthorized' });
      }

      const negotiation = await this.negotiationService.createNegotiation(
        propostaId,
        motoristaId,
        valor_ofertado
      );

      res.status(201).json(negotiation);
    } catch (error: any) {
      res.status(400).json({ message: error.message });
    }
  }

  async getByProposal(req: Request, res: Response) {
    try {
      const { propostaId } = req.params;
      const negotiations = await this.negotiationService.getByProposalId(propostaId);
      res.json(negotiations);
    } catch (error: any) {
      res.status(500).json({ message: error.message });
    }
  }

  async updateStatus(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { status } = req.body;
      const negotiation = await this.negotiationService.updateStatus(id, status);
      res.json(negotiation);
    } catch (error: any) {
      res.status(400).json({ message: error.message });
    }
  }
}

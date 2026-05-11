import { Request, Response } from 'express';
import { TravelProposalService } from '../services/TravelProposalService';

export class TravelProposalController {
  private travelProposalService: TravelProposalService;

  constructor() {
    this.travelProposalService = new TravelProposalService();
  }

  async create(req: Request, res: Response) {
    try {
      const clienteId = (req as any).user?.id;
      console.log(req)
      const { origem, destino, valor_inicial, data_ida, data_volta } = req.body;

      if (!clienteId) {
        return res.status(401).json({ message: 'Unauthorized' });
      }

      const travelProposal = await this.travelProposalService.createProposal({
        clienteId,
        origem,
        destino,
        valor_inicial,
        data_ida: new Date(data_ida),
        data_volta: data_volta ? new Date(data_volta) : null,
      });

      res.status(201).json(travelProposal);
    } catch (error: any) {
      res.status(400).json({ message: error.message });
    }
  }

  async getAll(req: Request, res: Response) {
    try {
      const proposals = await this.travelProposalService.listProposals();
      res.json(proposals);
    } catch (error: any) {
      res.status(500).json({ message: error.message });
    }
  }

  async getById(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const proposal = await this.travelProposalService.getProposalById(id);
      if (!proposal) {
        return res.status(404).json({ message: 'Travel proposal not found' });
      }
      res.json(proposal);
    } catch (error: any) {
      res.status(500).json({ message: error.message });
    }
  }

  async getByClient(req: Request, res: Response) {
    try {
      const clienteId = (req as any).user?.id;
      if (!clienteId) {
        return res.status(401).json({ message: 'Unauthorized' });
      }
      const proposals = await this.travelProposalService.listByClient(clienteId);
      res.json(proposals);
    } catch (error: any) {
      res.status(500).json({ message: error.message });
    }
  }

  async updateStatus(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { status } = req.body;
      const proposal = await this.travelProposalService.updateStatus(id, status);
      res.json(proposal);
    } catch (error: any) {
      res.status(400).json({ message: error.message });
    }
  }
}

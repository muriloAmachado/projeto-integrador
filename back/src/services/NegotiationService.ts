import { NegotiationRepository } from '../repositories/NegotiationRepository';
import { NegotiationStatus } from '../models/Negotiation';
import { TravelProposalRepository } from '../repositories/TravelProposalRepository';

export class NegotiationService {
  private negotiationRepository: NegotiationRepository;
  private travelProposalRepository: TravelProposalRepository;

  constructor() {
    this.negotiationRepository = new NegotiationRepository();
    this.travelProposalRepository = new TravelProposalRepository();
  }

  async createNegotiation(propostaId: string, motoristaId: string, valor_ofertado: string) {
    const proposal = await this.travelProposalRepository.findById(propostaId);
    if (!proposal) {
      throw new Error('Travel proposal not found');
    }

    return this.negotiationRepository.create({ propostaId, motoristaId, valor_ofertado });
  }

  async getByProposalId(propostaId: string) {
    return this.negotiationRepository.findByProposalId(propostaId);
  }

  async updateStatus(id: string, status: NegotiationStatus) {
    const negotiation = await this.negotiationRepository.findById(id);
    if (!negotiation) {
      throw new Error('Negotiation not found');
    }

    return this.negotiationRepository.updateStatus(id, status);
  }
}

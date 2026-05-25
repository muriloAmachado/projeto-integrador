import { TravelProposalRepository } from '../repositories/TravelProposalRepository';
import { CreateTravelProposalInput, TravelProposalStatus } from '../models/TravelProposal';
import RabbitMQService from './RabbitMQService';

export class TravelProposalService {
  private travelProposalRepository: TravelProposalRepository;

  constructor() {
    this.travelProposalRepository = new TravelProposalRepository();
  }

  async createProposal(input: CreateTravelProposalInput) {
    const proposal = await this.travelProposalRepository.create(input);

    // Publicar evento para consumidores (notificar motoristas, analytics, etc.)
    try {
      await RabbitMQService.publishMessage('travel-proposals', {
        type: 'PROPOSAL_CREATED',
        proposal: {
          id: proposal.id,
          clienteId: proposal.clienteId,
          origem: proposal.origem,
          destino: proposal.destino,
          valor_inicial: proposal.valor_inicial,
          data_ida: proposal.data_ida,
          data_volta: proposal.data_volta || null,
          status: proposal.status,
          criado_em: proposal.criado_em,
        },
      });
    } catch (err) {
      console.error('Erro ao publicar evento de proposta criada:', err);
    }

    return proposal;
  }

  async getProposalById(id: string) {
    return this.travelProposalRepository.findById(id);
  }

  async listProposals() {
    return this.travelProposalRepository.findAll();
  }

  async listByClient(clienteId: string) {
    return this.travelProposalRepository.findByClientId(clienteId);
  }

  async updateStatus(id: string, status: TravelProposalStatus) {
    return this.travelProposalRepository.updateStatus(id, status);
  }
}

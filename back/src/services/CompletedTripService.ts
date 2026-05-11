import { CompletedTripRepository } from '../repositories/CompletedTripRepository';
import { TravelProposalRepository } from '../repositories/TravelProposalRepository';

export class CompletedTripService {
  private completedTripRepository: CompletedTripRepository;
  private travelProposalRepository: TravelProposalRepository;

  constructor() {
    this.completedTripRepository = new CompletedTripRepository();
    this.travelProposalRepository = new TravelProposalRepository();
  }

  async completeTrip(propostaId: string, motoristaId: string, valor_final: string, codigo_confirma: string) {
    const proposal = await this.travelProposalRepository.findById(propostaId);
    if (!proposal) {
      throw new Error('Travel proposal not found');
    }

    return this.completedTripRepository.create({
      propostaId,
      motoristaId,
      clienteId: proposal.clienteId,
      valor_final,
      codigo_confirma,
    });
  }

  async getTripById(id: string) {
    return this.completedTripRepository.findById(id);
  }

  async findByProposal(propostaId: string) {
    return this.completedTripRepository.findByProposalId(propostaId);
  }

  async getTripsByMotorista(motoristaId: string) {
    return this.completedTripRepository.listByMotoristaId(motoristaId);
  }

  async getTripsByCliente(clienteId: string) {
    return this.completedTripRepository.listByClienteId(clienteId);
  }
}

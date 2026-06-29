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
    if (!proposal) throw new Error('Travel proposal not found');

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

  async getCodeForClient(propostaId: string, clienteId: string) {
    const trip = await this.completedTripRepository.findByProposalId(propostaId);
    if (!trip) throw new Error('Viagem não encontrada');
    if (trip.clienteId !== clienteId) throw new Error('Não autorizado');
    return { codigo_confirma: trip.codigo_confirma, finalizada: trip.finalizada };
  }

  async finalizeByCode(codigo: string, motoristaId: string) {
    const trip = await this.completedTripRepository.findByCode(codigo);
    if (!trip) throw new Error('Código inválido');
    if (trip.motoristaId !== motoristaId) throw new Error('Não autorizado');
    if (trip.finalizada) throw new Error('Viagem já finalizada');

    await this.completedTripRepository.finalize(trip.id);
    await this.travelProposalRepository.updateStatus(trip.propostaId, 'ENCERRADO');
  }

  async getTripsByMotorista(motoristaId: string) {
    return this.completedTripRepository.listByMotoristaId(motoristaId);
  }

  async getTripsByCliente(clienteId: string) {
    return this.completedTripRepository.listByClienteId(clienteId);
  }
}

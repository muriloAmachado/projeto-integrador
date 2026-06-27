import { NegotiationRepository } from '../repositories/NegotiationRepository';
import { NegotiationStatus } from '../models/Negotiation';
import { TravelProposalRepository } from '../repositories/TravelProposalRepository';
import { CompletedTripRepository } from '../repositories/CompletedTripRepository';
import NotificationService from './NotificationService';

export class NegotiationService {
  private negotiationRepository: NegotiationRepository;
  private travelProposalRepository: TravelProposalRepository;
  private completedTripRepository: CompletedTripRepository;

  constructor() {
    this.negotiationRepository = new NegotiationRepository();
    this.travelProposalRepository = new TravelProposalRepository();
    this.completedTripRepository = new CompletedTripRepository();
  }

  async createNegotiation(
    propostaId: string,
    senderId: string,
    senderRole: string,
    valor_ofertado: string
  ) {
    const proposal = await this.travelProposalRepository.findById(propostaId);
    if (!proposal) {
      throw new Error('Travel proposal not found');
    }

    if (senderRole === 'CLIENTE' && proposal.clienteId !== senderId) {
      throw new Error('Only the proposal owner can send a client counterproposal');
    }

    if (senderRole !== 'CLIENTE' && senderRole !== 'MOTORISTA') {
      throw new Error('Unauthorized');
    }

    const negotiation = await this.negotiationRepository.create({
      propostaId,
      motoristaId: senderId,
      valor_ofertado,
    });

    // Notifica a contraparte (cliente ou motoristas) sobre a oferta/contraproposta
    await NotificationService.publishNegotiationCreated({
      negotiation,
      proposal,
      senderId,
      senderRole,
    });

    return negotiation;
  }

  async getByProposalId(propostaId: string) {
    return this.negotiationRepository.findByProposalId(propostaId);
  }

  async acceptNegotiation(id: string, accepterId: string, accepterRole: string) {
    const negotiation = await this.negotiationRepository.findById(id);
    if (!negotiation) {
      throw new Error('Negotiation not found');
    }

    const proposal = negotiation.proposta;
    if (!proposal) {
      throw new Error('Travel proposal not found');
    }

    const senderIsClient = negotiation.motoristaId === proposal.clienteId;
    const accepterIsClient = accepterId === proposal.clienteId;

    if (accepterRole !== 'CLIENTE' && accepterRole !== 'MOTORISTA') {
      throw new Error('Unauthorized');
    }

    if (senderIsClient === accepterIsClient) {
      throw new Error('Unauthorized to accept this negotiation');
    }

    const existingTrip = await this.completedTripRepository.findByProposalId(proposal.id);
    if (existingTrip) {
      return existingTrip;
    }

    await this.negotiationRepository.updateStatus(id, 'ACEITA');
    await this.travelProposalRepository.updateStatus(proposal.id, 'ACEITO');

    const motoristaId = senderIsClient ? accepterId : negotiation.motoristaId;
    const codigoConfirma = `TRIP-${Math.floor(100000 + Math.random() * 900000)}`;

    const trip = await this.completedTripRepository.create({
      propostaId: proposal.id,
      motoristaId,
      clienteId: proposal.clienteId,
      valor_final: negotiation.valor_ofertado.toString(),
      codigo_confirma: codigoConfirma,
    });

    // Notifica a contraparte que o aceite final ocorreu e a viagem foi confirmada
    await NotificationService.publishNegotiationAccepted({
      trip,
      negotiation,
      accepterRole,
    });

    return trip;
  }

  async updateStatus(id: string, status: NegotiationStatus) {
    const negotiation = await this.negotiationRepository.findById(id);
    if (!negotiation) {
      throw new Error('Negotiation not found');
    }

    return this.negotiationRepository.updateStatus(id, status);
  }
}

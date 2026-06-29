import { TravelProposalRepository } from '../repositories/TravelProposalRepository';
import { CreateTravelProposalInput, TravelProposalStatus } from '../models/TravelProposal';
import NotificationService from './NotificationService';

export interface DriverTravelProposalFilters {
  origem?: string;
  destino?: string;
  data_ida?: string;
  data_volta?: string;
}

export class TravelProposalService {
  private travelProposalRepository: TravelProposalRepository;

  constructor() {
    this.travelProposalRepository = new TravelProposalRepository();
  }

  async createProposal(input: CreateTravelProposalInput) {
    const proposal = await this.travelProposalRepository.create(input);

    // Publica o evento para que os motoristas sejam notificados
    await NotificationService.publishProposalCreated(proposal);

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

  async listForDriver(filters: DriverTravelProposalFilters = {}) {
    return this.travelProposalRepository.findForDriver(filters);
  }

  async listDriverAcceptedProposals(motoristaId: string) {
    return this.travelProposalRepository.findDriverAcceptedProposals(motoristaId);
  }

  async updateStatus(id: string, status: TravelProposalStatus) {
    return this.travelProposalRepository.updateStatus(id, status);
  }
}

import { TravelProposalRepository } from '../repositories/TravelProposalRepository';
import { CreateTravelProposalInput, TravelProposalStatus } from '../models/TravelProposal';

export class TravelProposalService {
  private travelProposalRepository: TravelProposalRepository;

  constructor() {
    this.travelProposalRepository = new TravelProposalRepository();
  }

  async createProposal(input: CreateTravelProposalInput) {
    return this.travelProposalRepository.create(input);
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

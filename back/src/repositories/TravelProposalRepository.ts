import prisma from '../lib/prisma';
import { CreateTravelProposalInput, TravelProposalStatus } from '../models/TravelProposal';

export class TravelProposalRepository {
  async create(data: CreateTravelProposalInput) {
    return prisma.travelProposal.create({
      data: {
        clienteId: data.clienteId,
        origem: data.origem,
        destino: data.destino,
        valor_inicial: data.valor_inicial,
        data_ida: data.data_ida,
        data_volta: data.data_volta,
      },
    });
  }

  async findById(id: string) {
    return prisma.travelProposal.findUnique({
      where: { id },
    });
  }

  async findAll() {
    return prisma.travelProposal.findMany({
      orderBy: { criado_em: 'desc' },
    });
  }

  async findByClientId(clienteId: string) {
    return prisma.travelProposal.findMany({
      where: { clienteId },
      orderBy: { criado_em: 'desc' },
    });
  }

  async updateStatus(id: string, status: TravelProposalStatus) {
    return prisma.travelProposal.update({
      where: { id },
      data: { status },
    });
  }
}

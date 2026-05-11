import prisma from '../lib/prisma';
import { NegotiationStatus } from '../models/Negotiation';

export class NegotiationRepository {
  async create(data: { propostaId: string; motoristaId: string; valor_ofertado: string }) {
    return prisma.negotiation.create({
      data: {
        propostaId: data.propostaId,
        motoristaId: data.motoristaId,
        valor_ofertado: data.valor_ofertado,
      },
    });
  }

  async findById(id: string) {
    return prisma.negotiation.findUnique({ where: { id } });
  }

  async findByProposalId(propostaId: string) {
    return prisma.negotiation.findMany({
      where: { propostaId },
      orderBy: { criado_em: 'desc' },
    });
  }

  async updateStatus(id: string, status: NegotiationStatus) {
    return prisma.negotiation.update({
      where: { id },
      data: { status },
    });
  }
}

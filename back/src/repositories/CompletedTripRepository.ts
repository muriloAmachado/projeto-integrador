import prisma from '../lib/prisma';

export class CompletedTripRepository {
  async create(data: {
    propostaId: string;
    motoristaId: string;
    clienteId: string;
    valor_final: string;
    codigo_confirma: string;
  }) {
    return prisma.completedTrip.create({ data });
  }

  async findById(id: string) {
    return prisma.completedTrip.findUnique({ where: { id } });
  }

  async findByProposalId(propostaId: string) {
    return prisma.completedTrip.findUnique({ where: { propostaId } });
  }

  async findByCode(codigo_confirma: string) {
    return prisma.completedTrip.findUnique({ where: { codigo_confirma } });
  }

  async finalize(id: string) {
    return prisma.completedTrip.update({
      where: { id },
      data: { finalizada: true },
    });
  }

  async listByMotoristaId(motoristaId: string) {
    return prisma.completedTrip.findMany({
      where: { motoristaId },
      include: {
        proposta: {
          select: {
            origem: true,
            destino: true,
            data_ida: true,
            data_volta: true,
          },
        },
        cliente: {
          select: { nome: true, email: true },
        },
      },
      orderBy: { realizada_em: 'desc' },
    });
  }

  async listByClienteId(clienteId: string) {
    return prisma.completedTrip.findMany({
      where: { clienteId },
      orderBy: { realizada_em: 'desc' },
    });
  }
}

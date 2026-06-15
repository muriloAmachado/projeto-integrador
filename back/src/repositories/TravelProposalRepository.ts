import prisma from '../lib/prisma';
import { CreateTravelProposalInput, TravelProposalStatus } from '../models/TravelProposal';

interface TravelProposalDriverFilters {
  origem?: string;
  destino?: string;
  data_ida?: string;
  data_volta?: string;
}

const buildDayRange = (dateValue: string) => {
  const parsedDate = new Date(dateValue);

  if (Number.isNaN(parsedDate.getTime())) {
    throw new Error(`Invalid date filter: ${dateValue}`);
  }

  const start = new Date(Date.UTC(parsedDate.getUTCFullYear(), parsedDate.getUTCMonth(), parsedDate.getUTCDate()));
  const end = new Date(start);
  end.setUTCDate(end.getUTCDate() + 1);

  return { gte: start, lt: end };
};

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

  async findForDriver(filters: TravelProposalDriverFilters = {}) {
    const where = {
      status: 'PENDENTE' as const,
      ...(filters.origem
        ? {
            origem: {
              contains: filters.origem,
              mode: 'insensitive' as const,
            },
          }
        : {}),
      ...(filters.destino
        ? {
            destino: {
              contains: filters.destino,
              mode: 'insensitive' as const,
            },
          }
        : {}),
      ...(filters.data_ida
        ? {
            data_ida: buildDayRange(filters.data_ida),
          }
        : {}),
      ...(filters.data_volta
        ? {
            data_volta: buildDayRange(filters.data_volta),
          }
        : {}),
    };

    return prisma.travelProposal.findMany({
      where,
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

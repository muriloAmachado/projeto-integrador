export type TravelProposalStatus = 'PENDENTE' | 'NEGOCIANDO' | 'ACEITO' | 'CANCELADO';

export interface TravelProposal {
  id: string;
  clienteId: string;
  origem: string;
  destino: string;
  valor_inicial: string;
  data_ida: Date;
  data_volta?: Date | null;
  status: TravelProposalStatus;
  criado_em: Date;
}

export interface CreateTravelProposalInput {
  clienteId: string;
  origem: string;
  destino: string;
  valor_inicial: string;
  data_ida: Date;
  data_volta?: Date | null;
}

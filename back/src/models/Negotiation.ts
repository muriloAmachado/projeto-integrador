export type NegotiationStatus = 'EM_ANALISE' | 'ACEITA' | 'RECUSADA';

export interface Negotiation {
  id: string;
  propostaId: string;
  motoristaId: string;
  valor_ofertado: string;
  status: NegotiationStatus;
  criado_em: Date;
}

export interface CreateNegotiationInput {
  propostaId: string;
  motoristaId: string;
  valor_ofertado: string;
}

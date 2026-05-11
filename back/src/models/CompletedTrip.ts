export interface CompletedTrip {
  id: string;
  propostaId: string;
  motoristaId: string;
  clienteId: string;
  valor_final: string;
  codigo_confirma: string;
  realizada_em: Date;
}

export interface CreateCompletedTripInput {
  propostaId: string;
  motoristaId: string;
  clienteId: string;
  valor_final: string;
  codigo_confirma: string;
}

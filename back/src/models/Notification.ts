export type NotificationType =
  | 'PROPOSAL_CREATED'
  | 'NEGOTIATION_CREATED'
  | 'NEGOTIATION_ACCEPTED';

export interface Notification {
  id: string;
  userId: string;
  tipo: NotificationType;
  titulo: string;
  mensagem: string;
  data?: unknown;
  lida: boolean;
  criado_em: Date;
}

export interface CreateNotificationInput {
  userId: string;
  tipo: NotificationType;
  titulo: string;
  mensagem: string;
  data?: Record<string, unknown> | null;
}

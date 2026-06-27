/**
 * Topologia de mensageria de notificações no RabbitMQ.
 *
 * Os serviços de domínio (proposta, negociação) publicam eventos no exchange
 * `notifications.events` usando as routing keys abaixo. Uma única fila
 * (`notifications.persistence`) é vinculada ao exchange com o padrão `#`,
 * consumida pelo worker que persiste as notificações e as direciona aos
 * destinatários corretos.
 */

export const NOTIFICATIONS_EXCHANGE = 'notifications.events';
export const NOTIFICATIONS_QUEUE = 'notifications.persistence';
export const NOTIFICATIONS_PATTERN = '#';

export const RoutingKeys = {
  PROPOSAL_CREATED: 'proposal.created',
  NEGOTIATION_CREATED: 'negotiation.created',
  NEGOTIATION_ACCEPTED: 'negotiation.accepted',
} as const;

export type RoutingKey = (typeof RoutingKeys)[keyof typeof RoutingKeys];

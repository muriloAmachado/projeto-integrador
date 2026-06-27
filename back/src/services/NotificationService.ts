import RabbitMQService from './RabbitMQService';
import { NotificationRepository } from '../repositories/NotificationRepository';
import { UserRepository } from '../repositories/UserRepository';
import { NegotiationRepository } from '../repositories/NegotiationRepository';
import {
  NOTIFICATIONS_EXCHANGE,
  RoutingKeys,
  RoutingKey,
} from '../config/rabbitmq';
import { CreateNotificationInput } from '../models/Notification';

/**
 * Formata um valor monetário (number | string | Prisma.Decimal) como BRL.
 */
function formatBRL(value: unknown): string {
  const num = Number(value);
  if (Number.isNaN(num)) return String(value);
  return num.toLocaleString('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  });
}

class NotificationService {
  private notificationRepository = new NotificationRepository();
  private userRepository = new UserRepository();
  private negotiationRepository = new NegotiationRepository();

  // ============================================================
  // PRODUTORES — chamados pelos serviços de domínio
  // ============================================================

  /**
   * Publica o evento de demanda de viagem criada para que os motoristas
   * sejam notificados.
   */
  async publishProposalCreated(proposal: any): Promise<void> {
    await this.publish(RoutingKeys.PROPOSAL_CREATED, {
      proposalId: proposal.id,
      clienteId: proposal.clienteId,
      origem: proposal.origem,
      destino: proposal.destino,
      valor_inicial: proposal.valor_inicial?.toString?.() ?? proposal.valor_inicial,
      data_ida: proposal.data_ida,
      data_volta: proposal.data_volta ?? null,
    });
  }

  /**
   * Publica o evento de negociação criada (oferta/contraproposta).
   * Se o remetente é o motorista, o cliente é notificado; se é o cliente,
   * os motoristas que negociam a proposta são notificados.
   */
  async publishNegotiationCreated(params: {
    negotiation: any;
    proposal: any;
    senderId: string;
    senderRole: string;
  }): Promise<void> {
    const { negotiation, proposal, senderId, senderRole } = params;
    await this.publish(RoutingKeys.NEGOTIATION_CREATED, {
      negotiationId: negotiation.id,
      propostaId: proposal.id,
      clienteId: proposal.clienteId,
      senderId,
      senderRole,
      valor_ofertado:
        negotiation.valor_ofertado?.toString?.() ?? negotiation.valor_ofertado,
      origem: proposal.origem,
      destino: proposal.destino,
    });
  }

  /**
   * Publica o evento de negociação aceita. Se quem aceitou foi o cliente, o
   * motorista é notificado; se foi o motorista, o cliente é notificado.
   */
  async publishNegotiationAccepted(params: {
    trip: any;
    negotiation: any;
    accepterRole: string;
  }): Promise<void> {
    const { trip, negotiation, accepterRole } = params;
    const proposal = negotiation.proposta ?? {};
    await this.publish(RoutingKeys.NEGOTIATION_ACCEPTED, {
      negotiationId: negotiation.id,
      propostaId: trip.propostaId,
      clienteId: trip.clienteId,
      motoristaId: trip.motoristaId,
      valor_final: trip.valor_final?.toString?.() ?? trip.valor_final,
      codigo_confirma: trip.codigo_confirma,
      accepterRole,
      origem: proposal.origem,
      destino: proposal.destino,
    });
  }

  private async publish(routingKey: RoutingKey, payload: Record<string, any>) {
    try {
      await RabbitMQService.publishToExchange(NOTIFICATIONS_EXCHANGE, routingKey, {
        event: routingKey,
        ...payload,
        timestamp: new Date(),
      });
    } catch (err) {
      // Falha de mensageria não deve quebrar o fluxo principal da requisição
      console.error(`✗ Erro ao publicar evento "${routingKey}":`, err);
    }
  }

  // ============================================================
  // CONSUMIDOR — worker que persiste e direciona as notificações
  // ============================================================

  /**
   * Despacha uma mensagem recebida da fila de notificações de acordo com o
   * tipo de evento (`message.event`).
   */
  async handleEvent(message: any): Promise<void> {
    const event: RoutingKey | undefined = message?.event;

    switch (event) {
      case RoutingKeys.PROPOSAL_CREATED:
        return this.onProposalCreated(message);
      case RoutingKeys.NEGOTIATION_CREATED:
        return this.onNegotiationCreated(message);
      case RoutingKeys.NEGOTIATION_ACCEPTED:
        return this.onNegotiationAccepted(message);
      default:
        console.warn('Notificações: evento desconhecido recebido', message);
    }
  }

  /** Nova demanda criada → notifica todos os motoristas. */
  private async onProposalCreated(msg: any): Promise<void> {
    const drivers = await this.userRepository.findByRole('MOTORISTA');
    if (drivers.length === 0) {
      console.log('Notificações: nenhum motorista para notificar');
      return;
    }

    const mensagem = `Nova viagem de ${msg.origem} para ${msg.destino} por ${formatBRL(
      msg.valor_inicial
    )}`;

    const items: CreateNotificationInput[] = drivers.map((driver) => ({
      userId: driver.id,
      tipo: 'PROPOSAL_CREATED',
      titulo: 'Nova solicitação de viagem',
      mensagem,
      data: { proposalId: msg.proposalId },
    }));

    await this.notificationRepository.createMany(items);
    console.log(`✓ ${items.length} motorista(s) notificado(s) sobre nova demanda`);
  }

  /** Negociação criada → notifica a contraparte. */
  private async onNegotiationCreated(msg: any): Promise<void> {
    const valor = formatBRL(msg.valor_ofertado);
    const baseData = {
      proposalId: msg.propostaId,
      negotiationId: msg.negotiationId,
    };

    if (msg.senderRole === 'MOTORISTA') {
      // Motorista ofertou/contrapropôs → notifica o cliente dono da proposta
      await this.persist({
        userId: msg.clienteId,
        tipo: 'NEGOTIATION_CREATED',
        titulo: 'Você recebeu uma proposta de motorista',
        mensagem: `Um motorista ofertou ${valor} para sua viagem de ${msg.origem} a ${msg.destino}.`,
        data: baseData,
      });
      return;
    }

    // Cliente fez uma contraproposta → notifica os motoristas que negociam a proposta
    const negotiations = await this.negotiationRepository.findByProposalId(
      msg.propostaId
    );
    const driverIds = Array.from(
      new Set(
        negotiations
          .map((n) => n.motoristaId)
          .filter((id) => id && id !== msg.clienteId)
      )
    );

    if (driverIds.length === 0) {
      console.log('Notificações: nenhum motorista para a contraproposta do cliente');
      return;
    }

    await this.notificationRepository.createMany(
      driverIds.map((driverId) => ({
        userId: driverId,
        tipo: 'NEGOTIATION_CREATED' as const,
        titulo: 'Contraproposta do cliente',
        mensagem: `O cliente fez uma contraproposta de ${valor} para a viagem de ${msg.origem} a ${msg.destino}.`,
        data: baseData,
      }))
    );
  }

  /** Negociação aceita → notifica a contraparte e confirma a viagem. */
  private async onNegotiationAccepted(msg: any): Promise<void> {
    const valor = formatBRL(msg.valor_final);
    const data = {
      proposalId: msg.propostaId,
      negotiationId: msg.negotiationId,
      codigo_confirma: msg.codigo_confirma,
    };

    if (msg.accepterRole === 'CLIENTE') {
      // Cliente aceitou → notifica o motorista que teve o aceite recebido
      await this.persist({
        userId: msg.motoristaId,
        tipo: 'NEGOTIATION_ACCEPTED',
        titulo: 'Proposta aceita! Viagem confirmada',
        mensagem: `O cliente aceitou ${valor}. Viagem de ${msg.origem} a ${msg.destino} confirmada! Código: ${msg.codigo_confirma}.`,
        data,
      });
    } else {
      // Motorista aceitou a contraproposta → notifica o cliente
      await this.persist({
        userId: msg.clienteId,
        tipo: 'NEGOTIATION_ACCEPTED',
        titulo: 'Sua contraproposta foi aceita!',
        mensagem: `O motorista aceitou ${valor}. Viagem de ${msg.origem} a ${msg.destino} confirmada! Código: ${msg.codigo_confirma}.`,
        data,
      });
    }
  }

  // ============================================================
  // LEITURA — usada pelo app mobile via REST
  // ============================================================

  async listForUser(userId: string, onlyUnread = false) {
    return this.notificationRepository.findByUser(userId, onlyUnread);
  }

  async countUnread(userId: string) {
    return this.notificationRepository.countUnread(userId);
  }

  async markAsRead(id: string, userId: string) {
    const result = await this.notificationRepository.markAsRead(id, userId);
    return result.count > 0;
  }

  async markAllAsRead(userId: string) {
    const result = await this.notificationRepository.markAllAsRead(userId);
    return result.count;
  }

  private async persist(notification: CreateNotificationInput): Promise<void> {
    await this.notificationRepository.create(notification);
    console.log(
      `✓ Notificação "${notification.tipo}" criada para o usuário ${notification.userId}`
    );
  }
}

export default new NotificationService();

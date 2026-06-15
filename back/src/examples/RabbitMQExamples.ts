import { Request, Response } from 'express';
import rabbitMQService from '../services/RabbitMQService';

/**
 * Exemplos de como usar o RabbitMQService em controllers
 */

// ============================================
// EXEMPLO 1: Publicar evento ao criar viagem
// ============================================

export const createTravelProposal = async (req: Request, res: Response) => {
  try {
    // const proposal = await TravelProposalService.create(req.body);

    // Publicar evento na fila
    await rabbitMQService.publishMessage('travel-proposals', {
      type: 'PROPOSAL_CREATED',
      proposalId: 'proposal-123',
      driverId: 'driver-456',
      clientId: 'client-789',
      route: {
        startLocation: 'São Paulo',
        endLocation: 'Rio de Janeiro',
      },
      estimatedPrice: 150.0,
      createdAt: new Date(),
    });

    // res.status(201).json(proposal);
    res.status(201).json({ message: 'Proposta criada com sucesso' });
  } catch (error) {
    console.error('Erro ao criar proposta:', error);
    res.status(500).json({ error: 'Erro ao criar proposta' });
  }
};

// ============================================
// EXEMPLO 2: Publicar evento de negociação
// ============================================

export const updateNegotiation = async (req: Request, res: Response) => {
  try {
    const { negotiationId, status } = req.body;
    // const negotiation = await NegotiationService.update(negotiationId, { status });

    // Publicar evento
    await rabbitMQService.publishToExchange(
      'negotiation-events',
      'negotiation.updated',
      {
        negotiationId,
        status,
        timestamp: new Date(),
        previousStatus: 'PENDING',
      }
    );

    // res.json(negotiation);
    res.json({ message: 'Negociação atualizada com sucesso' });
  } catch (error) {
    console.error('Erro ao atualizar negociação:', error);
    res.status(500).json({ error: 'Erro ao atualizar negociação' });
  }
};

// ============================================
// EXEMPLO 3: Publicar evento de viagem concluída
// ============================================

export const completeTrip = async (req: Request, res: Response) => {
  try {
    const { tripId, driverId, rating } = req.body;

    // Publicar evento
    await rabbitMQService.publishMessage('trip-completed', {
      type: 'TRIP_COMPLETED',
      tripId,
      driverId,
      rating,
      completedAt: new Date(),
      amount: 200.0,
    });

    res.json({ message: 'Viagem concluída com sucesso' });
  } catch (error) {
    console.error('Erro ao concluir viagem:', error);
    res.status(500).json({ error: 'Erro ao concluir viagem' });
  }
};

// ============================================
// EXEMPLO 4: Solicitar processamento assíncrono
// ============================================

export const requestPayment = async (req: Request, res: Response) => {
  try {
    const { tripId, amount, userId } = req.body;

    // Publicar para processamento assíncrono
    await rabbitMQService.publishMessage('payment-processing', {
      type: 'PAYMENT_REQUEST',
      tripId,
      amount,
      userId,
      requestedAt: new Date(),
      retryCount: 0,
    });

    // Retornar imediatamente ao usuário
    res.status(202).send({
      message: 'Pagamento em processamento',
      status: 'PENDING',
    });
  } catch (error) {
    console.error('Erro ao solicitar pagamento:', error);
    res.status(500).json({ error: 'Erro ao solicitar pagamento' });
  }
};

// ============================================
// EXEMPLO 5: Enviar notificação
// ============================================

export const notifyUser = async (req: Request, res: Response) => {
  try {
    const { userId, message, type } = req.body;

    await rabbitMQService.publishMessage('notifications', {
      type: 'USER_NOTIFICATION',
      userId,
      message,
      notificationType: type,
      sentAt: new Date(),
      read: false,
    });

    res.json({ message: 'Notificação enviada' });
  } catch (error) {
    console.error('Erro ao enviar notificação:', error);
    res.status(500).json({ error: 'Erro ao enviar notificação' });
  }
};

// ============================================
// EXEMPLO 6: Usar em Service Layer
// ============================================

export class PaymentService {
  /**
   * Processa pagamento de forma assíncrona
   */
  static async requestPaymentProcessing(tripId: string, amount: number) {
    await rabbitMQService.publishMessage('payment-processing', {
      type: 'PROCESS_PAYMENT',
      tripId,
      amount,
      timestamp: new Date(),
    });

    console.log(`Pagamento solicitado para viagem ${tripId}`);
  }

  /**
   * Solicita reembolso
   */
  static async requestRefund(tripId: string, amount: number, reason: string) {
    await rabbitMQService.publishMessage('refund-requests', {
      type: 'REFUND_REQUEST',
      tripId,
      amount,
      reason,
      requestedAt: new Date(),
    });

    console.log(`Reembolso solicitado para viagem ${tripId}`);
  }
}

// ============================================
// EXEMPLO 7: Consumidor (no server.ts)
// ============================================

/**
 * No seu arquivo server.ts, adicione após conectar ao RabbitMQ:
 *
 * // Consumir eventos de propostas criadas
 * await rabbitMQService.consumeMessage(
 *   'travel-proposals',
 *   async (message) => {
 *     console.log('Nova proposta de viagem:', message);
 *     // Aqui você pode:
 *     // - Enviar notificação para usuários
 *     // - Atualizar cache
 *     // - Disparar outro evento
 *   }
 * );
 *
 * // Consumir eventos de pagamento
 * await rabbitMQService.consumeMessage(
 *   'payment-processing',
 *   async (message) => {
 *     console.log('Processando pagamento:', message);
 *     // - Integrar com gateway de pagamento
 *     // - Atualizar status no banco
 *     // - Enviar confirmação por email
 *   }
 * );
 *
 * // Consumir notificações
 * await rabbitMQService.consumeMessage(
 *   'notifications',
 *   async (message) => {
 *     console.log('Enviando notificação:', message);
 *     // - Integrar com serviço de push notifications
 *     // - Salvar no banco de dados
 *     // - Enviar por email/SMS
 *   }
 * );
 */

export default {
  createTravelProposal,
  updateNegotiation,
  completeTrip,
  requestPayment,
  notifyUser,
  PaymentService,
};

class NotificationService {
  /**
   * Notifica motoristas relevantes sobre uma nova proposta de viagem.
   * Atualmente implementa como placeholder que apenas publica na fila `notifications`.
   */
  async notifyDriversForProposal(proposal: any) {
    // TODO: implementar lógica de seleção de motoristas (ex.: geolocalização, disponibilidade)
    // Por enquanto publicamos uma mensagem genérica para a fila `notifications`.
    const rabbit = (await import('./RabbitMQService')).default;

    try {
      await rabbit.publishMessage('notifications', {
        type: 'DRIVER_NOTIFICATION',
        proposal,
        message: `Nova solicitação de viagem de ${proposal.origem} para ${proposal.destino}`,
        timestamp: new Date(),
      });

      console.log('✓ Notificação enviada para motoristas (fila `notifications`)');
    } catch (err) {
      console.error('✗ Erro ao enviar notificação para motoristas:', err);
    }
  }
}

export default new NotificationService();

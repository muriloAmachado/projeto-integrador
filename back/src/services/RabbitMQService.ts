import amqp from 'amqplib';

interface MessageHandler {
  (message: any): Promise<void>;
}

class RabbitMQService {
  private connection: any = null;
  private channel: any = null;
  private isConnecting = false;

  /**
   * Conecta ao servidor RabbitMQ
   */
  async connect(): Promise<void> {
    if (this.isConnecting) {
      // Aguardar conexão em progresso
      let attempts = 0;
      while (this.isConnecting && attempts < 30) {
        await new Promise(resolve => setTimeout(resolve, 100));
        attempts++;
      }
      return;
    }

    if (this.connection && this.channel) {
      console.log('✓ Já conectado ao RabbitMQ');
      return;
    }

    this.isConnecting = true;
    try {
      const url = process.env.RABBITMQ_URL || 'amqp://localhost:5672';
      const maxRetries = 5;
      let lastError: Error | null = null;

      for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          this.connection = await amqp.connect(url);
          if (this.connection && typeof this.connection.createChannel === 'function') {
            this.channel = await this.connection.createChannel();
          } else {
            throw new Error('amqplib: createChannel not available on connection');
          }

          // Setup de event listeners para reconexão
          this.connection.on && this.connection.on('error', (err: any) => {
            console.error('✗ Erro na conexão RabbitMQ:', err);
            this.connection = null;
            this.channel = null;
          });

          this.connection.on && this.connection.on('close', () => {
            console.warn('⚠️  Conexão RabbitMQ fechada');
            this.connection = null;
            this.channel = null;
          });

          console.log('✓ Conectado ao RabbitMQ');
          this.isConnecting = false;
          return;
        } catch (error) {
          lastError = error as Error;
          console.warn(
            `⚠️  Tentativa ${attempt}/${maxRetries} falhou: ${lastError.message}`
          );

          if (attempt < maxRetries) {
            await new Promise(resolve =>
              setTimeout(resolve, Math.pow(2, attempt) * 1000)
            );
          }
        }
      }

      throw lastError || new Error('Falha ao conectar ao RabbitMQ');
    } catch (error) {
      console.error('✗ Erro ao conectar ao RabbitMQ:', error);
      this.isConnecting = false;
      throw error;
    }
  }

  /**
   * Publica mensagem em fila
   */
  async publishMessage(queue: string, message: any): Promise<boolean> {
    if (!this.channel) {
      throw new Error('Canal RabbitMQ não inicializado');
    }

    try {
      await this.channel.assertQueue(queue, { durable: true });

      const sent = this.channel.sendToQueue(
        queue,
        Buffer.from(JSON.stringify(message)),
        { persistent: true, contentType: 'application/json' }
      );

      console.log(
        `✓ Mensagem publicada na fila "${queue}":`,
        JSON.stringify(message)
      );
      return sent;
    } catch (error) {
      console.error(`✗ Erro ao publicar mensagem na fila "${queue}":`, error);
      throw error;
    }
  }

  /**
   * Consome mensagens de uma fila
   */
  async consumeMessage(
    queue: string,
    callback: MessageHandler,
    prefetch: number = 1
  ): Promise<void> {
    if (!this.channel) {
      throw new Error('Canal RabbitMQ não inicializado');
    }

    try {
      await this.channel.assertQueue(queue, { durable: true });
      await this.channel.prefetch(prefetch);

      this.channel.consume(queue, async (msg: any | null) => {
        if (msg) {
          try {
            const content = JSON.parse(msg.content.toString());
            await callback(content);
            this.channel.ack && this.channel.ack(msg);
            console.log(
              `✓ Mensagem processada da fila "${queue}":`,
              content
            );
          } catch (error) {
            console.error(
              `✗ Erro ao processar mensagem da fila "${queue}":`,
              error
            );
            // Reenviar para fila se houver erro
            this.channel.nack && this.channel.nack(msg, false, true);
          }
        }
      });

      console.log(`✓ Consumidor iniciado para fila "${queue}"`);
    } catch (error) {
      console.error(`✗ Erro ao consumir mensagens da fila "${queue}":`, error);
      throw error;
    }
  }

  /**
   * Publica mensagem em exchange com routing key
   */
  async publishToExchange(
    exchange: string,
    routingKey: string,
    message: any
  ): Promise<void> {
    if (!this.channel) {
      throw new Error('Canal RabbitMQ não inicializado');
    }

    try {

      await this.channel.assertExchange(exchange, 'topic', { durable: true });

      this.channel.publish(
        exchange,
        routingKey,
        Buffer.from(JSON.stringify(message)),
        { persistent: true, contentType: 'application/json' }
      );

      console.log(
        `✓ Mensagem publicada no exchange "${exchange}" com routing key "${routingKey}":`,
        JSON.stringify(message)
      );
    } catch (error) {
      console.error(
        `✗ Erro ao publicar no exchange "${exchange}":`,
        error
      );
      throw error;
    }
  }

  /**
   * Vincula fila a exchange com padrão de routing
   */
  async bindQueue(
    queue: string,
    exchange: string,
    pattern: string
  ): Promise<void> {
    if (!this.channel) {
      throw new Error('Canal RabbitMQ não inicializado');
    }

    try {
      await this.channel.assertQueue(queue, { durable: true });
      await this.channel.assertExchange(exchange, 'topic', { durable: true });
      await this.channel.bindQueue(queue, exchange, pattern);

      console.log(
        `✓ Fila "${queue}" vinculada ao exchange "${exchange}" com padrão "${pattern}"`
      );
    } catch (error) {
      console.error(
        `✗ Erro ao vincular fila "${queue}" ao exchange "${exchange}":`,
        error
      );
      throw error;
    }
  }

  /**
   * Desconecta do RabbitMQ
   */
  async disconnect(): Promise<void> {
    try {
      if (this.channel && typeof this.channel.close === 'function') {
        await this.channel.close();
        this.channel = null;
      }
      if (this.connection && typeof this.connection.close === 'function') {
        await this.connection.close();
        this.connection = null;
      }
      console.log('✓ Desconectado do RabbitMQ');
    } catch (error) {
      console.error('✗ Erro ao desconectar do RabbitMQ:', error);
    }
  }

  /**
   * Verifica se está conectado
   */
  isConnected(): boolean {
    return !!this.connection && !!this.channel;
  }
}

export default new RabbitMQService();

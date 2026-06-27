import dotenv from 'dotenv';
import express from 'express';
import userRoutes from './routes/userRoutes';
import cors from 'cors';
import travelProposalRoutes from './routes/travelProposalRoutes';
import negotiationRoutes from './routes/negotiationRoutes';
import completedTripRoutes from './routes/completedTripRoutes';
import notificationRoutes from './routes/notificationRoutes';
import RabbitMQService from './services/RabbitMQService';
import NotificationService from './services/NotificationService';
import {
  NOTIFICATIONS_EXCHANGE,
  NOTIFICATIONS_QUEUE,
  NOTIFICATIONS_PATTERN,
} from './config/rabbitmq';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json());

app.use('/api/users', userRoutes);
app.use('/api/proposals', travelProposalRoutes);
app.use('/api/negotiations', negotiationRoutes);
app.use('/api/completed-trips', completedTripRoutes);
app.use('/api/notifications', notificationRoutes);

app.get('/', (req, res) => {
  res.json({ message: 'API is running!' });
});

(async () => {
  try {
    await RabbitMQService.connect();
    // Vincula a fila de notificações ao exchange de eventos e inicia o worker
    // que persiste e direciona as notificações aos destinatários.
    try {
      await RabbitMQService.bindQueue(
        NOTIFICATIONS_QUEUE,
        NOTIFICATIONS_EXCHANGE,
        NOTIFICATIONS_PATTERN
      );
      await RabbitMQService.consumeMessage(NOTIFICATIONS_QUEUE, async (message) => {
        await NotificationService.handleEvent(message);
      });
    } catch (err) {
      console.error('Não foi possível registrar consumidor de notificações:', err);
    }
  } catch (err) {
    console.error('Não foi possível conectar ao RabbitMQ na inicialização:', err);
  }

  const server = app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
  });

  const shutdown = async () => {
    console.log('Shutting down server...');
    server.close(async () => {
      await RabbitMQService.disconnect();
      process.exit(0);
    });
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
})();

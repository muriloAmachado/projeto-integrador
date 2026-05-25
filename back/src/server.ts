import dotenv from 'dotenv';
import express from 'express';
import userRoutes from './routes/userRoutes';
import travelProposalRoutes from './routes/travelProposalRoutes';
import negotiationRoutes from './routes/negotiationRoutes';
import completedTripRoutes from './routes/completedTripRoutes';
import RabbitMQService from './services/RabbitMQService';
import NotificationService from './services/NotificationService';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

app.use('/api/users', userRoutes);
app.use('/api/proposals', travelProposalRoutes);
app.use('/api/negotiations', negotiationRoutes);
app.use('/api/completed-trips', completedTripRoutes);

app.get('/', (req, res) => {
  res.json({ message: 'API is running!' });
});

(async () => {
  try {
    await RabbitMQService.connect();
    // Registrar consumidor para propostas criadas e notificar motoristas
    try {
      await RabbitMQService.consumeMessage('travel-proposals', async (message) => {
        try {
          if (message && message.type === 'PROPOSAL_CREATED' && message.proposal) {
            console.log('Consumidor: nova proposta recebida, notificando motoristas...', message.proposal.id);
            await NotificationService.notifyDriversForProposal(message.proposal);
          } else {
            console.log('Consumidor: mensagem de travel-proposals recebida (formato inesperado)', message);
          }
        } catch (err) {
          console.error('Erro ao processar mensagem de travel-proposals:', err);
        }
      });
    } catch (err) {
      console.error('Não foi possível registrar consumidor de travel-proposals:', err);
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

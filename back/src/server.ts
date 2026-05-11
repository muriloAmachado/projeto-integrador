import dotenv from 'dotenv';
import express from 'express';
import userRoutes from './routes/userRoutes';
import travelProposalRoutes from './routes/travelProposalRoutes';
import negotiationRoutes from './routes/negotiationRoutes';
import completedTripRoutes from './routes/completedTripRoutes';

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

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});

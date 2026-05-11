import 'dotenv/config';
import bcrypt from 'bcryptjs';
import prisma from '../src/lib/prisma';

async function main() {
  // 1. LIMPEZA DO BANCO (Ordem reversa das relações para evitar erro de Foreign Key)
  console.log('Limpando banco de dados...');
  await prisma.completedTrip.deleteMany();
  await prisma.negotiation.deleteMany();
  await prisma.travelProposal.deleteMany();
  await prisma.user.deleteMany();

  // 2. GERAÇÃO DO HASH
  const salt = await bcrypt.genSalt(10);
  const hash = await bcrypt.hash('Senha@123', salt);

  console.log('Criando usuários...');
  
  const cliente = await prisma.user.create({
    data: {
      nome: 'João Silva',
      email: 'joao.silva@example.com',
      senha_hash: hash,
      role: 'CLIENTE',
    },
  });

  const motorista = await prisma.user.create({
    data: {
      nome: 'Carlos Souza',
      email: 'carlos.souza@example.com',
      senha_hash: hash,
      role: 'MOTORISTA',
    },
  });

  const admin = await prisma.user.create({
    data: {
      nome: 'Admin',
      email: 'admin@example.com',
      senha_hash: hash,
      role: 'ADMIN',
    },
  });

  console.log('Criando propostas e relações...');

  const proposal1 = await prisma.travelProposal.create({
    data: {
      clienteId: cliente.id,
      origem: 'Campinas',
      destino: 'São Paulo',
      valor_inicial: '120.00',
      data_ida: new Date('2026-05-20T08:00:00Z'),
      status: 'PENDENTE',
    },
  });

  const proposal2 = await prisma.travelProposal.create({
    data: {
      clienteId: cliente.id,
      origem: 'Jundiaí',
      destino: 'Guarujá',
      valor_inicial: '220.00',
      data_ida: new Date('2026-05-22T10:00:00Z'),
      data_volta: new Date('2026-05-25T18:00:00Z'),
      status: 'ACEITO',
    },
  });

  await prisma.negotiation.create({
    data: {
      propostaId: proposal1.id,
      motoristaId: motorista.id,
      valor_ofertado: '110.00',
      status: 'EM_ANALISE',
    },
  });

  await prisma.completedTrip.create({
    data: {
      propostaId: proposal2.id,
      motoristaId: motorista.id,
      clienteId: cliente.id,
      valor_final: '210.00',
      codigo_confirma: 'CONF12345',
    },
  });

  console.log('✅ Seed concluída com sucesso!');
}

main()
  .catch((error) => {
    console.error('❌ Erro no seed:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
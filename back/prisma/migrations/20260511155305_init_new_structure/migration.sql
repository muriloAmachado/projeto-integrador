-- CreateEnum
CREATE TYPE "Role" AS ENUM ('CLIENTE', 'MOTORISTA', 'ADMIN');

-- CreateEnum
CREATE TYPE "TripStatus" AS ENUM ('PENDENTE', 'NEGOCIAÇÃO', 'ACEITO', 'CANCELADO');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "senha_hash" TEXT NOT NULL,
    "role" "Role" NOT NULL DEFAULT 'CLIENTE',
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TravelProposal" (
    "id" TEXT NOT NULL,
    "clienteId" TEXT NOT NULL,
    "origem" TEXT NOT NULL,
    "destino" TEXT NOT NULL,
    "valor_inicial" DECIMAL(10,2) NOT NULL,
    "data_ida" TIMESTAMP(3) NOT NULL,
    "data_volta" TIMESTAMP(3),
    "status" TEXT NOT NULL DEFAULT 'PENDENTE',
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TravelProposal_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Negotiation" (
    "id" TEXT NOT NULL,
    "propostaId" TEXT NOT NULL,
    "motoristaId" TEXT NOT NULL,
    "valor_ofertado" DECIMAL(10,2) NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'EM_ANALISE',
    "criado_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Negotiation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CompletedTrip" (
    "id" TEXT NOT NULL,
    "propostaId" TEXT NOT NULL,
    "motoristaId" TEXT NOT NULL,
    "clienteId" TEXT NOT NULL,
    "valor_final" DECIMAL(10,2) NOT NULL,
    "codigo_confirma" TEXT NOT NULL,
    "realizada_em" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CompletedTrip_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "CompletedTrip_propostaId_key" ON "CompletedTrip"("propostaId");

-- CreateIndex
CREATE UNIQUE INDEX "CompletedTrip_codigo_confirma_key" ON "CompletedTrip"("codigo_confirma");

-- AddForeignKey
ALTER TABLE "TravelProposal" ADD CONSTRAINT "TravelProposal_clienteId_fkey" FOREIGN KEY ("clienteId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Negotiation" ADD CONSTRAINT "Negotiation_propostaId_fkey" FOREIGN KEY ("propostaId") REFERENCES "TravelProposal"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Negotiation" ADD CONSTRAINT "Negotiation_motoristaId_fkey" FOREIGN KEY ("motoristaId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CompletedTrip" ADD CONSTRAINT "CompletedTrip_propostaId_fkey" FOREIGN KEY ("propostaId") REFERENCES "TravelProposal"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CompletedTrip" ADD CONSTRAINT "CompletedTrip_motoristaId_fkey" FOREIGN KEY ("motoristaId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CompletedTrip" ADD CONSTRAINT "CompletedTrip_clienteId_fkey" FOREIGN KEY ("clienteId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

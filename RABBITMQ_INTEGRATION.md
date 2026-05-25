# Integração com RabbitMQ — Eventos do Sistema (MOM)

Este documento descreve os eventos de Message-Oriented Middleware (RabbitMQ) usados pelo sistema, incluindo produtor, consumidor, payload JSON de exemplo e a fila/exchange utilizada.

## Convenções
- Filas: filas diretas nomeadas para cenários ponto-a-ponto e notificações específicas.
- Exchanges: usar `topic` exchange quando for necessário roteamento por chave (opcional neste documento).
- Mensagens são JSON; filas são `durable` e mensagens são publicadas com `persistent: true`.

## Tabela de Eventos

| Evento | Produtor | Consumidor | Payload (exemplo) | Fila / Exchange |
|---|---|---|---|---|
| `PROPOSAL_CREATED` | `TravelProposalService` (quando um cliente cadastra uma proposta) | `NotificationService` (consumidor que seleciona motoristas e publica notificações individuais) | `{ "type":"PROPOSAL_CREATED", "proposal": { "id":"p-123", "clienteId":"c-789", "origem":"São Paulo","destino":"Campinas","valor_inicial":"120.00","data_ida":"2026-06-01T10:00:00.000Z" } }` | fila: `travel-proposals` |
| `DRIVER_OFFER_ACCEPTED` | `DriverService` (quando motorista aceita proposta do cliente) | `ClientNotificationService` (notifica o cliente que o motorista aceitou) | `{ "type":"DRIVER_OFFER_ACCEPTED", "proposalId":"p-123", "driverId":"d-456", "timestamp":"2026-05-25T12:00:00.000Z" }` | fila: `client-notifications` |
| `PROPOSAL_RECREATED` | `TravelProposalService` (quando cliente reenvia/refaz uma proposta em cima de uma anterior) | `NotificationService` (notifica o(s) motorista(s) relevantes sobre a nova proposta) | `{ "type":"PROPOSAL_RECREATED", "proposal": { "id":"p-124", "clienteId":"c-789", "origem":"São Paulo","destino":"Campinas","valor_inicial":"130.00","data_ida":"2026-06-02T10:00:00.000Z" }, "previousProposalId":"p-123" }` | fila: `travel-proposals` (campo `type` distingue `PROPOSAL_CREATED` / `PROPOSAL_RECREATED`) |
| `MUTUAL_ACCEPTANCE` | Emissão coordenada por `AgreementService` (quando cliente e motorista confirmam aceitação mútua) | `NotificationService` e `TripManagementService` (notifica ambas as partes e inicia fluxo de viagem) | `{ "type":"MUTUAL_ACCEPTANCE", "proposalId":"p-123", "clientId":"c-789", "driverId":"d-456", "acceptedAt":"2026-05-25T12:30:00.000Z" }` | exchange: `trip-events` (routing key: `trip.accepted`) ou fila: `mutual-acceptance` |

## Como usar esses eventos (resumo prático)

- Ao criar/editar proposta, o `TravelProposalService` publica na fila `travel-proposals` o evento com `type` adequado (`PROPOSAL_CREATED` ou `PROPOSAL_RECREATED`).
- Um consumidor (`NotificationService`) consome `travel-proposals`, aplica regras de seleção de motoristas (por localização, disponibilidade, preferência) e publica mensagens de notificação específicas na fila `notifications` ou em filas por cliente/driver (`client-notifications`, `driver-notifications`).
- Quando um motorista aceita uma proposta, o `DriverService` publica `DRIVER_OFFER_ACCEPTED` em `client-notifications`; o `ClientNotificationService` consome e notifica o cliente (push / email / in-app).
- Quando há aceitação mútua, um `AgreementService` publica `MUTUAL_ACCEPTANCE` em `trip-events` (exchange `topic` com routing key `trip.accepted`) para que múltiplos consumidores (notificações, criação de registro de viagem, billing) sejam acionados.

## Recomendações de implementação

- Durabilidade: declarar filas com `durable: true` e publicar com `persistent: true` para evitar perda de mensagens.
- Idempotência: consumidores devem tratar eventos de forma idempotente (checar se já processaram um `proposalId`), evitando efeitos duplicados.
- DLQ / Retries: configurar dead-letter queues e políticas de retry para mensagens que falhem repetidamente.
- Autorização e segurança: em produção, usar users/vhosts e TLS entre serviços RabbitMQ.
- Escala: mover consumidores críticos para processos/workers separados (horizontalizar) e usar exchanges `topic` para roteamento quando necessário.

## Exemplos de publicação (Node.js / amqplib)

```ts
// publicar PROPOSAL_CREATED
await rabbit.publishMessage('travel-proposals', {
  type: 'PROPOSAL_CREATED',
  proposal: { id: 'p-123', clienteId: 'c-789', origem: 'São Paulo', destino: 'Campinas', valor_inicial: '120.00', data_ida: '2026-06-01T10:00:00.000Z' }
});

// publicar DRIVER_OFFER_ACCEPTED
await rabbit.publishMessage('client-notifications', {
  type: 'DRIVER_OFFER_ACCEPTED',
  proposalId: 'p-123',
  driverId: 'd-456',
  timestamp: new Date().toISOString()
});

// publicar MUTUAL_ACCEPTANCE via exchange topic
await rabbit.publishToExchange('trip-events', 'trip.accepted', {
  type: 'MUTUAL_ACCEPTANCE', proposalId: 'p-123', clientId: 'c-789', driverId: 'd-456', acceptedAt: new Date().toISOString()
});
```

---
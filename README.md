# Projeto Integrador — PUC

Aplicativo de transporte com negociação de frete entre clientes e motoristas.

- **Backend**: Node.js + Express + TypeScript + Prisma + PostgreSQL + RabbitMQ
- **Mobile**: Flutter (Android/iOS)

---

## Pré-requisitos

| Ferramenta | Versão mínima | Uso |
|---|---|---|
| [Podman](https://podman.io/getting-started/installation) | 4.1+ | Containers (API, banco, fila) |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | 3.10+ | App mobile |
| [Android Studio](https://developer.android.com/studio) ou dispositivo físico | — | Emulador / build |

> **Usuários Windows:** instale o Podman Desktop e certifique-se de que a máquina virtual do Podman está iniciada (`podman machine start`) antes de executar os comandos abaixo.

---

## Executando o backend com Podman

### 1. Clone o repositório

```bash
git clone <url-do-repositorio>
cd projeto-integrador
```

### 2. Suba os containers

```bash
podman compose up -d --build
```

Esse comando:
- Constrói a imagem da API a partir de `back/Dockerfile`
- Sobe o PostgreSQL 16 (porta `5432`)
- Sobe o RabbitMQ 3 com painel de gerenciamento (porta `5672` / painel em `15672`)
- Aguarda o banco e o RabbitMQ ficarem saudáveis antes de iniciar a API
- Executa as migrations automaticamente (`prisma migrate deploy`)
- Inicia a API na porta `3000`

### 3. Verifique se tudo está rodando

```bash
podman compose ps
```

Todos os serviços devem aparecer com status `running (healthy)` ou `running`.

Teste rápido da API:

```bash
curl http://localhost:3000
# Resposta esperada: {"message":"API is running!"}
```

### 4. Acesse o painel do RabbitMQ (opcional)

Abra `http://localhost:15672` no navegador.

- **Usuário:** `guest`
- **Senha:** `guest`

---

## Executando o app mobile

### 1. Configure a URL da API

O app usa `http://localhost:3000/api` por padrão, o que funciona no navegador web e em simuladores iOS. Para **emulador Android** ou **dispositivo físico**, é necessário passar a URL correta:

**Emulador Android** (localhost do host é `10.0.2.2` dentro do emulador):

```bash
cd mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

**Dispositivo físico** (substitua pelo IP da sua máquina na rede local):

```bash
cd mobile
flutter run --dart-define=API_BASE_URL=http://192.168.X.X:3000/api
```

Para descobrir seu IP local:
- **Windows:** `ipconfig` → procure por "Endereço IPv4"
- **Linux/macOS:** `ip addr` ou `ifconfig`

### 2. Instale as dependências e rode

```bash
cd mobile
flutter pub get
flutter run
```

---

## Comandos úteis

### Containers

```bash
# Ver logs em tempo real
podman compose logs -f

# Ver logs apenas da API
podman compose logs -f api

# Parar os containers (mantém os dados)
podman compose stop

# Parar e remover containers (mantém volumes com dados)
podman compose down

# Parar, remover containers E apagar todos os dados (banco + fila)
podman compose down -v

# Reconstruir a imagem da API após mudanças no código
podman compose up -d --build api
```

### Banco de dados

```bash
# Acessar o banco PostgreSQL diretamente
podman exec -it pi-db psql -U postgres -d lab

# Ver tabelas
\dt

# Sair
\q
```

### Migrations (caso necessário rodar manualmente)

```bash
podman exec -it pi-api npx prisma migrate deploy
```

---

## Variáveis de ambiente

As variáveis abaixo são definidas diretamente no `compose.yaml` para os containers. Para **desenvolvimento local** (sem container), o arquivo `back/.env` é utilizado.

| Variável | Valor nos containers | Descrição |
|---|---|---|
| `DATABASE_URL` | `postgresql://postgres:1234@db:5432/lab?schema=public` | Conexão com o PostgreSQL |
| `RABBITMQ_URL` | `amqp://guest:guest@rabbitmq:5672` | Conexão com o RabbitMQ |
| `JWT_SECRET` | `your_super_secret_jwt_key_here` | Chave para assinar tokens JWT |
| `PORT` | `3000` | Porta da API |

> Para produção, substitua `JWT_SECRET` por um valor seguro diretamente no `compose.yaml` ou em um arquivo `.env` separado.

---

## Desenvolvimento local (sem container)

Para rodar a API diretamente na máquina (necessário ter Node.js 20+ e PostgreSQL/RabbitMQ instalados localmente):

```bash
cd back
npm install
npm run dev
```

O arquivo `back/.env` já contém as URLs para serviços locais:

```env
DATABASE_URL="postgresql://postgres:1234@localhost:5432/lab?schema=public"
RABBITMQ_URL=amqp://guest:guest@localhost:5672
JWT_SECRET=your_super_secret_jwt_key_here
```

Você ainda pode usar os containers do banco e do RabbitMQ enquanto roda a API localmente:

```bash
# Sobe apenas banco e fila (sem a API)
podman compose up -d db rabbitmq
```

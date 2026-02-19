# DogPay - Architecture & Planning

> Sistema de pagamentos simulado com múltiplos serviços integrados

## Visão Geral

DogPay é uma aplicação que simula um serviço de pagamentos completo com arquitetura de microserviços:
- **Frontend Web** React 18 + Vite para interface no browser
- **Frontend Mobile** Flutter para iOS/Android
- **Auth Service** Go + Gin para autenticação com JWT
- **Payment Service** Go + Gin para processamento de pagamentos via fila

---

## Arquitetura

```
┌─────────────────────────┐    ┌─────────────────────────┐
│  Frontend Web            │    │  Frontend Mobile         │
│  (React + Vite)          │    │  (Flutter)               │
│  Port: 5173              │    │  iOS / Android           │
└─────────────────────────┘    └─────────────────────────┘
          │  POST /auth/login          │  POST /payments/transfer
          │  GET /auth/me              │  GET /payments/balance
          ▼                            ▼
┌──────────────────────┐    ┌──────────────────────────────────┐
│    Auth Service      │    │        Payment Service           │
│    (Go + Gin)        │    │        (Go + Gin)                │
│    Port: 8001        │    │        Port: 8002                │
└──────────────────────┘    └──────────────────────────────────┘
          │                           │              │
          ▼                           ▼              ▼
┌──────────────────────┐   ┌──────────────┐  ┌─────────────────┐
│   PostgreSQL         │   │  PostgreSQL  │  │    RabbitMQ     │
│   schema: auth       │   │  schema:     │  │  queue:         │
│   (users, sessions)  │   │  payments    │  │  transfers      │
│   Port: 5432         │   │  (accounts,  │  │  Port: 5672     │
└──────────────────────┘   │  transactions│  │  UI: 15672      │
                           └──────────────┘  └─────────────────┘
                                                      │
                                                      ▼
                                            ┌─────────────────┐
                                            │  Queue Consumer │
                                            │  (goroutine no  │
                                            │  Payment Svc)   │
                                            └─────────────────┘
```

---

## Stack Tecnológico

### Frontend Web
- **Framework**: React 18 + Vite 6
- **CSS**: Tailwind CSS 3 com paleta de cores Datadog (`#632CA6`)
- **Roteamento**: React Router v6
- **HTTP**: Axios + TanStack Query (React Query) para cache
- **Auth state**: Zustand (store para token JWT e dados do usuário)
- **Porta local**: 5173

### Frontend Mobile
- **Framework**: Flutter 3.41 (Dart)
- **State management**: Provider + ChangeNotifier
- **HTTP**: Dio (com interceptor JWT e auto-refresh de token)
- **Storage**: flutter_secure_storage (tokens armazenados com segurança)
- **Navegação**: go_router
- **Tema**: Paleta Datadog purple (`#632CA6`) — consistente com o frontend web
- **Plataformas**: iOS, Android, macOS desktop
- **Simulador**: iPhone 16 iOS 26.2 (`A85DE849-575F-4276-8AC6-46E3312DE551`)

### Auth Service
- **Linguagem**: Go 1.22
- **Framework**: Gin
- **Banco**: PostgreSQL — schema `auth` (users, refresh_tokens)
- **Auth**: JWT (access token 15min + refresh token 7d)
- **Senha**: bcrypt
- **DB driver**: pgx v5
- **Porta local**: 8001

### Payment Service
- **Linguagem**: Go 1.22
- **Framework**: Gin
- **Banco**: PostgreSQL — schema `payments` (accounts, transactions)
- **Fila**: RabbitMQ com DLQ (dead letter queue)
- **Porta local**: 8002

### Infraestrutura
- **Docker + Docker Compose**: orquestra todos os serviços localmente
- **PostgreSQL 16**: único servidor, schemas separados (`auth`, `payments`)
- **RabbitMQ 3.13**: Management UI disponível em `localhost:15672`

---

## Estrutura de Diretórios

```
~/projects/dogpay/
├── TASKS.md
├── PLAN.md
├── README.md
├── docker-compose.yml
├── .env / .env.example
├── scripts/
│   └── init-db.sh               # Cria schemas e aplica migrations
├── services/
│   ├── auth-service/            # Go module
│   │   ├── cmd/main.go
│   │   ├── internal/
│   │   │   ├── handlers/        # HTTP handlers (login, register, me, refresh)
│   │   │   ├── middleware/      # JWT middleware
│   │   │   ├── models/          # User structs
│   │   │   └── repository/      # DB queries (users, refresh_tokens)
│   │   ├── migrations/          # SQL migrations
│   │   ├── Dockerfile
│   │   └── go.mod
│   └── payment-service/         # Go module
│       ├── cmd/main.go
│       ├── internal/
│       │   ├── handlers/        # HTTP handlers (transfer, balance, history)
│       │   ├── middleware/      # JWT validation (stateless)
│       │   ├── models/          # Account, Transaction structs
│       │   ├── queue/           # RabbitMQ producer/consumer
│       │   └── repository/      # DB queries
│       ├── migrations/          # SQL migrations
│       ├── Dockerfile
│       └── go.mod
├── frontend/                    # React + Vite app
│   ├── src/
│   │   ├── pages/               # LoginPage, RegisterPage, DashboardPage
│   │   ├── hooks/               # useAuth, usePayments
│   │   ├── store/               # Zustand (auth state)
│   │   ├── services/            # API calls (axios)
│   │   └── main.tsx
│   ├── Dockerfile
│   └── package.json
└── mobile/                      # Flutter app
    ├── lib/
    │   ├── main.dart            # Entry point, providers, router
    │   ├── core/
    │   │   ├── theme.dart       # Tema Datadog purple
    │   │   └── api_client.dart  # Dio client com JWT interceptor
    │   ├── models/              # User, Transaction
    │   ├── services/            # AuthService, PaymentService
    │   ├── providers/           # AuthProvider, PaymentProvider
    │   └── screens/             # LoginScreen, RegisterScreen, DashboardScreen
    └── pubspec.yaml
```

---

## Decisões de Arquitetura

| Decisão | Escolha | Motivo |
|---|---|---|
| Frontend framework | React + Vite 6 | Maturidade, ecossistema, build rápido |
| Mobile framework | Flutter | Cross-platform (iOS + Android), single codebase, performance nativa |
| CSS | Tailwind | Agilidade sem overhead de biblioteca |
| Tema | Datadog Purple `#632CA6` | Consistência visual com a marca Datadog |
| Backend language | Go | Staticamente tipado, alta performance |
| Auth framework | Gin | Mais popular em Go, leve |
| Auth token | JWT stateless | Payment Service valida independentemente |
| DB | PostgreSQL | ACID compliance para dados financeiros |
| DB strategy | 1 servidor, 2 schemas | Simplicidade local; separar facilmente no futuro |
| Queue | RabbitMQ | Suporta DLQ, retries, routing |
| Containerização | Docker Compose | Ambiente local com 1 comando |
| Mobile state | Provider + ChangeNotifier | Simples, sem overhead; adequado para o escopo atual |
| Mobile HTTP | Dio | Interceptors, retry, timeout configurável |
| Mobile storage | flutter_secure_storage | Tokens JWT armazenados de forma segura no Keychain/Keystore |

---

## Fluxo de Transferência

```
Frontend (Web ou Mobile) → POST /payments/transfer
  → Payment Service valida JWT
  → Cria registro "pending" em transactions
  → Publica mensagem em RabbitMQ (transfer_id, from, to, amount)
  → Retorna 202 Accepted ao frontend

Consumer (background goroutine):
  → Recebe mensagem da fila
  → Inicia DB transaction
  → Verifica saldo (SELECT ... FOR UPDATE)
  → Debita conta origem / Credita conta destino
  → Atualiza status → "completed" (ou "failed")
  → Commit / Rollback
```

---

## Bugs Corrigidos

### Cache de dados entre sessões (2026-02-19)
**Problema**: Ao fazer logout e logar com outra conta, o frontend exibia saldo e extrato da sessão anterior até o próximo refetch automático.

**Causa**: TanStack Query (web) e Provider (mobile) mantinham cache em memória com chaves genéricas (`['balance']`, `['history']`), servindo dados antigos imediatamente ao navegar para o dashboard com a nova conta.

**Solução**: Chamar `queryClient.clear()` (web) e `paymentProvider.reset()` (mobile) no momento do logout e do login bem-sucedido, garantindo que dados frescos sejam buscados na nova sessão.

---

## Histórico de Desenvolvimento

### 2026-02-11 - Inicialização do Projeto
- Criada estrutura inicial de diretórios
- Criados arquivos TASKS.md e PLAN.md
- Definido propósito e objetivos gerais

### 2026-02-19 - Implementação Completa (Sessão 1)

#### Infraestrutura
- Repositório Git inicializado
- `docker-compose.yml` criado com PostgreSQL 16 + RabbitMQ 3.13 + todos os serviços
- `.env` / `.env.example` criados com todas as variáveis necessárias
- `scripts/init-db.sh` corrigido para aplicar migrations de subdirectórios automaticamente
- Migrations SQL criadas para schemas `auth` e `payments`

#### Auth Service (`services/auth-service/`)
- Go 1.22 + Gin + pgx v5 + JWT (`golang-jwt/jwt/v5`) + bcrypt
- Endpoints: `POST /auth/register`, `POST /auth/login`, `GET /auth/me`, `POST /auth/refresh`, `GET /health`
- Refresh tokens armazenados com hash SHA-256
- Ao criar usuário, notifica Payment Service via HTTP para criar conta (`/internal/accounts`)
- Compila sem erros (`go build ./...`)

#### Payment Service (`services/payment-service/`)
- Go 1.22 + Gin + pgx v5 + amqp091-go (RabbitMQ)
- Endpoints: `GET /payments/balance`, `POST /payments/transfer`, `GET /payments/history`, `GET /health`
- Endpoint interno: `POST /internal/accounts` (chamado pelo Auth Service)
- Consumer goroutine processa transferências atomicamente com `SELECT ... FOR UPDATE`
- DLQ (dead letter queue) para mensagens com falha (máx 3 tentativas)
- Compila sem erros (`go build ./...`)

#### Frontend Web (`frontend/`)
- React 18 + Vite 6 + TypeScript + Tailwind CSS 3
- Zustand com `persist` middleware (tokens salvos em localStorage)
- TanStack Query com auto-refresh (balance: 10s, history: 5s)
- Axios com interceptor JWT + renovação automática de token via refresh
- Páginas: `LoginPage`, `RegisterPage`, `DashboardPage`
- Dashboard: card de saldo com gradiente, formulário de transferência, extrato com status
- Build de produção funcional (`npm run build`)
- Containerizado com Nginx (SPA routing configurado)

#### Tema Visual
- Paleta Datadog purple adicionada ao `tailwind.config.js`:
  - `dd-50` a `dd-900` com cor principal `dd-600 = #632CA6`
- Todas as classes `blue-*` e `indigo-*` substituídas por `dd-*` nos 3 componentes de página

#### Bug Fix — Cache entre sessões
- `useLogout`: adicionado `queryClient.clear()` antes de deslogar
- `useLogin` / `useRegister`: adicionado `queryClient.clear()` no `onSuccess`
- Garante que dados da sessão anterior não apareçam ao logar com nova conta

#### Dados de Teste
- 10 usuários dummy criados via API (`alice@dogpay.com` até `jack@dogpay.com`)
- Senha padrão: `password123`
- Saldo inicial: R$ 50.000.000,00 cada
- Migrations aplicadas manualmente via `psql` (fix no `init-db.sh` previne para futuras instâncias)

#### Frontend Mobile (`mobile/`)
- Flutter 3.41 + Dart, projeto criado com suporte iOS, Android e macOS
- Dependências: `dio`, `flutter_secure_storage`, `provider`, `go_router`, `intl`
- Tema unificado com o web: Datadog purple `#632CA6` em todo o app
- `AuthProvider`: gerencia estado de login com `AuthStatus` (unknown/authenticated/unauthenticated)
- `PaymentProvider`: carrega balance + history, auto-refresh a cada 10s via `Timer.periodic`
- `api_client.dart`: Dio com interceptor JWT + auto-refresh de token em respostas 401
- Screens: `LoginScreen`, `RegisterScreen`, `DashboardScreen`
- Dashboard: card de saldo com gradiente, pull-to-refresh, formulário de transferência, extrato
- iOS 26.2 Simulator runtime baixado (8.39 GB) e instalado via `xcodebuild -downloadPlatform iOS`
- Simulador "iPhone 16 - DogPay" criado (`A85DE849-575F-4276-8AC6-46E3312DE551`)
- App rodando no simulador iPhone 16 iOS 26.2

---

## Comandos Úteis

```bash
# Subir todos os serviços
cd ~/projects/dogpay && docker compose up --build

# Listar usuários no banco
docker exec dogpay-postgres psql -U dogpay -d dogpay \
  -c "SELECT u.name, u.email, a.balance FROM auth.users u JOIN payments.accounts a ON a.user_id = u.id ORDER BY u.name;"

# Rodar frontend mobile no simulador iPhone 16
cd ~/projects/dogpay/mobile
flutter run -d "A85DE849-575F-4276-8AC6-46E3312DE551"

# Rodar frontend mobile no macOS
cd ~/projects/dogpay/mobile
flutter run -d macos

# Hot reload (dentro do flutter run)
# r → hot reload
# R → hot restart
# q → quit
```

---

## Próximas Iterações

1. **Observabilidade**: Adicionar tracing (OpenTelemetry), métricas (Prometheus), logs estruturados (zerolog)
2. **Testes**: Unit tests para handlers e repository em Go; widget tests no Flutter
3. **Deploy AWS**: ECS/Fargate para serviços Go, RDS para PostgreSQL, SQS substituindo RabbitMQ, CloudFront para o frontend web
4. **API Gateway**: Nginx ou AWS API Gateway como ponto único de entrada
5. **Notificações**: Push notification no mobile ao completar transferências
6. **CI/CD**: GitHub Actions para build, test e deploy automático

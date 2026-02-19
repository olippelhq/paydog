# DogPay 🐾

Sistema de pagamentos simulado com arquitetura de microserviços.

## Serviços

| Serviço | Tecnologia | Porta |
|---|---|---|
| Frontend | React + Vite + Tailwind | 5173 |
| Auth Service | Go + Gin + PostgreSQL | 8001 |
| Payment Service | Go + Gin + PostgreSQL + RabbitMQ | 8002 |
| PostgreSQL | - | 5432 |
| RabbitMQ | - | 5672 / 15672 (UI) |

## Setup Rápido

### Pré-requisitos
- Docker + Docker Compose
- Go 1.22+ (para desenvolvimento local)
- Node.js 20+ (para desenvolvimento local)

### Rodando com Docker

```bash
# 1. Copiar variáveis de ambiente
cp .env.example .env

# 2. Subir todos os serviços
docker compose up --build

# 3. Acessar
# Frontend: http://localhost:5173
# Auth API: http://localhost:8001
# Payment API: http://localhost:8002
# RabbitMQ UI: http://localhost:15672 (dogpay/dogpay_secret)
```

### Desenvolvimento Local

```bash
# Auth Service
cd services/auth-service
go run ./cmd/main.go

# Payment Service
cd services/payment-service
go run ./cmd/main.go

# Frontend
cd frontend
npm install
npm run dev
```

## API Endpoints

### Auth Service (port 8001)

| Método | Endpoint | Descrição |
|---|---|---|
| POST | `/auth/register` | Criar conta |
| POST | `/auth/login` | Login |
| GET | `/auth/me` | Dados do usuário (JWT) |
| POST | `/auth/refresh` | Renovar token |
| GET | `/health` | Health check |

### Payment Service (port 8002)

| Método | Endpoint | Descrição |
|---|---|---|
| GET | `/payments/balance` | Saldo (JWT) |
| POST | `/payments/transfer` | Transferir (JWT) |
| GET | `/payments/history` | Extrato (JWT) |
| GET | `/health` | Health check |

## Fluxo de Transferência

```
Frontend → POST /payments/transfer
  → Payment Service valida JWT
  → Cria registro "pending" em transactions
  → Publica mensagem no RabbitMQ
  → Retorna 202 Accepted

Consumer (background goroutine):
  → Consome mensagem da fila
  → Inicia DB transaction
  → Debita conta origem / Credita conta destino
  → Atualiza status → "completed" (ou "failed")
```

## Testando com cURL

```bash
# Registrar
curl -X POST http://localhost:8001/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@example.com","password":"secret123","name":"Alice"}'

# Login
TOKEN=$(curl -s -X POST http://localhost:8001/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"alice@example.com","password":"secret123"}' | jq -r '.access_token')

# Saldo
curl -H "Authorization: Bearer $TOKEN" http://localhost:8002/payments/balance

# Transferir
curl -X POST http://localhost:8002/payments/transfer \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"to_email":"bob@example.com","amount":50.00,"description":"Teste"}'
```

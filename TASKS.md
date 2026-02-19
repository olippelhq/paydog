# DogPay - Tasks

> Sistema de gerenciamento de tarefas para o projeto DogPay

## Status Legend
- 🔵 **TODO**: Tarefa planejada
- 🟡 **IN_PROGRESS**: Em andamento
- 🟢 **DONE**: Concluída
- 🔴 **BLOCKED**: Bloqueada (aguardando dependência)
- ⚪ **CANCELLED**: Cancelada

---

## Backlog

### 🔵 TODO - Observabilidade
**Descrição**: Adicionar OpenTelemetry (tracing), Prometheus (métricas) e logs estruturados (zerolog/zap) aos serviços Go
**Data Criação**: 2026-02-19
**Prioridade**: Média
**Dependências**: Fase 1-5 completas

### 🔵 TODO - Testes Automatizados
**Descrição**: Unit tests para handlers e repository em ambos os serviços Go; widget tests no Flutter; integration tests com Docker Compose
**Data Criação**: 2026-02-19
**Prioridade**: Média
**Dependências**: Fase 1-5 completas

### 🔵 TODO - Push Notifications Mobile
**Descrição**: Notificar o usuário no app mobile quando uma transferência for concluída ou recebida (via Firebase Cloud Messaging ou APNs)
**Data Criação**: 2026-02-19
**Prioridade**: Média
**Dependências**: Frontend Mobile completo

### 🔵 TODO - CI/CD
**Descrição**: GitHub Actions para build, lint, test e deploy automático de todos os serviços
**Data Criação**: 2026-02-19
**Prioridade**: Média
**Dependências**: Testes Automatizados

### 🔵 TODO - Deploy AWS
**Descrição**: ECS/Fargate para serviços Go, RDS para PostgreSQL, SQS substituindo RabbitMQ, CloudFront para frontend web
**Data Criação**: 2026-02-19
**Prioridade**: Baixa
**Dependências**: Observabilidade, CI/CD

### 🔵 TODO - API Gateway
**Descrição**: Nginx ou AWS API Gateway como ponto único de entrada para os microserviços (elimina necessidade de CORS por serviço)
**Data Criação**: 2026-02-19
**Prioridade**: Baixa
**Dependências**: Deploy AWS

---

## Em Progresso

_(Nenhuma tarefa em andamento)_

---

## Concluídas

### 🟢 DONE - Estrutura de Projeto Criada
**Descrição**: Criação da estrutura inicial de diretórios e arquivos de planejamento
**Data Conclusão**: 2026-02-11
**Tempo Gasto**: 30 minutos

### 🟢 DONE - Arquitetura e Stack Definidos
**Descrição**: Arquitetura de 3 serviços (Frontend + Auth + Payment) com PostgreSQL e RabbitMQ; decisões documentadas no PLAN.md
**Data Conclusão**: 2026-02-19

### 🟢 DONE - Fase 1: Docker + Infraestrutura
**Descrição**: `docker-compose.yml` com PostgreSQL 16 + RabbitMQ 3.13, `.env`/`.env.example`, `scripts/init-db.sh`, migrations SQL, Git init
**Data Conclusão**: 2026-02-19
**Verificação**: `docker compose up` → PostgreSQL em `localhost:5432`, RabbitMQ UI em `localhost:15672`

### 🟢 DONE - Fase 2: Auth Service
**Descrição**: Go 1.22 + Gin + pgx + JWT + bcrypt. Endpoints: `POST /auth/register`, `POST /auth/login`, `GET /auth/me`, `POST /auth/refresh`, `GET /health`. Notifica Payment Service ao registrar usuário.
**Data Conclusão**: 2026-02-19
**Verificação**: `go build ./...` compila sem erros

### 🟢 DONE - Fase 3: Frontend Web
**Descrição**: React 18 + Vite 6 + TypeScript + Tailwind CSS. Pages: LoginPage, RegisterPage, DashboardPage. Zustand + TanStack Query + Axios com interceptor JWT.
**Data Conclusão**: 2026-02-19
**Verificação**: `npm run build` — build de produção bem-sucedido (260 kB JS)

### 🟢 DONE - Fase 4: Payment Service
**Descrição**: Go 1.22 + Gin + pgx + RabbitMQ (amqp091-go). Endpoints: `GET /payments/balance`, `POST /payments/transfer`, `GET /payments/history`, `GET /health`, `POST /internal/accounts`. Consumer goroutine com `SELECT ... FOR UPDATE` e DLQ.
**Data Conclusão**: 2026-02-19
**Verificação**: `go build ./...` compila sem erros

### 🟢 DONE - Fase 5: Integração
**Descrição**: CORS configurado em ambos os serviços Go, README criado com instruções e exemplos cURL, `.gitignore` configurado, PLAN.md e TASKS.md documentados
**Data Conclusão**: 2026-02-19

### 🟢 DONE - Tema Visual Datadog Purple
**Descrição**: Substituição de todas as cores azuis/índigo pelo roxo da Datadog (`#632CA6`) no frontend web. Paleta `dd-50` a `dd-900` criada no `tailwind.config.js` e aplicada em LoginPage, RegisterPage e DashboardPage.
**Data Conclusão**: 2026-02-19

### 🟢 DONE - Fix: Migrations Automáticas no Docker
**Descrição**: `scripts/init-db.sh` corrigido para iterar e aplicar os arquivos `.sql` dos subdiretórios `/docker-entrypoint-initdb.d/auth/` e `/docker-entrypoint-initdb.d/payment/` automaticamente no primeiro boot do PostgreSQL.
**Data Conclusão**: 2026-02-19

### 🟢 DONE - Fix: Cache de Dados entre Sessões
**Descrição**: Bug onde ao fazer logout e logar com outra conta, o dashboard exibia dados da sessão anterior. Corrigido chamando `queryClient.clear()` (web) no login e logout, garantindo que o cache do React Query seja limpo ao trocar de usuário.
**Data Conclusão**: 2026-02-19

### 🟢 DONE - Dados de Teste (Seed)
**Descrição**: 10 usuários dummy criados via API (`alice@dogpay.com` até `jack@dogpay.com`, senha `password123`) com saldo de R$ 50.000.000,00 cada. Contas vinculadas no schema `payments`.
**Data Conclusão**: 2026-02-19

### 🟢 DONE - Frontend Mobile (Flutter)
**Descrição**: App Flutter 3.41 com suporte iOS, Android e macOS. Screens: LoginScreen, RegisterScreen, DashboardScreen. Tema Datadog purple consistente com o web. Dio com interceptor JWT + auto-refresh. flutter_secure_storage para tokens. Provider para state management. go_router para navegação. Auto-refresh de saldo e extrato a cada 10s.
**Data Conclusão**: 2026-02-19
**Verificação**: `flutter analyze` — zero erros; app rodando no simulador iPhone 16 iOS 26.2

### 🟢 DONE - iOS 26.2 Simulator Runtime
**Descrição**: Runtime do simulador iOS 26.2 baixado (8.39 GB) via `xcodebuild -downloadPlatform iOS`. Simulador "iPhone 16 - DogPay" criado (`A85DE849-575F-4276-8AC6-46E3312DE551`). App Flutter validado e rodando no simulador.
**Data Conclusão**: 2026-02-19

---

## Bloqueadas

_(Nenhuma tarefa bloqueada)_

---

## Notas
- Para rodar o projeto completo: `docker compose up --build` na raiz do projeto
- RabbitMQ Management UI: http://localhost:15672 (`dogpay` / `dogpay_secret`)
- Frontend web: http://localhost:5173
- Rodar mobile no simulador: `flutter run -d "A85DE849-575F-4276-8AC6-46E3312DE551"` em `~/projects/dogpay/mobile`
- Rodar mobile no macOS: `flutter run -d macos` em `~/projects/dogpay/mobile`
- Usuários de teste: `alice@dogpay.com` … `jack@dogpay.com` — senha: `password123`

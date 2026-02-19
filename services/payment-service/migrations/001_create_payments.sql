-- Payments schema migrations
CREATE SCHEMA IF NOT EXISTS payments;

CREATE TABLE IF NOT EXISTS payments.accounts (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL UNIQUE,
    balance     NUMERIC(20, 2) NOT NULL DEFAULT 0.00,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON payments.accounts(user_id);

CREATE TYPE payments.transaction_status AS ENUM ('pending', 'completed', 'failed');

CREATE TABLE IF NOT EXISTS payments.transactions (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_account_id   UUID REFERENCES payments.accounts(id),
    to_account_id     UUID NOT NULL REFERENCES payments.accounts(id),
    amount            NUMERIC(20, 2) NOT NULL CHECK (amount > 0),
    status            payments.transaction_status NOT NULL DEFAULT 'pending',
    description       TEXT,
    error_message     TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_transactions_from_account ON payments.transactions(from_account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_to_account ON payments.transactions(to_account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON payments.transactions(status);

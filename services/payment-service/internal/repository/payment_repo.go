package repository

import (
	"context"
	"fmt"

	"github.com/dogpay/payment-service/internal/models"
	"github.com/jackc/pgx/v5/pgxpool"
)

type PaymentRepository struct {
	db *pgxpool.Pool
}

func NewPaymentRepository(db *pgxpool.Pool) *PaymentRepository {
	return &PaymentRepository{db: db}
}

func (r *PaymentRepository) CreateAccount(ctx context.Context, userID string) (*models.Account, error) {
	account := &models.Account{}
	err := r.db.QueryRow(ctx, `
		INSERT INTO payments.accounts (user_id, balance)
		VALUES ($1, 1000.00)
		ON CONFLICT (user_id) DO UPDATE SET updated_at = NOW()
		RETURNING id, user_id, balance, created_at, updated_at
	`, userID).Scan(&account.ID, &account.UserID, &account.Balance, &account.CreatedAt, &account.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("create account: %w", err)
	}
	return account, nil
}

func (r *PaymentRepository) GetAccountByUserID(ctx context.Context, userID string) (*models.Account, error) {
	account := &models.Account{}
	err := r.db.QueryRow(ctx, `
		SELECT id, user_id, balance, created_at, updated_at
		FROM payments.accounts
		WHERE user_id = $1
	`, userID).Scan(&account.ID, &account.UserID, &account.Balance, &account.CreatedAt, &account.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("get account by user_id: %w", err)
	}
	return account, nil
}

func (r *PaymentRepository) GetAccountByEmail(ctx context.Context, email string) (*models.Account, error) {
	account := &models.Account{}
	err := r.db.QueryRow(ctx, `
		SELECT pa.id, pa.user_id, pa.balance, pa.created_at, pa.updated_at
		FROM payments.accounts pa
		JOIN auth.users au ON au.id = pa.user_id
		WHERE au.email = $1
	`, email).Scan(&account.ID, &account.UserID, &account.Balance, &account.CreatedAt, &account.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("get account by email: %w", err)
	}
	return account, nil
}

func (r *PaymentRepository) CreatePendingTransaction(ctx context.Context, fromAccountID, toAccountID string, amount float64, description string) (*models.Transaction, error) {
	tx := &models.Transaction{}
	err := r.db.QueryRow(ctx, `
		INSERT INTO payments.transactions (from_account_id, to_account_id, amount, status, description)
		VALUES ($1, $2, $3, 'pending', $4)
		RETURNING id, from_account_id, to_account_id, amount, status, description, error_message, created_at, updated_at
	`, fromAccountID, toAccountID, amount, description).Scan(
		&tx.ID, &tx.FromAccountID, &tx.ToAccountID, &tx.Amount, &tx.Status,
		&tx.Description, &tx.ErrorMessage, &tx.CreatedAt, &tx.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("create pending transaction: %w", err)
	}
	return tx, nil
}

func (r *PaymentRepository) ProcessTransfer(ctx context.Context, transactionID, fromAccountID, toAccountID string, amount float64) error {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// Check and debit sender
	var fromBalance float64
	err = tx.QueryRow(ctx, `
		SELECT balance FROM payments.accounts WHERE id = $1 FOR UPDATE
	`, fromAccountID).Scan(&fromBalance)
	if err != nil {
		return r.failTransaction(ctx, transactionID, "sender account not found")
	}

	if fromBalance < amount {
		return r.failTransaction(ctx, transactionID, "insufficient funds")
	}

	// Debit sender
	_, err = tx.Exec(ctx, `
		UPDATE payments.accounts SET balance = balance - $1, updated_at = NOW() WHERE id = $2
	`, amount, fromAccountID)
	if err != nil {
		return r.failTransaction(ctx, transactionID, "failed to debit sender")
	}

	// Credit recipient
	_, err = tx.Exec(ctx, `
		UPDATE payments.accounts SET balance = balance + $1, updated_at = NOW() WHERE id = $2
	`, amount, toAccountID)
	if err != nil {
		return r.failTransaction(ctx, transactionID, "failed to credit recipient")
	}

	// Mark completed
	_, err = tx.Exec(ctx, `
		UPDATE payments.transactions SET status = 'completed', updated_at = NOW() WHERE id = $1
	`, transactionID)
	if err != nil {
		return fmt.Errorf("update transaction status: %w", err)
	}

	return tx.Commit(ctx)
}

func (r *PaymentRepository) failTransaction(ctx context.Context, transactionID, reason string) error {
	_, err := r.db.Exec(ctx, `
		UPDATE payments.transactions SET status = 'failed', error_message = $1, updated_at = NOW() WHERE id = $2
	`, reason, transactionID)
	return err
}

func (r *PaymentRepository) GetTransactionHistory(ctx context.Context, accountID string) ([]models.Transaction, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id, from_account_id, to_account_id, amount, status, description, error_message, created_at, updated_at
		FROM payments.transactions
		WHERE from_account_id = $1 OR to_account_id = $1
		ORDER BY created_at DESC
		LIMIT 50
	`, accountID)
	if err != nil {
		return nil, fmt.Errorf("get transaction history: %w", err)
	}
	defer rows.Close()

	var txs []models.Transaction
	for rows.Next() {
		var tx models.Transaction
		if err := rows.Scan(
			&tx.ID, &tx.FromAccountID, &tx.ToAccountID, &tx.Amount, &tx.Status,
			&tx.Description, &tx.ErrorMessage, &tx.CreatedAt, &tx.UpdatedAt,
		); err != nil {
			return nil, err
		}
		txs = append(txs, tx)
	}
	return txs, nil
}
